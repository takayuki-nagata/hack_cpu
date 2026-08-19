-- Copyright 2026 Takayuki Nagata All Rights Reserved.
-- RISC-V RV32I Type Definitions Package

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package rv32i_types is

    -- 7-bit Opcodes
    constant OPCODE_R_TYPE   : std_logic_vector(6 downto 0) := "0110011";
    constant OPCODE_I_TYPE   : std_logic_vector(6 downto 0) := "0010011";
    constant OPCODE_LOAD     : std_logic_vector(6 downto 0) := "0000011";
    constant OPCODE_STORE    : std_logic_vector(6 downto 0) := "0100011";
    constant OPCODE_BRANCH   : std_logic_vector(6 downto 0) := "1100011";
    constant OPCODE_JAL      : std_logic_vector(6 downto 0) := "1101111";
    constant OPCODE_JALR     : std_logic_vector(6 downto 0) := "1100111";
    constant OPCODE_LUI      : std_logic_vector(6 downto 0) := "0110111";
    constant OPCODE_AUIPC    : std_logic_vector(6 downto 0) := "0010111";

    -- funct3 for ALU I-type / R-type
    constant FUNCT3_ADD_SUB : std_logic_vector(2 downto 0) := "000";
    constant FUNCT3_SLL     : std_logic_vector(2 downto 0) := "001";
    constant FUNCT3_SLT     : std_logic_vector(2 downto 0) := "010";
    constant FUNCT3_SLTU    : std_logic_vector(2 downto 0) := "011";
    constant FUNCT3_XOR     : std_logic_vector(2 downto 0) := "100";
    constant FUNCT3_SRL_SRA : std_logic_vector(2 downto 0) := "101";
    constant FUNCT3_OR      : std_logic_vector(2 downto 0) := "110";
    constant FUNCT3_AND     : std_logic_vector(2 downto 0) := "111";

    -- funct3 for Branch
    constant FUNCT3_BEQ     : std_logic_vector(2 downto 0) := "000";
    constant FUNCT3_BNE     : std_logic_vector(2 downto 0) := "001";
    constant FUNCT3_BLT     : std_logic_vector(2 downto 0) := "100";
    constant FUNCT3_BGE     : std_logic_vector(2 downto 0) := "101";
    constant FUNCT3_BLTU    : std_logic_vector(2 downto 0) := "110";
    constant FUNCT3_BGEU    : std_logic_vector(2 downto 0) := "111";

    -- 4-bit ALU Control Signals
    constant ALU_ADD  : std_logic_vector(3 downto 0) := "0000";
    constant ALU_SUB  : std_logic_vector(3 downto 0) := "0001";
    constant ALU_SLL  : std_logic_vector(3 downto 0) := "0010";
    constant ALU_SLT  : std_logic_vector(3 downto 0) := "0011";
    constant ALU_SLTU : std_logic_vector(3 downto 0) := "0100";
    constant ALU_XOR  : std_logic_vector(3 downto 0) := "0101";
    constant ALU_SRL  : std_logic_vector(3 downto 0) := "0110";
    constant ALU_SRA  : std_logic_vector(3 downto 0) := "0111";
    constant ALU_OR   : std_logic_vector(3 downto 0) := "1000";
    constant ALU_AND  : std_logic_vector(3 downto 0) := "1001";
    constant ALU_COPY_B : std_logic_vector(3 downto 0) := "1010";
    constant ALU_COPY_A : std_logic_vector(3 downto 0) := "1011";

end package rv32i_types;
