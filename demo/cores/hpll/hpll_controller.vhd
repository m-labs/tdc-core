-------------------------------------------------------------------------------
-- Title      : DMTD Helper PLL (HPLL) - programmable PI controller
-- Project    : White Rabbit Switch
-------------------------------------------------------------------------------
-- File       : hpll_controller.vhd
-- Author     : Tomasz Wlostowski
-- Company    : CERN BE-Co-HT
-- Created    : 2010-06-14
-- Last update: 2010-06-21
-- Platform   : FPGA-generic
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: Dual, programmable PI controller:
-- - first channel processes the frequency error (gain defined by P_KP/P_KI)
-- - second channel processes the phase error (gain defined by F_KP/F_KI)
-- The PI controller starts in the frequency lock mode (using 1st channel).
-- After locking on the frequency, it switches to phase mode (2nd channel). 
-------------------------------------------------------------------------------
-- Copyright (c) 2010 Tomasz Wlostowski
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author          Description
-- 2010-06-14  1.0      twlostow        Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity hpll_controller is
  generic(
    g_error_bits          : integer := 12;
    g_dacval_bits         : integer := 16;
    g_output_bias         : integer := 32767;
    g_integrator_fracbits : integer := 16;
    g_integrator_overbits : integer := 6;
    g_coef_bits           : integer := 16

    );
  port (
    clk_sys_i      : in std_logic;
    rst_n_sysclk_i : in std_logic;

-------------------------------------------------------------------------------
-- Phase & frequency error inputs
-------------------------------------------------------------------------------

    phase_err_i       : in std_logic_vector(g_error_bits-1 downto 0);
    phase_err_stb_p_i : in std_logic;

    freq_err_i       : in std_logic_vector(g_error_bits-1 downto 0);
    freq_err_stb_p_i : in std_logic;

-------------------------------------------------------------------------------
-- DAC Output
-------------------------------------------------------------------------------

    dac_val_o       : out std_logic_vector(g_dacval_bits-1 downto 0);
    dac_val_stb_p_o : out std_logic;

    sync_dividers_p_o : out std_logic;

-------------------------------------------------------------------------------
-- Wishbone regs
-------------------------------------------------------------------------------    

-- PLL enable
    hpll_pcr_enable_i : in std_logic;

-- PI force freq mode. '1' causes the PI to stay in frequency lock mode all the
-- time.
    hpll_pcr_force_f_i : in std_logic;

-- Frequency Kp/Ki
    hpll_fbgr_f_kp_i : in std_logic_vector(g_coef_bits-1 downto 0);
    hpll_fbgr_f_ki_i : in std_logic_vector(g_coef_bits-1 downto 0);

-- Phase Kp/Ki
    hpll_pbgr_p_kp_i : in std_logic_vector(g_coef_bits-1 downto 0);
    hpll_pbgr_p_ki_i : in std_logic_vector(g_coef_bits-1 downto 0);

-- Lock detect

    hpll_ldcr_ld_thr_i  : in std_logic_vector(7 downto 0);
    hpll_ldcr_ld_samp_i : in std_logic_vector(7 downto 0);

-- Flags: frequency lock
    hpll_psr_freq_lk_o        : out std_logic;
-- Flags: phase lock
    hpll_psr_phase_lk_o       : out std_logic;
-- Flags: loss-of-lock indicator
    hpll_psr_lock_lost_i      : in  std_logic;
    hpll_psr_lock_lost_o      : out std_logic;
    hpll_psr_lock_lost_load_i : in  std_logic;

-- phase/freq error recording FIFO
    hpll_rfifo_wr_req_o  : out std_logic;
    hpll_rfifo_wr_full_i : in  std_logic;
    hpll_rfifo_fp_mode_o : out std_logic;
    hpll_rfifo_err_val_o : out std_logic_vector(g_error_bits-1 downto 0);
    hpll_rfifo_dac_val_o : out std_logic_vector(g_dacval_bits-1 downto 0)
    );


end hpll_controller;

