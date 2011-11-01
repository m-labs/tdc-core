-------------------------------------------------------------------------------
-- Title      : DMTD Helper PLL (HPLL) - bang-bang phase/frequency detector
-- Project    : White Rabbit Switch
-------------------------------------------------------------------------------
-- File       : hpll_bangbang_pd.vhd
-- Author     : Tomasz Wlostowski
-- Company    : CERN BE-Co-HT
-- Created    : 2010-06-14
-- Last update: 2011-01-14
-- Platform   : FPGA-generic
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: Bang-bang type phase detector. clk_ref_i and clk_fbck_i clocks
-- are divided by hpll_divr_div_ref_i and hpll_divr_div_fb_i respectively and
-- compared. The phase error is outputted every (2^hpll_pcr_pd_gate_i + 10)
-- clk_fbck_i cycles. Divider counters can be synchronized at any moment 
-- by pulsing the sync_dividers_p_i signal.
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

entity hpll_bangbang_pd is

  port (
-------------------------------------------------------------------------------
-- Clocks & resets
-------------------------------------------------------------------------------

-- reference clock
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
-- I/O
-------------------------------------------------------------------------------

    sync_dividers_p_i : in std_logic;

    phase_err_o       : out std_logic_vector(11 downto 0);
    phase_err_stb_p_o : out std_logic;

-------------------------------------------------------------------------------
-- Wishbone regs
-------------------------------------------------------------------------------

-- phase counter gating 
    hpll_pcr_pd_gate_i : in std_logic_vector(2 downto 0);

-- reference divider
    hpll_divr_div_ref_i : in std_logic_vector(15 downto 0);

-- feedback divider
    hpll_divr_div_fb_i : in std_logic_vector(15 downto 0);

-------------------------------------------------------------------------------
-- Debug outputs
-------------------------------------------------------------------------------

    dbg_ref_divided_o  : out std_logic;
    dbg_fbck_divided_o : out std_logic;
    dbg_pd_up_o        : out std_logic;
    dbg_pd_down_o      : out std_logic
    );

  attribute rom_extract: string;
  attribute rom_extract of hpll_bangbang_pd : entity is "no";
end hpll_bangbang_pd;


architecture rtl of hpll_bangbang_pd is

  
  constant c_COUNTER_BITS : integer                       := 18;
  constant c_ONES         : std_logic_vector(63 downto 0) := (others => '1');
  constant c_ZEROS        : std_logic_vector(63 downto 0) := (others => '0');

  signal gate_counter : unsigned(c_COUNTER_BITS-1 downto 0);
  signal gate_p       : std_logic;

  signal updown_counter : signed(c_COUNTER_BITS-1 downto 0);

  -- phase error clamping stuff
  signal ph_err_sign        : std_logic;
  signal ph_err_extrabits   : std_logic_vector(c_COUNTER_BITS - 12 downto 0);
  signal ph_err_clamp_plus  : std_logic;
  signal ph_err_clamp_minus : std_logic;

  signal ph_sreg_delay : std_logic_vector(4 downto 0);


  signal ph_err   : signed(c_COUNTER_BITS-1 downto 0);
  signal ph_err_p : std_logic;

  signal ph_err_avg_slv : std_logic_vector(11 downto 0);
  signal ph_err_avg_p   : std_logic;

  signal clk_ref_div2 : std_logic;      -- reference clock/2

  -- phase detector input signals (after division)
  signal pd_in_ref  : std_logic;
  signal pd_in_fbck : std_logic;

  -- phase detector outputs
  signal pd_a, pd_b, pd_t, pd_ta : std_logic;
  signal pd_up, pd_down          : std_logic;
  signal atb_together            : std_logic_vector(2 downto 0);


  -- divider counters
  signal div_ctr_ref  : unsigned(15 downto 0);  -- max N =  65535
  signal div_ctr_fbck : unsigned(15 downto 0);  -- max N =  65535

  -- counter sync signals
  signal sync_dividers_ref_p  : std_logic;
  signal sync_dividers_fbck_p : std_logic;

  -- disable RAM extraction (XST is trying to implement the phase detector in a
  -- RAM)

 
--  attribute ram_extract of pd_down : signal is "no";
  
