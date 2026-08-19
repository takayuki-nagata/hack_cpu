# Hack & RISC-V RV32I VHDL CPU Core Implementation

A modern VHDL-2008 implementation of both the **Nand2Tetris 16-bit Hack CPU**, the **32-bit RISC-V RV32I Processor Core**, and a **Unified Auto-Detection Micro-Op Translation CPU Core** with **100% Official RISC-V Architectural Test Compliance (`riscv-arch-test`)**.

---

## Project Structure

```
hack_cpu/
├── Makefile                        # Build & Test targets
├── README.md                       # Project documentation
├── LICENSE                         # MIT License
├── .gitignore                      # Git ignore rules
├── .gitmodules                     # Git Submodules configuration
├── .github/
│   └── workflows/
│       └── test.yml                # GitHub Actions Continuous Integration pipeline
├── scripts/
│   ├── link.ld                     # Bare-metal linker script for compliance test compilation
│   ├── run_arch_test.py            # Automated riscv-arch-test harness script
│   └── target_env/                 # Target headers for riscv-arch-test framework
├── vendor/
│   └── riscv-arch-test             # Official RISC-V Architectural Test Suite (Git Submodule)
├── rtl/                            # RTL Design Sources
│   ├── hack/                       # Standalone 16-bit Hack CPU RTL (alu.vhd, decode.vhd, cpu.vhd)
│   ├── rv32i/                      # Standalone 32-bit RISC-V RV32I CPU RTL (rv32i_types.vhd, etc.)
│   └── unified/                    # Unified Micro-Op Translation CPU RTL (unified_cpu.vhd, etc.)
└── testbench/                      # Testbenches
    ├── hack/                       # Hack 16-bit Testbenches
    ├── rv32i/                      # RV32I Testbenches & Compliance Test Suite
    └── unified/                    # Unified Dual-ISA Testbenches & Memory Loader
```

---

## Architecture Overview

### 1. Unified Auto-Detection Translation Processor (`rtl/unified/unified_cpu.vhd`)
Integrates a 32-bit RISC-V execution engine (32-bit ALU, 32x32-bit Register File, sub-word load steering) with a **First-Instruction Auto Mode Detector** and a **Hack-to-RV32I Micro-Op Translator**:
- `auto_mode_detector.vhd`: Inspects the instruction fetched at `PC = 0x00000000` on reset to automatically detect whether the binary is 16-bit Hack or 32-bit RISC-V.
- `hack_translator.vhd`: Translates all 18 Hack C-instruction computation variants and A-instructions into 32-bit RISC-V micro-ops (mapping Hack $A \to x1$ and $D \to x2$).
- `unified_cpu.vhd`: Top-level CPU core executing both Hack and RISC-V machine code seamlessly.

### 2. Standalone 16-Bit Hack CPU Core (`rtl/hack/`)
- `alu.vhd`: 16-bit ALU (numeric_std).
- `decode.vhd`: Instruction decoder for Hack A-instructions and C-instructions.
- `cpu.vhd`: Top-level Hack CPU core.

### 3. Standalone 32-Bit RISC-V RV32I CPU Core (`rtl/rv32i/`)
- `rv32i_types.vhd`: Package definitions for RISC-V opcodes, funct3/funct7, and ALU constants.
- `rv32i_regfile.vhd`: 32 x 32-bit Register File (with $x0$ hardwired to 0).
- `rv32i_alu.vhd`: 32-bit ALU.
- `rv32i_decode.vhd`: 32-bit Instruction Decoder and immediate generator.
- `rv32i_cpu.vhd`: Top-level RISC-V RV32I single-cycle processor core with sub-word memory access (`LB`, `LBU`, `LH`, `LHU`, `LW`, `SB`, `SH`, `SW`) and Spec JALR LSB masking.

---

## Simulation & Testing with Open Source Tools

This project uses **[GHDL](https://ghdl.github.io/ghdl/)** (VHDL-2008 standard), **[GTKWave](http://gtkwave.sourceforge.net/)**, **[riscv-arch-test](https://github.com/riscv-non-isa/riscv-arch-test)**, and **[GitHub Actions](https://github.com/features/actions)** for Continuous Integration (CI).

### Prerequisites

#### On Fedora Linux:
```bash
sudo dnf install -y ghdl gtkwave make python3 gcc-riscv64-linux-gnu
```

#### On Ubuntu / Debian:
```bash
sudo apt-get update
sudo apt-get install -y ghdl gtkwave make python3 gcc-riscv64-linux-gnu
```

### Initializing Submodules

Cloning repository with submodules:
```bash
git clone --recursive https://github.com/takayuki-nagata/hack_cpu.git
```

Or initialize submodules in an existing clone:
```bash
git submodule update --init --recursive
```

---

## Running Test Suites

Run all testbenches and architectural compliance tests:
```bash
make test
```

Run specific test targets:
```bash
make test-arch-compliance  # Run official riscv-arch-test (39 assembly test cases)
make test-compliance       # Run RISC-V VHDL spec compliance testbench
make test-unified          # Test Unified Dual-ISA Auto-Detection Core
make test-hack             # Test Standalone Hack 16-bit CPU Core
make test-rv32i            # Test Standalone RISC-V 32-bit CPU Core
```

---

## Waveform Inspection

To simulate and open the generated VCD waveform in GTKWave:
```bash
make wave
```

Clean build outputs:
```bash
make clean
```
