-------------------------------------------------------------------------------
-- TDC Core / CERN
-------------------------------------------------------------------------------
--
-- unit name: tb_freqc
--
-- author: Sebastien Bourdeauducq, sebastien@milkymist.org
--
-- description: Test bench for frequency counter
--
-- references: http://www.ohwr.org/projects/tdc-core
--
-------------------------------------------------------------------------------
-- last changes:
-- 2011-08-17 SB Created file
-------------------------------------------------------------------------------

-- Copyright (C) 2011 Sebastien Bourdeauducq

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.tdc_package.all;

entity tb_freqc is
    generic(
        g_COUNTER_WIDTH : positive := 20;
        g_TIMER_WIDTH   : positive := 16;
        g_CLK_PERIOD    : real := 8.0;
        g_CLK_M_PERIOD  : real := 4.36
    );
end entity;

architecture tb of tb_freqc is

signal clk   : std_logic;
signal reset : std_logic;
signal clk_m : std_logic;
signal start : std_logic;
signal ready : std_logic;
signal freq  : std_logic_vector(g_COUNTER_WIDTH-1 downto 0);

signal end_simulation : boolean := false;

begin
    cmp_dut: tdc_freqc
        generic map(
            g_COUNTER_WIDTH => g_COUNTER_WIDTH,
            g_TIMER_WIDTH   => g_TIMER_WIDTH
        )
        port map(
            clk_i   => clk,
            reset_i => reset,
            clk_m_i => clk_m,
            start_i => start,
            ready_o => ready,
            freq_o  => freq
        );
    
    process
    begin
        clk <= '0';
        wait for g_CLK_PERIOD/2.0 * 1 ns;
        clk <= '1';
        wait for g_CLK_PERIOD/2.0 * 1 ns;
        if end_simulation then
            wait;
        end if;
    end process;
    
    process
    begin
        clk_m <= '0';
        wait for g_CLK_M_PERIOD/2.0 * 1 ns;
        clk_m <= '1';
        wait for g_CLK_M_PERIOD/2.0 * 1 ns;
        if end_simulation then
            wait;
        end if;
    end process;
    
    process
    variable v_freq_int       : integer;
    variable v_ratio_actual   : real;
    variable v_ratio_measured : real;
    variable v_error          : real;
    variable v_max_error      : real;
    begin
        start <= '0';
        reset <= '1';
        wait until rising_edge(clk);
        reset <= '0';
        wait until rising_edge(clk);
        
        start <= '1';
        wait until rising_edge(clk);
        wait for 1 ns;
        assert ready = '0' severity failure;
        start <= '0';
        wait until ready = '1';
        v_freq_int := to_integer(unsigned(freq));
        v_ratio_actual := g_CLK_PERIOD/g_CLK_M_PERIOD;
        v_ratio_measured := real(v_freq_int)/real(2**g_TIMER_WIDTH-1);
        v_error := abs(v_ratio_measured-v_ratio_actual);
        v_max_error := 1.0/real(2**g_TIMER_WIDTH-1);
        report "Raw measured value: " & integer'image(v_freq_int);
        report "g_CLK_PERIOD/g_CLK_M_PERIOD (actual): " & real'image(v_ratio_actual);
        report "g_CLK_PERIOD/g_CLK_M_PERIOD (measured): " & real'image(v_ratio_measured);
        report "Error: " & real'image(v_error) & " (maximum: " & real'image(v_max_error) & ")";
        assert v_error <= v_max_error severity failure;
        
        report "Test passed.";
        end_simulation <= true;
        wait;
    end process;
end architecture;
