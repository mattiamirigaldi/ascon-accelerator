# Hardware Design of Ascon (SP 800-232)

[Ascon](https://ascon.iaik.tugraz.at) is a family of authenticated encryption and hashing algorithms designed to be lightweight and easy to implement, even with added countermeasures against side-channel attacks. Ascon has been selected as new standard for lightweight cryptography in the [NIST Lightweight Cryptography competition](https://csrc.nist.gov/Projects/Lightweight-Cryptography) (2019–2023). The current draft standard of Ascon is available [here](https://doi.org/10.6028/NIST.SP.800-232.ipd).

## Files

- `rtl/`: SystemVerilog implementation of the Ascon core.
- `surfer/`: Files for the [Surfer](https://surfer-project.org/) waveform viewer.
- `synth/`: Files for [Yosys](https://github.com/YosysHQ/yosys) synthesis.
- `ascon.py`: Python reference implementation of Ascon, used by `test.py`.
- `LICENSE`: License file.
- `Makefile`: Makefile for rtl simulation, rtl synthesis, and waveform viewing.
- `README.md`: This README.
- `test.py`: Python script for running the [cocotb](https://www.cocotb.org/) test bench.

## Interface

The following table contains a description of the interface signals:

| **Name**     | **Bits** | **Description**                                  |
|--------------|:--------:|--------------------------------------------------|
| `clk`        |     1    | Clock signal.                                    |
| `rst`        |     1    | Reset signal. Note: Synchronous active high.     |

## RTL Simulation

- Install the Verilator open-source verilog simulator:
  - Ubuntu:
    - `apt-get install verilator`
  - Fedora:
    - `dnf install verilator`
    - `dnf install verilator-devel`
  - Build from source:
    - [Git Quick Install](https://verilator.org/guide/latest/install.html#git-quick-install)
- Install the [cocotb](https://www.cocotb.org/) open-source verilog test bench environment:
  - `pip install cocotb`
- Execute the cocotb test bench:
  - `make` or `make sim`

## RTL Synthesis

- Install the Yosys open-source synthesis suite (tested with version `0.53`):
  - Ubuntu:
    - `apt-get install yosys`
  - Fedora:
    - `dnf install yosys`
- Execute the yosys synthesis script:
  - `make syn`

## RTL Post-Synthesis Simulation

- Execute the yosys synthesis script:
  - `make syn`
- Execute the cocotb test bench for synthesized RTL:
  - `make sim syn=1`

## View Waveforms

- Make sure you have a recent verilator version (>= `v5.0.38`).
- Uncomment all `--trace` arguments in the Makefile.
- Install the [Surfer](https://surfer-project.org/) waveform viewer.
  - `cargo install --git https://gitlab.com/surfer-project/surfer surfer`
- View waveform of cocotb test bench run:
  - `make` or `make sim`
  - `make surf`
- View waveform of post-synthesis cocotb test bench run:
  - `make syn`
  - `make sim syn=1`
  - `make surf syn=1`
- Example waveform of test bench output:

<p align="center">
<img src="surfer/surfer.png" alt="Surfer waveform viewer" width="600"/>
</p>

## Integration in X-Heep 

## Contact

- Mattia Mirigaldi (https://github.com/mattiamirigaldi)

