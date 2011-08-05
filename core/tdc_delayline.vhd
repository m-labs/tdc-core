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
-- 2011-08-01 SB Created file
-------------------------------------------------------------------------------

-- Copyright (C) 2011 Sebastien Bourdeauducq

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
signal unreg : std_logic_vector(4*g_WIDTH-1 downto 0);
signal reg1  : std_logic_vector(4*g_WIDTH-1 downto 0);
begin
    -- generate a carry chain
    g_carry4: for i in 0 to g_WIDTH-1 generate
        g_firstcarry4: if i = 0 generate
            cmp_CARRY4: CARRY4 port map(
                CO => unreg(3 downto 0),
                CI => '0',
                CYINIT => signal_i,
                DI => "0000",
                S => "1111"
            );
         end generate;
         g_nextcarry4: if i > 0 generate
            cmp_CARRY4: CARRY4 port map(
                CO => unreg(4*(i+1)-1 downto 4*i),
                CI => unreg(4*i-1),
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
                D => unreg(j),
                Q => reg1(j)
            );
        cmp_FDR_2: FDR
            generic map(
                INIT => '0'
            )
            port map(
                C => clk_i,
                R => reset_i,
                D => reg1(j),
                Q => taps_o(j)
            );
    end generate;
end architecture;
