-- Copyright 2018 Takayuki Nagata All Rights Reserved.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity cpu is
    Port ( inM         : in  STD_LOGIC_VECTOR (15 downto 0);
           instruction : in  STD_LOGIC_VECTOR (15 downto 0);
           reset       : in  STD_LOGIC;
           outM        : out STD_LOGIC_VECTOR (15 downto 0);
           writeM      : out STD_LOGIC;
           addressM    : out STD_LOGIC_VECTOR (14 downto 0);
           pc          : out STD_LOGIC_VECTOR (14 downto 0);
           clk         : in  STD_LOGIC);
end cpu;

architecture Behavioral of cpu is
    signal A_reg  : STD_LOGIC_VECTOR (15 downto 0) := (others => '0');
    signal D_reg  : STD_LOGIC_VECTOR (15 downto 0) := (others => '0');
    signal PC_reg : STD_LOGIC_VECTOR (15 downto 0) := (others => '0');

    component alu
        Port ( X  : in  STD_LOGIC_VECTOR (15 downto 0);
               Y  : in  STD_LOGIC_VECTOR (15 downto 0);
               O  : out STD_LOGIC_VECTOR (15 downto 0);
               zx : in  STD_LOGIC;
               nx : in  STD_LOGIC;
               zy : in  STD_LOGIC;
               ny : in  STD_LOGIC;
               f  : in  STD_LOGIC;
               no : in  STD_LOGIC;
               zr : out STD_LOGIC;
               ng : out STD_LOGIC);
    end component;

    component decode
        Port ( instruction : in  STD_LOGIC_VECTOR (15 downto 0);
               i           : out STD_LOGIC;
               v           : out STD_LOGIC_VECTOR (14 downto 0);
               a           : out STD_LOGIC;
               c           : out STD_LOGIC_VECTOR (0 to 5);
               d           : out STD_LOGIC_VECTOR (0 to 2);
               j           : out STD_LOGIC_VECTOR (0 to 2));
    end component;

    signal Y_int  : STD_LOGIC_VECTOR (15 downto 0);
    signal O_int  : STD_LOGIC_VECTOR (15 downto 0);
    signal zr_int : STD_LOGIC;
    signal ng_int : STD_LOGIC;

    signal i_int  : STD_LOGIC;
    signal v_int  : STD_LOGIC_VECTOR (14 downto 0);
    signal a_int  : STD_LOGIC;
    signal c_int  : STD_LOGIC_VECTOR (0 to 5);
    signal d_int  : STD_LOGIC_VECTOR (0 to 2);
    signal j_int  : STD_LOGIC_VECTOR (0 to 2);
begin
    cpu_decode : decode
        port map (
            instruction => instruction,
            i           => i_int,
            v           => v_int,
            a           => a_int,
            c           => c_int,
            d           => d_int,
            j           => j_int
        );

    cpu_alu : alu
        port map (
            X  => D_reg,
            Y  => Y_int,
            O  => O_int,
            zx => c_int(0),
            nx => c_int(1),
            zy => c_int(2),
            ny => c_int(3),
            f  => c_int(4),
            no => c_int(5),
            zr => zr_int,
            ng => ng_int
        );

    -- CPU outputs
    outM     <= O_int;
    writeM   <= d_int(2);
    addressM <= A_reg(14 downto 0);
    pc       <= PC_reg(14 downto 0);

    -- Mux for ALU Y input (select between A_reg and inM)
    Y_int <= inM when a_int = '1' else A_reg;

    -- Synchronous CPU register updates
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                PC_reg <= (others => '0');
            else
                -- A_reg update
                if i_int = '0' then
                    -- A instruction
                    A_reg <= '0' & v_int;
                elsif d_int(0) = '1' then
                    -- C instruction with d1 = 1
                    A_reg <= O_int;
                end if;

                -- D_reg update
                if d_int(1) = '1' then
                    D_reg <= O_int;
                end if;

                -- PC_reg update
                if (j_int(0) = '1' and ng_int = '1') or
                   (j_int(1) = '1' and zr_int = '1') or
                   (j_int(2) = '1' and ng_int = '0' and zr_int = '0') then
                    PC_reg <= A_reg;
                else
                    PC_reg <= std_logic_vector(unsigned(PC_reg) + 1);
                end if;
            end if;
        end if;
    end process;
end Behavioral;

