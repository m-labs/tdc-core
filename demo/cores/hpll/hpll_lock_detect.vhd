-------------------------------------------------------------------------------
-- Title      : DMTD Helper PLL (HPLL) - lock detection logic
-- Project    : White Rabbit Switch
-------------------------------------------------------------------------------
-- File       : hpll_controller.vhd
-- Author     : Tomasz Wlostowski
-- Company    : CERN BE-Co-HT
-- Created    : 2010-06-14
-- Last update: 2010-08-23
-- Platform   : FPGA-generic
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: 
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



entity hpll_lock_detect is
  
  port (
    rst_n_sysclk_i : std_logic;
    clk_sys_i      : std_logic;


    phase_err_i       : in std_logic_vector(11 downto 0);
    phase_err_stb_p_i : in std_logic;

    freq_err_i       : in std_logic_vector(11 downto 0);
    freq_err_stb_p_i : in std_logic;


    hpll_ldcr_ld_samp_i      : in std_logic_vector(7 downto 0);
    hpll_ldcr_ld_thr_i : in std_logic_vector(7 downto 0);

-- Flags: frequency lock
    hpll_psr_freq_lk_o        : out std_logic;
-- Flags: phase lock
    hpll_psr_phase_lk_o       : out std_logic;
-- Flags: loss-of-lock indicator
    hpll_psr_lock_lost_i      : in  std_logic;
    hpll_psr_lock_lost_o      : out std_logic;
    hpll_psr_lock_lost_load_i : in  std_logic;

-- PI frequency/phase mode select
    freq_mode_o : out std_logic
    );

end hpll_lock_detect;

architecture syn of hpll_lock_detect is

  type t_lock_detect_state is (LD_WAIT_FREQ_LOCK, LD_WAIT_PHASE_LOCK, LD_LOCKED);

  signal ph_err_sign_d0 : std_logic;
  signal ph_err_sign    : std_logic;
  signal ph_err_valid   : std_logic;

  signal ph_err_duty_cntr : unsigned(7 downto 0);
  signal ph_err_lock_cntr : unsigned(7 downto 0);

  signal f_err_lock_cntr : unsigned(7 downto 0);

  signal phase_lock : std_logic;
  signal freq_lock  : std_logic;

  signal state : t_lock_detect_state;

  signal f_err_int : integer;
  
begin


  ph_err_sign <= phase_err_i(phase_err_i'length-1);

  lock_detect_phase : process (clk_sys_i, rst_n_sysclk_i)
  begin
    if rising_edge(clk_sys_i) then
      if(rst_n_sysclk_i = '0') then
        ph_err_valid     <= '0';
        ph_err_sign_d0   <= '0';
        ph_err_valid     <= '0';
        ph_err_duty_cntr <= (others => '0');
        ph_err_lock_cntr <= (others => '0');
        phase_lock       <= '0';
      else
-- new phase error value arrived
        if(phase_err_stb_p_i = '1') then
          ph_err_sign_d0 <= ph_err_sign;

          -- the sign of the phase error has changed, check how long it will
          -- take to flip again
          if(ph_err_sign /= ph_err_sign_d0) then
            ph_err_duty_cntr <= (others => '0');

            -- if the phase error has been changing its sign frequent enough
            -- for a given number of samples, we assume the PLL is locked
            if(std_logic_vector(ph_err_lock_cntr) = hpll_ldcr_ld_samp_i) then
              phase_lock       <= '1';
            else
              ph_err_lock_cntr <= ph_err_lock_cntr + 1;
              phase_lock <= '0';
            end if;
          else
            -- if the phase error remains positive or negative for too long,
            -- we are out of lock

            if(std_logic_vector(ph_err_duty_cntr) = hpll_ldcr_ld_thr_i) then
              ph_err_lock_cntr <= (others => '0');
              phase_lock       <= '0';
            else
              ph_err_duty_cntr <= ph_err_duty_cntr + 1;
            end if;

         
          end if;
        end if;
      end if;
    end if;
  end process;

  f_err_int <= to_integer(signed(freq_err_i));

  lock_detect_freq : process(clk_sys_i, rst_n_sysclk_i)
  begin
    if rising_edge(clk_sys_i) then
      if(rst_n_sysclk_i = '0') then
        freq_lock       <= '0';
        f_err_lock_cntr <= (others => '0');
      else
        if(freq_err_stb_p_i = '1') then
          if(f_err_int > -300 and f_err_int < 300) then

            if(std_logic_vector(f_err_lock_cntr) = hpll_ldcr_ld_samp_i) then
              freq_lock <= '1';
            else
              f_err_lock_cntr <= f_err_lock_cntr + 1;
              freq_lock       <= '0';
            end if;
          else
            f_err_lock_cntr <= (others => '0');
            freq_lock       <= '0';
          end if;
        end if;
      end if;
    end if;
  end process;


  lock_fsm : process(clk_sys_i, rst_n_sysclk_i)
  begin  -- process
    if rising_edge(clk_sys_i) then
      if (rst_n_sysclk_i = '0') then
        state                <= LD_WAIT_FREQ_LOCK;
        freq_mode_o          <= '1';
        hpll_psr_lock_lost_o <= '0';
      else

        if(hpll_psr_lock_lost_load_i = '1' and hpll_psr_lock_lost_i = '1') then
          hpll_psr_lock_lost_o <= '0';
        end if;

        case state is
          when LD_WAIT_FREQ_LOCK =>
            if(freq_lock = '1') then
              state       <= LD_WAIT_PHASE_LOCK;
              freq_mode_o <= '0';
            else
              freq_mode_o <= '1';
            end if;

          when LD_WAIT_PHASE_LOCK =>
            if(phase_lock = '1') then
              state <= LD_LOCKED;
            end if;

          when LD_LOCKED =>
            if(phase_lock = '0' or freq_lock = '0') then
              hpll_psr_lock_lost_o <= '1';
            end if;

            if(phase_lock = '0') then
              state <= LD_WAIT_PHASE_LOCK;
            elsif freq_lock = '0' then
              state <= LD_WAIT_FREQ_LOCK;
            end if;
            
          when others => null;
        end case;
      end if;
    end if;
  end process;

  hpll_psr_phase_lk_o <= phase_lock;
  hpll_psr_freq_lk_o  <= freq_lock;
  
end syn;
