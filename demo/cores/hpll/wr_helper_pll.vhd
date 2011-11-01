-------------------------------------------------------------------------------
-- Project    : Helper PLL for generation of DMTD offset clock
-------------------------------------------------------------------------------
-- File       : wr_helper_pll.vhd
-- Author     : Javier Serrano, Tomasz Wlostowski
-- Institute  : CERN
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: This is a generic PLL that assumes a DAC and VCO outside the
-- FPGA. The reset is assumed to be synchronized with the system clock outside
-- this block. The block receives a reference clock of frequency f and derives
-- from it a clock of frequency f*(num/den) where num and den are two 16-bit
-- unsigned numbers. The PI loop filter has controllable proportional and
-- integral gains which are also 16-bit unsigned. The output to the DAC is a
-- 16-bit signed number.
-------------------------------------------------------------------------------
-- Revisions:
-- Date                 Version  Author         Description
-- 4 April 2010         1.0      J.Serrano      Created
-- 15 June 2010         1.1      twlostow       redesigned....
-- 12 Jan 2011          1.2      twlostow       added generic configuration options
-------------------------------------------------------------------------------

library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.platform_specific.all;
use work.common_components.all;

entity wr_helper_pll is
  generic (
    g_num_ref_inputs            : integer := 1;
    g_with_wishbone             : integer := 1;
    g_dacval_bits               : integer := 16;
    g_output_bias               : integer := 32767;
    g_div_ref                   : integer := 0;
    g_div_fb                    : integer := 0;
    g_kp_freq                   : integer := 0;
    g_ki_freq                   : integer := 0;
    g_kp_phase                  : integer := 0;
    g_ki_phase                  : integer := 0;
    g_ld_threshold              : integer := 0;
    g_ld_samples                : integer := 0;
    g_fd_gating                 : integer := 0;
    g_pd_gating                 : integer := 0;
    g_ferr_setpoint             : integer := 0
    );

  port (
    rst_n_i : in std_logic;             -- Synchronous reset

    cfg_enable_i       : in std_logic;
    cfg_force_freq_i   : in std_logic;
    cfg_clear_status_i : in std_logic;
    cfg_refsel_i       : in std_logic_vector(1 downto 0);

    stat_flock_o     : out std_logic;
    stat_plock_o     : out std_logic;
    stat_lock_lost_o : out std_logic;

    clk_ref_i  : in std_logic_vector(g_num_ref_inputs-1 downto 0);
    clk_sys_i  : in std_logic;          -- System clock
    clk_fbck_i : in std_logic;          -- Fed-back clock

    dac_data_o    : out std_logic_vector(g_dacval_bits-1 downto 0);
    dac_load_p1_o : out std_logic;

    auxout1_o : out std_logic;
    auxout2_o : out std_logic;
    auxout3_o : out std_logic;

    wb_addr_i : in  std_logic_vector(3 downto 0);
    wb_data_i : in  std_logic_vector(31 downto 0);
    wb_data_o : out std_logic_vector(31 downto 0);
    wb_cyc_i  : in  std_logic;
    wb_sel_i  : in  std_logic_vector(3 downto 0);
    wb_stb_i  : in  std_logic;
    wb_we_i   : in  std_logic;
    wb_ack_o  : out std_logic

    );

end wr_helper_pll;

