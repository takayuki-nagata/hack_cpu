-- Copyright 2026 Takayuki Nagata All Rights Reserved.
-- Testbench for RISC-V RV32I CPU Core

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.rv32i_types.all;

entity rv32i_cpu_tb is
end rv32i_cpu_tb;

architecture behavior of rv32i_cpu_tb is

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
            timer_irq_in: in  std_logic := '0';
            ext_irq_in  : in  std_logic := '0';
            sw_irq_in   : in  std_logic := '0'
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

    constant clk_period : time := 10 ns;

    -- Instruction Encoding Helpers
    function make_i_type(imm : integer; rs1 : integer; funct3 : std_logic_vector(2 downto 0); rd : integer; opcode : std_logic_vector(6 downto 0)) return std_logic_vector is
        variable res : std_logic_vector(31 downto 0);
    begin
        res(31 downto 20) := std_logic_vector(to_signed(imm, 12));
        res(19 downto 15) := std_logic_vector(to_unsigned(rs1, 5));
        res(14 downto 12) := funct3;
        res(11 downto 7)  := std_logic_vector(to_unsigned(rd, 5));
        res(6 downto 0)   := opcode;
        return res;
    end function;

    function make_r_type(funct7 : std_logic_vector(6 downto 0); rs2 : integer; rs1 : integer; funct3 : std_logic_vector(2 downto 0); rd : integer; opcode : std_logic_vector(6 downto 0)) return std_logic_vector is
        variable res : std_logic_vector(31 downto 0);
    begin
        res(31 downto 25) := funct7;
        res(24 downto 20) := std_logic_vector(to_unsigned(rs2, 5));
        res(19 downto 15) := std_logic_vector(to_unsigned(rs1, 5));
        res(14 downto 12) := funct3;
        res(11 downto 7)  := std_logic_vector(to_unsigned(rd, 5));
        res(6 downto 0)   := opcode;
        return res;
    end function;

begin

    uut : rv32i_cpu
        port map (
            clk         => clk,
            reset       => reset,
            instr_in    => instr_in,
            data_in     => data_in,
            pc_out      => pc_out,
            data_addr   => data_addr,
            data_out    => data_out,
            mem_write   => mem_write
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
        reset <= '1';
        wait for clk_period * 2;
        reset <= '0';

        -- Instruction 1: ADDI x1, x0, 15  (x1 = 15)
        instr_in <= make_i_type(15, 0, FUNCT3_ADD_SUB, 1, OPCODE_I_TYPE);
        wait for clk_period;

        -- Instruction 2: ADDI x2, x0, 25  (x2 = 25)
        instr_in <= make_i_type(25, 0, FUNCT3_ADD_SUB, 2, OPCODE_I_TYPE);
        wait for clk_period;

        -- Instruction 3: ADD x3, x1, x2   (x3 = x1 + x2 = 40)
        instr_in <= make_r_type("0000000", 2, 1, FUNCT3_ADD_SUB, 3, OPCODE_R_TYPE);
        wait for clk_period;

        -- Instruction 4: SUB x4, x2, x1   (x4 = x2 - x1 = 10)
        instr_in <= make_r_type("0100000", 1, 2, FUNCT3_ADD_SUB, 4, OPCODE_R_TYPE);
        wait for clk_period;

        -- Instruction 5: SW x3, 4(x0)     (store x3=40 to mem[4])
        instr_in <= "0000000" & "00011" & "00000" & FUNCT3_ADD_SUB & "00100" & OPCODE_STORE;
        wait for clk_period;
        assert mem_write = '1' report "SW mem_write failure" severity failure;
        assert data_addr = x"00000004" report "SW addr failure" severity failure;
        assert data_out = std_logic_vector(to_unsigned(40, 32)) report "SW data failure" severity failure;

        report "rv32i_cpu_tb executed successfully!";
        wait;
    end process;

end behavior;
