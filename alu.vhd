-- Copyright 2018 Takayuki Nagata All Rights Reserved.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity alu is
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
end alu;

architecture Behavioral of alu is
    signal X_int   : STD_LOGIC_VECTOR (15 downto 0);
    signal Y_int   : STD_LOGIC_VECTOR (15 downto 0);
    signal O_int_f : STD_LOGIC_VECTOR (15 downto 0);
    signal O_int_n : STD_LOGIC_VECTOR (15 downto 0);
    signal O_int   : STD_LOGIC_VECTOR (15 downto 0);
begin
    -- Pre-process X
    process(X, zx, nx)
    begin
        if zx = '1' then
            if nx = '1' then
                X_int <= (others => '1');
            else
                X_int <= (others => '0');
            end if;
        else
            if nx = '1' then
                X_int <= not X;
            else
                X_int <= X;
            end if;
        end if;
    end process;

    -- Pre-process Y
    process(Y, zy, ny)
    begin
        if zy = '1' then
            if ny = '1' then
                Y_int <= (others => '1');
            else
                Y_int <= (others => '0');
            end if;
        else
            if ny = '1' then
                Y_int <= not Y;
            else
                Y_int <= Y;
            end if;
        end if;
    end process;

    -- Function compute (ADD or AND)
    process(X_int, Y_int, f)
    begin
        if f = '1' then
            O_int_f <= std_logic_vector(signed(X_int) + signed(Y_int));
        else
            O_int_f <= X_int and Y_int;
        end if;
    end process;

    -- Post-process output negation
    process(O_int_f, no)
    begin
        if no = '1' then
            O_int_n <= not O_int_f;
        else
            O_int_n <= O_int_f;
        end if;
    end process;

    O_int <= O_int_n;
    O     <= O_int;

    -- Zero flag and Negative flag determination
    zr <= '1' when O_int = "0000000000000000" else '0';
    ng <= O_int(15);

end Behavioral;


