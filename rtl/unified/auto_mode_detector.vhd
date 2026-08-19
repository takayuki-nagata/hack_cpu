-- Copyright 2026 Takayuki Nagata All Rights Reserved.
-- First-Instruction Auto Mode Detector for Hack-to-RV32I CPU

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.rv32i_types.all;

entity auto_mode_detector is
    Port (
        clk           : in  std_logic;
        reset         : in  std_logic;
        first_instr   : in  std_logic_vector(31 downto 0);
        is_riscv_mode : out std_logic
    );
end auto_mode_detector;

architecture Behavioral of auto_mode_detector is
    signal mode_latched : std_logic := '0';
    signal riscv_flag   : std_logic := '0';
begin
    is_riscv_mode <= riscv_flag;

    process(clk)
        variable opcode : std_logic_vector(6 downto 0);
    begin
        if rising_edge(clk) then
            if reset = '1' then
                mode_latched <= '0';
                riscv_flag   <= '0';
            elsif mode_latched = '0' then
                opcode := first_instr(6 downto 0);
                -- RISC-V 32-bit instructions always have bits[1:0] = "11" and valid 7-bit opcode
                if first_instr(1 downto 0) = "11" and
                   (opcode = OPCODE_R_TYPE or opcode = OPCODE_I_TYPE or
                    opcode = OPCODE_LOAD   or opcode = OPCODE_STORE  or
                    opcode = OPCODE_BRANCH or opcode = OPCODE_JAL    or
                    opcode = OPCODE_JALR   or opcode = OPCODE_LUI    or
                    opcode = OPCODE_AUIPC) then
                    riscv_flag <= '1';
                else
                    riscv_flag <= '0';
                end if;
                mode_latched <= '1';
            end if;
        end if;
    end process;
end Behavioral;
