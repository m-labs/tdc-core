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
-- 2011-08-12 SB Test pipelining and polarity inversion
-- 2011-08-03 SB Created file
-------------------------------------------------------------------------------

-- Copyright (C) 2011 Sebastien Bourdeauducq

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.tdc_package.all;

entity tb_lbc is
    generic(
        g_N: positive := 6
    );
end entity;

architecture tb of tb_lbc is

function chr(sl: std_logic) return character is
variable v_c: character;
begin
    case sl is
        when 'U' => v_c := 'U';
        when 'X' => v_c := 'X';
        when '0' => v_c := '0';
        when '1' => v_c := '1';
        when 'Z' => v_c := 'Z';
        when 'W' => v_c := 'W';
        when 'L' => v_c := 'L';
        when 'H' => v_c := 'H';
        when '-' => v_c := '-';
    end case;
    return v_c;
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

signal clk      : std_logic;
signal reset    : std_logic;
signal d        : std_logic_vector(2**g_N-2 downto 0);
signal count    : std_logic_vector(g_N-1 downto 0);
signal polarity : std_logic;

begin
    cmp_dut: tdc_lbc
        generic map(
            g_N   => g_N,
            g_NIN => 2**g_N-1
        )
        port map(
            clk_i      => clk,
            reset_i    => reset,
            d_i        => d,
            count_o    => count,
            polarity_o => polarity
        );
    process
    variable v_polarity : std_logic;
    variable v_d        : std_logic_vector(2**g_N-2 downto 0);
    variable v_seed1    : positive := 1;
    variable v_seed2    : positive := 2;
    variable v_rand     : real;
    variable v_int_rand : integer;
    variable v_stim     : std_logic_vector(0 downto 0);
    begin
        -- reset
        reset <= '1';
        clk <= '0';
        wait for 5 ns;
        clk <= '1';
        wait for 5 ns;
        reset <= '0';
        
        for i in 1 to 2**g_N+2-1 loop
            -- generate test vector
            if i < 2**g_N then
                if i rem 2 = 0 then
                    v_polarity := '0';
                else
                    v_polarity := '1';
                end if;
                for j in 0 to 2**g_N-2 loop
                    if j > 2**g_N-2-i then
                        v_d(j) := v_polarity;
                    elsif j = 2**g_N-2-i then
                        v_d(j) := not v_polarity;
                    else
                        uniform(v_seed1, v_seed2, v_rand);
                        v_int_rand := integer(trunc(v_rand*2.0));
                        v_stim := std_logic_vector(to_unsigned(v_int_rand, v_stim'length));
                        v_d(j) := v_stim(0);
                    end if;
                end loop;
                report "Vector out: " & str(v_d) & " (polarity: " & chr(v_polarity) & ")";
                d <= v_d;
            end if;
            -- verify output
            if i > 2 then
                if i rem 2 = 0 then
                    v_polarity := '0';
                else
                    v_polarity := '1';
                end if;
                report "Result in: expected:" & integer'image(i-2) & "(" & chr(v_polarity) & ") output:" & integer'image(to_integer(unsigned(count))) & "(" & chr(polarity) & ")";
                assert v_polarity = polarity severity failure;
                assert i-2 = to_integer(unsigned(count)) severity failure;
            end if;
            -- pulse clock
            clk <= '0';
            wait for 5 ns;
            clk <= '1';
            wait for 5 ns;
        end loop;
        report "Test passed.";
        wait;
    end process;
end architecture;
