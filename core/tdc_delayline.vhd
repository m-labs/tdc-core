-------------------------------------------------------------------------------
-- TDC Core / CERN
-------------------------------------------------------------------------------
--
-- unit name: tdc_delayline
--
-- author: Sebastien Bourdeauducq, sebastien@milkymist.org
--
-- description: Delay line based on CARRY4 primitives
--
-- references: http://www.ohwr.org/projects/tdc-core
--
-------------------------------------------------------------------------------
-- last changes:
-- 2011-10-27 SB MSB first
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
-- The delay line uses a carry chain. It is made up of CARRY4 primitives whose
-- CO outputs are registered by the dedicated D flip flops of the same slices.
-- The signal is injected at the CYINIT pin at the bottom of the carry chain.
-- The CARRY4 primitives have their S inputs hardwired to 1, which means the
-- carry chain becomes a delay line with the signal going unchanged through the
-- MUXCY elements. Since each CARRY4 contains four MUXCY elements, the delay
-- line has four times as many taps as there are CARRY4 primitives.
--
-- There is a second layer of registers to prevent metastability.

library ieee;
use ieee.std_logic_1164.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.tdc_package.all;

entity tdc_delayline is
    generic(
        -- Number of CARRY4 elements.
        g_WIDTH: positive
    );
    port(
         clk_i        : in std_logic;
         reset_i      : in std_logic;
         signal_i     : in std_logic;
         taps_o       : out std_logic_vector(4*g_WIDTH-1 downto 0)
    );
end entity;

architecture rtl of tdc_delayline is
signal unreg_rev : std_logic_vector(4*g_WIDTH-1 downto 0);
signal reg1_rev  : std_logic_vector(4*g_WIDTH-1 downto 0);
signal taps_rev  : std_logic_vector(4*g_WIDTH-1 downto 0);

function f_bit_reverse(s: std_logic_vector) return std_logic_vector is
variable v_r: std_logic_vector(s'high downto s'low);
begin 
    for i in s'high downto s'low loop
        v_r(i) := s(s'high-i);
    end loop; 
    return v_r;
end function;

begin
    -- generate a carry chain
    g_carry4: for i in 0 to g_WIDTH-1 generate
        g_firstcarry4: if i = 0 generate
            cmp_CARRY4: CARRY4 port map(
                CO => unreg_rev(3 downto 0),
                CI => '0',
                CYINIT => signal_i,
                DI => "0000",
                S => "1111"
            );
         end generate;
         g_nextcarry4: if i > 0 generate
            cmp_CARRY4: CARRY4 port map(
                CO => unreg_rev(4*(i+1)-1 downto 4*i),
                CI => unreg_rev(4*i-1),
                CYINIT => '0',
                DI => "0000",
                S => "1111"
            );
         end generate;
    end generate;
    
    -- double latch the output
    g_fd: for j in 0 to 4*g_WIDTH-1 generate
        cmp_FDR_1: FDR
            generic map(
                INIT => '0'
            )
            port map(
                C => clk_i,
                R => reset_i,
                D => unreg_rev(j),
                Q => reg1_rev(j)
            );
        cmp_FDR_2: FDR
            generic map(
                INIT => '0'
            )
            port map(
                C => clk_i,
                R => reset_i,
                D => reg1_rev(j),
                Q => taps_rev(j)
            );
    end generate;
    
    taps_o <= f_bit_reverse(taps_rev);
end architecture;
