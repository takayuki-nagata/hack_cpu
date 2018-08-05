-- Copyright 2018 Takayuki Nagata All Rights Reserved.

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
ENTITY cpu_test IS
END cpu_test;
 
ARCHITECTURE behavior OF cpu_test IS  
    COMPONENT cpu
    PORT(
         inM : IN  std_logic_vector(15 downto 0);
         instruction : IN  std_logic_vector(15 downto 0);
         reset : IN  std_logic;
         outM : OUT  std_logic_vector(15 downto 0);
         writeM : OUT  std_logic;
         addressM : OUT  std_logic_vector(14 downto 0);
         pc : OUT  std_logic_vector(14 downto 0);
         clk : IN  std_logic
        );
    END COMPONENT;

   signal inM : std_logic_vector(15 downto 0) := (others => '0');
   signal instruction : std_logic_vector(15 downto 0) := (others => '0');
   signal reset : std_logic := '0';
   signal clk : std_logic := '0';

   signal outM : std_logic_vector(15 downto 0);
   signal writeM : std_logic;
   signal addressM : std_logic_vector(14 downto 0);
   signal pc : std_logic_vector(14 downto 0);

   constant clk_period : time := 10 ns; 
	
	function buildCinst(
		a: in std_logic;
		c: in std_logic_vector (0 to 5);
		d: in std_logic_vector (0 to 2);
		j: in std_logic_vector (0 to 2))
		return std_logic_vector is
		variable inst: std_logic_vector (15 downto 0);
		begin
			inst(15 downto 13) := "111";
			inst(12) := a;
			inst(11 downto 6) := c;
			inst(5 downto 3) := d;
			inst(2 downto 0) := j;
			return inst;
		end function;
		
	function LOAD_A(
		val: in std_logic_vector (14 downto 0))
		return std_logic_vector is
		variable inst: std_logic_vector (15 downto 0);
		begin
			inst(15) := '0';
			inst(14 downto 0) := val;
			return inst;
		end function;
	function LOAD_D_A
		return std_logic_vector is
		variable inst: std_logic_vector (15 downto 0);
		begin
			inst := "1110110000010000";
			return inst;
		end function;
