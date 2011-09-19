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
-- This contains component declarations for all the modules of the TDC core.
-- It is used both internally to instantiate modules, and by the user to
-- instantiate the top-level "tdc" module.

library ieee;
use ieee.std_logic_1164.all;

package tdc_package is

component tdc is
    generic(
        g_CHANNEL_COUNT  : positive := 2;
        g_CARRY4_COUNT   : positive := 100;
        g_RAW_COUNT      : positive := 9;
        g_FP_COUNT       : positive := 13;
        g_COARSE_COUNT   : positive := 25;
        g_RO_LENGTH      : positive := 20;
        g_FCOUNTER_WIDTH : positive := 13;
        g_FTIMER_WIDTH   : positive := 10
    );
    port(
        clk_i        : in std_logic;
        reset_i      : in std_logic;
        ready_o      : out std_logic;
        
        cc_rst_i     : in std_logic;
        cc_cy_o      : out std_logic;
        
        deskew_i     : in std_logic_vector(g_CHANNEL_COUNT*(g_COARSE_COUNT+g_FP_COUNT)-1 downto 0);
        
        signal_i     : in std_logic_vector(g_CHANNEL_COUNT-1 downto 0);
        calib_i      : in std_logic_vector(g_CHANNEL_COUNT-1 downto 0);
        
        detect_o     : out std_logic_vector(g_CHANNEL_COUNT-1 downto 0);
        polarity_o   : out std_logic_vector(g_CHANNEL_COUNT-1 downto 0);
        raw_o        : out std_logic_vector(g_CHANNEL_COUNT*g_RAW_COUNT-1 downto 0);
        fp_o         : out std_logic_vector(g_CHANNEL_COUNT*(g_COARSE_COUNT+g_FP_COUNT)-1 downto 0);
        
        freeze_req_i : in std_logic;
        freeze_ack_o : out std_logic;
        cs_next_i    : in std_logic;
        cs_last_o    : out std_logic;
        calib_sel_i  : in std_logic;
        lut_a_i      : in std_logic_vector(g_RAW_COUNT-1 downto 0);
        lut_d_o      : out std_logic_vector(g_FP_COUNT-1 downto 0);
        his_a_i      : in std_logic_vector(g_RAW_COUNT-1 downto 0);
        his_d_o      : out std_logic_vector(g_FP_COUNT-1 downto 0);
        oc_start_i   : in std_logic;
        oc_ready_o   : out std_logic;
        oc_freq_o    : out std_logic_vector(g_FCOUNTER_WIDTH-1 downto 0);
        oc_sfreq_o   : out std_logic_vector(g_FCOUNTER_WIDTH-1 downto 0)
    );
end component;

component tdc_controller is
    generic(
        g_RAW_COUNT      : positive;
        g_FP_COUNT       : positive;
        g_FCOUNTER_WIDTH : positive
    );
    port(
        clk_i        : in std_logic;
        reset_i      : in std_logic;
        ready_o      : out std_logic;

        next_o       : out std_logic;
        last_i       : in std_logic;
        calib_sel_o  : out std_logic;
        
        lut_a_o      : out std_logic_vector(g_RAW_COUNT-1 downto 0);
        lut_we_o     : out std_logic;
        lut_d_o      : out std_logic_vector(g_FP_COUNT-1 downto 0);
        
        c_detect_i   : in std_logic;
        c_raw_i      : in std_logic_vector(g_RAW_COUNT-1 downto 0);
        his_a_o      : out std_logic_vector(g_RAW_COUNT-1 downto 0);
        his_we_o     : out std_logic;
        his_d_o      : out std_logic_vector(g_FP_COUNT-1 downto 0);
        his_d_i      : in std_logic_vector(g_FP_COUNT-1 downto 0);

        oc_start_o   : out std_logic;
        oc_ready_i   : in std_logic;
        oc_freq_i    : in std_logic_vector(g_FCOUNTER_WIDTH-1 downto 0);
        oc_store_o   : out std_logic;
        oc_sfreq_i   : in std_logic_vector(g_FCOUNTER_WIDTH-1 downto 0);
        
        freeze_req_i : in std_logic;
        freeze_ack_o : out std_logic
    );
end component;

