-- Copyright 2026 Takayuki Nagata All Rights Reserved.
-- Testbench for Unified CPU with Comprehensive Hack & RISC-V Verification

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
        -- TEST 1: Auto-Detect Hack 16-Bit Mode & Execute Full Hack Program
        -- =========================================================================
        reset <= '1';
        wait for clk_period * 2;
        
        -- PC=0: Hack A-instruction @15 (Load 15 into A/x1)
        instr_in <= x"0000" & "0000000000001111"; 
        reset <= '0';
        wait for clk_period;
        
        -- Assert Hack mode auto-detected (active_mode = '0')
        assert active_mode = '0' report "Auto-detection failed for Hack mode" severity failure;
        assert unsigned(pc_out) = 2 report "Hack PC increment failed after PC=0" severity failure;

        -- PC=2: Hack C-instruction D=A ("1110110000010000")
        instr_in <= x"0000" & "1110110000010000";
        wait for clk_period;
        assert unsigned(pc_out) = 4 report "Hack PC increment failed after PC=2" severity failure;

        -- PC=4: Hack C-instruction D=D+1 ("1110011111010000")
        instr_in <= x"0000" & "1110011111010000";
        wait for clk_period;
        assert unsigned(pc_out) = 6 report "Hack PC increment failed after PC=4" severity failure;

        -- PC=6: Hack C-instruction M=D ("1110001100001000")
        instr_in <= x"0000" & "1110001100001000";
        wait for clk_period;
        assert mem_write = '1' report "Hack memory write assertion failed" severity failure;
        assert unsigned(data_addr) = 15 report "Hack memory store address assertion failed" severity failure;
        assert unsigned(data_out) = 16 report "Hack memory store value assertion failed" severity failure;

        report "[PASS] Hack 16-bit mode full program verification successful!";

        -- =========================================================================
        -- TEST 2: Auto-Detect RISC-V 32-Bit Mode & Execute Full RISC-V Program
        -- =========================================================================
        reset <= '1';
        wait for clk_period * 2;

        -- PC=0: RISC-V ADDI x10, x0, 42 (0x02a00513)
        instr_in <= x"02a00513"; 
        reset <= '0';
        wait for clk_period;

        -- Assert RISC-V mode auto-detected (active_mode = '1')
        assert active_mode = '1' report "Auto-detection failed for RISC-V mode" severity failure;
        assert unsigned(pc_out) = 4 report "RISC-V PC increment failed after PC=0" severity failure;

        -- PC=4: RISC-V ADDI x11, x0, 100 (0x06400593)
        instr_in <= x"06400593";
        wait for clk_period;
        assert unsigned(pc_out) = 8 report "RISC-V PC increment failed after PC=4" severity failure;

        -- PC=8: RISC-V ADD x12, x10, x11 (0x00b50633) -> x12 = 142
        instr_in <= x"00b50633";
        wait for clk_period;
        assert unsigned(pc_out) = 12 report "RISC-V PC increment failed after PC=8" severity failure;

        -- PC=12: RISC-V SW x12, 0(x10) (0x00c52023) -> Store 142 to addr 42
        instr_in <= x"00c52023";
        wait for clk_period;
        assert mem_write = '1' report "RISC-V memory write assertion failed" severity failure;
        assert unsigned(data_addr) = 42 report "RISC-V memory store address assertion failed" severity failure;
        assert unsigned(data_out) = 142 report "RISC-V memory store value assertion failed" severity failure;

        -- PC=16: RISC-V JAL x0, 8 (0x0080006f) -> Jump PC to 24
        instr_in <= x"0080006f";
        wait for clk_period;
        assert unsigned(pc_out) = 24 report "RISC-V JAL jump target assertion failed" severity failure;

        report "[PASS] RISC-V 32-bit mode full program verification successful!";
        report "unified_cpu_tb executed successfully! All dual-ISA assertions passed.";
        wait;
    end process;

end behavior;
