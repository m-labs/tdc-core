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
-- 2011-08-01 SB Created file
-------------------------------------------------------------------------------

-- Copyright (C) 2011 Sebastien Bourdeauducq

library ieee;
use ieee.std_logic_1164.all;

library work;
use work.tdc_package.all;

entity tdc_lbc is
    generic(
        -- Number of output bits.
        g_N : positive;
        -- Number of input bits. Maximum is 2^g_N-1.
        g_NIN: positive
    );
    port(
         clk_i        : in std_logic;
         reset_i      : in std_logic;
         d_i          : in std_logic_vector(g_NIN-1 downto 0);
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
signal count_reg   : std_logic_vector(g_N-1 downto 0);
signal d_completed : std_logic_vector(2**g_N-2 downto 0);
begin
    polarity_o <= polarity;
    
    g_expand: if g_NIN < 2**g_N-1 generate
        d_completed <= d_i & (2**g_N-1-g_NIN-1 downto 0 => not polarity);
    end generate;
    g_dontexpand: if g_NIN = 2**g_N-1 generate
        d_completed <= d_i;
    end generate;
    
    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                polarity <= '1';
                count_reg <= (others => '0');
                count_o <= (others => '0');
            else
                polarity <= not d_completed(2**g_N-2);
                count_reg <= f_cls(d_completed, polarity);
                count_o <= count_reg;
            end if;
        end if;
    end process;
end architecture;
