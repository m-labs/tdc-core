-------------------------------------------------------------------------------
-- TDC Core / CERN
-------------------------------------------------------------------------------
--
-- unit name: tdc_channelbank
--
-- author: Sebastien Bourdeauducq, sebastien@milkymist.org
--
-- description: Automatic channel bank
--
-- references: http://www.ohwr.org/projects/tdc-core
--
-------------------------------------------------------------------------------
-- last changes:
-- 2011-11-05 SB Added extra histogram bits support
-- 2011-10-25 SB Created file
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
-- This module instantiates the single- or multi-channel bank depending
-- on the g_CHANNEL_COUNT generic.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.tdc_package.all;

entity tdc_channelbank is
    generic(
        -- Number of channels.
        g_CHANNEL_COUNT  : positive;
        -- Number of CARRY4 elements per channel.
        g_CARRY4_COUNT   : positive;
        -- Number of raw output bits.
        g_RAW_COUNT      : positive;
        -- Number of fractional part bits.
        g_FP_COUNT       : positive;
        -- Number of extra histogram bits.
        g_EXHIS_COUNT    : positive;
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
         
        -- Control.
        cc_rst_i    : in std_logic;
        cc_cy_o     : out std_logic;
        next_i      : in std_logic;
        last_o      : out std_logic;
        calib_sel_i : in std_logic;
        
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
         
        -- LUT access.
        lut_a_i     : in std_logic_vector(g_RAW_COUNT-1 downto 0);
        lut_we_i    : in std_logic;
        lut_d_i     : in std_logic_vector(g_FP_COUNT-1 downto 0);
        lut_d_o     : out std_logic_vector(g_FP_COUNT-1 downto 0);
        
        -- Histogram.
        c_detect_o  : out std_logic;
        c_raw_o     : out std_logic_vector(g_RAW_COUNT-1 downto 0);
        his_a_i     : in std_logic_vector(g_RAW_COUNT-1 downto 0);
        his_we_i    : in std_logic;
        his_d_i     : in std_logic_vector(g_FP_COUNT+g_EXHIS_COUNT-1 downto 0);
        his_d_o     : out std_logic_vector(g_FP_COUNT+g_EXHIS_COUNT-1 downto 0);
        
        -- Online calibration.
        oc_start_i  : in std_logic;
        oc_ready_o  : out std_logic;
        oc_freq_o   : out std_logic_vector(g_FCOUNTER_WIDTH-1 downto 0);
        oc_store_i  : in std_logic;
        oc_sfreq_o  : out std_logic_vector(g_FCOUNTER_WIDTH-1 downto 0)
    );
end entity;

architecture rtl of tdc_channelbank is
begin
    g_single: if g_CHANNEL_COUNT = 1 generate
        cmp_channelbank: tdc_channelbank_single
            generic map(
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
                next_i       => next_i,
                last_o       => last_o,
                calib_sel_i  => calib_sel_i,
                
                deskew_i     => deskew_i,
                 
                signal_i     => signal_i(0),
                calib_i      => calib_i(0),
                 
                detect_o     => detect_o(0),
                polarity_o   => polarity_o(0),
                raw_o        => raw_o,
                fp_o         => fp_o,
                 
                lut_a_i      => lut_a_i,
                lut_we_i     => lut_we_i,
                lut_d_i      => lut_d_i,
                lut_d_o      => lut_d_o,
                
                c_detect_o   => c_detect_o,
                c_raw_o      => c_raw_o,
                his_a_i      => his_a_i,
                his_we_i     => his_we_i,
                his_d_i      => his_d_i,
                his_d_o      => his_d_o,

                oc_start_i   => oc_start_i,
                oc_ready_o   => oc_ready_o,
                oc_freq_o    => oc_freq_o,
                oc_store_i   => oc_store_i,
                oc_sfreq_o   => oc_sfreq_o
            );
    end generate;
    g_multi: if g_CHANNEL_COUNT > 1 generate
        cmp_channelbank: tdc_channelbank_multi
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
                next_i       => next_i,
                last_o       => last_o,
                calib_sel_i  => calib_sel_i,
                
                deskew_i     => deskew_i,
                 
                signal_i     => signal_i,
                calib_i      => calib_i,
                 
                detect_o     => detect_o,
                polarity_o   => polarity_o,
                raw_o        => raw_o,
                fp_o         => fp_o,
                 
                lut_a_i      => lut_a_i,
                lut_we_i     => lut_we_i,
                lut_d_i      => lut_d_i,
                lut_d_o      => lut_d_o,
                
                c_detect_o   => c_detect_o,
                c_raw_o      => c_raw_o,
                his_a_i      => his_a_i,
                his_we_i     => his_we_i,
                his_d_i      => his_d_i,
                his_d_o      => his_d_o,

                oc_start_i   => oc_start_i,
                oc_ready_o   => oc_ready_o,
                oc_freq_o    => oc_freq_o,
                oc_store_i   => oc_store_i,
                oc_sfreq_o   => oc_sfreq_o
            );
    end generate;
end architecture;
