-------------------------------------------------------------------------------
-- TDC Core / CERN
-------------------------------------------------------------------------------
--
-- unit name: tdc_lbc
--
-- author: Sebastien Bourdeauducq, sebastien@milkymist.org
--
-- description: Leading bit counter
--
-- references: http://www.ohwr.org/projects/tdc-core
--
-------------------------------------------------------------------------------
-- last changes:
-- 2011-11-07 SB Pre-inversion
-- 2011-10-27 SB Fix pipeline balance
-- 2011-08-01 SB Created file
-------------------------------------------------------------------------------

-- Copyright (C) 2011 CERN
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as published by
-- the Free Software Foundation, version 3 of the License.
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
-- You should have received a copy of the GNU Lesser General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.

-- DESCRIPTION:
-- Encoder for the delay line. Counts the number of leading bits equal to the
-- current polarity. The current polarity is the opposite of the most
-- significant bit of the input vector from the previous cycle.

library ieee;
use ieee.std_logic_1164.all;

library work;
use work.tdc_package.all;

entity tdc_lbc is
    generic(
        -- Number of output bits.
        g_N      : positive;
        -- Number of input bits. Maximum is 2^g_N-1.
        g_NIN    : positive;
        -- Number of cycles to ignore input after a transition.
        g_IGNORE : natural
    );
    port(
         clk_i        : in std_logic;
         reset_i      : in std_logic;
         d_i          : in std_logic_vector(g_NIN-1 downto 0);
         ipolarity_o  : out std_logic;
         polarity_o   : out std_logic;
         count_o      : out std_logic_vector(g_N-1 downto 0)
    );
end entity;

architecture rtl of tdc_lbc is

-- "Count leading symbol" function inspired by the post by Ulf Samuelsson
-- http://www.velocityreviews.com/forums/t25846-p4-how-to-count-zeros-in-registers.html
--
-- The idea is to use a divide-and-conquer approach to process a 2^N bit number.
-- We split the number in two equal halves of 2^(N-1) bits:
--   MMMMLLLL
-- then, we check if all bits of MMMM are of the counted symbol.
-- If it is,
--      then the number of leading symbols is 2^(N-1) + CLS(LLLL)
-- If it is not,
--      then the number of leading symbols is CLS(MMMM)
-- Recursion stops with CLS(0)=0 and CLS(1)=1.
--
-- If at least one bit of the input is not the symbol, we never propagate a carry
-- and the additions can be replaced by OR's, giving the result bit per bit.
-- We assume here an implicit LSB with a !symbol value, and work with inputs
-- widths that are a power of 2 minus one.
function f_cls(d: std_logic_vector; symbol: std_logic) return std_logic_vector is
variable v_d: std_logic_vector(d'length-1 downto 0);
begin
    v_d := d; -- fix indices
    if v_d'length = 1 then
        if v_d(0) = symbol then
            return "1";
        else
            return "0";
        end if;
    else
        if v_d(v_d'length-1 downto v_d'length/2) = (v_d'length-1 downto v_d'length/2 => symbol) then
            return "1" & f_cls(v_d(v_d'length/2-1 downto 0), symbol);
        else
            return "0" & f_cls(v_d(v_d'length-1 downto v_d'length/2+1), symbol);
        end if;
    end if;
end function;

signal polarity    : std_logic;
signal polarity_d1 : std_logic;
signal count       : std_logic_vector(g_N-1 downto 0);
signal count_d1    : std_logic_vector(g_N-1 downto 0);
signal d_completed : std_logic_vector(2**g_N-2 downto 0);
signal ignore      : std_logic;

-- enable retiming
attribute register_balancing: string;
attribute register_balancing of count: signal is "backward";
attribute register_balancing of count_d1: signal is "backward";

begin
    g_expand: if g_NIN < 2**g_N-1 generate
        d_completed <= d_i & (2**g_N-1-g_NIN-1 downto 0 => '0');
    end generate;
    g_dontexpand: if g_NIN = 2**g_N-1 generate
        d_completed <= d_i;
    end generate;
    
    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                polarity <= '1';
                polarity_d1 <= '1';
                count <= (others => '0');
                count_d1 <= (others => '0');
            else
                if (d_completed(2**g_N-2) = '1') and (ignore = '0') then
                    polarity <= not polarity;
                end if;
                polarity_d1 <= not polarity;
                count <= f_cls(d_completed, '1');
                count_d1 <= count;
            end if;
        end if;
    end process;
    
    g_ignoresr: if g_IGNORE > 0 generate
    signal ignore_sr: std_logic_vector(g_IGNORE-1 downto 0);
    begin
        process(clk_i)
        begin
            if rising_edge(clk_i) then
                if reset_i = '1' then
                    ignore_sr <= (others => '0');
                else
                    if (d_completed(2**g_N-2) = '1') and (ignore = '0') then
                        ignore_sr <= (others => '0');
                        ignore_sr(g_IGNORE-1) <= '1';
                    else
                        ignore_sr <= "0" & ignore_sr(g_IGNORE-1 downto 1);
                    end if;
                end if;
            end if;
        end process;
        ignore <= '0' when (ignore_sr = (ignore_sr'range => '0')) else '1';
    end generate;
    
    g_noignore: if g_IGNORE = 0 generate
    begin
        ignore <= '0';
    end generate;
    
    ipolarity_o <= polarity;
    polarity_o <= polarity_d1;
    count_o <= count_d1;
end architecture;
