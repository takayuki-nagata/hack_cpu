# Hack & RISC-V RV32I VHDL CPU Core Implementation

A VHDL implementation of both the **Nand2Tetris 16-bit Hack CPU** and the **32-bit RISC-V RV32I Processor Core**.

## Project Architecture

### 16-Bit Hack CPU Core
- `alu.vhd`: 16-bit ALU (Arithmetic Logic Unit).
- `decode.vhd`: Instruction decoder for Hack A-instructions and C-instructions.
- `cpu.vhd`: Top-level Hack CPU core combining PC, Register file, ALU, and Decoder.
- `alu_test.vhd`: Testbench for 16-bit ALU operations.
- `decode_test.vhd`: Testbench for Hack instruction decoder.
- `cpu_test.vhd`: Testbench for Hack CPU execution.

### 32-Bit RISC-V RV32I CPU Core
- `rv32i_types.vhd`: RISC-V opcodes, funct3/funct7 definitions, and ALU operation package.
- `rv32i_regfile.vhd`: 32 x 32-bit Register File (with $x0$ hardwired to 0).
- `rv32i_alu.vhd`: 32-bit ALU supporting ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND operations.
- `rv32i_decode.vhd`: 32-bit Instruction Decoder and immediate sign-extension generator (R, I, S, B, U, J types).
- `rv32i_cpu.vhd`: Top-level RISC-V RV32I single-cycle processor core.
- `rv32i_cpu_tb.vhd`: Testbench for RV32I instruction execution.

---

## Simulation & Testing with Open Source Tools

This project uses **[GHDL](https://ghdl.github.io/ghdl/)** (VHDL-2008 standard) for open-source VHDL simulation and **[GTKWave](http://gtkwave.sourceforge.net/)** for waveform visualization.

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

Run all testbenches (both Hack CPU and RV32I RISC-V CPU):
```bash
make test
```

Run Hack CPU tests:
```bash
make test-hack
```

Run RV32I RISC-V CPU testbench:
```bash
make test-rv32i
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
