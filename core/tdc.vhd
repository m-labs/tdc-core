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
-- 2011-11-05 SB Added extra histogram bits support
-- 2011-08-17 SB Created file
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
-- Top level module of the TDC core, contains all logic except the optional
-- host interface.

library ieee;
use ieee.std_logic_1164.all;

library work;
use work.tdc_package.all;

entity tdc is
    generic(
        -- Number of channels.
        g_CHANNEL_COUNT  : positive := 1;
        -- Number of CARRY4 elements per channel.
        g_CARRY4_COUNT   : positive := 124;
        -- Number of raw output bits.
        g_RAW_COUNT      : positive := 9;
        -- Number of fractional part bits.
        g_FP_COUNT       : positive := 13;
        -- Number of extra histogram bits.
        g_EXHIS_COUNT    : positive := 4;
        -- Number of coarse counter bits.
        g_COARSE_COUNT   : positive := 25;
        -- Length of each ring oscillator.
        g_RO_LENGTH      : positive := 31;
        -- Frequency counter width.
        g_FCOUNTER_WIDTH : positive := 13;
        -- Frequency counter timer width.
        g_FTIMER_WIDTH   : positive := 14
    );
    port(
        clk_i        : in std_logic;
        reset_i      : in std_logic;
        ready_o      : out std_logic;
        
        -- Coarse counter control.
        cc_rst_i     : in std_logic;
        cc_cy_o      : out std_logic;
        
        -- Per-channel deskew inputs.
        deskew_i     : in std_logic_vector(g_CHANNEL_COUNT*(g_COARSE_COUNT+g_FP_COUNT)-1 downto 0);
        
        -- Per-channel signal inputs.
        signal_i     : in std_logic_vector(g_CHANNEL_COUNT-1 downto 0);
        calib_i      : in std_logic_vector(g_CHANNEL_COUNT-1 downto 0);
        
         -- Per-channel detection outputs.
        detect_o     : out std_logic_vector(g_CHANNEL_COUNT-1 downto 0);
        polarity_o   : out std_logic_vector(g_CHANNEL_COUNT-1 downto 0);
        raw_o        : out std_logic_vector(g_CHANNEL_COUNT*g_RAW_COUNT-1 downto 0);
        fp_o         : out std_logic_vector(g_CHANNEL_COUNT*(g_COARSE_COUNT+g_FP_COUNT)-1 downto 0);
        
        -- Debug interface.
        freeze_req_i : in std_logic;
        freeze_ack_o : out std_logic;
        cs_next_i    : in std_logic;
        cs_last_o    : out std_logic;
        calib_sel_i  : in std_logic;
        lut_a_i      : in std_logic_vector(g_RAW_COUNT-1 downto 0);
        lut_d_o      : out std_logic_vector(g_FP_COUNT-1 downto 0);
        his_a_i      : in std_logic_vector(g_RAW_COUNT-1 downto 0);
        his_d_o      : out std_logic_vector(g_FP_COUNT+g_EXHIS_COUNT-1 downto 0);
        oc_start_i   : in std_logic;
        oc_ready_o   : out std_logic;
        oc_freq_o    : out std_logic_vector(g_FCOUNTER_WIDTH-1 downto 0);
        oc_sfreq_o   : out std_logic_vector(g_FCOUNTER_WIDTH-1 downto 0)
    );
end entity;

architecture rtl of tdc is
signal cs_next     : std_logic;
signal cs_next_c   : std_logic;
signal cs_last     : std_logic;
signal calib_sel   : std_logic;
signal calib_sel_c : std_logic;

signal lut_a       : std_logic_vector(g_RAW_COUNT-1 downto 0);
signal lut_a_c     : std_logic_vector(g_RAW_COUNT-1 downto 0);
signal lut_we      : std_logic;
signal lut_d_w     : std_logic_vector(g_FP_COUNT-1 downto 0);
signal lut_d_r     : std_logic_vector(g_FP_COUNT-1 downto 0);

signal c_detect    : std_logic;
signal c_raw       : std_logic_vector(g_RAW_COUNT-1 downto 0);
signal his_a       : std_logic_vector(g_RAW_COUNT-1 downto 0);
signal his_a_c     : std_logic_vector(g_RAW_COUNT-1 downto 0);
signal his_we      : std_logic;
signal his_d_w     : std_logic_vector(g_FP_COUNT+g_EXHIS_COUNT-1 downto 0);
signal his_d_r     : std_logic_vector(g_FP_COUNT+g_EXHIS_COUNT-1 downto 0);

