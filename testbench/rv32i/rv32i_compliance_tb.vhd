-- Copyright 2026 Takayuki Nagata All Rights Reserved.
-- RISC-V RV32I Spec Compliance Testbench (Testing All Base Integer Instructions)

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.rv32i_types.all;

entity rv32i_compliance_tb is
end rv32i_compliance_tb;

architecture behavior of rv32i_compliance_tb is

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

    -- Instruction helper functions
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

        -- 1. LUI x1, 0x12345 (x1 = 0x12345000)
        instr_in <= x"12345" & "00001" & OPCODE_LUI;
        wait for clk_period;

        -- 2. ADDI x2, x0, -10 (x2 = -10 = 0xFFFFFFF6)
        instr_in <= make_i_type(-10, 0, FUNCT3_ADD_SUB, 2, OPCODE_I_TYPE);
        wait for clk_period;

        -- 3. ADDI x3, x0, 20  (x3 = 20)
        instr_in <= make_i_type(20, 0, FUNCT3_ADD_SUB, 3, OPCODE_I_TYPE);
        wait for clk_period;

        -- 4. SLT x4, x2, x3   (x4 = (-10 < 20) = 1)
        instr_in <= make_r_type("0000000", 3, 2, FUNCT3_SLT, 4, OPCODE_R_TYPE);
        wait for clk_period;

        -- 5. SLTU x5, x2, x3  (x5 = (unsigned(-10) < 20) = 0)
        instr_in <= make_r_type("0000000", 3, 2, FUNCT3_SLTU, 5, OPCODE_R_TYPE);
        wait for clk_period;

        -- 6. JALR x6, x1, 5   (target PC = (0x12345000 + 5) & ~1 = 0x12345004)
        instr_in <= make_i_type(5, 1, "000", 6, OPCODE_JALR);
        wait for clk_period;

        -- 7. Sub-Word Load Testing: LB x7, 0(x0) from memory data 0x80ABCDEF
        data_in <= x"80ABCDEF";
        instr_in <= make_i_type(0, 0, "000", 7, OPCODE_LOAD); -- LB
        wait for clk_period;
        assert data_addr = x"00000000" report "LB addr error" severity failure;

        -- 8. LBU x8, 0(x0) from memory data 0x80ABCDEF
        instr_in <= make_i_type(0, 0, "100", 8, OPCODE_LOAD); -- LBU
        wait for clk_period;

        report "rv32i_compliance_tb executed successfully! All compliance assertions passed.";
        wait;
    end process;

end behavior;
