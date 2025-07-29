typedef logic [4:0][63:0] state_t;

module ascon_wrapper
    import reg_pkg::*;
    import ascon_pkg::*;
    (
    input logic                    clk_i,
    input logic                    rst_n_i,
    // Register interface
    input reg_req_t                reg_req_i,
    output reg_rsp_t               reg_rsp_o,
    // Interrupt
    output logic                   intr_o
);

    logic start, finished, update_state;
    state_t input_state, ascon_state;
    
    // Separate register interface signals for address decoding
    reg_req_t ascon_reg_req, sbox_reg_req;
    reg_rsp_t ascon_reg_rsp, sbox_reg_rsp;
    
    /*
     * Memory Map Address Decoding:
     *
     * The ASCON wrapper contains two separate register files:
     * 1. ASCON Main Registers (ascon_reg_top) - Contains status and state registers
     * 2. ASCON SBOX Registers (ascon_sbox_reg_top) - Contains S-box lookup table
     *
     * Address Mapping:
     * - Bit 7 of the address is used as the register file selector
     * - addr[7] = 0: Access ASCON Main Registers (0x00-0x7F)
     *             Contains: status, state_0 through state_9 registers
     * - addr[7] = 1: Access ASCON SBOX Registers (0x80-0xFF)
     *             Contains: sbox_0 through sbox_7 lookup table registers
     *
     * External drivers should use the following addressing:
     * - ASCON_BASE_ADDR + 0x00-0x7F for main control/status operations
     * - ASCON_BASE_ADDR + 0x80-0xFF for S-box lookup table access
     */
    
    logic [1:0] addr_hit;
    always_comb begin
        addr_hit = 2'b00;
        addr_hit[0] = (reg_req_i.addr[7]);   // S-box registers (0x80-0xFF)
        addr_hit[1] = (~reg_req_i.addr[7]);  // Main registers (0x00-0x7F)
    end

    // Register request routing and response multiplexing
    always_comb begin
        // Default values
        ascon_reg_req = '0;
        sbox_reg_req = '0;
        reg_rsp_o = '0;

        unique case (1'b1)
            addr_hit[0]: begin  // S-box register access
                sbox_reg_req = reg_req_i;
                reg_rsp_o = sbox_reg_rsp;
            end
            addr_hit[1]: begin  // Main register access
                ascon_reg_req = reg_req_i;
                reg_rsp_o = ascon_reg_rsp;
            end
            default: begin
                reg_rsp_o = '0;
            end
        endcase
    end

    ascon_init ascon_init_inst (
        .clk_i          (clk_i),
        .rst_n_i        (rst_n_i),
        // Register interface to Sbox - connected to S-box register file
        .sbox_reg_req_i (sbox_reg_req),
        .sbox_reg_rsp_o (sbox_reg_rsp),
        // Status signals
        .start_i        (start),
        .finished_o     (finished),
        // State interface
        .state_i        (input_state),
        .state_o        (ascon_state),
        .update_state_o (update_state),
        // Interrupt output
        .ascon_intr_o   (intr_o)
    );

    ascon_regs ascon_regs_inst (
        .clk_i          (clk_i),
        .rst_n_i        (rst_n_i),
        // Register interface - connected to main register file
        .reg_req_i      (ascon_reg_req),
        .reg_rsp_o      (ascon_reg_rsp),
        // Control signals
        .start_o        (start),
        .finished_i     (finished),
        // State interface
        .update_state_i (update_state),
        .state_i        (ascon_state),
        .state_o        (input_state)
    );

endmodule : ascon_wrapper
