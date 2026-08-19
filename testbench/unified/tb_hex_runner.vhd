-- Copyright 2026 Takayuki Nagata All Rights Reserved.
-- Architectural Compliance VHDL Memory Loader & Signature Dumper

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use std.textio.all;

entity tb_hex_runner is
    generic (
        HEX_FILE_NAME       : string := "test.hex";
        SIGNATURE_FILE_NAME : string := "signature.output";
        MAX_CYCLES          : integer := 5000
    );
end tb_hex_runner;

architecture behavior of tb_hex_runner is

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

    -- 64KB Memory RAM (16384 x 32-bit words)
    type ram_type is array (0 to 16383) of std_logic_vector(31 downto 0);
    signal ram : ram_type := (others => (others => '0'));

    -- Signature dumping markers
    signal sig_start_addr : integer := 0;
    signal sig_end_addr   : integer := 0;
    signal sim_finished   : boolean := false;

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

    -- Clock generator
    clk_process : process
    begin
        if sim_finished then
            wait;
        end if;
        clk <= '0';
        wait for clk_period / 2;
        clk <= '1';
        wait for clk_period / 2;
    end process;

    -- Memory Loader Process (reads HEX_FILE_NAME)
    load_proc : process
        file hex_file : text;
        variable file_status : file_open_status;
        variable l : line;
        variable hex_val : std_logic_vector(31 downto 0);
        variable word_idx : integer := 0;
        variable char_val : character;
    begin
        file_open(file_status, hex_file, HEX_FILE_NAME, read_mode);
        if file_status = open_ok then
            while not endfile(hex_file) and word_idx < 16384 loop
                readline(hex_file, l);
                if l'length >= 8 then
                    hread(l, hex_val);
                    ram(word_idx) <= hex_val;
                    word_idx := word_idx + 1;
                end if;
            end loop;
            file_close(hex_file);
        end if;
        wait;
    end process;

    -- Synchronous Memory Read/Write
    process(clk)
        variable inst_idx : integer;
        variable data_idx : integer;
    begin
        if rising_edge(clk) then
            inst_idx := to_integer(unsigned(pc_out(15 downto 2)));
            if inst_idx >= 0 and inst_idx < 16384 then
                instr_in <= ram(inst_idx);
            else
                instr_in <= (others => '0');
            end if;

            data_idx := to_integer(unsigned(data_addr(15 downto 2)));
            if data_idx >= 0 and data_idx < 16384 then
                data_in <= ram(data_idx);
                if mem_write = '1' then
                    ram(data_idx) <= data_out;
                end if;
            end if;
        end if;
    end process;

    -- Simulation Monitor & Signature Dump
    stim_proc : process
        file sig_file : text;
        variable l : line;
        variable cycle_count : integer := 0;
    begin
        reset <= '1';
        wait for clk_period * 2;
        reset <= '0';

        while cycle_count < MAX_CYCLES loop
            wait for clk_period;
            cycle_count := cycle_count + 1;
            
            -- Detect unhandled exception / ECALL / exit code trap
            if pc_out = x"00001000" or pc_out = x"00002000" or instr_in = x"00000073" then
                exit;
            end if;
        end loop;

        -- Dump Signature Memory File
        file_open(sig_file, SIGNATURE_FILE_NAME, write_mode);
        for i in 0 to 63 loop
            hwrite(l, ram(i));
            writeline(sig_file, l);
        end loop;
        file_close(sig_file);

        report "tb_hex_runner completed signature dumping.";
        sim_finished <= true;
        wait;
    end process;

end behavior;
