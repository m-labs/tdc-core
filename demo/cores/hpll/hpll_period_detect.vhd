-------------------------------------------------------------------------------
-- Title      : DMTD Helper PLL (HPLL) - linear frequency/period detector.
-- Project    : White Rabbit Switch
-------------------------------------------------------------------------------
-- File       : hpll_period_detect.vhd
-- Author     : Tomasz Wlostowski
-- Company    : CERN BE-Co-HT
-- Created    : 2010-06-14
-- Last update: 2011-04-08
-- Platform   : FPGA-generic
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: Simple linear frequency detector with programmable error
-- setpoint and gating period. The measured clocks are: clk_ref_i and clk_fbck_i.
-- The error value is outputted every 2^(hpll_fbcr_fd_gate_i + 14) cycles on a
-- freq_err_o. A pulse is produced on freq_err_stb_p_o every time freq_err_o
-- is updated with a new value. freq_err_o value is:
-- - positive when clk_fbck_i is slower than selected frequency setpoint
-- - negative when clk_fbck_i is faster than selected frequency setpoint
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

use work.common_components.all;

entity hpll_period_detect is
  generic(
    g_freq_err_frac_bits: integer);
  port (
-------------------------------------------------------------------------------
-- Clocks & resets
-------------------------------------------------------------------------------

-- reference clocks
    clk_ref_i : in std_logic;

-- fed-back (VCO) clock
    clk_fbck_i : in std_logic;

-- system clock (wishbone and I/O)
    clk_sys_i : in std_logic;

-- reset signals (the same reset synced to different clocks)
    rst_n_refclk_i : in std_logic;
    rst_n_fbck_i   : in std_logic;
    rst_n_sysclk_i : in std_logic;

-------------------------------------------------------------------------------
-- Outputs
-------------------------------------------------------------------------------    

-- frequency error value (signed)
    freq_err_o       : out std_logic_vector(11 downto 0);

-- frequency error valid pulse    
    freq_err_stb_p_o : out std_logic;

-------------------------------------------------------------------------------
-- Wishbone regs
-------------------------------------------------------------------------------

-- gating period:
    hpll_fbcr_fd_gate_i : in std_logic_vector(2 downto 0);

-- frequency error setpoint:
    hpll_fbcr_ferr_set_i : in std_logic_vector(11 downto 0)
    );

end hpll_period_detect;

architecture rtl of hpll_period_detect is

-- derived from the maximum gating period (2 ^ 21 + 1 "safety" bit)
   constant c_COUNTER_BITS : integer := 22;  
-- number of fractional bits in the frequency error output
--  constant c_FREQ_ERR_FRAC_BITS : integer := 7; 

-- frequency counters: feedback clock & gating counter
  signal counter_fb   : unsigned(c_COUNTER_BITS-1 downto 0);
  signal counter_gate : unsigned(c_COUNTER_BITS-1 downto 0);

-- clock domain synchronization stuff...
  signal gate_sreg : std_logic_vector(3 downto 0);
  signal pstb_sreg : std_logic_vector(3 downto 0);
  signal gate_p, period_p : std_logic;

  signal gate_cntr_bitsel : std_logic;
  signal desired_freq     : unsigned(c_COUNTER_BITS-1 downto 0);
  signal cur_freq         : unsigned(c_COUNTER_BITS-1 downto 0);

  signal delta_f: signed(11 downto 0);
  
begin  -- rtl


