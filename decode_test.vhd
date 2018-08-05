-- Copyright 2018 Takayuki Nagata All Rights Reserved.

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
ENTITY decode_test IS
END decode_test;
 
ARCHITECTURE behavior OF decode_test IS  
    COMPONENT decode
    PORT(
         instruction : IN  std_logic_vector(15 downto 0);
         v : OUT  std_logic_vector(14 downto 0);
         a : OUT  std_logic;
         c : OUT  std_logic_vector(0 to 5);
         d : OUT  std_logic_vector(0 to 2);
         j : OUT  std_logic_vector(0 to 2)
        );
    END COMPONENT;
   signal instruction : std_logic_vector(15 downto 0) := (others => '0');
   signal v : std_logic_vector(14 downto 0);
   signal a : std_logic;
   signal c : std_logic_vector(0 to 5);
   signal d : std_logic_vector(0 to 2);
   signal j : std_logic_vector(0 to 2); 
BEGIN
   uut: decode PORT MAP (
          instruction => instruction,
          v => v,
          a => a,
          c => c,
          d => d,
          j => j
        );
   stim_proc: process
   begin
		instruction <= "0111000111000111"; -- A instruction: v=111000111000111
		wait for 10ns;
		assert v = "111000111000111" report "v=111000111000111" severity failure;
		
		instruction <= "1110001110100001"; -- C instruction: a=0 c=001110 d=100 j=001
		wait for 10ns;
		assert a = '0' report "a=0" severity failure;
		assert c = "001110" report "c=001110" severity failure;
		assert d = "100" report "d=100" severity failure;
		assert j = "001" report "j=001" severity failure;
		
		instruction <= "1111010101001100"; -- C instruction: a=1 c=010101 d=001 j=100
		wait for 10ns;
		assert a = '1' report "a=1" severity failure;
		assert c = "010101" report "c=010101" severity failure;
		assert d = "001" report "d=001" severity failure;
		assert j = "100" report "j=100" severity failure;
      wait;
   end process;
END;
