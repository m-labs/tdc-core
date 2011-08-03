-------------------------------------------------------------------------------
-- TDC Core / CERN
-------------------------------------------------------------------------------
--
-- unit name: tb_lbc
--
-- author: Sebastien Bourdeauducq, sebastien@milkymist.org
--
-- description: Test bench for leading bit counter
--
-- references: http://www.ohwr.org/projects/tdc-core
--
-------------------------------------------------------------------------------
-- last changes:
-- 2011-08-03 SB Created file
-------------------------------------------------------------------------------

-- Copyright (C) 2011 Sebastien Bourdeauducq

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity tb_lbc is
    generic(
        g_N: positive := 6
    );
end entity;

architecture tb of tb_lbc is

function chr(sl: std_logic) return character is
variable c: character;
begin
    case sl is
        when 'U' => c:= 'U';
        when 'X' => c:= 'X';
        when '0' => c:= '0';
        when '1' => c:= '1';
        when 'Z' => c:= 'Z';
        when 'W' => c:= 'W';
        when 'L' => c:= 'L';
        when 'H' => c:= 'H';
        when '-' => c:= '-';
    end case;
return c;
end function;

function str(slv: std_logic_vector) return string is
variable result : string (1 to slv'length);
variable r      : integer;
begin
    r := 1;
    for i in slv'range loop
        result(r) := chr(slv(i));
        r := r + 1;
    end loop;
    return result;
end function;

signal polarity : std_logic;
signal d        : std_logic_vector(2**g_N-2 downto 0);
signal count    : std_logic_vector(g_N-1 downto 0);

begin
    dut: entity work.tdc_lbc
        generic map(
            g_N => g_N
        )
        port map(
            polarity_i   => polarity,
            d_i          => d,
            count_o      => count
        );
    polarity <= '0';
    process
    variable seed1     : positive := 1;
    variable seed2     : positive := 2;
    variable rand      : real;
    variable int_rand  : integer;
    variable stim      : std_logic_vector(0 downto 0); 
    begin
        for i in 0 to 2**g_N-1 loop
            -- generate test vector
            for j in 0 to 2**g_N-2 loop
                if j > 2**g_N-2-i then
                    d(j) <= '1';
                elsif j = 2**g_N-2-i then
                    d(j) <= '0';
                else
                    uniform(seed1, seed2, rand);
                    int_rand := integer(trunc(rand*2.0));
                    stim := std_logic_vector(to_unsigned(int_rand, stim'length));
                    d(j) <= stim(0);
                end if;
            end loop;
            -- generate, print and verify output
            wait for 10 ns;
            report "Vector:" & str(d) & " Expected:" & integer'image(i) & " Result:" & integer'image(to_integer(unsigned(count)));
            assert i = to_integer(unsigned(count)) severity failure;
        end loop;
        report "Test passed.";
        wait;
    end process;
end architecture;
