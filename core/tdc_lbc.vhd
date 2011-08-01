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

entity tdc_lbc is
    generic (
        -- Number of output bits.
        -- The number of input bits is 2^g_N-1.
        g_N : positive := 4
    );
    port (
         polarity_i   : in std_logic;
         d_i          : in std_logic_vector(2**g_N-2 downto 0);
         count_o      : out std_logic_vector(g_N-1 downto 0)
    );
end entity;

architecture rtl of tdc_lbc is

-- "Count leading ones" function inspired by the post by Ulf Samuelsson
-- http://www.velocityreviews.com/forums/t25846-p4-how-to-count-zeros-in-registers.html
--
-- The idea is to use a divide-and-conquer approach to process a 2^N bit number.
-- We split the number in two equal halves of 2^(N-1) bits:
--   MMMMLLLL
-- then, we check if MMMM is all 1's.
-- If it is,
--      then the number of leading ones is 2^(N-1) + CLO(LLLL)
-- If it is not,
--      then the number of leading ones is CLO(MMMM)
-- Recursion stops with CLO(0)=0 and CLO(1)=1.
--
-- If the input is not all ones, we never propagate a carry and
-- the additions can be replaced by OR's, giving the result bit per bit.
-- We assume here an implicit LSB with a 0 value, and work with inputs
-- widths that are a power of 2 minus one.
function f_clo(d: std_logic_vector) return std_logic_vector is
variable v_d: std_logic_vector(d'length-1 downto 0);
begin
    v_d := d; -- fix indices
    if v_d'length = 1 then
        return v_d(0 downto 0);
    else
        if v_d(v_d'length-1 downto v_d'length/2) = (v_d'length-1 downto v_d'length/2 => '1') then
            return "1" & f_clo(v_d(v_d'length/2-1 downto 0));
        else
            return "0" & f_clo(v_d(v_d'length-1 downto v_d'length/2+1));
        end if;
    end if;
end function;

signal d_x : std_logic_vector(d_i'length-1 downto 0);
begin
    d_x <= (d_i'length-1 downto 0 => polarity_i) xor d_i;
    count_o <= f_clo(d_x);
end architecture;