architecture behavioral of hpll_controller is

  component hpll_lock_detect
    port (
      rst_n_sysclk_i            :     std_logic;
      clk_sys_i                 :     std_logic;
      phase_err_i               : in  std_logic_vector(11 downto 0);
      phase_err_stb_p_i         : in  std_logic;
      freq_err_i                : in  std_logic_vector(11 downto 0);
      freq_err_stb_p_i          : in  std_logic;
      hpll_ldcr_ld_samp_i       : in  std_logic_vector(7 downto 0);
      hpll_ldcr_ld_thr_i        : in  std_logic_vector(7 downto 0);
      hpll_psr_freq_lk_o        : out std_logic;
      hpll_psr_phase_lk_o       : out std_logic;
      hpll_psr_lock_lost_i      : in  std_logic;
      hpll_psr_lock_lost_o      : out std_logic;
      hpll_psr_lock_lost_load_i : in  std_logic;
      freq_mode_o               : out std_logic);
  end component;

  type t_hpll_state is (HPLL_WAIT_SAMPLE, HPLL_MUL_KI, HPLL_INTEGRATE, HPLL_MUL_KP, HPLL_CALC_SUM, HPLL_ROUND_SUM);


  -- integrator size: 12 error bits + 16 coefficient bits + 6 overflow bits
  constant c_INTEGRATOR_BITS : integer := g_error_bits + g_integrator_overbits + g_coef_bits;

  constant c_ZEROS : unsigned (63 downto 0) := (others => '0');
  constant c_ONES  : unsigned (63 downto 0) := (others => '1');

  -- DAC DC bias (extended by c_INTEGRATOR_FRACBITS). By default it's half of the
  -- output voltage scale.
  constant c_OUTPUT_BIAS : signed(g_dacval_bits + g_integrator_fracbits-1 downto 0) := to_signed(g_output_bias, g_dacval_bits) & to_signed(0, g_integrator_fracbits);

  -- Multiplier size. A = error value, B = coefficient value
  constant c_MUL_A_BITS : integer := g_error_bits;
  constant c_MUL_B_BITS : integer := g_coef_bits;

  -- the integrator
  signal i_reg : signed(c_INTEGRATOR_BITS-1 downto 0);

  -- multiplier IO
  signal mul_A   : signed(c_MUL_A_BITS - 1 downto 0);
  signal mul_B   : signed(c_MUL_B_BITS - 1 downto 0);
  signal mul_OUT : signed(c_MUL_A_BITS + c_MUL_B_BITS - 1 downto 0);

  signal mul_out_reg : signed(c_MUL_A_BITS + c_MUL_B_BITS - 1 downto 0);

  signal pi_state : t_hpll_state;

  -- 1: we are in the frequency mode, 0: we are in phase mode.
  signal freq_mode    : std_logic;
  signal freq_mode_ld : std_logic;

  signal output_val           : unsigned(c_INTEGRATOR_BITS-1 downto 0);
  signal output_val_unrounded : unsigned(g_dacval_bits-1 downto 0);
  signal output_val_round_up  : std_logic;

  signal dac_val_int : std_logic_vector(g_dacval_bits-1 downto 0);

begin  -- behavioral

  LOCK_DET : hpll_lock_detect
    port map (
      rst_n_sysclk_i            => rst_n_sysclk_i,
      clk_sys_i                 => clk_sys_i,
      phase_err_i               => phase_err_i,
      phase_err_stb_p_i         => phase_err_stb_p_i,
      freq_err_i                => freq_err_i,
      freq_err_stb_p_i          => freq_err_stb_p_i,
      hpll_ldcr_ld_samp_i       => hpll_ldcr_ld_samp_i,
      hpll_ldcr_ld_thr_i  => hpll_ldcr_ld_thr_i,
      hpll_psr_freq_lk_o        => hpll_psr_freq_lk_o,
      hpll_psr_phase_lk_o       => hpll_psr_phase_lk_o,
      hpll_psr_lock_lost_i      => hpll_psr_lock_lost_i,
      hpll_psr_lock_lost_o      => hpll_psr_lock_lost_o,
      hpll_psr_lock_lost_load_i => hpll_psr_lock_lost_load_i,
      freq_mode_o               => freq_mode_ld);

-- shared multiplier
  multiplier : process (mul_A, mul_B)
  begin  -- process
    mul_OUT <= mul_A * mul_B;
  end process;


  output_val_unrounded <= output_val(g_integrator_fracbits + g_dacval_bits - 1 downto g_integrator_fracbits);
  output_val_round_up  <= std_logic(output_val(g_integrator_fracbits - 1));

  main_fsm : process (clk_sys_i, rst_n_sysclk_i)
  begin  -- process
    if rising_edge(clk_sys_i) then
      if rst_n_sysclk_i = '0' then
        i_reg             <= (others => '0');
        freq_mode         <= '1';       -- start in frequency lock mode
        pi_state          <= HPLL_WAIT_SAMPLE;
        dac_val_stb_p_o   <= '0';
        dac_val_int       <= (others => '0');
        sync_dividers_p_o <= '0';
        freq_mode         <= '1';

      else
        if hpll_pcr_enable_i = '0' then
          pi_state        <= HPLL_WAIT_SAMPLE;
          dac_val_stb_p_o <= '0';
          freq_mode       <= '1';
          
        else
          case pi_state is

