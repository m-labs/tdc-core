-------------------------------------------------------------------------------
-- TDC Core / CERN
-------------------------------------------------------------------------------
--
-- unit name: tdc_hostif
--
-- author: Sebastien Bourdeauducq, sebastien@milkymist.org
--
-- description: Host interface for the TDC core
--
-- references: http://www.ohwr.org/projects/tdc-core
--
-------------------------------------------------------------------------------
-- last changes:
-- 2011-08-27 SB Reduced supported channel count to 8
-- 2011-08-26 SB Created file
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
-- Top level module of the TDC core, contains all logic including the optional
-- host interface. It instantiates the basic TDC core and a Wishbone interface.

library ieee;
use ieee.std_logic_1164.all;

library work;
use work.tdc_package.all;
use work.tdc_hostif_package.all;

entity tdc_hostif is
    generic(
        g_CHANNEL_COUNT  : positive := 2;
        g_CARRY4_COUNT   : positive := 100;
        g_RAW_COUNT      : positive := 9;
        g_FP_COUNT       : positive := 13;
        g_COARSE_COUNT   : positive := 25;
        g_RO_LENGTH      : positive := 31;
        g_FCOUNTER_WIDTH : positive := 13;
        g_FTIMER_WIDTH   : positive := 10
    );
    port(
        rst_n_i   : in std_logic;
        wb_clk_i  : in std_logic;
        
        wb_addr_i : in std_logic_vector(5 downto 0);
        wb_data_i : in std_logic_vector(31 downto 0);
        wb_data_o : out std_logic_vector(31 downto 0);
        wb_cyc_i  : in std_logic;
        wb_sel_i  : in std_logic_vector(3 downto 0);
        wb_stb_i  : in std_logic;
        wb_we_i   : in std_logic;
        wb_ack_o  : out std_logic;
        wb_irq_o  : out std_logic;
        
        cc_rst_i  : in std_logic;
        cc_cy_o   : out std_logic;
        signal_i  : in std_logic_vector(g_CHANNEL_COUNT-1 downto 0);
        calib_i   : in std_logic_vector(g_CHANNEL_COUNT-1 downto 0)
    );
end entity;

architecture rtl of tdc_hostif is
signal reset      : std_logic;
signal ready      : std_logic;
signal cc_cy      : std_logic;
signal deskew     : std_logic_vector(g_CHANNEL_COUNT*(g_COARSE_COUNT+g_FP_COUNT)-1 downto 0);
signal detect     : std_logic_vector(g_CHANNEL_COUNT-1 downto 0);
signal polarity   : std_logic_vector(g_CHANNEL_COUNT-1 downto 0);
signal raw        : std_logic_vector(g_CHANNEL_COUNT*g_RAW_COUNT-1 downto 0);
signal fp         : std_logic_vector(g_CHANNEL_COUNT*(g_COARSE_COUNT+g_FP_COUNT)-1 downto 0);
signal freeze_req : std_logic;
signal freeze_ack : std_logic;
signal cs_next    : std_logic;
signal cs_last    : std_logic;
signal calib_sel  : std_logic;
signal lut_a      : std_logic_vector(g_RAW_COUNT-1 downto 0);
signal lut_d      : std_logic_vector(g_FP_COUNT-1 downto 0);
signal his_a      : std_logic_vector(g_RAW_COUNT-1 downto 0);
signal his_d      : std_logic_vector(g_FP_COUNT-1 downto 0);
signal oc_start   : std_logic;
signal oc_ready   : std_logic;
signal oc_freq    : std_logic_vector(g_FCOUNTER_WIDTH-1 downto 0);
signal oc_sfreq   : std_logic_vector(g_FCOUNTER_WIDTH-1 downto 0);

signal wbg_luta : std_logic_vector(15 downto 0);
signal wbg_lutd : std_logic_vector(31 downto 0);
signal wbg_hisa : std_logic_vector(15 downto 0);
signal wbg_hisd : std_logic_vector(31 downto 0);
signal wbg_fcr  : std_logic_vector(31 downto 0);
signal wbg_fcsr : std_logic_vector(31 downto 0);

