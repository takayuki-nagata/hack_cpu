-- Copyright 2018 Takayuki Nagata All Rights Reserved.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity decode is
    Port ( instruction : in  STD_LOGIC_VECTOR (15 downto 0);
	        i : out  STD_LOGIC;
           v : out  STD_LOGIC_VECTOR (14 downto 0);
           a : out  STD_LOGIC;
           c : out  STD_LOGIC_VECTOR (0 to 5);
           d : out  STD_LOGIC_VECTOR (0 to 2);
           j : out  STD_LOGIC_VECTOR (0 to 2));
end decode;

architecture Behavioral of decode is
begin
	process(instruction)begin
		if instruction(15) = '0' then
		-- A instruction: 0 vvvvvvvvvvvvvvv
			i <= '0';
			v <= instruction(14 downto 0);
			a <= '0';
			c <= "000000";
			d <= "000";
			j <= "000";
		else
		-- C instruction: 1xx a c1c2c3c4c5c6 d1d2d3 j1j2j3
			i <= '1';
			v <= "000000000000000";
			a <= instruction(12);
			c(0 to 5) <= instruction(11 downto 6);
			d(0 to 2) <= instruction(5 downto 3);
			j(0 to 2) <= instruction(2 downto 0);
		end if;
	end process;
end Behavioral;