component tdc_channelbank is
    generic(
        g_CHANNEL_COUNT  : positive;
        g_CARRY4_COUNT   : positive;
        g_RAW_COUNT      : positive;
        g_FP_COUNT       : positive;
        g_COARSE_COUNT   : positive;
        g_RO_LENGTH      : positive;
        g_FCOUNTER_WIDTH : positive;
        g_FTIMER_WIDTH   : positive
    );
    port(
        clk_i       : in std_logic;
        reset_i     : in std_logic;
         
        cc_rst_i    : in std_logic;
        cc_cy_o     : out std_logic;
        next_i      : in std_logic;
        last_o      : out std_logic;
        calib_sel_i : in std_logic;
        
        deskew_i    : in std_logic_vector(g_CHANNEL_COUNT*(g_COARSE_COUNT+g_FP_COUNT)-1 downto 0);
         
        signal_i    : in std_logic_vector(g_CHANNEL_COUNT-1 downto 0);
        calib_i     : in std_logic_vector(g_CHANNEL_COUNT-1 downto 0);
         
        detect_o    : out std_logic_vector(g_CHANNEL_COUNT-1 downto 0);
        polarity_o  : out std_logic_vector(g_CHANNEL_COUNT-1 downto 0);
        raw_o       : out std_logic_vector(g_CHANNEL_COUNT*g_RAW_COUNT-1 downto 0);
        fp_o        : out std_logic_vector(g_CHANNEL_COUNT*(g_COARSE_COUNT+g_FP_COUNT)-1 downto 0);
         
        lut_a_i     : in std_logic_vector(g_RAW_COUNT-1 downto 0);
        lut_we_i    : in std_logic;
        lut_d_i     : in std_logic_vector(g_FP_COUNT-1 downto 0);
        lut_d_o     : out std_logic_vector(g_FP_COUNT-1 downto 0);
        
        c_detect_o  : out std_logic;
        c_raw_o     : out std_logic_vector(g_RAW_COUNT-1 downto 0);
        his_a_i     : in std_logic_vector(g_RAW_COUNT-1 downto 0);
        his_we_i    : in std_logic;
        his_d_i     : in std_logic_vector(g_FP_COUNT-1 downto 0);
        his_d_o     : out std_logic_vector(g_FP_COUNT-1 downto 0);

        oc_start_i  : in std_logic;
        oc_ready_o  : out std_logic;
        oc_freq_o   : out std_logic_vector(g_FCOUNTER_WIDTH-1 downto 0);
        oc_store_i  : in std_logic;
        oc_sfreq_o  : out std_logic_vector(g_FCOUNTER_WIDTH-1 downto 0)
    );
end component;

component tdc_freqc is
    generic(
        g_COUNTER_WIDTH : positive;
        g_TIMER_WIDTH   : positive
    );
    port(
        clk_i   : in std_logic;
        reset_i : in std_logic;
        
        clk_m_i : in std_logic;
        start_i : in std_logic;
        ready_o : out std_logic;
        freq_o  : out std_logic_vector(g_COUNTER_WIDTH-1 downto 0)
    );
end component;

component tdc_channel is
    generic(
        g_CARRY4_COUNT : positive;
        g_RAW_COUNT    : positive;
        g_FP_COUNT     : positive;
        g_COARSE_COUNT : positive;
        g_RO_LENGTH    : positive
    );
    port(
        clk_i       : in std_logic;
        reset_i     : in std_logic;

        coarse_i    : in std_logic_vector(g_COARSE_COUNT-1 downto 0);
        deskew_i    : in std_logic_vector((g_COARSE_COUNT+g_FP_COUNT)-1 downto 0);

        signal_i    : in std_logic;
        calib_i     : in std_logic;
        calib_sel_i : in std_logic;

        detect_o    : out std_logic;
        polarity_o  : out std_logic;
        raw_o       : out std_logic_vector(g_RAW_COUNT-1 downto 0);
        fp_o        : out std_logic_vector((g_COARSE_COUNT+g_FP_COUNT)-1 downto 0);

        lut_a_i     : in std_logic_vector(g_RAW_COUNT-1 downto 0);
        lut_we_i    : in std_logic;
        lut_d_i     : in std_logic_vector(g_FP_COUNT-1 downto 0);
        lut_d_o     : out std_logic_vector(g_FP_COUNT-1 downto 0);

        ro_en_i     : in std_logic;
        ro_clk_o    : out std_logic
    );
end component;

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

component tdc_divider is
    generic(
        g_WIDTH: positive
    );
    port(
        clk_i       : in std_logic;
        reset_i     : in std_logic;
        
        start_i     : in std_logic;
        dividend_i  : in std_logic_vector(g_WIDTH-1 downto 0);
        divisor_i   : in std_logic_vector(g_WIDTH-1 downto 0);
        
        ready_o     : out std_logic;
        quotient_o  : out std_logic_vector(g_WIDTH-1 downto 0);
        remainder_o : out std_logic_vector(g_WIDTH-1 downto 0)
    );
end component;

component tdc_psync is
    port(
        clk_src_i : in std_logic;
        p_i       : in std_logic;
        
        clk_dst_i : in std_logic;
        p_o       : out std_logic
    );
end component;

end package;
