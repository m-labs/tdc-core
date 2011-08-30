-------------------------------------------------------------------------------
-- TDC Core / CERN
-------------------------------------------------------------------------------
--
-- unit name: tb_divider
--
-- author: Sebastien Bourdeauducq, sebastien@milkymist.org
--
-- description: Test bench for the integer divider
--
-- references: http://www.ohwr.org/projects/tdc-core
--
-------------------------------------------------------------------------------
-- last changes:
-- 2011-08-18 SB Created file
-------------------------------------------------------------------------------

-- Copyright (C) 2011 Sebastien Bourdeauducq

-- DESCRIPTION:
-- This test validates the integer divider by making it compute the quotient
-- and remainder of all 0 ... 2^g_WIDTH positive integer values by all
-- 1 ... 2^g_WIDTH values. It then checks for the correct results.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.tdc_package.all;

entity tb_divider is
    generic(
        g_WIDTH : positive := 5
    );
end entity;

architecture tb of tb_divider is

signal clk       : std_logic;
signal reset     : std_logic;
signal start     : std_logic;
signal dividend  : std_logic_vector(g_WIDTH-1 downto 0);
signal divisor   : std_logic_vector(g_WIDTH-1 downto 0);
signal ready     : std_logic;
signal quotient  : std_logic_vector(g_WIDTH-1 downto 0);
signal remainder : std_logic_vector(g_WIDTH-1 downto 0);

signal end_simulation : boolean := false;

begin
    cmp_dut: tdc_divider
        generic map(
            g_WIDTH => g_WIDTH
        )
        port map(
            clk_i       => clk,
            reset_i     => reset,
            start_i     => start,
            dividend_i  => dividend,
            divisor_i   => divisor,
            ready_o     => ready,
            quotient_o  => quotient,
            remainder_o => remainder
        );
    
    process
    begin
        clk <= '0';
        wait for 4 ns;
        clk <= '1';
        wait for 4 ns;
        if end_simulation then
            wait;
        end if;
    end process;
    
    process
    variable v_quotient_got  : integer;
    variable v_remainder_got : integer;
    variable v_quotient_exp  : integer;
    variable v_remainder_exp : integer;
    begin
        start <= '0';
        reset <= '1';
        wait until rising_edge(clk);
        reset <= '0';
        wait until rising_edge(clk);
        
        for p in 0 to 2**g_WIDTH-1 loop
            for q in 1 to 2**g_WIDTH-1 loop
                dividend <= std_logic_vector(to_unsigned(p, g_WIDTH));
                divisor <= std_logic_vector(to_unsigned(q, g_WIDTH));
                start <= '1';
                wait until rising_edge(clk);
                wait for 1 ns;
                assert ready = '0' severity failure;
                start <= '0';
                wait until ready = '1';
                v_quotient_got := to_integer(unsigned(quotient));
                v_remainder_got := to_integer(unsigned(remainder));
                v_quotient_exp := p/q;
                v_remainder_exp := p rem q;
                report integer'image(p) & " = " & integer'image(q) 
                    & " * " & integer'image(v_quotient_got) & " + " & integer'image(v_remainder_got);
                assert v_quotient_got = v_quotient_exp severity failure;
                assert v_remainder_got = v_remainder_exp severity failure;
            end loop;
        end loop;
        
        report "Test passed.";
        end_simulation <= true;
        wait;
    end process;
end architecture;
