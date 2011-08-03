-------------------------------------------------------------------------------
-- TDC Core / CERN
-------------------------------------------------------------------------------
--
-- unit name: tdc_channel
--
-- author: Sebastien Bourdeauducq, sebastien@milkymist.org
--
-- description: Per-channel processing
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
use work.tdc_package.all;

entity tdc_channel is
    generic(
        -- Number of CARRY4 elements.
        g_CARRY4_COUNT : positive;
        -- Number of raw output bits.
        g_RAW_COUNT    : positive
    );
    port(
         clk_i        : in std_logic;
         reset_i      : in std_logic;
         signal_i     : in std_logic;
         detect_o     : out std_logic;
         polarity_o   : out std_logic;
         raw_o        : out std_logic_vector(g_RAW_COUNT-1 downto 0)
    );
end entity;

architecture rtl of tdc_channel is
signal taps                  : std_logic_vector(4*g_CARRY4_COUNT-1 downto 0);
signal polarity, polarity_d1 : std_logic;
signal raw                   : std_logic_vector(g_RAW_COUNT-1 downto 0);
begin
    cmp_delayline: tdc_delayline
        generic map(
            g_WIDTH => g_CARRY4_COUNT
        )
        port map(
             clk_i        => clk_i,
             reset_i      => reset_i,
             signal_i     => signal_i,
             taps_o       => taps
        );
    
    cmp_lbc: tdc_lbc
        generic map(
            g_N     => g_RAW_COUNT,
            g_NIN   => g_CARRY4_COUNT*4
        )
        port map(
             clk_i        => clk_i,
             reset_i      => reset_i,
             d_i          => taps,
             polarity_o   => polarity,
             count_o      => raw
        );
    
    polarity_o <= polarity_d1;
    
    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                detect_o <= '0';
                polarity_d1 <= '1';
                raw_o <= (others => '0');
            else
                detect_o <= polarity xor polarity_d1;
                polarity_d1 <= polarity;
                raw_o <= raw;
            end if;
        end if;
    end process;

end architecture;
