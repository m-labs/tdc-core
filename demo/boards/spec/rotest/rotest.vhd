-------------------------------------------------------------------------------
-- TDC Core / CERN
-------------------------------------------------------------------------------
--
-- unit name: rotest
--
-- author: Sebastien Bourdeauducq, sebastien@milkymist.org
--
-- description: Ring oscillator HW test
--
-- references: http://www.ohwr.org/projects/tdc-core
--
-------------------------------------------------------------------------------
-- last changes:
-- 2011-10-22 SB Created file
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
-- Instantiates the ring oscillator and connects the output to the first LEMO
-- connector of the FMC 5ch DIO (J2), for easy observation of the signal.
-- Push button 0 is connected to the enable input of the ring oscillator.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.tdc_package.all;

entity rotest is
    port(
        en    : in std_logic;
        led   : out std_logic;
        
        out_p : out std_logic;
        out_n : out std_logic;
        oe_n  : out std_logic
    );
end entity;

architecture rtl of rotest is
signal out_se : std_logic;
begin
    cmp_obuf: OBUFDS
        generic map(
            IOSTANDARD => "DEFAULT"
        )
        port map(
            O  => out_p,
            OB => out_n,
            I  => out_se
        );
    cmp_ringosc: tdc_ringosc
        generic map(
            g_LENGTH => 31
        )
        port map(
            en_i  => en,
            clk_o => out_se
        );
    led <= not en;
    oe_n <= '0';
end architecture;