architecture rtl of wr_helper_pll is

  component hpll_wb_slave
    port (
      rst_n_i                   : in  std_logic;
      wb_clk_i                  : in  std_logic;
      wb_addr_i                 : in  std_logic_vector(3 downto 0);
      wb_data_i                 : in  std_logic_vector(31 downto 0);
      wb_data_o                 : out std_logic_vector(31 downto 0);
      wb_cyc_i                  : in  std_logic;
      wb_sel_i                  : in  std_logic_vector(3 downto 0);
      wb_stb_i                  : in  std_logic;
      wb_we_i                   : in  std_logic;
      wb_ack_o                  : out std_logic;
      hpll_pcr_enable_o         : out std_logic;
      hpll_pcr_force_f_o        : out std_logic;
      hpll_pcr_dac_clksel_o     : out std_logic_vector(2 downto 0);
      hpll_pcr_pd_gate_o        : out std_logic_vector(2 downto 0);
      hpll_pcr_swrst_o          : out std_logic;
      hpll_pcr_refsel_o         : out std_logic_vector(1 downto 0);
      hpll_divr_div_ref_o       : out std_logic_vector(15 downto 0);
      hpll_divr_div_fb_o        : out std_logic_vector(15 downto 0);
      hpll_fbgr_f_kp_o          : out std_logic_vector(15 downto 0);
      hpll_fbgr_f_ki_o          : out std_logic_vector(15 downto 0);
      hpll_pbgr_p_kp_o          : out std_logic_vector(15 downto 0);
      hpll_pbgr_p_ki_o          : out std_logic_vector(15 downto 0);
      hpll_ldcr_ld_thr_o        : out std_logic_vector(7 downto 0);
      hpll_ldcr_ld_samp_o       : out std_logic_vector(7 downto 0);
      hpll_fbcr_fd_gate_o       : out std_logic_vector(2 downto 0);
      hpll_fbcr_ferr_set_o      : out std_logic_vector(11 downto 0);
      hpll_psr_freq_lk_i        : in  std_logic;
      hpll_psr_phase_lk_i       : in  std_logic;
      hpll_psr_lock_lost_o      : out std_logic;
      hpll_psr_lock_lost_i      : in  std_logic;
      hpll_psr_lock_lost_load_o : out std_logic;
      hpll_rfifo_wr_req_i       : in  std_logic;
      hpll_rfifo_wr_full_o      : out std_logic;
      hpll_rfifo_fp_mode_i      : in  std_logic;
      hpll_rfifo_err_val_i      : in  std_logic_vector(11 downto 0);
      hpll_rfifo_dac_val_i      : in  std_logic_vector(15 downto 0));
  end component;

  component hpll_period_detect
    port (
      clk_ref_i            : in  std_logic;
      clk_fbck_i           : in  std_logic;
      clk_sys_i            : in  std_logic;
      rst_n_refclk_i       : in  std_logic;
      rst_n_fbck_i         : in  std_logic;
      rst_n_sysclk_i       : in  std_logic;
      freq_err_o           : out std_logic_vector(11 downto 0);
      freq_err_stb_p_o     : out std_logic;
      hpll_fbcr_fd_gate_i  : in  std_logic_vector(2 downto 0);
      hpll_fbcr_ferr_set_i : in  std_logic_vector(11 downto 0));
  end component;

  component hpll_bangbang_pd
    port (
      clk_ref_i           : in  std_logic;
      clk_fbck_i          : in  std_logic;
      clk_sys_i           : in  std_logic;
      rst_n_refclk_i      : in  std_logic;
      rst_n_fbck_i        : in  std_logic;
      rst_n_sysclk_i      : in  std_logic;
      sync_dividers_p_i   : in  std_logic;
      phase_err_o         : out std_logic_vector(11 downto 0);
      phase_err_stb_p_o   : out std_logic;
      hpll_pcr_pd_gate_i  : in  std_logic_vector(2 downto 0);
      hpll_divr_div_ref_i : in  std_logic_vector(15 downto 0);
      hpll_divr_div_fb_i  : in  std_logic_vector(15 downto 0);
      dbg_ref_divided_o   : out std_logic;
      dbg_fbck_divided_o  : out std_logic;
      dbg_pd_up_o         : out std_logic;
      dbg_pd_down_o       : out std_logic);
  end component;

  component hpll_controller
    generic (
      g_error_bits          : integer;
      g_dacval_bits         : integer;
      g_output_bias         : integer;
      g_integrator_fracbits : integer;
      g_integrator_overbits : integer;
      g_coef_bits           : integer);
    port (
      clk_sys_i                 : in  std_logic;
      rst_n_sysclk_i            : in  std_logic;
      phase_err_i               : in  std_logic_vector(g_error_bits-1 downto 0);
      phase_err_stb_p_i         : in  std_logic;
      freq_err_i                : in  std_logic_vector(g_error_bits-1 downto 0);
      freq_err_stb_p_i          : in  std_logic;
      dac_val_o                 : out std_logic_vector(g_dacval_bits-1 downto 0);
      dac_val_stb_p_o           : out std_logic;
      sync_dividers_p_o         : out std_logic;
      hpll_pcr_enable_i         : in  std_logic;
      hpll_pcr_force_f_i        : in  std_logic;
      hpll_fbgr_f_kp_i          : in  std_logic_vector(g_coef_bits-1 downto 0);
      hpll_fbgr_f_ki_i          : in  std_logic_vector(g_coef_bits-1 downto 0);
      hpll_pbgr_p_kp_i          : in  std_logic_vector(g_coef_bits-1 downto 0);
      hpll_pbgr_p_ki_i          : in  std_logic_vector(g_coef_bits-1 downto 0);
      hpll_ldcr_ld_thr_i        : in  std_logic_vector(7 downto 0);
      hpll_ldcr_ld_samp_i       : in  std_logic_vector(7 downto 0);
      hpll_psr_freq_lk_o        : out std_logic;
      hpll_psr_phase_lk_o       : out std_logic;
      hpll_psr_lock_lost_i      : in  std_logic;
      hpll_psr_lock_lost_o      : out std_logic;
      hpll_psr_lock_lost_load_i : in  std_logic;
      hpll_rfifo_wr_req_o       : out std_logic;
      hpll_rfifo_wr_full_i      : in  std_logic;
      hpll_rfifo_fp_mode_o      : out std_logic;
      hpll_rfifo_err_val_o      : out std_logic_vector(g_error_bits-1 downto 0);
      hpll_rfifo_dac_val_o      : out std_logic_vector(g_dacval_bits-1 downto 0));
  end component;

  component serial_dac
    generic (
      g_num_data_bits  : integer;
      g_num_extra_bits : integer);
    port (
      clk_i         : in  std_logic;
      rst_n_i       : in  std_logic;
      value1_i      : in  std_logic_vector(g_num_data_bits-1 downto 0);
      value1_stb_i  : in  std_logic;
      value2_i      : in  std_logic_vector(g_num_data_bits-1 downto 0);
      value2_stb_i  : in  std_logic;
      driver_sel_i  : in  std_logic;
      sclk_divsel_i : in  std_logic_vector(2 downto 0);
      dac_cs_n_o    : out std_logic;
      dac_sclk_o    : out std_logic;
      dac_sdata_o   : out std_logic);
  end component;

