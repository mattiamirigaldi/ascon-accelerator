# Hardware Design of Ascon (SP 800-232)

[Ascon](https://ascon.iaik.tugraz.at) is a family of authenticated encryption and hashing algorithms designed to be lightweight and easy to implement, even with added countermeasures against side-channel attacks. Ascon has been selected as the new standard for lightweight cryptography in the [NIST Lightweight Cryptography competition](https://csrc.nist.gov/Projects/Lightweight-Cryptography) (2019–2023). The current draft standard of Ascon is available [here](https://doi.org/10.6028/NIST.SP.800-232.ipd).

## Implementation Overview

This repository contains an RTL implementation of the Ascon initialization phase with a programmable S-box implemented as memory writable externally. The accelerator is integrated into X-HEEP as a loosely coupled accelerator.

## ascon\_init Module

The `ascon_init` module performs the initialization phase of the Ascon algorithm. It initializes the internal state using provided inputs and applies the Ascon permutation function for 12 rounds. The module implements a two-state FSM (IDLE and BUSY), transitioning from IDLE to BUSY upon receiving the start signal and returning to IDLE after completing the rounds. The S-box transformation is implemented via an external programmable lookup table that can be configured through a register interface.

## Files Description

RTL implementation files:

* `ascon_init.sv`: RTL implementation of the Ascon initialization phase.
* `ascon_wrapper.sv`: Wrapper module that instantiates `ascon_init` and integrates it as a loosely coupled accelerator in X-HEEP. It provides memory-mapped interfaces for data registers, control and status registers, and the programmable S-box.
* `asconp_lut.sv`
* `ascon_reg_pkg.sv`
* `ascon_regs.sv`
* `ascon_reg_top.sv`
* `ascon_sbox_reg_pkg.sv`
* `ascon_sbox_reg_top.sv`
* `config.sv`
* `sbox_registers_lut.sv`
* `sub_layer_lut.sv`

Other supporting files:

* `surfer/`: Files for the [Surfer](https://surfer-project.org/) waveform viewer.
* `synth/`: Files for [Yosys](https://github.com/YosysHQ/yosys) synthesis.
* `operations_init`: Python reference implementation of Ascon, used by `test.py`.
* `LICENSE`: License file.
* `Makefile`: Makefile for RTL simulation, RTL synthesis, and waveform viewing.
* `README.md`: This README.
* `test_ascon_init.py`: Python script for running the [cocotb](https://www.cocotb.org/) test bench.

## Interface

| **Name**         | **Bits**       | **Description**                                          |
| ---------------- | -------------- | -------------------------------------------------------- |
| `clk_i`          | 1              | Clock signal.                                            |
| `rst_n_i`        | 1              | Reset signal (active low).                               |
| `start_i`        | 1              | Start signal to initiate initialization phase.           |
| `finished_o`     | 1              | Indicates completion of initialization (high when done). |
| `state_i`        | 320 (5×64-bit) | Input state for initialization.                          |
| `state_o`        | 320 (5×64-bit) | Output state after initialization.                       |
| `update_state_o` | 1              | Indicates that the output state is valid.                |
| `sbox_reg_req_i` | Custom         | S-box register interface request.                         |
| `sbox_reg_rsp_o` | Custom         | S-box register interface response.                        |
| `ascon_intr_o`   | 1              | Interrupt signal indicating initialization completion.   |

## RTL Simulation

* Install Verilator:

  * Ubuntu: `apt-get install verilator`
  * Fedora: `dnf install verilator verilator-devel`
  * [Build from source](https://verilator.org/guide/latest/install.html#git-quick-install)

* Install cocotb:

  * `pip install cocotb`

* Execute testbench:

  * `make` or `make sim`

## RTL Synthesis

* Install Yosys (tested version `0.53`):

  * Ubuntu: `apt-get install yosys`
  * Fedora: `dnf install yosys`

* Execute synthesis:

  * `make syn`

## RTL Post-Synthesis Simulation

* Run synthesis: `make syn`
* Run synthesized simulation: `make sim syn=1`

## View Waveforms

* Ensure Verilator version >= `v5.0.38`.

* Uncomment `--trace` in Makefile.

* Install [Surfer](https://surfer-project.org/):

  * `cargo install --git https://gitlab.com/surfer-project/surfer surfer`

* View waveform:

  * `make sim`
  * `make surf`

* View synthesized waveform:

  * `make syn`
  * `make sim syn=1`
  * `make surf syn=1`

## Integration in X-HEEP

The `ascon_wrapper.sv` module integrates the accelerator as loosely coupled within the X-HEEP platform. It includes memory-mapped interfaces for data registers, control/status registers, and external S-box memory access. The wrapper allows the processor to control the initialization phase, monitor its progress via interrupts, and configure the S-box through standard register interfaces.

## Contact

* Mattia Mirigaldi ([GitHub](https://github.com/mattiamirigaldi))
