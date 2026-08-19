GHDL = ghdl
GHDLFLAGS = --std=08
GHDLRUNFLAGS = --vcd=wave.vcd

.PHONY: all test test-alu test-decode test-cpu clean wave

all: test

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

test: test-alu test-decode test-cpu

wave: test-alu
	gtkwave wave.vcd &

clean:
	ghdl --clean
	rm -f *.o *.cf wave.vcd alu_test decode_test cpu_test