-- Software reset, synced to different clocks.
  signal rst_n_refclk, rst_n_fbck, rst_n_sysclk : std_logic;
-- freq & phase error
  signal freq_err                               : std_logic_vector(11 downto 0);
  signal phase_err                              : std_logic_vector(11 downto 0);
  signal freq_err_stb_p, phase_err_stb_p        : std_logic;
-- DAC drive value
  signal dac_val                                : std_logic_vector(15 downto 0);
  signal dac_val_stb_p                          : std_logic;

  signal sync_dividers_p : std_logic;

  signal dbg_ref_divided  : std_logic;
  signal dbg_fbck_divided : std_logic;
  signal dbg_pd_up        : std_logic;
  signal dbg_pd_down      : std_logic;

-- wishbone regs

  signal hpll_pcr_enable         : std_logic;
  signal hpll_pcr_force_f        : std_logic;
  signal hpll_pcr_dac_clksel     : std_logic_vector(2 downto 0);
  signal hpll_pcr_pd_gate        : std_logic_vector(2 downto 0);
  signal hpll_pcr_swrst          : std_logic;
  signal hpll_pcr_refsel         : std_logic_vector(1 downto 0);
  signal hpll_divr_div_ref       : std_logic_vector(15 downto 0);
  signal hpll_divr_div_fb        : std_logic_vector(15 downto 0);
  signal hpll_fbgr_f_kp          : std_logic_vector(15 downto 0);
  signal hpll_fbgr_f_ki          : std_logic_vector(15 downto 0);
  signal hpll_pbgr_p_kp          : std_logic_vector(15 downto 0);
  signal hpll_pbgr_p_ki          : std_logic_vector(15 downto 0);
  signal hpll_ldcr_ld_thr        : std_logic_vector(7 downto 0);
  signal hpll_ldcr_ld_samp       : std_logic_vector(7 downto 0);
  signal hpll_fbcr_fd_gate       : std_logic_vector(2 downto 0);
  signal hpll_fbcr_ferr_set      : std_logic_vector(11 downto 0);
  signal hpll_psr_freq_lk        : std_logic;
  signal hpll_psr_phase_lk       : std_logic;
  signal hpll_psr_lock_lost_out  : std_logic;
  signal hpll_psr_lock_lost_in   : std_logic;
  signal hpll_psr_lock_lost_load : std_logic;

  signal hpll_rfifo_wr_req  : std_logic;
  signal hpll_rfifo_wr_full : std_logic;
  signal hpll_rfifo_fp_mode : std_logic;
  signal hpll_rfifo_err_val : std_logic_vector(11 downto 0);
  signal hpll_rfifo_dac_val : std_logic_vector(15 downto 0);

  signal clk_ref_muxed : std_logic;

  
