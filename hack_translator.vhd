-- Copyright 2026 Takayuki Nagata All Rights Reserved.
-- Hack-to-RV32I Micro-Op Translator Front-End

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.rv32i_types.all;

entity hack_translator is
    Port (
        instr_16     : in  std_logic_vector(15 downto 0);
        rs1          : out std_logic_vector(4 downto 0); -- Operand 1 (D = x2)
        rs2          : out std_logic_vector(4 downto 0); -- Operand 2 (A = x1)
        rd           : out std_logic_vector(4 downto 0);
        imm          : out std_logic_vector(31 downto 0);
        alu_op       : out std_logic_vector(3 downto 0);
        use_imm      : out std_logic;
        use_mem      : out std_logic; -- '1' if ALU Y is Memory[x1]
        we_reg_a     : out std_logic; -- Write to A (x1)
        we_reg_d     : out std_logic; -- Write to D (x2)
        we_mem       : out std_logic; -- Write to Memory[x1]
        jump_cond    : out std_logic_vector(2 downto 0);
        is_c_instr   : out std_logic
    );
end hack_translator;

architecture Behavioral of hack_translator is
begin
    process(instr_16)
        variable c_code : std_logic_vector(5 downto 0);
        variable d_code : std_logic_vector(2 downto 0);
    begin
        -- Default mappings: x1 = A, x2 = D
        rs1 <= "00010"; -- x2 (D)
        rs2 <= "00001"; -- x1 (A)
        rd  <= "00001";

        if instr_16(15) = '0' then
            -- A-Instruction: 0 vvvvvvvvvvvvvvv
            is_c_instr <= '0';
            imm        <= std_logic_vector(resize(unsigned(instr_16(14 downto 0)), 32));
            alu_op     <= ALU_COPY_B;
            use_imm    <= '1';
            use_mem    <= '0';
            we_reg_a   <= '1';
            we_reg_d   <= '0';
            we_mem     <= '0';
            jump_cond  <= "000";
        else
            -- C-Instruction: 1xx a c1c2c3c4c5c6 d1d2d3 j1j2j3
            is_c_instr <= '1';
            imm        <= (others => '0');
            use_imm    <= '0';
            use_mem    <= instr_16(12); -- a bit (0 = A, 1 = M)

            c_code := instr_16(11 downto 6);
            d_code := instr_16(5 downto 3);
            jump_cond <= instr_16(2 downto 0);

            we_reg_a <= d_code(2); -- d1 = A
            we_reg_d <= d_code(1); -- d2 = D
            we_mem   <= d_code(0); -- d3 = M

            case c_code is
                when "101010" => alu_op <= ALU_COPY_B; -- 0 (handled via zero)
                when "001100" => alu_op <= ALU_COPY_B; -- D
                when "110000" => alu_op <= ALU_COPY_B; -- A or M
                when "000010" => alu_op <= ALU_ADD;    -- D+A or D+M
                when "010011" => alu_op <= ALU_SUB;    -- D-A or D-M
                when "000000" => alu_op <= ALU_AND;    -- D&A or D&M
                when "010101" => alu_op <= ALU_OR;     -- D|A or D|M
                when "000101" => alu_op <= ALU_XOR;    -- D^A or D^M
                when others   => alu_op <= ALU_ADD;
            end case;
        end if;
    end process;
end Behavioral;
