GHDL = ghdl
GHDLFLAGS = --std=08
GHDLRUNFLAGS = --vcd=wave.vcd

RV32I_SRCS = rv32i_types.vhd rv32i_regfile.vhd rv32i_alu.vhd rv32i_decode.vhd rv32i_cpu.vhd
RV32I_TB = rv32i_cpu_tb.vhd

.PHONY: all test test-hack test-rv32i test-alu test-decode test-cpu clean wave

all: test

# --- Hack 16-bit CPU Tests ---
test-alu:
	$(GHDL) -a $(GHDLFLAGS) alu.vhd alu_test.vhd
	$(GHDL) -e $(GHDLFLAGS) alu_test
	$(GHDL) -r $(GHDLFLAGS) alu_test $(GHDLRUNFLAGS)

test-decode:
	$(GHDL) -a $(GHDLFLAGS) decode.vhd decode_test.vhd
	$(GHDL) -e $(GHDLFLAGS) decode_test
	$(GHDL) -r $(GHDLFLAGS) decode_test

test-cpu:
	$(GHDL) -a $(GHDLFLAGS) decode.vhd alu.vhd cpu.vhd cpu_test.vhd
	$(GHDL) -e $(GHDLFLAGS) cpu_test
	$(GHDL) -r $(GHDLFLAGS) cpu_test --stop-time=600ns

test-hack: test-alu test-decode test-cpu

# --- RISC-V 32-bit RV32I Core Tests ---
test-rv32i:
	$(GHDL) -a $(GHDLFLAGS) $(RV32I_SRCS) $(RV32I_TB)
	$(GHDL) -e $(GHDLFLAGS) rv32i_cpu_tb
	$(GHDL) -r $(GHDLFLAGS) rv32i_cpu_tb --stop-time=200ns

test: test-hack test-rv32i

wave: test-alu
	gtkwave wave.vcd &

clean:
	ghdl --clean
	rm -f *.o *.cf wave.vcd alu_test decode_test cpu_test rv32i_cpu_tb
