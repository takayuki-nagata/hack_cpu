-- Copyright 2018 Takayuki Nagata All Rights Reserved.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;

entity alu is
    Port ( X : in  STD_LOGIC_VECTOR (15 downto 0);
           Y : in  STD_LOGIC_VECTOR (15 downto 0);
           O : out  STD_LOGIC_VECTOR (15 downto 0);
           zx : in  STD_LOGIC;
           nx : in  STD_LOGIC;
           zy : in  STD_LOGIC;
           ny : in  STD_LOGIC;
           f : in  STD_LOGIC;
           no : in  STD_LOGIC;
           zr : out  STD_LOGIC;
           ng : out  STD_LOGIC);
end alu;

architecture Behavioral of alu is
	signal X_int : STD_LOGIC_VECTOR (15 downto 0);
	signal Y_int : STD_LOGIC_VECTOR (15 downto 0);
	signal O_int_f : STD_LOGIC_VECTOR (15 downto 0);
	signal O_int_n: STD_LOGIC_VECTOR (15 downto 0);
	signal O_int: STD_LOGIC_VECTOR (15 downto 0);
begin
	process(X, zx, nx)begin
		if zx = '1' then
			if nx = '1' then
				X_int <= "1111111111111111";
			else
				X_int <= "0000000000000000";
			end if;
		else
			if nx = '1' then
				X_int <= not X;
			else
				X_int <= X;
			end if;
		end if;
	end process;
	
	process(Y, zy, ny)begin
		if zy = '1' then
			if ny = '1' then
				Y_int <= "1111111111111111";
			else
				Y_int <= "0000000000000000";
			end if;
		else
			if ny = '1' then
				Y_int <= not Y;
			else
				Y_int <= Y;
			end if;
		end if;
	end process;
	
	process(X_int, Y_int, f)begin
		if f = '1' then
			O_int_f <= X_int + Y_int;
		else
			O_int_f <= X_int and Y_int;
		end if;
	end process;
	
	process(O_int_f, no)begin
		if no = '1' then
			O_int_n <= not O_int_f;
		else
			O_int_n <= O_int_f;
		end if;
	end process;
	
	O_int <=  O_int_n;
	
	process(O_int)begin
		if O_int = "0" then
			zr <= '1';
			ng <= '0';
		elsif O_int < "0" then
			zr <= '0';
			ng <= '1';
		else
			zr <= '0';
			ng <= '0';
		end if;
	end process;
	
	O <= O_int;
end Behavioral;

