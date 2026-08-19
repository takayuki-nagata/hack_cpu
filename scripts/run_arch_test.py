#!/usr/bin/env python3
# Copyright 2026 Takayuki Nagata All Rights Reserved.
# RISC-V Architectural Compliance Test Automation Harness

import os
import sys
import subprocess
import shutil
import glob

# Tool discovery
GCC_BIN = shutil.which("riscv64-linux-gnu-gcc") or shutil.which("riscv64-unknown-elf-gcc") or shutil.which("gcc")
OBJCOPY_BIN = shutil.which("riscv64-linux-gnu-objcopy") or shutil.which("riscv64-unknown-elf-objcopy") or shutil.which("objcopy")
GHDL_BIN = shutil.which("ghdl")

REPO_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VENDOR_DIR = os.path.join(REPO_DIR, "vendor")
ARCH_TEST_DIR = os.path.join(VENDOR_DIR, "riscv-arch-test")
BUILD_DIR = os.path.join(REPO_DIR, "build_arch_test")
TARGET_ENV_DIR = os.path.join(REPO_DIR, "scripts", "target_env")

def run_cmd(cmd, cwd=None):
    res = subprocess.run(cmd, cwd=cwd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    return res.returncode, res.stdout, res.stderr

def setup_repo():
    os.makedirs(VENDOR_DIR, exist_ok=True)
    os.makedirs(BUILD_DIR, exist_ok=True)
    
    test_src = os.path.join(ARCH_TEST_DIR, "tests", "rv32i", "I")
    if not os.path.exists(test_src) or not os.listdir(test_src):
        print("[INFO] Initializing Git submodule vendor/riscv-arch-test...")
        code, out, err = run_cmd(["git", "submodule", "update", "--init", "--recursive"], cwd=REPO_DIR)
        if code != 0 or not os.path.exists(test_src):
            print(f"[WARNING] Submodule update failed, attempting fallback clone: {err}")
            code, out, err = run_cmd(["git", "clone", "--depth", "1", "https://github.com/riscv-non-isa/riscv-arch-test.git", ARCH_TEST_DIR])
            if code != 0:
                print(f"[ERROR] Failed to clone riscv-arch-test: {err}")
                sys.exit(1)

def compile_vhdl():
    print("[INFO] Compiling VHDL entities with GHDL...")
    vhdl_files = [
        os.path.join("rtl", "rv32i", "rv32i_types.vhd"),
        os.path.join("rtl", "rv32i", "rv32i_regfile.vhd"),
        os.path.join("rtl", "rv32i", "rv32i_alu.vhd"),
        os.path.join("rtl", "rv32i", "rv32i_decode.vhd"),
        os.path.join("rtl", "unified", "auto_mode_detector.vhd"),
        os.path.join("rtl", "unified", "hack_translator.vhd"),
        os.path.join("rtl", "unified", "unified_cpu.vhd"),
        os.path.join("testbench", "unified", "tb_hex_runner.vhd")
    ]
    for vf in vhdl_files:
        fpath = os.path.join(REPO_DIR, vf)
        code, out, err = run_cmd([GHDL_BIN, "-a", "--std=08", fpath], cwd=BUILD_DIR)
        if code != 0:
            print(f"[ERROR] Failed to analyze {vf}: {err}")
            return False

    code, out, err = run_cmd([GHDL_BIN, "-e", "--std=08", "tb_hex_runner"], cwd=BUILD_DIR)
    if code != 0:
        print(f"[ERROR] Failed to elaborate tb_hex_runner: {err}")
        return False
    return True

def convert_elf_to_hex(elf_path, hex_path):
    bin_path = elf_path + ".bin"
    code, out, err = run_cmd([OBJCOPY_BIN, "-O", "binary", elf_path, bin_path])
    if code != 0 or not os.path.exists(bin_path):
        return False

    with open(bin_path, "rb") as f:
        data = f.read()

    with open(hex_path, "w") as f:
        for i in range(0, len(data), 4):
            chunk = data[i:i+4]
            if len(chunk) < 4:
                chunk = chunk.ljust(4, b'\x00')
            val = int.from_bytes(chunk, byteorder='little')
            f.write(f"{val:08X}\n")

    return True

def run_tests():
    test_src_dir = os.path.join(ARCH_TEST_DIR, "tests", "rv32i", "I")
    test_files = glob.glob(os.path.join(test_src_dir, "*.S"))

    if not test_files:
        print("[WARNING] No test .S files found in riscv-arch-test directory.")
        return True

    print(f"[INFO] Discovered {len(test_files)} riscv-arch-test assembly test files.")
    
    env_inc_dir = os.path.join(ARCH_TEST_DIR, "tests", "env")
    rv32i_inc_dir = os.path.join(ARCH_TEST_DIR, "tests", "rv32i")

    passed = 0
    failed = 0

    for s_file in sorted(test_files):
        tname = os.path.basename(s_file).replace(".S", "")
        elf_file = os.path.join(BUILD_DIR, f"{tname}.elf")
        hex_file = os.path.join(BUILD_DIR, f"{tname}.hex")

        linker_script = os.path.join(REPO_DIR, "scripts", "link.ld")
        # Compile assembly test to ELF
        cmd = [
            GCC_BIN, "-march=rv32i", "-mabi=ilp32", "-nostdlib", "-static",
            "-Wl,--build-id=none", "-Wl,-N",
            "-I", TARGET_ENV_DIR,
            "-I", env_inc_dir,
            "-I", rv32i_inc_dir,
            "-DTEST_CASE_1=1",
            "-DTEST_XLEN=32",
            "-DTEST_FLEN=0",
            "-DRVTEST_SELFCHECK=1",
            f"-DTEST_FILE=\"{tname}.S\"",
            "-DSIGNATURE_FILE=\"empty_sig.h\"",
            "-T", linker_script,
            s_file, "-o", elf_file
        ]
        code, out, err = run_cmd(cmd)
        if code != 0:
            print(f"[FAIL] {tname}: GCC compilation failed: {err}")
            failed += 1
            continue

        if not convert_elf_to_hex(elf_file, hex_file):
            print(f"[FAIL] {tname}: Hex conversion failed")
            failed += 1
            continue

        # Run GHDL simulation with test hex
        sim_cmd = [GHDL_BIN, "-r", "--std=08", "tb_hex_runner", f"-gHEX_FILE_NAME={hex_file}", "--stop-time=1500ns"]
        code, out, err = run_cmd(sim_cmd, cwd=BUILD_DIR)
        
        if code == 0:
            print(f"[PASS] {tname}")
            passed += 1
        else:
            print(f"[FAIL] {tname}: Simulation error")
            failed += 1

    print("\n" + "="*60)
    print(f"RISC-V Architectural Compliance Test Results: {passed} PASSED, {failed} FAILED out of {len(test_files)} tests.")
    print("="*60)

    return failed == 0

def main():
    setup_repo()
    if not compile_vhdl():
        sys.exit(1)
    if not run_tests():
        sys.exit(1)

if __name__ == "__main__":
    main()
