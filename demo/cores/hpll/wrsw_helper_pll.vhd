-------------------------------------------------------------------------------
-- Project    : Phase-Locked Loop
-------------------------------------------------------------------------------
-- File       : pll.vhd
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
-------------------------------------------------------------------------------

library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.platform_specific.all;
use work.common_components.all;

entity wrsw_helper_pll is

  port (
    rst_n_i : in std_logic;             -- Synchronous reset

    clk_ref_local_i : in std_logic;     -- Reference clock (from TCXO)
    clk_ref_up0_i   : in std_logic;     -- Reference clock (from uplink 0)
    clk_ref_up1_i   : in std_logic;     -- Reference clock (from uplink 1)

    clk_sys_i  : in std_logic;          -- System clock
    clk_fbck_i : in std_logic;          -- Fed-back clock

    dac_cs_n_o  : out std_logic;
    dac_sclk_o  : out std_logic;
    dac_sdata_o : out std_logic;

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

end wrsw_helper_pll;

architecture rtl of wrsw_helper_pll is

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
    generic(
      g_freq_err_frac_bits:integer := 7
      );
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
  signal clk_ref_vec: std_logic_vector(2 downto 0);

    
begin  -- architecture rtl

  
  rst_n_sysclk <= not hpll_pcr_swrst;

  clk_ref_vec(0) <= clk_ref_local_i;
  clk_ref_vec(1) <= clk_ref_up1_i;
  clk_ref_vec(2) <= clk_ref_up0_i;
  

  -- warning: this is NOT GOOD, but works :)
  mux_clocks : process(hpll_pcr_refsel, clk_ref_vec)
  begin
    clk_ref_muxed <= '0';
    for i in 0 to 2 loop
      if(to_integer(unsigned(hpll_pcr_refsel)) = i) then
        clk_ref_muxed <= clk_ref_vec(i);
      end if;
    end loop;  -- i
  end process;
  
--  clk_ref_muxed <= clk_ref_up1_i;

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
      g_dacval_bits         => 16,
      g_output_bias         => 32767,
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

    
  DAC : serial_dac
    generic map (
      g_num_data_bits  => 16,
      g_num_extra_bits => 8
      )
    port map (
      clk_i         => clk_sys_i,
      rst_n_i       => rst_n_i,
      value1_i      => dac_val,
      value1_stb_i  => dac_val_stb_p,
      value2_i      => (others => '0'),
      value2_stb_i  => '0',
      driver_sel_i  => '0',
      sclk_divsel_i => hpll_pcr_dac_clksel,
      dac_cs_n_o    => dac_cs_n_o,
      dac_sclk_o    => dac_sclk_o,
      dac_sdata_o   => dac_sdata_o);


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


  auxout1_o <= dbg_fbck_divided;
  auxout2_o <= dbg_ref_divided;
  



end architecture rtl;
