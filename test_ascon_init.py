import cocotb
from cocotb.triggers import RisingEdge
from cocotb.clock import Clock

from operations_init import ascon_init
import sboxes 

VERBOSE = 2

KEY   = bytes.fromhex("000102030405060708090A0B0C0D0E0F")
NONCE = bytes.fromhex("00112233445566778899AABBCCDDEEFF")

def five_words_to_int(state_bytes: bytes) -> list[int]:
    # convert 40 bytes to five 64-bit integers [S0, S1, S2, S3, S4] 
    assert len(state_bytes) == 40
    return [int.from_bytes(state_bytes[i*8:(i+1)*8], "big") for i in range(5)]

def int_to_320bv(words: list[int]) -> int:
    """Pack five 64-bit ints [S4‖S3‖S2‖S1‖S0] into one 320-bit integer."""
    assert len(words) == 5
    out = 0
    for w in reversed(words):          # S4 is MSW
        out = (out << 64) | (w & ((1<<64)-1))
    return out

async def clear_ascon_init(dut):
    dut.rst_n.value = 0
    dut.start_i.value = 0
    dut.upd_sbox_i.value = 0
    dut.sbox_addr_i.value = 0
    dut.sbox_new_data_i.value = 0
    dut.state_i.value = [0] * 320 # 5 * 64 bits
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

async def reset_dut(dut):
    dut.rst_n.value = 0
    dut.start_i.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

async def send_state(dut, words):
    # wait until DUT idle
    while int(dut.busy_o.value):
        await RisingEdge(dut.clk)
    dut.state_i.value = int_to_320bv(words)
    dut.start_i.value = 1
    await RisingEdge(dut.clk)
    dut.start_i.value = 0  # drop the pulse
    await RisingEdge(dut.clk)   

async def receive_state(dut):
    while int(dut.busy_o.value):
        await RisingEdge(dut.clk)
    raw = dut.state_o.value.integer     # one 320-bit integer converted to Python int
    out = [(raw >> (64*i)) & ((1 << 64) - 1) for i in range(5)]  # S0=Lsb
    return list(out)    # [S4, S3, S2, S1, S0]

async def update_sbox(dut, sbox_addr, sbox_new_data):
    dut.upd_sbox_i.value = 1
    dut.sbox_addr_i.value = sbox_addr
    dut.sbox_new_data_i.value = sbox_new_data
    await RisingEdge(dut.clk)
    dut.upd_sbox_i.value = 0
    await RisingEdge(dut.clk)

async def update_sbox_from_type(dut, sbox_type, start_addr):
    """
    Update the hardware S-box with 4 consecutive entries from the specified S-box type.
    """
    # Get the 20-bit update data from 4 consecutive S-box entries
    update_data = sboxes.get_sbox_update_data(sbox_type, start_addr)
    # Update the hardware S-box
    await update_sbox(dut, start_addr, update_data)
    if VERBOSE >= 2:
        dut._log.info(f"Updated S-box with {sbox_type} entries [{start_addr}-{start_addr+3}]: 0x{update_data:05x}")

async def load_complete_sbox(dut, sbox_type):
    """
    Load a complete S-box into the hardware by updating consecutive non-overlapping 4-entry groups.
    Groups: [0-3], [4-7], [8-11], [12-15], [16-19], [20-23], [24-27], [28-31]
    """
    dut._log.info(f"Loading complete S-box: {sbox_type}")
    # Load consecutive non-overlapping 4-entry groups
    for group in range(8):  # 8 groups: 0, 1, 2, 3, 4, 5, 6, 7
        start_addr = group * 4  # 0, 4, 8, 12, 16, 20, 24, 28
        await update_sbox_from_type(dut, sbox_type, start_addr)
    dut._log.info(f"Completed loading S-box: {sbox_type}")
    
# Toggle the value of one signal
async def toggle(dut, signalStr, value):
    eval(signalStr, dict(dut=cocotb.top)).value = value
    await RisingEdge(dut.clk)
    eval(signalStr, dict(dut=cocotb.top)).value = 0

# Log the content of multiple byte arrays
def log(dut, verbose, dashes, **kwargs):
    if verbose <= VERBOSE:
        for k, val in kwargs.items():
            dut._log.info(
                "%s %s %s",
                k,
                " " * (8 - len(k)),
                "".join("{:02X}".format(x) for x in val),
            )
        if dashes:
            dut._log.info("------------------------------------------")
    
@cocotb.test()
async def test_init(dut):
    # start clock
    cocotb.start_soon(Clock(dut.clk, 1, "ns").start())
    
    for sbox_type in sboxes.sbox.keys():
        print(f"Testing S-box type: {sbox_type}")
        # reset
        await reset_dut(dut)

        # -------- SW reference ----------
        # ascon_init returns the output state laid out as 40 bytes which corresponds to S0[63:0] ‖ S1[63:0] ‖ S2[63:0] ‖ S3[63:0] ‖ S4[63:0]
        result_sw_bytes = ascon_init(KEY, NONCE, "Ascon-128", sbox_type)
        result_sw_words = five_words_to_int(result_sw_bytes)

        # -------- HW -----------
        # Load S-box into HW 
        await load_complete_sbox(dut, sbox_type)
        # Send initial state to HW
        await send_state(dut, five_words_to_int(
            bytes([0x80, 0x40, 0x0c, 0x06]) + b"\x00"*4 + KEY + NONCE))  # IV||0^12||key||nonce
        result_hw_words = await receive_state(dut)

        # --- Run 10 more cycles ---
        for _ in range(10):
            await RisingEdge(dut.clk)

        log(dut, verbose=2, dashes=1)

        mismatches = [
            f"Word {i}: SW={sw:016X}  HW={hw:016X}"
            for i, (sw, hw) in enumerate(zip(result_sw_words, result_hw_words))
            if sw != hw
        ]

        if mismatches:
            for line in mismatches:
                dut._log.error(line)
            dut._log.error(f"❌ With {sbox_type} total mismatches = {len(mismatches)}")
        else:
            dut._log.info(f"✅ With {sbox_type} hardware matches golden model")