begin  -- architecture rtl

  
  rst_n_sysclk <= not hpll_pcr_swrst;

  -- warning: this is NOT GOOD, but works :)
  mux_clocks : process(hpll_pcr_refsel, clk_ref_i)
  begin
    clk_ref_muxed <= '0';
    for i in 0 to g_num_ref_inputs-1 loop
      if(to_integer(unsigned(hpll_pcr_refsel)) = i) then
        clk_ref_muxed <= clk_ref_i(i);
      end if;
    end loop;  -- i
  end process;


  sync_reset_refclk : sync_ffs
    generic map (
      g_sync_edge => "positive")
    port map (
      clk_i    => clk_ref_muxed,
      rst_n_i  => rst_n_i,
      data_i   => rst_n_sysclk,
      synced_o => rst_n_refclk,
      npulse_o => open,
      ppulse_o => open);

  sync_reset_fbck : sync_ffs
    generic map (
      g_sync_edge => "positive")
    port map (
      clk_i    => clk_fbck_i,
      rst_n_i  => rst_n_i,
      data_i   => rst_n_sysclk,
      synced_o => rst_n_fbck,
      npulse_o => open,
      ppulse_o => open);

  FREQ_DETECT : hpll_period_detect
    port map (
      clk_ref_i            => clk_ref_muxed,
      clk_fbck_i           => clk_fbck_i,
      clk_sys_i            => clk_sys_i,
      rst_n_refclk_i       => rst_n_refclk,
      rst_n_fbck_i         => rst_n_fbck,
      rst_n_sysclk_i       => rst_n_sysclk,
      freq_err_o           => freq_err,
      freq_err_stb_p_o     => freq_err_stb_p,
      hpll_fbcr_fd_gate_i  => hpll_fbcr_fd_gate,
      hpll_fbcr_ferr_set_i => hpll_fbcr_ferr_set);


  BB_DETECT : hpll_bangbang_pd
    port map (
      clk_ref_i           => clk_ref_muxed,
      clk_fbck_i          => clk_fbck_i,
      clk_sys_i           => clk_sys_i,
      rst_n_refclk_i      => rst_n_refclk,
      rst_n_fbck_i        => rst_n_fbck,
      rst_n_sysclk_i      => rst_n_sysclk,
      sync_dividers_p_i   => sync_dividers_p,
      phase_err_o         => phase_err,
      phase_err_stb_p_o   => phase_err_stb_p,
      hpll_pcr_pd_gate_i  => hpll_pcr_pd_gate,
      hpll_divr_div_ref_i => hpll_divr_div_ref,
      hpll_divr_div_fb_i  => hpll_divr_div_fb,
      dbg_ref_divided_o   => dbg_ref_divided,
      dbg_fbck_divided_o  => dbg_fbck_divided,
      dbg_pd_up_o         => dbg_pd_up,
      dbg_pd_down_o       => dbg_pd_down);


  
  PI_CTL : hpll_controller
    generic map (
      g_error_bits          => 12,
      g_dacval_bits         => g_dacval_bits,
      g_output_bias         => g_output_bias,
      g_integrator_fracbits => 16,
      g_integrator_overbits => 6,
      g_coef_bits           => 16)
    port map (
      clk_sys_i                 => clk_sys_i,
      rst_n_sysclk_i            => rst_n_sysclk,
      phase_err_i               => phase_err,
      phase_err_stb_p_i         => phase_err_stb_p,
      freq_err_i                => freq_err,
      freq_err_stb_p_i          => freq_err_stb_p,
      dac_val_o                 => dac_val,
      dac_val_stb_p_o           => dac_val_stb_p,
      sync_dividers_p_o         => sync_dividers_p,
      hpll_pcr_enable_i         => hpll_pcr_enable,
      hpll_pcr_force_f_i        => hpll_pcr_force_f,
      hpll_fbgr_f_kp_i          => hpll_fbgr_f_kp,
      hpll_fbgr_f_ki_i          => hpll_fbgr_f_ki,
      hpll_pbgr_p_kp_i          => hpll_pbgr_p_kp,
      hpll_pbgr_p_ki_i          => hpll_pbgr_p_ki,
      hpll_ldcr_ld_thr_i        => hpll_ldcr_ld_thr,
      hpll_ldcr_ld_samp_i       => hpll_ldcr_ld_samp,
      hpll_psr_freq_lk_o        => hpll_psr_freq_lk,
      hpll_psr_phase_lk_o       => hpll_psr_phase_lk,
      hpll_psr_lock_lost_i      => hpll_psr_lock_lost_out,
      hpll_psr_lock_lost_o      => hpll_psr_lock_lost_in,
      hpll_psr_lock_lost_load_i => hpll_psr_lock_lost_load,
      hpll_rfifo_wr_req_o       => hpll_rfifo_wr_req,
      hpll_rfifo_wr_full_i      => hpll_rfifo_wr_full,
      hpll_rfifo_fp_mode_o      => hpll_rfifo_fp_mode,
      hpll_rfifo_err_val_o      => hpll_rfifo_err_val,
      hpll_rfifo_dac_val_o      => hpll_rfifo_dac_val
      );


 
    dac_data_o    <= dac_val;
    dac_load_p1_o <= dac_val_stb_p;


  gen_wb_slave : if(g_with_wishbone /= 0) generate
    WB_SLAVE : hpll_wb_slave
      port map (
        rst_n_i                   => rst_n_i,
        wb_clk_i                  => clk_sys_i,
        wb_addr_i                 => wb_addr_i,
        wb_data_i                 => wb_data_i,
        wb_data_o                 => wb_data_o,
        wb_cyc_i                  => wb_cyc_i,
        wb_sel_i                  => wb_sel_i,
        wb_stb_i                  => wb_stb_i,
        wb_we_i                   => wb_we_i,
        wb_ack_o                  => wb_ack_o,
        hpll_pcr_enable_o         => hpll_pcr_enable,
        hpll_pcr_force_f_o        => hpll_pcr_force_f,
        hpll_pcr_dac_clksel_o     => hpll_pcr_dac_clksel,
        hpll_pcr_pd_gate_o        => hpll_pcr_pd_gate,
        hpll_pcr_swrst_o          => hpll_pcr_swrst,
        hpll_pcr_refsel_o         => hpll_pcr_refsel,
        hpll_divr_div_ref_o       => hpll_divr_div_ref,
        hpll_divr_div_fb_o        => hpll_divr_div_fb,
        hpll_fbgr_f_kp_o          => hpll_fbgr_f_kp,
        hpll_fbgr_f_ki_o          => hpll_fbgr_f_ki,
        hpll_pbgr_p_kp_o          => hpll_pbgr_p_kp,
        hpll_pbgr_p_ki_o          => hpll_pbgr_p_ki,
        hpll_ldcr_ld_thr_o        => hpll_ldcr_ld_thr,
        hpll_ldcr_ld_samp_o       => hpll_ldcr_ld_samp,
        hpll_fbcr_fd_gate_o       => hpll_fbcr_fd_gate,
        hpll_fbcr_ferr_set_o      => hpll_fbcr_ferr_set,
        hpll_psr_freq_lk_i        => hpll_psr_freq_lk,
        hpll_psr_phase_lk_i       => hpll_psr_phase_lk,
        hpll_psr_lock_lost_o      => hpll_psr_lock_lost_out,
        hpll_psr_lock_lost_i      => hpll_psr_lock_lost_in,
        hpll_psr_lock_lost_load_o => hpll_psr_lock_lost_load,
        hpll_rfifo_wr_req_i       => hpll_rfifo_wr_req,
        hpll_rfifo_wr_full_o      => hpll_rfifo_wr_full,
        hpll_rfifo_fp_mode_i      => hpll_rfifo_fp_mode,
        hpll_rfifo_err_val_i      => hpll_rfifo_err_val,
        hpll_rfifo_dac_val_i      => hpll_rfifo_dac_val
        );
  end generate gen_wb_slave;

  gen_no_wb_slave : if(g_with_wishbone = 0) generate



    hpll_pcr_enable   <= cfg_enable_i;
    hpll_pcr_force_f  <= cfg_force_freq_i;
    hpll_pcr_pd_gate  <= std_logic_vector(to_unsigned(g_pd_gating, hpll_pcr_pd_gate'length));
    hpll_pcr_swrst    <= '0';
    hpll_pcr_refsel   <= cfg_refsel_i;
    hpll_divr_div_ref <= std_logic_vector(to_unsigned(g_div_ref, hpll_divr_div_ref'length));
    hpll_divr_div_fb  <= std_logic_vector(to_unsigned(g_div_fb, hpll_divr_div_fb'length));
    hpll_fbgr_f_kp    <= std_logic_vector(to_unsigned(g_kp_freq, hpll_fbgr_f_kp'length));
    hpll_fbgr_f_ki    <= std_logic_vector(to_unsigned(g_ki_freq, hpll_fbgr_f_ki'length));
    hpll_pbgr_p_kp    <= std_logic_vector(to_unsigned(g_kp_phase, hpll_pbgr_p_kp'length));
    hpll_pbgr_p_ki    <= std_logic_vector(to_unsigned(g_ki_phase, hpll_pbgr_p_ki'length));

    hpll_ldcr_ld_thr   <= std_logic_vector(to_unsigned(g_ld_threshold, hpll_ldcr_ld_thr'length));
    hpll_ldcr_ld_samp  <= std_logic_vector(to_unsigned(g_ld_samples, hpll_ldcr_ld_samp'length));
    hpll_fbcr_fd_gate  <= std_logic_vector(to_unsigned(g_fd_gating, hpll_fbcr_fd_gate'length));
    hpll_fbcr_ferr_set <= std_logic_vector(to_unsigned(g_ferr_setpoint, hpll_fbcr_ferr_set'length));

    stat_flock_o     <= hpll_psr_freq_lk;
    stat_plock_o     <= hpll_psr_phase_lk;
    stat_lock_lost_o <= hpll_psr_lock_lost_in;


    hpll_psr_lock_lost_out  <= '1';
    hpll_psr_lock_lost_load <= cfg_clear_status_i;

    hpll_rfifo_wr_full <= '0';
  end generate gen_no_wb_slave;




  auxout1_o <= dbg_fbck_divided;
  auxout2_o <= dbg_ref_divided;
  



end architecture rtl;
