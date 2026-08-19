-- Copyright 2026 Takayuki Nagata All Rights Reserved.
-- RISC-V RV32I 32x32-bit Register File

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity rv32i_regfile is
    Port (
        clk      : in  std_logic;
        reset    : in  std_logic;
        we       : in  std_logic;
        rs1_addr : in  std_logic_vector(4 downto 0);
        rs2_addr : in  std_logic_vector(4 downto 0);
        rd_addr  : in  std_logic_vector(4 downto 0);
        wr_data  : in  std_logic_vector(31 downto 0);
        rs1_data : out std_logic_vector(31 downto 0);
        rs2_data : out std_logic_vector(31 downto 0)
    );
end rv32i_regfile;

architecture Behavioral of rv32i_regfile is
    type reg_array is array (0 to 31) of std_logic_vector(31 downto 0);
    signal registers : reg_array := (others => (others => '0'));
begin
    -- Read operations (asynchronous): x0 is hardwired to 0
    process(rs1_addr, registers)
    begin
        if unsigned(rs1_addr) = 0 then
            rs1_data <= (others => '0');
        else
            rs1_data <= registers(to_integer(unsigned(rs1_addr)));
        end if;
    end process;

    process(rs2_addr, registers)
    begin
        if unsigned(rs2_addr) = 0 then
            rs2_data <= (others => '0');
        else
            rs2_data <= registers(to_integer(unsigned(rs2_addr)));
        end if;
    end process;

    -- Write operation (synchronous)
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                registers <= (others => (others => '0'));
            elsif we = '1' and unsigned(rd_addr) /= 0 then
                registers(to_integer(unsigned(rd_addr))) <= wr_data;
            end if;
        end if;
    end process;
end Behavioral;