-- decoding FD gating field from FBCR register:
  decode_fd_gating : process(hpll_fbcr_fd_gate_i, counter_gate)
  begin
    case hpll_fbcr_fd_gate_i is
      when "000" => gate_cntr_bitsel <= std_logic(counter_gate(14));  -- div: 16384
                    desired_freq <= to_unsigned(16384, desired_freq'length);
      when "001" => gate_cntr_bitsel <= std_logic(counter_gate(15));  -- ....
                    desired_freq <= to_unsigned(32768, desired_freq'length);
      when "010" => gate_cntr_bitsel <= std_logic(counter_gate(16));
                    desired_freq <= to_unsigned(65536, desired_freq'length);
      when "011" => gate_cntr_bitsel <= std_logic(counter_gate(17));
                    desired_freq <= to_unsigned(131072, desired_freq'length);
      when "100" => gate_cntr_bitsel <= std_logic(counter_gate(18));
                    desired_freq <= to_unsigned(262144, desired_freq'length);
      when "101" => gate_cntr_bitsel <= std_logic(counter_gate(19));
                    desired_freq <= to_unsigned(524288, desired_freq'length);
      when "110" => gate_cntr_bitsel <= std_logic(counter_gate(20));  -- ....
                    desired_freq <= to_unsigned(1048576, desired_freq'length);
      when "111" => gate_cntr_bitsel <= std_logic(counter_gate(21));  -- div: 2097152
                    desired_freq <= to_unsigned(2097152, desired_freq'length);
      when others => null;
    end case;
  end process;

-------------------------------------------------------------------------------
-- Gating counter: produces a gating pulse on gate_p (clk_fbck_i domain) with
-- period configured by FD_GATE field in FBCR register
-------------------------------------------------------------------------------  
  
  gating_counter : process(clk_ref_i, rst_n_refclk_i)
  begin
    if rising_edge(clk_ref_i) then
      if(rst_n_refclk_i = '0') then
        counter_gate <= to_unsigned(1, counter_gate'length);
        gate_sreg    <= (others => '0');
      else
        if(gate_cntr_bitsel = '1') then
          -- counter bit selected by hpll_fbcr_fd_gate_i changed from 0 to 1?
          -- reset the counter and generate the gating signal for feedback counter
          counter_gate <= to_unsigned(1, counter_gate'length);
          gate_sreg    <= (others => '1');
        else
          -- advance the counter and generate a longer pulse on gating signal
          -- using a shift register so the sync chain will always work regardless of
          -- the clock frequency.
          counter_gate <= counter_gate + 1;
          gate_sreg    <= '0' & gate_sreg(gate_sreg'length-1 downto 1);
        end if;
      end if;
    end if;
  end process;

-- sync logic for the gate_p pulse (from clk_ref_i to clk_fbck_i)
  sync_gating_pulse : sync_ffs
    generic map (
      g_sync_edge => "positive")
    port map (
      clk_i    => clk_fbck_i,
      rst_n_i  => rst_n_fbck_i,
      data_i   => gate_sreg(0),
      synced_o => open,
      npulse_o => open,
      ppulse_o => gate_p);

-------------------------------------------------------------------------------
-- Main period/frequency measurement process: Takes a snapshot of the counter_fb
-- every time there's a pulse on gate_p. The capture of new frequency value
-- is indicated by pulsing period_p.
-------------------------------------------------------------------------------  

  period_detect : process(clk_fbck_i, rst_n_fbck_i)
  begin
    if rising_edge(clk_fbck_i) then
      if rst_n_fbck_i = '0' then
        counter_fb <= to_unsigned(1, counter_fb'length);
        cur_freq   <= (others => '0');
        pstb_sreg  <= (others => '0');
      else
        if(gate_p = '1') then
          counter_fb <= to_unsigned(1, counter_fb'length);
          cur_freq   <= counter_fb;
          pstb_sreg  <= (others => '1');
        else
          counter_fb <= counter_fb + 1;
          pstb_sreg  <= '0' & pstb_sreg(pstb_sreg'length-1 downto 1);
        end if;
      end if;
    end if;
  end process;

-- synchronization logic for period_p (from clk_fbck_i to clk_sys_i)
  sync_period_pulse : sync_ffs
    generic map (
      g_sync_edge => "positive")
    port map (
      clk_i    => clk_sys_i,
      rst_n_i  => rst_n_sysclk_i,
      data_i   => pstb_sreg(0),
      synced_o => open,
      npulse_o => open,
      ppulse_o => period_p);

-- calculate the frequency difference, padded by some fractional bits
  delta_f <= resize(signed(desired_freq) - signed(cur_freq), delta_f'length-g_freq_err_frac_bits) & to_signed(0, g_freq_err_frac_bits);


-------------------------------------------------------------------------------
-- Calculates the phase error by taking the difference between reference and
-- measured frequency and subtracting the error setpoint from FERR_SET field
-- in FBCR register.
-------------------------------------------------------------------------------

  freq_err_output : process(clk_sys_i, rst_n_sysclk_i)
  begin
    if rising_edge(clk_sys_i) then
      if rst_n_sysclk_i = '0' then
        freq_err_stb_p_o <= '0';
        freq_err_o       <= (others => '0');
      else
        if(period_p = '1') then
          freq_err_o <= std_logic_vector(resize(delta_f - signed (hpll_fbcr_ferr_set_i), freq_err_o'length));
        end if;
        freq_err_stb_p_o <= period_p;
      end if;
    end if;
  end process;


end rtl;
