-------------------------------------------------------------------------------
-- TDC Core / CERN
-------------------------------------------------------------------------------
--
-- unit name: tdc
--
-- author: Sebastien Bourdeauducq, sebastien@milkymist.org
--
-- description: Top level module
--
-- references: http://www.ohwr.org/projects/tdc-core
--
-------------------------------------------------------------------------------
-- last changes:
-- 2011-08-17 SB Created file
-------------------------------------------------------------------------------

-- Copyright (C) 2011 Sebastien Bourdeauducq

library ieee;
use ieee.std_logic_1164.all;

library work;
use work.tdc_package.all;

entity tdc is
    generic(
        -- Number of channels.
        g_CHANNEL_COUNT  : positive;
        -- Number of CARRY4 elements per channel.
        g_CARRY4_COUNT   : positive;
        -- Number of raw output bits.
        g_RAW_COUNT      : positive;
        -- Number of fractional part bits.
        g_FP_COUNT       : positive;
        -- Number of coarse counter bits.
        g_COARSE_COUNT   : positive;
        -- Length of each ring oscillator.
        g_RO_LENGTH      : positive;
        -- Frequency counter width.
        g_FCOUNTER_WIDTH : positive;
        -- Frequency counter timer width.
        g_FTIMER_WIDTH   : positive
    );
    port(
        clk_i       : in std_logic;
        reset_i     : in std_logic;
        ready_o     : out std_logic;
        
        -- Coarse counter control.
        cc_rst_i    : in std_logic;
        cc_cy_o     : out std_logic;
        
        -- Per-channel deskew inputs.
        deskew_i    : in std_logic_vector(g_CHANNEL_COUNT*(g_COARSE_COUNT+g_FP_COUNT)-1 downto 0);
        
        -- Per-channel signal inputs.
        signal_i    : in std_logic_vector(g_CHANNEL_COUNT-1 downto 0);
        calib_i     : in std_logic_vector(g_CHANNEL_COUNT-1 downto 0);
        
         -- Per-channel detection outputs.
        detect_o    : out std_logic_vector(g_CHANNEL_COUNT-1 downto 0);
        polarity_o  : out std_logic_vector(g_CHANNEL_COUNT-1 downto 0);
        raw_o       : out std_logic_vector(g_CHANNEL_COUNT*g_RAW_COUNT-1 downto 0);
        fp_o        : out std_logic_vector(g_CHANNEL_COUNT*(g_COARSE_COUNT+g_FP_COUNT)-1 downto 0);
        
        -- Debug interface.
        -- TODO
    );
end entity;

architecture rtl of tdc is
begin
end architecture;
