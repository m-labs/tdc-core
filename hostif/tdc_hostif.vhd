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
-- 2011-08-26 SB Created file
-------------------------------------------------------------------------------

-- Copyright (C) 2011 Sebastien Bourdeauducq

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
        g_RO_LENGTH      : positive := 20;
        g_FCOUNTER_WIDTH : positive := 13;
        g_FTIMER_WIDTH   : positive := 10
    );
    port(
        rst_n_i   : in std_logic;
        wb_clk_i  : in std_logic;
        
        wb_addr_i : in std_logic_vector(7 downto 0);
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
constant c_NCHAN: positive := 30;

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
            tdc_desh8_o => wbg_des(575 downto 544),
            tdc_desl8_o => wbg_des(543 downto 512),
            tdc_desh9_o => wbg_des(639 downto 608),
            tdc_desl9_o => wbg_des(607 downto 576),
            tdc_desh10_o => wbg_des(703 downto 672),
            tdc_desl10_o => wbg_des(671 downto 640),
            tdc_desh11_o => wbg_des(767 downto 736),
            tdc_desl11_o => wbg_des(735 downto 704),
            tdc_desh12_o => wbg_des(831 downto 800),
            tdc_desl12_o => wbg_des(799 downto 768),
            tdc_desh13_o => wbg_des(895 downto 864),
            tdc_desl13_o => wbg_des(863 downto 832),
            tdc_desh14_o => wbg_des(959 downto 928),
            tdc_desl14_o => wbg_des(927 downto 896),
            tdc_desh15_o => wbg_des(1023 downto 992),
            tdc_desl15_o => wbg_des(991 downto 960),
            tdc_desh16_o => wbg_des(1087 downto 1056),
            tdc_desl16_o => wbg_des(1055 downto 1024),
            tdc_desh17_o => wbg_des(1151 downto 1120),
            tdc_desl17_o => wbg_des(1119 downto 1088),
            tdc_desh18_o => wbg_des(1215 downto 1184),
            tdc_desl18_o => wbg_des(1183 downto 1152),
            tdc_desh19_o => wbg_des(1279 downto 1248),
            tdc_desl19_o => wbg_des(1247 downto 1216),
            tdc_desh20_o => wbg_des(1343 downto 1312),
            tdc_desl20_o => wbg_des(1311 downto 1280),
            tdc_desh21_o => wbg_des(1407 downto 1376),
            tdc_desl21_o => wbg_des(1375 downto 1344),
            tdc_desh22_o => wbg_des(1471 downto 1440),
            tdc_desl22_o => wbg_des(1439 downto 1408),
            tdc_desh23_o => wbg_des(1535 downto 1504),
            tdc_desl23_o => wbg_des(1503 downto 1472),
            tdc_desh24_o => wbg_des(1599 downto 1568),
            tdc_desl24_o => wbg_des(1567 downto 1536),
            tdc_desh25_o => wbg_des(1663 downto 1632),
            tdc_desl25_o => wbg_des(1631 downto 1600),
            tdc_desh26_o => wbg_des(1727 downto 1696),
            tdc_desl26_o => wbg_des(1695 downto 1664),
            tdc_desh27_o => wbg_des(1791 downto 1760),
            tdc_desl27_o => wbg_des(1759 downto 1728),
            tdc_desh28_o => wbg_des(1855 downto 1824),
            tdc_desl28_o => wbg_des(1823 downto 1792),
            tdc_desh29_o => wbg_des(1919 downto 1888),
            tdc_desl29_o => wbg_des(1887 downto 1856),
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
            tdc_raw8_i => wbg_raw(287 downto 256),
            tdc_mesh8_i => wbg_mes(575 downto 544),
            tdc_mesl8_i => wbg_mes(543 downto 512),
            tdc_raw9_i => wbg_raw(319 downto 288),
            tdc_mesh9_i => wbg_mes(639 downto 608),
            tdc_mesl9_i => wbg_mes(607 downto 576),
            tdc_raw10_i => wbg_raw(351 downto 320),
            tdc_mesh10_i => wbg_mes(703 downto 672),
            tdc_mesl10_i => wbg_mes(671 downto 640),
            tdc_raw11_i => wbg_raw(383 downto 352),
            tdc_mesh11_i => wbg_mes(767 downto 736),
            tdc_mesl11_i => wbg_mes(735 downto 704),
            tdc_raw12_i => wbg_raw(415 downto 384),
            tdc_mesh12_i => wbg_mes(831 downto 800),
            tdc_mesl12_i => wbg_mes(799 downto 768),
            tdc_raw13_i => wbg_raw(447 downto 416),
            tdc_mesh13_i => wbg_mes(895 downto 864),
            tdc_mesl13_i => wbg_mes(863 downto 832),
            tdc_raw14_i => wbg_raw(479 downto 448),
            tdc_mesh14_i => wbg_mes(959 downto 928),
            tdc_mesl14_i => wbg_mes(927 downto 896),
            tdc_raw15_i => wbg_raw(511 downto 480),
            tdc_mesh15_i => wbg_mes(1023 downto 992),
            tdc_mesl15_i => wbg_mes(991 downto 960),
            tdc_raw16_i => wbg_raw(543 downto 512),
            tdc_mesh16_i => wbg_mes(1087 downto 1056),
            tdc_mesl16_i => wbg_mes(1055 downto 1024),
            tdc_raw17_i => wbg_raw(575 downto 544),
            tdc_mesh17_i => wbg_mes(1151 downto 1120),
            tdc_mesl17_i => wbg_mes(1119 downto 1088),
            tdc_raw18_i => wbg_raw(607 downto 576),
            tdc_mesh18_i => wbg_mes(1215 downto 1184),
            tdc_mesl18_i => wbg_mes(1183 downto 1152),
            tdc_raw19_i => wbg_raw(639 downto 608),
            tdc_mesh19_i => wbg_mes(1279 downto 1248),
            tdc_mesl19_i => wbg_mes(1247 downto 1216),
            tdc_raw20_i => wbg_raw(671 downto 640),
            tdc_mesh20_i => wbg_mes(1343 downto 1312),
            tdc_mesl20_i => wbg_mes(1311 downto 1280),
            tdc_raw21_i => wbg_raw(703 downto 672),
            tdc_mesh21_i => wbg_mes(1407 downto 1376),
            tdc_mesl21_i => wbg_mes(1375 downto 1344),
            tdc_raw22_i => wbg_raw(735 downto 704),
            tdc_mesh22_i => wbg_mes(1471 downto 1440),
            tdc_mesl22_i => wbg_mes(1439 downto 1408),
            tdc_raw23_i => wbg_raw(767 downto 736),
            tdc_mesh23_i => wbg_mes(1535 downto 1504),
            tdc_mesl23_i => wbg_mes(1503 downto 1472),
            tdc_raw24_i => wbg_raw(799 downto 768),
            tdc_mesh24_i => wbg_mes(1599 downto 1568),
            tdc_mesl24_i => wbg_mes(1567 downto 1536),
            tdc_raw25_i => wbg_raw(831 downto 800),
            tdc_mesh25_i => wbg_mes(1663 downto 1632),
            tdc_mesl25_i => wbg_mes(1631 downto 1600),
            tdc_raw26_i => wbg_raw(863 downto 832),
            tdc_mesh26_i => wbg_mes(1727 downto 1696),
            tdc_mesl26_i => wbg_mes(1695 downto 1664),
            tdc_raw27_i => wbg_raw(895 downto 864),
            tdc_mesh27_i => wbg_mes(1791 downto 1760),
            tdc_mesl27_i => wbg_mes(1759 downto 1728),
            tdc_raw28_i => wbg_raw(927 downto 896),
            tdc_mesh28_i => wbg_mes(1855 downto 1824),
            tdc_mesl28_i => wbg_mes(1823 downto 1792),
            tdc_raw29_i => wbg_raw(959 downto 928),
            tdc_mesh29_i => wbg_mes(1919 downto 1888),
            tdc_mesl29_i => wbg_mes(1887 downto 1856),
            irq_ie0_i => wbg_ie(0),
            irq_ie1_i => wbg_ie(1),
            irq_ie2_i => wbg_ie(2),
            irq_ie3_i => wbg_ie(3),
            irq_ie4_i => wbg_ie(4),
            irq_ie5_i => wbg_ie(5),
            irq_ie6_i => wbg_ie(6),
            irq_ie7_i => wbg_ie(7),
            irq_ie8_i => wbg_ie(8),
            irq_ie9_i => wbg_ie(9),
            irq_ie10_i => wbg_ie(10),
            irq_ie11_i => wbg_ie(11),
            irq_ie12_i => wbg_ie(12),
            irq_ie13_i => wbg_ie(13),
            irq_ie14_i => wbg_ie(14),
            irq_ie15_i => wbg_ie(15),
            irq_ie16_i => wbg_ie(16),
            irq_ie17_i => wbg_ie(17),
            irq_ie18_i => wbg_ie(18),
            irq_ie19_i => wbg_ie(19),
            irq_ie20_i => wbg_ie(20),
            irq_ie21_i => wbg_ie(21),
            irq_ie22_i => wbg_ie(22),
            irq_ie23_i => wbg_ie(23),
            irq_ie24_i => wbg_ie(24),
            irq_ie25_i => wbg_ie(25),
            irq_ie26_i => wbg_ie(26),
            irq_ie27_i => wbg_ie(27),
            irq_ie28_i => wbg_ie(28),
            irq_ie29_i => wbg_ie(29)
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
