-------------------------------------------------------------------------------
-- TDC Core / CERN
-------------------------------------------------------------------------------
--
-- unit name: tdc_package
--
-- author: Sebastien Bourdeauducq, sebastien@milkymist.org
--
-- description: Component declarations for the TDC core
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

package tdc_package is

component tdc_ringosc is
    generic(
        g_LENGTH: positive
    );
    port(
         en_i  : in std_logic;
         clk_o : out std_logic
    );
end component;

component tdc_lbc is
    generic(
        g_N : positive;
        g_NIN: positive
    );
    port(
         clk_i        : in std_logic;
         reset_i      : in std_logic;
         d_i          : in std_logic_vector(g_NIN-1 downto 0);
         polarity_o   : out std_logic;
         count_o      : out std_logic_vector(g_N-1 downto 0)
    );
end component;

component tdc_delayline is
    generic(
        g_WIDTH : positive
    );
    port(
         clk_i        : in std_logic;
         reset_i      : in std_logic;
         signal_i     : in std_logic;
         taps_o       : out std_logic_vector(4*g_WIDTH-1 downto 0)
    );
end component;

end package;
