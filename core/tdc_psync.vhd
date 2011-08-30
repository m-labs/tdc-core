-------------------------------------------------------------------------------
-- TDC Core / CERN
-------------------------------------------------------------------------------
--
-- unit name: tdc_psync
--
-- author: Sebastien Bourdeauducq, sebastien@milkymist.org
--
-- description: Pulse synchronizer
--
-- references: http://www.ohwr.org/projects/tdc-core
--
-------------------------------------------------------------------------------
-- last changes:
-- 2011-08-14 SB Created file
-------------------------------------------------------------------------------

-- Copyright (C) 2011 Sebastien Bourdeauducq

-- DESCRIPTION:
-- Converts a single clock cycle pulse in the clk_src_i domain into a single
-- clock cycle pulse in the clk_dst_i domain.
-- It does so by converting the pulse into a level change, synchronizing
-- this level change into the destination domain by double latching, and
-- finally restoring the pulse in the destination domain.

library ieee;
use ieee.std_logic_1164.all;

library work;
use work.tdc_package.all;

entity tdc_psync is
    port(
        clk_src_i : in std_logic;
        p_i       : in std_logic;
        
        clk_dst_i : in std_logic;
        p_o       : out std_logic
    );
end entity;

architecture rtl of tdc_psync is
-- Initialize registers at FPGA configuration.
signal level    : std_logic := '0';
signal level_d1 : std_logic := '0';
signal level_d2 : std_logic := '0';
signal level_d3 : std_logic := '0';
-- Prevent inference of a SRL* primitive, which does not
-- have good metastability resistance.
attribute keep: string;
attribute keep of level_d1: signal is "true";
attribute keep of level_d2: signal is "true";
attribute keep of level_d3: signal is "true";
begin
    -- Convert incoming pulses into level flips.
    process(clk_src_i)
    begin
        if rising_edge(clk_src_i) then
            if p_i = '1' then
                level <= not level;
            end if;
        end if;
    end process;
    
    -- Synchronize level to clk_dst domain and register.
    process(clk_dst_i)
    begin
        if rising_edge(clk_dst_i) then
            level_d1 <= level;
            level_d2 <= level_d1;
            level_d3 <= level_d2;
        end if;
    end process;
    
    -- Convert level flips back into pulses synchronous to clk_dst domain.
    p_o <= level_d2 xor level_d3;
end architecture;
