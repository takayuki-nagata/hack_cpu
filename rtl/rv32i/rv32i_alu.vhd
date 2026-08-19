-- Copyright 2026 Takayuki Nagata All Rights Reserved.
-- RISC-V RV32I 32-bit Arithmetic Logic Unit

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.rv32i_types.all;

entity rv32i_alu is
    Port (
        a       : in  std_logic_vector(31 downto 0);
        b       : in  std_logic_vector(31 downto 0);
        alu_op  : in  std_logic_vector(3 downto 0);
        result  : out std_logic_vector(31 downto 0);
        zero    : out std_logic
    );
end rv32i_alu;

architecture Behavioral of rv32i_alu is
    signal res_int : std_logic_vector(31 downto 0);
begin
    process(a, b, alu_op)
        variable shift_amt : integer range 0 to 31;
    begin
        shift_amt := to_integer(unsigned(b(4 downto 0)));
        case alu_op is
            when ALU_ADD =>
                res_int <= std_logic_vector(signed(a) + signed(b));
            when ALU_SUB =>
                res_int <= std_logic_vector(signed(a) - signed(b));
            when ALU_SLL =>
                res_int <= std_logic_vector(shift_left(unsigned(a), shift_amt));
            when ALU_SLT =>
                if signed(a) < signed(b) then
                    res_int <= x"00000001";
                else
                    res_int <= x"00000000";
                end if;
            when ALU_SLTU =>
                if unsigned(a) < unsigned(b) then
                    res_int <= x"00000001";
                else
                    res_int <= x"00000000";
                end if;
            when ALU_XOR =>
                res_int <= a xor b;
            when ALU_SRL =>
                res_int <= std_logic_vector(shift_right(unsigned(a), shift_amt));
            when ALU_SRA =>
                res_int <= std_logic_vector(shift_right(signed(a), shift_amt));
            when ALU_OR =>
                res_int <= a or b;
            when ALU_AND =>
                res_int <= a and b;
            when ALU_COPY_B =>
                res_int <= b;
            when ALU_COPY_A =>
                res_int <= a;
            when others =>
                res_int <= (others => '0');
        end case;
    end process;

    result <= res_int;
    zero   <= '1' when res_int = x"00000000" else '0';
end Behavioral;
