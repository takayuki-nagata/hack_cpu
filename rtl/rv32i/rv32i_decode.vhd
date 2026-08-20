-- Copyright 2026 Takayuki Nagata All Rights Reserved.
-- RISC-V RV32I Instruction Decoder & Immediate Generator

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.rv32i_types.all;

entity rv32i_decode is
    Port (
        instruction : in  std_logic_vector(31 downto 0);
        opcode      : out std_logic_vector(6 downto 0);
        rd          : out std_logic_vector(4 downto 0);
        funct3      : out std_logic_vector(2 downto 0);
        rs1         : out std_logic_vector(4 downto 0);
        rs2         : out std_logic_vector(4 downto 0);
        funct7      : out std_logic_vector(6 downto 0);
        imm         : out std_logic_vector(31 downto 0);
        csr_addr    : out std_logic_vector(11 downto 0);
        uimm        : out std_logic_vector(31 downto 0)
    );
end rv32i_decode;

architecture Behavioral of rv32i_decode is
    signal op_internal : std_logic_vector(6 downto 0);
begin
    op_internal <= instruction(6 downto 0);
    opcode      <= op_internal;
    rd          <= instruction(11 downto 7);
    funct3      <= instruction(14 downto 12);
    rs1         <= instruction(19 downto 15);
    rs2         <= instruction(24 downto 20);
    funct7      <= instruction(31 downto 25);
    csr_addr    <= instruction(31 downto 20);
    uimm        <= std_logic_vector(resize(unsigned(instruction(19 downto 15)), 32));

    -- Immediate generation based on instruction format
    process(instruction, op_internal)
    begin
        case op_internal is
            -- I-type (ADDI, SLTI, LW, JALR, etc.)
            when OPCODE_I_TYPE | OPCODE_LOAD | OPCODE_JALR =>
                imm <= std_logic_vector(resize(signed(instruction(31 downto 20)), 32));

            -- S-type (SW, SH, SB)
            when OPCODE_STORE =>
                imm <= std_logic_vector(resize(signed(instruction(31 downto 25) & instruction(11 downto 7)), 32));

            -- B-type (BEQ, BNE, BLT, BGE, etc.)
            when OPCODE_BRANCH =>
                imm <= std_logic_vector(resize(signed(instruction(31) & instruction(7) & instruction(30 downto 25) & instruction(11 downto 8) & '0'), 32));

            -- U-type (LUI, AUIPC)
            when OPCODE_LUI | OPCODE_AUIPC =>
                imm <= instruction(31 downto 12) & x"000";

            -- J-type (JAL)
            when OPCODE_JAL =>
                imm <= std_logic_vector(resize(signed(instruction(31) & instruction(19 downto 12) & instruction(20) & instruction(30 downto 21) & '0'), 32));

            -- SYSTEM / CSR
            when OPCODE_SYSTEM =>
                imm <= std_logic_vector(resize(unsigned(instruction(19 downto 15)), 32));

            when others =>
                imm <= (others => '0');
        end case;
    end process;
end Behavioral;