signal oc_start    : std_logic;
signal oc_start_c  : std_logic;
signal oc_ready    : std_logic;
signal oc_freq     : std_logic_vector(g_FCOUNTER_WIDTH-1 downto 0);
signal oc_store    : std_logic;
signal oc_sfreq    : std_logic_vector(g_FCOUNTER_WIDTH-1 downto 0);

signal freeze_ack : std_logic;
begin
    cmp_channelbank: tdc_channelbank
        generic map(
            g_CHANNEL_COUNT  => g_CHANNEL_COUNT,
            g_CARRY4_COUNT   => g_CARRY4_COUNT,
            g_RAW_COUNT      => g_RAW_COUNT,
            g_FP_COUNT       => g_FP_COUNT,
            g_EXHIS_COUNT    => g_EXHIS_COUNT,
            g_COARSE_COUNT   => g_COARSE_COUNT,
            g_RO_LENGTH      => g_RO_LENGTH,
            g_FCOUNTER_WIDTH => g_FCOUNTER_WIDTH,
            g_FTIMER_WIDTH   => g_FTIMER_WIDTH
        )
        port map(
            clk_i        => clk_i,
            reset_i      => reset_i,
             
            cc_rst_i     => cc_rst_i,
            cc_cy_o      => cc_cy_o,
            next_i       => cs_next,
            last_o       => cs_last,
            calib_sel_i  => calib_sel,
            
            deskew_i     => deskew_i,
             
            signal_i     => signal_i,
            calib_i      => calib_i,
             
            detect_o     => detect_o,
            polarity_o   => polarity_o,
            raw_o        => raw_o,
            fp_o         => fp_o,
             
            lut_a_i      => lut_a,
            lut_we_i     => lut_we,
            lut_d_i      => lut_d_w,
            lut_d_o      => lut_d_r,
            
            c_detect_o   => c_detect,
            c_raw_o      => c_raw,
            his_a_i      => his_a,
            his_we_i     => his_we,
            his_d_i      => his_d_w,
            his_d_o      => his_d_r,

            oc_start_i   => oc_start,
            oc_ready_o   => oc_ready,
            oc_freq_o    => oc_freq,
            oc_store_i   => oc_store,
            oc_sfreq_o   => oc_sfreq
        );
    
    cmp_controller: tdc_controller
        generic map(
            g_RAW_COUNT      => g_RAW_COUNT,
            g_FP_COUNT       => g_FP_COUNT,
            g_EXHIS_COUNT    => g_EXHIS_COUNT,
            g_FCOUNTER_WIDTH => g_FCOUNTER_WIDTH
        )
        port map(
            clk_i       => clk_i,
            reset_i     => reset_i,
            ready_o     => ready_o,
            
            next_o      => cs_next_c,
            last_i      => cs_last,
            calib_sel_o => calib_sel_c,
            
            lut_a_o     => lut_a_c,
            lut_we_o    => lut_we,
            lut_d_o     => lut_d_w,
            
            c_detect_i  => c_detect,
            c_raw_i     => c_raw,
            his_a_o     => his_a_c,
            his_we_o    => his_we,
            his_d_o     => his_d_w,
            his_d_i     => his_d_r,

            oc_start_o  => oc_start_c,
            oc_ready_i  => oc_ready,
            oc_freq_i   => oc_freq,
            oc_store_o  => oc_store,
            oc_sfreq_i  => oc_sfreq,
            
            freeze_req_i => freeze_req_i,
            freeze_ack_o => freeze_ack
        );

    -- Debug interface signals.
    cs_next <= cs_next_i when (freeze_ack = '1') else cs_next_c;
    calib_sel <= calib_sel_i when (freeze_ack = '1') else calib_sel_c;
    lut_a <= lut_a_i when (freeze_ack = '1') else lut_a_c;
    his_a <= his_a_i when (freeze_ack = '1') else his_a_c;
    oc_start <= oc_start_i when (freeze_ack = '1') else oc_start_c;
    freeze_ack_o <= freeze_ack;
    cs_last_o <= cs_last;
    lut_d_o <= lut_d_r;
    his_d_o <= his_d_r;
    oc_ready_o <= oc_ready;
    oc_freq_o <= oc_freq;
    oc_sfreq_o <= oc_sfreq;
end architecture;
