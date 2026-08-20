GHDL = ghdl
GHDLFLAGS = --std=08
GHDLRUNFLAGS = --vcd=wave.vcd

RTL_HACK = rtl/hack/decode.vhd rtl/hack/alu.vhd rtl/hack/cpu.vhd
RTL_RV32I = rtl/rv32i/rv32i_types.vhd rtl/rv32i/rv32i_regfile.vhd rtl/rv32i/rv32i_alu.vhd rtl/rv32i/rv32i_decode.vhd rtl/rv32i/rv32i_csrs.vhd
RTL_UNIFIED = $(RTL_RV32I) rtl/unified/auto_mode_detector.vhd rtl/unified/hack_translator.vhd rtl/unified/unified_cpu.vhd

.PHONY: all test test-hack test-rv32i test-csr test-unified test-compliance test-arch-compliance test-alu test-decode test-cpu clean wave

all: test

# --- Hack 16-bit CPU Tests ---
test-alu:
	$(GHDL) -a $(GHDLFLAGS) rtl/hack/alu.vhd testbench/hack/alu_test.vhd
	$(GHDL) -e $(GHDLFLAGS) alu_test
	$(GHDL) -r $(GHDLFLAGS) alu_test $(GHDLRUNFLAGS)

test-decode:
	$(GHDL) -a $(GHDLFLAGS) rtl/hack/decode.vhd testbench/hack/decode_test.vhd
	$(GHDL) -e $(GHDLFLAGS) decode_test
	$(GHDL) -r $(GHDLFLAGS) decode_test

test-cpu:
	$(GHDL) -a $(GHDLFLAGS) $(RTL_HACK) testbench/hack/cpu_test.vhd
	$(GHDL) -e $(GHDLFLAGS) cpu_test
	$(GHDL) -r $(GHDLFLAGS) cpu_test --stop-time=600ns

test-hack: test-alu test-decode test-cpu

# --- RISC-V 32-bit RV32I Core Tests ---
test-rv32i:
	$(GHDL) -a $(GHDLFLAGS) $(RTL_RV32I) rtl/rv32i/rv32i_cpu.vhd testbench/rv32i/rv32i_cpu_tb.vhd
	$(GHDL) -e $(GHDLFLAGS) rv32i_cpu_tb
	$(GHDL) -r $(GHDLFLAGS) rv32i_cpu_tb --stop-time=200ns

test-csr:
	$(GHDL) -a $(GHDLFLAGS) $(RTL_RV32I) rtl/rv32i/rv32i_cpu.vhd testbench/rv32i/rv32i_csr_tb.vhd
	$(GHDL) -e $(GHDLFLAGS) rv32i_csr_tb
	$(GHDL) -r $(GHDLFLAGS) rv32i_csr_tb --stop-time=200ns

test-compliance:
	$(GHDL) -a $(GHDLFLAGS) $(RTL_RV32I) rtl/rv32i/rv32i_cpu.vhd testbench/rv32i/rv32i_compliance_tb.vhd
	$(GHDL) -e $(GHDLFLAGS) rv32i_compliance_tb
	$(GHDL) -r $(GHDLFLAGS) rv32i_compliance_tb --stop-time=300ns

# --- Official riscv-arch-test Architectural Compliance Test Suite ---
test-arch-compliance:
	python3 scripts/run_arch_test.py

# --- Unified Auto-Detection Translation Core Tests ---
test-unified:
	$(GHDL) -a $(GHDLFLAGS) $(RTL_UNIFIED) testbench/unified/unified_cpu_tb.vhd
	$(GHDL) -e $(GHDLFLAGS) unified_cpu_tb
	$(GHDL) -r $(GHDLFLAGS) unified_cpu_tb --stop-time=200ns

test: test-hack test-rv32i test-csr test-compliance test-unified test-arch-compliance

wave: test-alu
	gtkwave wave.vcd &

clean:
	ghdl --clean
	rm -rf *.o *.cf wave.vcd alu_test decode_test cpu_test rv32i_cpu_tb unified_cpu_tb rv32i_compliance_tb rv32i_csr_tb build_arch_test
