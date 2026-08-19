# Hack & RISC-V RV32I VHDL CPU Core Implementation

A VHDL implementation of both the **Nand2Tetris 16-bit Hack CPU**, the **32-bit RISC-V RV32I Processor Core**, and a **Unified Auto-Detection Micro-Op Translation CPU Core**.

## Project Architecture

### 1. Unified Auto-Detection Translation Processor (`unified_cpu.vhd`)
Integrates the 32-bit RISC-V execution hardware (32-bit ALU & 32x32-bit Register File) with a **First-Instruction Auto Mode Detector** and a **Hack-to-RV32I Micro-Op Translator**:
- `auto_mode_detector.vhd`: Inspects the instruction fetched at `PC = 0x00000000` on reset to automatically detect whether the program is Hack 16-bit or RISC-V 32-bit.
- `hack_translator.vhd`: Translates 16-bit Hack A/C instructions into 32-bit RISC-V micro-ops (mapping Hack $A \to x1$ and $D \to x2$).
- `unified_cpu.vhd`: Top-level CPU core executing both Hack and RISC-V machine code seamlessly.
- `unified_cpu_tb.vhd`: Testbench verifying first-instruction auto-detection and execution.

### 2. Standalone 16-Bit Hack CPU Core
- `alu.vhd`: 16-bit ALU (Arithmetic Logic Unit).
- `decode.vhd`: Instruction decoder for Hack A-instructions and C-instructions.
- `cpu.vhd`: Top-level Hack CPU core combining PC, Register file, ALU, and Decoder.
- `alu_test.vhd`: Testbench for 16-bit ALU operations.
- `decode_test.vhd`: Testbench for Hack instruction decoder.
- `cpu_test.vhd`: Testbench for Hack CPU execution.

### 3. Standalone 32-Bit RISC-V RV32I CPU Core
- `rv32i_types.vhd`: RISC-V opcodes, funct3/funct7 definitions, and ALU operation package.
- `rv32i_regfile.vhd`: 32 x 32-bit Register File (with $x0$ hardwired to 0).
- `rv32i_alu.vhd`: 32-bit ALU supporting ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND operations.
- `rv32i_decode.vhd`: 32-bit Instruction Decoder and immediate sign-extension generator (R, I, S, B, U, J types).
- `rv32i_cpu.vhd`: Top-level RISC-V RV32I single-cycle processor core.
- `rv32i_cpu_tb.vhd`: Testbench for RV32I instruction execution.

---

## Simulation & Testing with Open Source Tools

This project uses **[GHDL](https://ghdl.github.io/ghdl/)** (VHDL-2008 standard) for open-source VHDL simulation, **[GTKWave](http://gtkwave.sourceforge.net/)** for waveform visualization, and **[GitHub Actions](https://github.com/features/actions)** for Continuous Integration (CI).

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

Run all testbenches:
```bash
make test
```

Run specific test suites:
```bash
make test-unified   # Test Auto-Detection Translation CPU Core
make test-hack      # Test Standalone Hack 16-bit CPU Core
make test-rv32i     # Test Standalone RISC-V 32-bit CPU Core
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
