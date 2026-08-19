-- Copyright 2026 Takayuki Nagata All Rights Reserved.
-- Testbench for Unified CPU with Auto Mode Detection & Translation Engine

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.rv32i_types.all;

entity unified_cpu_tb is
end unified_cpu_tb;

architecture behavior of unified_cpu_tb is

    component unified_cpu
        Port (
            clk            : in  std_logic;
            reset          : in  std_logic;
            instr_in       : in  std_logic_vector(31 downto 0);
            data_in        : in  std_logic_vector(31 downto 0);
            pc_out         : out std_logic_vector(31 downto 0);
            data_addr      : out std_logic_vector(31 downto 0);
            data_out       : out std_logic_vector(31 downto 0);
            mem_write      : out std_logic;
            active_mode    : out std_logic
        );
    end component;

    signal clk         : std_logic := '0';
    signal reset       : std_logic := '0';
    signal instr_in    : std_logic_vector(31 downto 0) := (others => '0');
    signal data_in     : std_logic_vector(31 downto 0) := (others => '0');
    signal pc_out      : std_logic_vector(31 downto 0);
    signal data_addr   : std_logic_vector(31 downto 0);
    signal data_out    : std_logic_vector(31 downto 0);
    signal mem_write   : std_logic;
    signal active_mode : std_logic;

    constant clk_period : time := 10 ns;

begin

    uut : unified_cpu
        port map (
            clk         => clk,
            reset       => reset,
            instr_in    => instr_in,
            data_in     => data_in,
            pc_out      => pc_out,
            data_addr   => data_addr,
            data_out    => data_out,
            mem_write   => mem_write,
            active_mode => active_mode
        );

    -- Clock process
    clk_process : process
    begin
        clk <= '0';
        wait for clk_period / 2;
        clk <= '1';
        wait for clk_period / 2;
    end process;

    -- Stimulus process
    stim_proc : process
    begin
        -- =========================================================================
        -- TEST 1: Auto-Detect Hack 16-Bit Mode & Translate Micro-Ops
        -- =========================================================================
        reset <= '1';
        wait for clk_period * 2;
        
        -- First Instruction at PC=0: Hack A-instruction (Load 15 into A/x1)
        instr_in <= x"0000" & "0000000000001111"; 
        reset <= '0';
        wait for clk_period;
        
        -- Assert Hack mode auto-detected
        assert active_mode = '0' report "Auto-detection failed for Hack mode" severity failure;

        -- Instruction 2: Hack C-instruction: D = A
        instr_in <= x"0000" & "1110110000010000";
        wait for clk_period;

        -- =========================================================================
        -- TEST 2: Auto-Detect RISC-V 32-Bit Native Mode
        -- =========================================================================
        reset <= '1';
        wait for clk_period * 2;

        -- First Instruction at PC=0: RISC-V ADDI x1, x0, 15 (0x00f00093)
        instr_in <= x"00f00093"; 
        reset <= '0';
        wait for clk_period;

        -- Assert RISC-V mode auto-detected
        assert active_mode = '1' report "Auto-detection failed for RISC-V mode" severity failure;

        report "unified_cpu_tb executed successfully!";
        wait;
    end process;

end behavior;