-------------------------------------------------------------------------------
-- State: HPLL wait for input sample. When a frequency error (or phase error)
-- sample arrives from the detector, start the PI update.
-------------------------------------------------------------------------------
            when HPLL_WAIT_SAMPLE =>

              dac_val_stb_p_o     <= '0';
              hpll_rfifo_wr_req_o <= '0';

-- frequency lock mode, got a frequency sample
              if(freq_mode = '1' and freq_err_stb_p_i = '1') then
                pi_state <= HPLL_MUL_KI;
                mul_A    <= signed(freq_err_i);
                mul_B    <= signed(hpll_fbgr_f_ki_i);
-- phase lock mode, got a phase sample
              elsif (freq_mode = '0' and phase_err_stb_p_i = '1') then
                pi_state <= HPLL_MUL_KI;
                mul_A    <= signed(phase_err_i);
                mul_B    <= signed(hpll_pbgr_p_ki_i);
              end if;

-------------------------------------------------------------------------------
-- State: HPLL multiply by Ki: multiples the phase/freq error by an appropriate
-- Kp/Ki coefficient, set up the multipler for (error * Kp) operation.
-------------------------------------------------------------------------------              
            when HPLL_MUL_KI =>

              sync_dividers_p_o <= '0';

              if(freq_mode = '1') then
                mul_B <= signed(hpll_fbgr_f_kp_i);
              else
                mul_B <= signed(hpll_pbgr_p_kp_i);
              end if;

              mul_out_reg <= mul_OUT;   -- just keep the result
              pi_state    <= HPLL_INTEGRATE;

-------------------------------------------------------------------------------
-- State: HPLL integrate: add the (Error * Ki) to the integrator register
-------------------------------------------------------------------------------              
            when HPLL_INTEGRATE =>
              i_reg <= i_reg + mul_out_reg;

              pi_state <= HPLL_MUL_KP;

-------------------------------------------------------------------------------
-- State: HPLL multiply by Kp: does the same as HPLL_MUL_KI but for the proportional
-- branch. 
-------------------------------------------------------------------------------              
            when HPLL_MUL_KP =>


              mul_out_reg <= mul_OUT;
              pi_state    <= HPLL_CALC_SUM;

              
            when HPLL_CALC_SUM =>

              output_val <= unsigned(c_OUTPUT_BIAS + resize(mul_out_reg, output_val'length) + resize(i_reg, output_val'length));
              pi_state   <= HPLL_ROUND_SUM;

-------------------------------------------------------------------------------
-- State: HPLL round sum: calculates the final DAC value, with 0.5LSB rounding.
-- Also checks for the frequency lock.
-------------------------------------------------------------------------------              

            when HPLL_ROUND_SUM =>
              dac_val_stb_p_o <= '1';


-- +-0.5 rounding of the output value
              if(output_val_round_up = '1') then
                dac_val_int <= std_logic_vector(output_val_unrounded + 1);
              else
                dac_val_int <= std_logic_vector(output_val_unrounded);
              end if;

              pi_state <= HPLL_WAIT_SAMPLE;

              if(hpll_pcr_force_f_i = '0') then
                freq_mode <= freq_mode_ld;
              else
                freq_mode <= '1';
              end if;

              if(freq_mode = '1' and freq_mode_ld = '0') then
                sync_dividers_p_o <= '1';
              end if;

              hpll_rfifo_wr_req_o <= not hpll_rfifo_wr_full_i;
              
            when others => null;
          end case;
        end if;
      end if;
    end if;
  end process;

-- record some diagnostic stuff (error, dac val) into a FIFO
  hpll_rfifo_fp_mode_o <= freq_mode;
  hpll_rfifo_dac_val_o <= dac_val_int;
  hpll_rfifo_err_val_o <= phase_err_i when freq_mode = '0' else freq_err_i;

  dac_val_o <= dac_val_int;
  
  
end behavioral;
