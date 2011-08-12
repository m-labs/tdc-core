-------------------------------------------------------------------------------
-- TDC Core / CERN
-------------------------------------------------------------------------------
--
-- unit name: tdc_ringosc
--
-- author: Sebastien Bourdeauducq, sebastien@milkymist.org
--
-- description: Ring oscillator based on LUT primitives
--
-- references: http://www.ohwr.org/projects/tdc-core
--
-------------------------------------------------------------------------------
-- last changes:
-- 2011-08-05 SB Created file
-------------------------------------------------------------------------------

-- Copyright (C) 2011 Sebastien Bourdeauducq

library ieee;
use ieee.std_logic_1164.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.tdc_package.all;

entity tdc_ringosc is
    generic(
        -- Number of LUT elements. Must be odd!
        g_LENGTH: positive
    );
    port(
        -- Enable/reset_n input. The oscillator should be reset at least once.
        -- When disabled, the output is 0.
         en_i  : in std_logic;
         -- Oscillator output.
         clk_o : out std_logic
    );
end entity;

architecture rtl of tdc_ringosc is
signal s: std_logic_vector(g_LENGTH downto 0);
attribute keep: string;
attribute keep of s: signal is "true";
begin
    g_luts: for i in 0 to g_LENGTH-1 generate
        g_firstlut: if i = 0 generate
            cmp_LUT: LUT2
                generic map(
                    INIT => "0100"
                )
                port map(
                    I0 => s(i),
                    I1 => en_i,
                    O => s(i+1)
                );
         end generate;
         g_nextlut: if i > 0 generate
            cmp_LUT: LUT1
                generic map(
                    INIT => "01"
                )
                port map(
                    I0 => s(i),
                    O => s(i+1)
                );
         end generate;
    end generate;
    s(0) <= s(g_LENGTH);
    clk_o <= s(g_LENGTH);
end architecture;
