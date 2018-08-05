-- Copyright 2018 Takayuki Nagata All Rights Reserved.

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_signed.ALL;
USE ieee.numeric_std.ALL;
 
ENTITY alu_test IS
END alu_test;
ARCHITECTURE behavior OF alu_test IS 
    COMPONENT alu
    PORT(
         X : IN  std_logic_vector(15 downto 0);
         Y : IN  std_logic_vector(15 downto 0);
         O : OUT  std_logic_vector(15 downto 0);
         zx : IN  std_logic;
         nx : IN  std_logic;
         zy : IN  std_logic;
         ny : IN  std_logic;
         f : IN  std_logic;
         no : IN  std_logic;
         zr : OUT  std_logic;
         ng : OUT  std_logic
        );
    END COMPONENT;
   signal X : std_logic_vector(15 downto 0) := (others => '0');
   signal Y : std_logic_vector(15 downto 0) := (others => '0');
   signal zx : std_logic := '0';
   signal nx : std_logic := '0';
   signal zy : std_logic := '0';
   signal ny : std_logic := '0';
   signal f : std_logic := '0';
   signal no : std_logic := '0';
   signal O : std_logic_vector(15 downto 0);
   signal zr : std_logic;
   signal ng : std_logic;
BEGIN
   uut: alu PORT MAP (
          X => X,
          Y => Y,
          O => O,
          zx => zx,
          nx => nx,
          zy => zy,
          ny => ny,
          f => f,
          no => no,
          zr => zr,
          ng => ng
        );
   stim_proc: process
   begin
		X <= "0000000000000011";
		Y <= "0000000000000001";
		
		zx <= '1'; nx <= '0'; zy <= '1'; ny <= '0'; f <= '1'; no <= '0';
		wait for 10 ns;
		assert signed(O) = 0 report "0" severity failure;
		
		zx <= '1'; nx <= '1'; zy <= '1'; ny <= '1'; f <= '1'; no <= '1';
		wait for 10 ns;
		assert signed(O) = 1 report "1" severity failure;
		
		zx <= '1'; nx <= '1'; zy <= '1'; ny <= '0'; f <= '1'; no <= '0';
		wait for 10 ns;
		assert signed(O) = -1 report "-1" severity failure;
		
		zx <= '0'; nx <= '0'; zy <= '1'; ny <= '1'; f <= '0'; no <= '0';
		wait for 10 ns;
		assert O = X report "X" severity failure;
		
		zx <= '1'; nx <= '1'; zy <= '0'; ny <= '0'; f <= '0'; no <= '0';
		wait for 10 ns;
		assert O = Y report "Y" severity failure;
		
		zx <= '0'; nx <= '0'; zy <= '1'; ny <= '1'; f <= '0'; no <= '1';
		wait for 10 ns;
		assert O = not X report "!X" severity failure;
		
		zx <= '1'; nx <= '1'; zy <= '0'; ny <= '0'; f <= '0'; no <= '1';
		wait for 10 ns;
		assert O = not Y report "!Y" severity failure;
		
		zx <= '0'; nx <= '0'; zy <= '1'; ny <= '1'; f <= '1'; no <= '1';
		wait for 10 ns;
		assert O = std_logic_vector(signed(X)*(-1)) report "-X" severity failure;
		
		zx <= '1'; nx <= '1'; zy <= '0'; ny <= '0'; f <= '1'; no <= '1';
		wait for 10 ns;
		assert O = std_logic_vector(signed(Y)*(-1)) report "-Y" severity failure;
		
		zx <= '0'; nx <= '1'; zy <= '1'; ny <= '1'; f <= '1'; no <= '1';
		wait for 10 ns;
		assert O = std_logic_vector(signed(X)+1) report "X+1" severity failure;
		
		zx <= '1'; nx <= '1'; zy <= '0'; ny <= '1'; f <= '1'; no <= '1';
		wait for 10 ns;
		assert O = std_logic_vector(signed(Y)+1) report "X+Y" severity failure;
		
		zx <= '0'; nx <= '0'; zy <= '1'; ny <= '1'; f <= '1'; no <= '0';
		wait for 10 ns;
		assert O = std_logic_vector(signed(X)-1) report "X-1" severity failure;
		
		zx <= '1'; nx <= '1'; zy <= '0'; ny <= '0'; f <= '1'; no <= '0';
		wait for 10 ns;
		assert O = std_logic_vector(signed(Y)-1) report "Y-1" severity failure;
		
		zx <= '0'; nx <= '0'; zy <= '0'; ny <= '0'; f <= '1'; no <= '0';
		wait for 10 ns;
		assert O = (X+Y) report "X+Y" severity failure;
		
		zx <= '0'; nx <= '1'; zy <= '0'; ny <= '0'; f <= '1'; no <= '1';
		wait for 10 ns;
		assert O = (X-Y) report "X-Y" severity failure;
		
		zx <= '0'; nx <= '0'; zy <= '0'; ny <= '1'; f <= '1'; no <= '1';
		wait for 10 ns;
		assert O = (Y-X) report "Y-X" severity failure;
		
		zx <= '0'; nx <= '0'; zy <= '0'; ny <= '0'; f <= '0'; no <= '0';
		wait for 10 ns;
		assert O  = (X and Y) report "X&Y" severity failure;
		
		zx <= '0'; nx <= '1'; zy <= '0'; ny <= '1'; f <= '0'; no <= '1';
		wait for 10 ns;
		assert O = (X or Y) report "X|Y" severity failure;
		
		wait;
   end process;
END;