begin  -- rtl


  sync_ffs_sync_dividers_ref : sync_ffs
    generic map (
      g_sync_edge => "positive")
    port map (
      clk_i    => clk_ref_i,
      rst_n_i  => rst_n_refclk_i,
      data_i   => sync_dividers_p_i,
      synced_o => open,
      npulse_o => open,
      ppulse_o => sync_dividers_ref_p);

  sync_ffs_sync_dividers_fbck : sync_ffs
    generic map (
      g_sync_edge => "positive")
    port map (
      clk_i    => clk_fbck_i,
      rst_n_i  => rst_n_fbck_i,
      data_i   => sync_dividers_p_i,
      synced_o => open,
      npulse_o => open,
      ppulse_o => sync_dividers_fbck_p);

-- divide the reference clock by 2 - the reference clock must be 2x slower
-- than the VCO clock for proper operation of the BB detector
  divide_ref_2 : process(clk_ref_i, rst_n_refclk_i)
  begin
    if rising_edge(clk_ref_i) then
      if rst_n_refclk_i = '0' then
        clk_ref_div2 <= '0';
      else
        clk_ref_div2 <= not clk_ref_div2;
      end if;
    end if;
  end process;


-- Divides the reference clock by DIV_REF, output signal: pd_in_ref.
  divide_ref_N : process (clk_ref_i, rst_n_refclk_i)
  begin  -- process
    if rising_edge(clk_ref_i) then
      if rst_n_refclk_i = '0' or sync_dividers_ref_p = '1' then
        div_ctr_ref <= to_unsigned(1, div_ctr_ref'length);
        pd_in_ref   <= '0';
      else
        if(clk_ref_div2 = '1') then  -- reference clock must be at the half rate of
          -- the VCO clock
          if (div_ctr_ref = unsigned(hpll_divr_div_ref_i)) then
            div_ctr_ref <= to_unsigned(1, div_ctr_ref'length);
            pd_in_ref   <= not pd_in_ref;  -- divide the clock :)
          else
            div_ctr_ref <= div_ctr_ref + 1;
          end if;
        end if;
      end if;
    end if;
  end process;

-- Divides the VCO clock by DIV_FB, output signal: pd_in_fbck
  divide_fbck_N : process (clk_fbck_i, rst_n_fbck_i)
  begin  -- process
    if rising_edge(clk_fbck_i) then
      if rst_n_fbck_i = '0' or sync_dividers_fbck_p = '1' then
        div_ctr_fbck <= to_unsigned(1, div_ctr_fbck'length);
        pd_in_fbck   <= '0';
      else
        if (div_ctr_fbck = unsigned(hpll_divr_div_fb_i)) then
          div_ctr_fbck <= to_unsigned(1, div_ctr_fbck'length);
          pd_in_fbck   <= not pd_in_fbck;  -- divide the clock :)
        else
          div_ctr_fbck <= div_ctr_fbck + 1;
        end if;
      end if;
    end if;
  end process;


-------------------------------------------------------------------------------
-- Bang-bang PD
-------------------------------------------------------------------------------  

  bb_pd_negedge : process(pd_in_fbck)
  begin
    if falling_edge(pd_in_fbck) then
      pd_ta <= pd_in_ref;
    end if;
  end process;


   bb_pd_posedge : process(pd_in_fbck)
  begin
    if rising_edge(pd_in_fbck) then
      pd_b <= pd_in_ref;
      pd_a <= pd_b;
      pd_t <= pd_ta;
    end if;
  end process;

  atb_together <= pd_a & pd_t & pd_b;

  decode_bangbang : process(atb_together)
  begin
    case (atb_together) is
      when "000" =>                     -- no transition
        pd_up   <= '0';
        pd_down <= '0';
      when "001" =>                     -- too fast
        pd_up   <= '0';
        pd_down <= '1';
      when "010" =>                     -- invalid
        pd_up   <= '1';
        pd_down <= '1';
      when "011" =>                     -- too slow
        pd_up   <= '1';
        pd_down <= '0';
      when "100" =>                     -- too slow
        pd_up   <= '1';
        pd_down <= '0';
      when "101" =>                     -- invalid
        pd_up   <= '1';
        pd_down <= '1';
      when "110" =>                     -- too fast
        pd_up   <= '0';
        pd_down <= '1';
      when "111" =>                     -- no transition
        pd_up   <= '0';
        pd_down <= '0';
      when others => null;
    end case;
  end process;


-- decodes the PD_GATE field from PCR register and generates the gating pulse
-- on gate_p.
  phase_gating_decode : process (hpll_pcr_pd_gate_i, gate_counter)
  begin
    case hpll_pcr_pd_gate_i is
      when "000"  => gate_p <= gate_counter(10);  -- gating: 1024
      when "001"  => gate_p <= gate_counter(11);  -- gating: 2048
      when "010"  => gate_p <= gate_counter(12);  -- gating: 4096
      when "011"  => gate_p <= gate_counter(13);  -- gating: 8192
      when "100"  => gate_p <= gate_counter(14);  -- gating: 16384
      when "101"  => gate_p <= gate_counter(15);  -- gating: 32768
      when "110"  => gate_p <= gate_counter(16);  -- gating: 65536
      when "111"  => gate_p <= gate_counter(17);  -- gating: 131072
      when others => null;
    end case;
  end process;

-- error counter: accumulates UP/DOWN pulses from the phase detector in
-- updown_counter. The counter value is outputted to ph_err when there's a
-- pulse on gate_p signal and then the accumulating counter is reset.

  count_updown : process(clk_fbck_i, rst_n_fbck_i)
  begin
    if rising_edge(clk_fbck_i) then
      if rst_n_fbck_i = '0' then
        ph_err         <= (others => '0');
        ph_sreg_delay  <= (others => '0');
        updown_counter <= (others => '0');
        gate_counter   <= to_unsigned(1, gate_counter'length);
      else
        if(gate_p = '1') then
-- got a gating pulse? output the new phase value
          gate_counter  <= to_unsigned(1, gate_counter'length);
          ph_sreg_delay <= (others => '1');

-- check if we have a up/down pulse during counter reset
          if(pd_up = '1' and pd_down = '0') then
            updown_counter <= to_signed(1, updown_counter'length);
          elsif (pd_up = '0' and pd_down = '1') then
            updown_counter <= to_signed(-1, updown_counter'length);
          else
            updown_counter <= (others => '0');
          end if;

          ph_err <= updown_counter;
        else
          gate_counter  <= gate_counter + 1;
          ph_sreg_delay <= '0' & ph_sreg_delay (ph_sreg_delay'length -1 downto 1);

-- count the PD detector pulses
          if(pd_up = '1' and pd_down = '0') then
            updown_counter <= updown_counter + 1;
          elsif (pd_up = '0' and pd_down = '1') then
            updown_counter <= updown_counter - 1;
          end if;
        end if;
      end if;
    end if;
  end process;





-- sync chain (from clk_fbck_i to clk_sys_i) for the new phase error pulse (ph_err_p).
  sync_ffs_phase_p : sync_ffs
    generic map (
      g_sync_edge => "positive")
    port map (
      clk_i    => clk_sys_i,
      rst_n_i  => rst_n_sysclk_i,
      data_i   => ph_sreg_delay(0),
      synced_o => open,
      npulse_o => open,
      ppulse_o => ph_err_p);

-- phase error clamping stuff:
  ph_err_sign      <= std_logic(ph_err(ph_err'length-1));
  ph_err_extrabits <= std_logic_vector(ph_err(ph_err'length-1 downto phase_err_o'length-1));

  ph_err_clamp_minus <= '1' when ph_err_sign = '1' and (ph_err_extrabits /= c_ONES(ph_err_extrabits'length-1 downto 0)) else '0';

  ph_err_clamp_plus <= '1' when ph_err_sign = '0' and (ph_err_extrabits /= c_ZEROS(ph_err_extrabits'length-1 downto 0)) else '0';

  error_output : process (clk_sys_i, rst_n_sysclk_i)
  begin  -- process
    if rising_edge(clk_sys_i) then
      if (rst_n_sysclk_i = '0') then
        ph_err_avg_slv <= (others => '0');
        ph_err_avg_p   <= '0';
      else

-- got new value of the phase error? output it with clamping:)
        if(ph_err_clamp_minus = '1') then
          ph_err_avg_slv <= '1' & c_ZEROS(phase_err_o'length-2 downto 0);
        elsif (ph_err_clamp_plus = '1') then
          ph_err_avg_slv <= '0' & c_ONES(phase_err_o'length-2 downto 0);
        else
          ph_err_avg_slv <= std_logic_vector(ph_err(phase_err_o'length-1 downto 0));
        end if;

        ph_err_avg_p <= ph_err_p;
        
      end if;
    end if;
  end process;


  phase_err_o       <= ph_err_avg_slv;
  phase_err_stb_p_o <= ph_err_avg_p;

-- drive the "debug" outputs  
  dbg_pd_down_o      <= pd_down;
  dbg_pd_up_o        <= pd_up;
  dbg_fbck_divided_o <= pd_in_fbck;
  dbg_ref_divided_o  <= pd_in_ref;
  
end rtl;

