# Hack CPU VHDL Implementation

An implementation of the CPU of the Hack architecture from [Nand2Tetris](https://www.nand2tetris.org/) written in VHDL.

## Project Structure
- `alu.vhd`: 16-bit ALU (Arithmetic Logic Unit).
- `decode.vhd`: Instruction decoder for Hack A-instructions and C-instructions.
- `cpu.vhd`: Top-level CPU core combining PC, Register file, ALU, and Decoder.
- `alu_test.vhd`: Testbench for ALU operations.
- `decode_test.vhd`: Testbench for instruction decoder.
- `cpu_test.vhd`: Testbench for CPU execution.

## Simulation & Testing with Open Source Tools

This project uses **[GHDL](https://ghdl.github.io/ghdl/)** for open-source VHDL simulation and **[GTKWave](http://gtkwave.sourceforge.net/)** for waveform visualization.

### Prerequisites

On Fedora Linux:
```bash
sudo dnf install -y ghdl gtkwave make
```

On Ubuntu/Debian:
```bash
sudo apt-get install -y ghdl gtkwave make
```

### Running Tests

Run all testbenches (`alu_test`, `decode_test`, `cpu_test`):
```bash
make test
```

Run individual testbenches:
```bash
make test-alu
make test-decode
make test-cpu
```

### Waveform Inspection

To simulate and open the generated VCD waveform in GTKWave:
```bash
make wave
```

Clean build artifacts:
```bash
make clean
```