-- maximum number of channels the host interface can support
constant c_NCHAN: positive := 8;

signal wbg_des    : std_logic_vector(c_NCHAN*64-1 downto 0);
signal wbg_pol    : std_logic_vector(c_NCHAN-1 downto 0);
signal wbg_raw    : std_logic_vector(c_NCHAN*32-1 downto 0);
signal wbg_mes    : std_logic_vector(c_NCHAN*64-1 downto 0);
signal wbg_ie     : std_logic_vector(c_NCHAN-1 downto 0);
begin
    cmp_tdc: tdc
        generic map(
            g_CHANNEL_COUNT  => g_CHANNEL_COUNT,
            g_CARRY4_COUNT   => g_CARRY4_COUNT,
            g_RAW_COUNT      => g_RAW_COUNT,
            g_FP_COUNT       => g_FP_COUNT,
            g_COARSE_COUNT   => g_COARSE_COUNT,
            g_RO_LENGTH      => g_RO_LENGTH,
            g_FCOUNTER_WIDTH => g_FCOUNTER_WIDTH,
            g_FTIMER_WIDTH   => g_FTIMER_WIDTH
        )
        port map(
            clk_i        => wb_clk_i,
            reset_i      => reset,
            ready_o      => ready,
            cc_rst_i     => cc_rst_i,
            cc_cy_o      => cc_cy,
            deskew_i     => deskew,
            signal_i     => signal_i,
            calib_i      => calib_i,
            detect_o     => detect,
            polarity_o   => polarity,
            raw_o        => raw,
            fp_o         => fp,
            freeze_req_i => freeze_req,
            freeze_ack_o => freeze_ack,
            cs_next_i    => cs_next,
            cs_last_o    => cs_last,
            calib_sel_i  => calib_sel,
            lut_a_i      => lut_a,
            lut_d_o      => lut_d,
            his_a_i      => his_a,
            his_d_o      => his_d,
            oc_start_i   => oc_start,
            oc_ready_o   => oc_ready,
            oc_freq_o    => oc_freq,
            oc_sfreq_o   => oc_sfreq
        );
    cc_cy_o <= cc_cy;
    
    cmp_wb: tdc_wb
        port map(
            rst_n_i   => rst_n_i,
            wb_clk_i  => wb_clk_i,
            wb_addr_i => wb_addr_i,
            wb_data_i => wb_data_i,
            wb_data_o => wb_data_o,
            wb_cyc_i  => wb_cyc_i,
            wb_sel_i  => wb_sel_i,
            wb_stb_i  => wb_stb_i,
            wb_we_i   => wb_we_i,
            wb_ack_o  => wb_ack_o,
            wb_irq_o  => wb_irq_o,
            
            tdc_cs_rst_o    => reset,
            tdc_cs_rdy_i    => ready,
            irq_isc_i       => ready,
            irq_icc_i       => cc_cy,
            tdc_dctl_req_o  => freeze_req,
            tdc_dctl_ack_i  => freeze_ack,
            tdc_csel_next_o => cs_next,
            tdc_csel_last_i => cs_last,
            tdc_cal_o       => calib_sel,
            tdc_fcc_st_o    => oc_start,
            tdc_fcc_rdy_i   => oc_ready,
            
            tdc_luta_o      => wbg_luta,
            tdc_lutd_i      => wbg_lutd,
            tdc_hisa_o      => wbg_hisa,
            tdc_hisd_i      => wbg_hisd,
            tdc_fcr_i       => wbg_fcr,
            tdc_fcsr_i      => wbg_fcsr,
            
            tdc_pol_i       => wbg_pol,
            
            -- begin autogenerated connections
            tdc_desh0_o => wbg_des(63 downto 32),
            tdc_desl0_o => wbg_des(31 downto 0),
            tdc_desh1_o => wbg_des(127 downto 96),
            tdc_desl1_o => wbg_des(95 downto 64),
            tdc_desh2_o => wbg_des(191 downto 160),
            tdc_desl2_o => wbg_des(159 downto 128),
            tdc_desh3_o => wbg_des(255 downto 224),
            tdc_desl3_o => wbg_des(223 downto 192),
            tdc_desh4_o => wbg_des(319 downto 288),
            tdc_desl4_o => wbg_des(287 downto 256),
            tdc_desh5_o => wbg_des(383 downto 352),
            tdc_desl5_o => wbg_des(351 downto 320),
            tdc_desh6_o => wbg_des(447 downto 416),
            tdc_desl6_o => wbg_des(415 downto 384),
            tdc_desh7_o => wbg_des(511 downto 480),
            tdc_desl7_o => wbg_des(479 downto 448),
            tdc_raw0_i => wbg_raw(31 downto 0),
            tdc_mesh0_i => wbg_mes(63 downto 32),
            tdc_mesl0_i => wbg_mes(31 downto 0),
            tdc_raw1_i => wbg_raw(63 downto 32),
            tdc_mesh1_i => wbg_mes(127 downto 96),
            tdc_mesl1_i => wbg_mes(95 downto 64),
            tdc_raw2_i => wbg_raw(95 downto 64),
            tdc_mesh2_i => wbg_mes(191 downto 160),
            tdc_mesl2_i => wbg_mes(159 downto 128),
            tdc_raw3_i => wbg_raw(127 downto 96),
            tdc_mesh3_i => wbg_mes(255 downto 224),
            tdc_mesl3_i => wbg_mes(223 downto 192),
            tdc_raw4_i => wbg_raw(159 downto 128),
            tdc_mesh4_i => wbg_mes(319 downto 288),
            tdc_mesl4_i => wbg_mes(287 downto 256),
            tdc_raw5_i => wbg_raw(191 downto 160),
            tdc_mesh5_i => wbg_mes(383 downto 352),
            tdc_mesl5_i => wbg_mes(351 downto 320),
            tdc_raw6_i => wbg_raw(223 downto 192),
            tdc_mesh6_i => wbg_mes(447 downto 416),
            tdc_mesl6_i => wbg_mes(415 downto 384),
            tdc_raw7_i => wbg_raw(255 downto 224),
            tdc_mesh7_i => wbg_mes(511 downto 480),
            tdc_mesl7_i => wbg_mes(479 downto 448),
            irq_ie0_i => wbg_ie(0),
            irq_ie1_i => wbg_ie(1),
            irq_ie2_i => wbg_ie(2),
            irq_ie3_i => wbg_ie(3),
            irq_ie4_i => wbg_ie(4),
            irq_ie5_i => wbg_ie(5),
            irq_ie6_i => wbg_ie(6),
            irq_ie7_i => wbg_ie(7)
            -- end autogenerated connections
        );
    
    -- All synthesizers I know of will set unconnected bits to 0.
    lut_a <= wbg_luta(g_RAW_COUNT-1 downto 0);
    wbg_lutd(lut_d'range) <= lut_d;
    his_a <= wbg_hisa(g_RAW_COUNT-1 downto 0);
    wbg_hisd(his_d'range) <= his_d;
    wbg_fcr(oc_freq'range) <= oc_freq;
    wbg_fcsr(oc_sfreq'range) <= oc_sfreq;
    
    g_connect: for i in 0 to g_CHANNEL_COUNT-1 generate
        deskew((i+1)*(g_COARSE_COUNT+g_FP_COUNT)-1 downto i*(g_COARSE_COUNT+g_FP_COUNT))
            <= wbg_des(i*64+g_COARSE_COUNT+g_FP_COUNT-1 downto i*64);
        wbg_raw(i*32+g_RAW_COUNT-1 downto i*32)
            <= raw((i+1)*g_RAW_COUNT-1 downto i*g_RAW_COUNT);
        wbg_mes(i*64+g_COARSE_COUNT+g_FP_COUNT-1 downto i*64)
            <= fp((i+1)*(g_COARSE_COUNT+g_FP_COUNT)-1 downto i*(g_COARSE_COUNT+g_FP_COUNT));
    end generate;
    wbg_pol(polarity'range) <= polarity;
    wbg_ie(detect'range) <= detect;

end architecture;
