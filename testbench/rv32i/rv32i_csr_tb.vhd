-- Copyright 2026 Takayuki Nagata All Rights Reserved.
-- Unit Testbench for RISC-V RV32I CSRs & System Trap Unit

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.rv32i_types.all;

entity rv32i_csr_tb is
end rv32i_csr_tb;

architecture Behavioral of rv32i_csr_tb is

    component rv32i_cpu
        Port (
            clk         : in  std_logic;
            reset       : in  std_logic;
            instr_in    : in  std_logic_vector(31 downto 0);
            data_in     : in  std_logic_vector(31 downto 0);
            pc_out      : out std_logic_vector(31 downto 0);
            data_addr   : out std_logic_vector(31 downto 0);
            data_out    : out std_logic_vector(31 downto 0);
            mem_write   : out std_logic;
            timer_irq_in: in  std_logic;
            ext_irq_in  : in  std_logic;
            sw_irq_in   : in  std_logic
        );
    end component;

    signal clk          : std_logic := '0';
    signal reset        : std_logic := '1';
    signal instr_in     : std_logic_vector(31 downto 0) := x"00000013"; -- NOP (addi x0, x0, 0)
    signal data_in      : std_logic_vector(31 downto 0) := (others => '0');
    signal pc_out       : std_logic_vector(31 downto 0);
    signal data_addr    : std_logic_vector(31 downto 0);
    signal data_out     : std_logic_vector(31 downto 0);
    signal mem_write    : std_logic;
    signal timer_irq_in : std_logic := '0';
    signal ext_irq_in   : std_logic := '0';
    signal sw_irq_in    : std_logic := '0';

    constant CLK_PERIOD : time := 10 ns;

begin

    -- CPU instantiation
    uut : rv32i_cpu
        port map (
            clk          => clk,
            reset        => reset,
            instr_in     => instr_in,
            data_in      => data_in,
            pc_out       => pc_out,
            data_addr    => data_addr,
            data_out     => data_out,
            mem_write    => mem_write,
            timer_irq_in => timer_irq_in,
            ext_irq_in   => ext_irq_in,
            sw_irq_in    => sw_irq_in
        );

    -- Clock generation
    clk_process : process
    begin
        clk <= '0';
        wait for CLK_PERIOD / 2;
        clk <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    -- Stimulus process
    stim_proc : process
    begin
        -- Hold Reset
        reset <= '1';
        wait for CLK_PERIOD * 2;
        reset <= '0';
        wait for CLK_PERIOD;

        -- Test 1: Write x10 = 0x8000 (ADDI x10, x0, 0x8000 -> not signed overflow, let's use LUI)
        -- LUI x10, 0x80000 (x10 = 0x80000000)
        instr_in <= x"80000537";
        wait for CLK_PERIOD;

        -- Test 2: Write CSR mtvec (0x305) with x10 = 0x80000000 using csrrw x0, mtvec, x10
        -- Encoding: imm=0x305, rs1=10, funct3=001(CSRRW), rd=0, op=1110011 -> 0x30551073
        instr_in <= x"30551073";
        wait for CLK_PERIOD;

        -- Test 3: Execute ECALL (0x00000073)
        instr_in <= x"00000073";
        wait for CLK_PERIOD;

        -- Verify PC redirected to mtvec (0x80000000)
        assert pc_out = x"80000000" report "ECALL trap failed to vector to mtvec!" severity failure;
        report "[PASS] ECALL trap vectoring to mtvec successful!";

        -- Test 4: Execute MRET (0x30200073) to return to mepc
        instr_in <= x"30200073";
        wait for CLK_PERIOD;

        report "[PASS] CSR & System Exception Trap Unit test executed successfully!";
        wait;
    end process;

end Behavioral;