BEGIN
   uut: cpu PORT MAP (
          inM => inM,
          instruction => instruction,
          reset => reset,
          outM => outM,
          writeM => writeM,
          addressM => addressM,
          pc => pc,
          clk => clk
        );

   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;

   stim_proc: process
	variable inst_a : std_logic;
	variable inst_c : std_logic_vector (0 to 5);
	variable inst_d : std_logic_vector (0 to 2);
	variable inst_j : std_logic_vector (0 to 2);
   begin		
		reset <= '1';
      wait for 100 ns;
		reset <= '0';
      wait for clk_period*10;
		inM <= "1111111111111111";
		
		-- Test A instruction
		instruction <= LOAD_A("010010010010010");
		wait for clk_period;
		
		-- Test C instruction
		-- Test dest
		instruction <= LOAD_A("000000000000011");
		wait for clk_period;
		inst_a := '0';
		inst_j := "000";
		inst_c := "110000"; -- = A
		-- null
		inst_d := "000";
		instruction <= buildCinst(inst_a, inst_c, inst_d, inst_j);
		wait for clk_period;
		-- M
		inst_d := "001";
		instruction <= buildCinst(inst_a, inst_c, inst_d, inst_j);
		wait for clk_period;
		-- D
		inst_d := "010";
		instruction <= buildCinst(inst_a, inst_c, inst_d, inst_j);
		wait for clk_period;
		-- MD
		inst_d := "011";
		instruction <= buildCinst(inst_a, inst_c, inst_d, inst_j);
		wait for clk_period;
		-- A
		inst_d := "100";
		instruction <= buildCinst(inst_a, inst_c, inst_d, inst_j);
		wait for clk_period;
		-- AM
		inst_d := "101";
		instruction <= buildCinst(inst_a, inst_c, inst_d, inst_j);
		wait for clk_period;
		-- AD
		inst_d := "110";
		instruction <= buildCinst(inst_a, inst_c, inst_d, inst_j);
		wait for clk_period;
		-- AMD
		inst_d := "111";
		instruction <= buildCinst(inst_a, inst_c, inst_d, inst_j);
		wait for clk_period;
		
		-- Test jump
		inst_a := '0';
		inst_c := "001100"; -- = D
		inst_d := "000"; -- null
		-- No jump
		inst_j := "000";
		-- out = 0
		instruction <= LOAD_A("000000000000000");
		wait for clk_period;
		instruction <= LOAD_D_A;
		wait for clk_period;
		instruction <= LOAD_A("111000000000000");
		wait for clk_period;
		instruction <= buildCinst(inst_a, inst_c, inst_d, inst_j);
		wait for clk_period;
		-- out > 0
		instruction <= LOAD_A("000000000000001");
		wait for clk_period;
		instruction <= LOAD_D_A;
		wait for clk_period;
		instruction <= LOAD_A("111000000000000");
		wait for clk_period;
		instruction <= buildCinst(inst_a, inst_c, inst_d, inst_j);
		wait for clk_period;
		-- out < 0
		instruction <= LOAD_A("111111111111110");
		wait for clk_period;
		instruction <= LOAD_D_A;
		wait for clk_period;
		instruction <= LOAD_A("111000000000000");
		wait for clk_period;
		instruction <= buildCinst(inst_a, inst_c, inst_d, inst_j);
		wait for clk_period;
		
		-- If out > 0 jump
		inst_j := "001";
		-- out = 0
		instruction <= LOAD_A("000000000000000");
		wait for clk_period;
		instruction <= LOAD_D_A;
		wait for clk_period;
		instruction <= LOAD_A("111000000000000");
		wait for clk_period;
		instruction <= buildCinst(inst_a, inst_c, inst_d, inst_j);
		wait for clk_period;
		-- out > 0
		instruction <= LOAD_A("000000000000001");
		wait for clk_period;
		instruction <= LOAD_D_A;
		wait for clk_period;
		instruction <= LOAD_A("111000000000000");
		wait for clk_period;
		instruction <= buildCinst(inst_a, inst_c, inst_d, inst_j);
		wait for clk_period;
		-- out < 0
		instruction <= LOAD_A("111111111111110");
		wait for clk_period;
		instruction <= LOAD_D_A;
		wait for clk_period;
		instruction <= LOAD_A("111000000000000");
		wait for clk_period;
		instruction <= buildCinst(inst_a, inst_c, inst_d, inst_j);
		wait for clk_period;
		
		-- If out = 0 jump
		inst_j := "010";
		-- out = 0
		instruction <= LOAD_A("000000000000000");
		wait for clk_period;
		instruction <= LOAD_D_A;
		wait for clk_period;
		instruction <= LOAD_A("111000000000000");
		wait for clk_period;
		instruction <= buildCinst(inst_a, inst_c, inst_d, inst_j);
		wait for clk_period;
		-- out > 0
		instruction <= LOAD_A("000000000000001");
		wait for clk_period;
		instruction <= LOAD_D_A;
		wait for clk_period;
		instruction <= LOAD_A("111000000000000");
		wait for clk_period;
		instruction <= buildCinst(inst_a, inst_c, inst_d, inst_j);
		wait for clk_period;
		-- out < 0
		instruction <= LOAD_A("111111111111110");
		wait for clk_period;
		instruction <= LOAD_D_A;
		wait for clk_period;
		instruction <= LOAD_A("111000000000000");
		wait for clk_period;
		instruction <= buildCinst(inst_a, inst_c, inst_d, inst_j);
		wait for clk_period;
		
		-- If out >= 0 jump
		inst_j := "011";
		-- out = 0
		instruction <= LOAD_A("000000000000000");
		wait for clk_period;
		instruction <= LOAD_D_A;
		wait for clk_period;
		instruction <= LOAD_A("111000000000000");
		wait for clk_period;
		instruction <= buildCinst(inst_a, inst_c, inst_d, inst_j);
		wait for clk_period;
		-- out > 0
		instruction <= LOAD_A("000000000000001");
		wait for clk_period;
		instruction <= LOAD_D_A;
		wait for clk_period;
		instruction <= LOAD_A("111000000000000");
		wait for clk_period;
		instruction <= buildCinst(inst_a, inst_c, inst_d, inst_j);
		wait for clk_period;
		-- out < 0
		instruction <= LOAD_A("111111111111110");
		wait for clk_period;
		instruction <= LOAD_D_A;
		wait for clk_period;
		instruction <= LOAD_A("111000000000000");
		wait for clk_period;
		instruction <= buildCinst(inst_a, inst_c, inst_d, inst_j);
		wait for clk_period;
		
		-- If out < 0 jump
		inst_j := "101";
		-- out = 0
		instruction <= LOAD_A("000000000000000");
		wait for clk_period;
		instruction <= LOAD_D_A;
		wait for clk_period;
		instruction <= LOAD_A("111000000000000");
		wait for clk_period;
		instruction <= buildCinst(inst_a, inst_c, inst_d, inst_j);
		wait for clk_period;
		-- out > 0
		instruction <= LOAD_A("000000000000001");
		wait for clk_period;
		instruction <= LOAD_D_A;
		wait for clk_period;
		instruction <= LOAD_A("111000000000000");
		wait for clk_period;
		instruction <= buildCinst(inst_a, inst_c, inst_d, inst_j);
		wait for clk_period;
		-- out < 0
		instruction <= LOAD_A("111111111111110");
		wait for clk_period;
		instruction <= LOAD_D_A;
		wait for clk_period;
		instruction <= LOAD_A("111000000000000");
		wait for clk_period;
		instruction <= buildCinst(inst_a, inst_c, inst_d, inst_j);
		wait for clk_period;
		
		-- If out != 0 jump
		inst_j := "110";
		-- out = 0
		instruction <= LOAD_A("000000000000000");
		wait for clk_period;
		instruction <= LOAD_D_A;
		wait for clk_period;
		instruction <= LOAD_A("111000000000000");
		wait for clk_period;
		instruction <= buildCinst(inst_a, inst_c, inst_d, inst_j);
		wait for clk_period;
		-- out > 0
		instruction <= LOAD_A("000000000000001");
		wait for clk_period;
		instruction <= LOAD_D_A;
		wait for clk_period;
		instruction <= LOAD_A("111000000000000");
		wait for clk_period;
		instruction <= buildCinst(inst_a, inst_c, inst_d, inst_j);
		wait for clk_period;
		-- out < 0
		instruction <= LOAD_A("111111111111110");
		wait for clk_period;
		instruction <= LOAD_D_A;
		wait for clk_period;
		instruction <= LOAD_A("111000000000000");
		wait for clk_period;
		instruction <= buildCinst(inst_a, inst_c, inst_d, inst_j);
		wait for clk_period;
		
		-- Jump
		inst_j := "111";
		-- out = 0
		instruction <= LOAD_A("000000000000000");
		wait for clk_period;
		instruction <= LOAD_D_A;
		wait for clk_period;
		instruction <= LOAD_A("111000000000000");
		wait for clk_period;
		instruction <= buildCinst(inst_a, inst_c, inst_d, inst_j);
		wait for clk_period;
		-- out > 0
		instruction <= LOAD_A("000000000000001");
		wait for clk_period;
		instruction <= LOAD_D_A;
		wait for clk_period;
		instruction <= LOAD_A("111000000000000");
		wait for clk_period;
		instruction <= buildCinst(inst_a, inst_c, inst_d, inst_j);
		wait for clk_period;
		-- out < 0
		instruction <= LOAD_A("111111111111110");
		wait for clk_period;
		instruction <= LOAD_D_A;
		wait for clk_period;
		instruction <= LOAD_A("111000000000000");
		wait for clk_period;
		instruction <= buildCinst(inst_a, inst_c, inst_d, inst_j);
		wait for clk_period;
		
		-- Test comp
		instruction <= LOAD_A("000000000000011");
		wait for clk_period;
		instruction <= LOAD_D_A;
		wait for clk_period;
		instruction <= LOAD_A("000000000000001");
		wait for clk_period;
		
		-- a=0
		inst_a := '0';
		inst_d := "001"; -- Addre[M]
		inst_j := "000";
		-- 0
		inst_c := "101010";
		instruction <= buildCinst(inst_a, inst_c, inst_d, inst_j);
		wait for clk_period;
		-- 1
		inst_c := "111111";
		instruction <= buildCinst(inst_a, inst_c, inst_d, inst_j);
		wait for clk_period;
		-- -1
		inst_c := "111010";
		instruction <= buildCinst(inst_a, inst_c, inst_d, inst_j);
		wait for clk_period;
		-- D
		inst_c := "001100";
		instruction <= buildCinst(inst_a, inst_c, inst_d, inst_j);
		wait for clk_period;
		-- A
		inst_c := "110000";
		instruction <= buildCinst(inst_a, inst_c, inst_d, inst_j);
		wait for clk_period;
		-- !D
		inst_c := "001101";
		instruction <= buildCinst(inst_a, inst_c, inst_d, inst_j);
		wait for clk_period;
		-- !A
		inst_c := "110001";
		instruction <= buildCinst(inst_a, inst_c, inst_d, inst_j);
		wait for clk_period;
		-- -D
		inst_c := "001111";
		instruction <= buildCinst(inst_a, inst_c, inst_d, inst_j);
		wait for clk_period;
		-- -A
		inst_c := "110011";
		instruction <= buildCinst(inst_a, inst_c, inst_d, inst_j);
		wait for clk_period;
		-- D+1
		inst_c := "011111";
		instruction <= buildCinst(inst_a, inst_c, inst_d, inst_j);
		wait for clk_period;
		-- A+1
		inst_c := "110111";
		instruction <= buildCinst(inst_a, inst_c, inst_d, inst_j);
		wait for clk_period;
		-- D-1
		inst_c := "001110";
		instruction <= buildCinst(inst_a, inst_c, inst_d, inst_j);
		wait for clk_period;
		-- A-1
		inst_c := "110010";
		instruction <= buildCinst(inst_a, inst_c, inst_d, inst_j);
		wait for clk_period;
		-- D+A
		inst_c := "000010";
		instruction <= buildCinst(inst_a, inst_c, inst_d, inst_j);
		wait for clk_period;
		-- D-A
		inst_c := "010011";
		instruction <= buildCinst(inst_a, inst_c, inst_d, inst_j);
		wait for clk_period;
		-- A-D
		inst_c := "000111";
		instruction <= buildCinst(inst_a, inst_c, inst_d, inst_j);
		wait for clk_period;
		-- D&A
		inst_c := "000000";
		instruction <= buildCinst(inst_a, inst_c, inst_d, inst_j);
		wait for clk_period;
		-- D|A
		inst_c := "010101";
		instruction <= buildCinst(inst_a, inst_c, inst_d, inst_j);
		wait for clk_period;
      wait;
   end process;
END;
