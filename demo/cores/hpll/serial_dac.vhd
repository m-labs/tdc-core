-------------------------------------------------------------------------------
-- Title      : Serial DAC interface
-- Project    : White Rabbit Switch
-------------------------------------------------------------------------------
-- File       : serial_dac.vhd
-- Author     : paas, slayer
-- Company    : CERN BE-Co-HT
-- Created    : 2010-02-25
-- Last update: 2010-06-21
-- Platform   : fpga-generic
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: The dac unit provides an interface to a 16 bit serial Digita to Analogue converter (max5441, SPI?/QSPI?/MICROWIRE? compatible) 
--
-------------------------------------------------------------------------------
-- Copyright (c) 2010 CERN
-------------------------------------------------------------------------------
-- Revisions  :1
-- Date        Version  Author  Description
-- 2009-01-24  1.0      paas    Created
-- 2010-02-25  1.1      slayer  Modified for rev 1.1 switch
-------------------------------------------------------------------------------


library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


entity serial_dac is

  generic (
    g_num_data_bits  : integer := 16;
    g_num_extra_bits : integer := 8
    );

  port (
-- clock & reset
    clk_i   : in std_logic;
    rst_n_i : in std_logic;

-- channel 1 value and value load strobe
    value1_i     : in std_logic_vector(g_num_data_bits-1 downto 0);
    value1_stb_i : in std_logic;

-- channel 2 value and value load strobe
    value2_i     : in std_logic_vector(g_num_data_bits-1 downto 0);
    value2_stb_i : in std_logic;

-- channel select: 0 = channel 1, 1 = channel 2
    driver_sel_i  : in std_logic;

-- SCLK divider: 000 = clk_i/8 ... 111 = clk_i/1024
    sclk_divsel_i : in std_logic_vector(2 downto 0);

-- DAC I/F
    dac_cs_n_o  : out std_logic;
    dac_sclk_o  : out std_logic;
    dac_sdata_o : out std_logic
    );
end serial_dac;


architecture syn of serial_dac is

  signal divider        : unsigned(11 downto 0);
  signal dataSh         : std_logic_vector(g_num_data_bits + g_num_extra_bits-1 downto 0);
  signal bitCounter     : std_logic_vector(g_num_data_bits + g_num_extra_bits+1 downto 0);
  signal endSendingData : std_logic;
  signal sendingData    : std_logic;
  signal iDacClk        : std_logic;
  signal iValidValue    : std_logic;

  signal divider_muxed : std_logic;
begin

  select_divider : process (divider, sclk_divsel_i)
  begin  -- process
    case sclk_divsel_i is
      when "000"  => divider_muxed <= divider(1);  -- sclk = clk_i/8
      when "001"  => divider_muxed <= divider(2);  -- sclk = clk_i/16
      when "010"  => divider_muxed <= divider(3);  -- sclk = clk_i/32
      when "011"  => divider_muxed <= divider(4);  -- sclk = clk_i/64
      when "100"  => divider_muxed <= divider(5);  -- sclk = clk_i/128
      when "101"  => divider_muxed <= divider(6);  -- sclk = clk_i/256
      when "110"  => divider_muxed <= divider(7);  -- sclk = clk_i/512
      when "111"  => divider_muxed <= divider(8);  -- sclk = clk_i/1024
      when others => null;
    end case;
  end process;


  iValidValue <= value1_stb_i when driver_sel_i = '0' else value2_stb_i;

  process(clk_i, rst_n_i)
  begin
    if rst_n_i = '0' then
      sendingData <= '0';
    elsif rising_edge(clk_i) then
      if iValidValue = '1' and sendingData = '0' then
        sendingData <= '1';
      elsif endSendingData = '1' then
        sendingData <= '0';
      end if;
    end if;
  end process;

  process(clk_i)
  begin
    if rising_edge(clk_i) then
      if iValidValue = '1' then
        divider <= (others => '0');
      elsif sendingData = '1' then
        if(divider_muxed = '1') then
          divider <= (others => '0');
        else
          divider <= divider + 1;
        end if;
      elsif endSendingData = '1' then
        divider <= (others => '0');
      end if;
    end if;
  end process;


  process(clk_i, rst_n_i)
  begin
    if rst_n_i = '0' then
      iDacClk <= '1';                   -- 0
    elsif rising_edge(clk_i) then
      if iValidValue = '1' then
        iDacClk <= '1';                 -- 0
      elsif divider_muxed = '1' then
        iDacClk <= not(iDacClk);
      elsif endSendingData = '1' then
        iDacClk <= '1';                 -- 0
      end if;
    end if;
  end process;

  process(clk_i, rst_n_i)
  begin
    if rst_n_i = '0' then
      dataSh <= (others => '0');
    elsif rising_edge(clk_i) then
      if iValidValue = '1' and sendingData = '0' then
        if driver_sel_i = '1' then
          dataSh <= std_logic_vector(to_unsigned(0, g_num_extra_bits)) & value2_i;
        else
          dataSh <= std_logic_vector(to_unsigned(0, g_num_extra_bits)) & value1_i;
        end if;
      elsif sendingData = '1' and divider_muxed = '1' and iDacClk = '0' then
        dataSh(0)                    <= dataSh(dataSh'left);
        dataSh(dataSh'left downto 1) <= dataSh(dataSh'left - 1 downto 0);
      end if;
    end if;
  end process;

  process(clk_i)
  begin
    if rising_edge(clk_i) then
      if iValidValue = '1' and sendingData = '0' then
        bitCounter(0)                        <= '1';
        bitCounter(bitCounter'left downto 1) <= (others => '0');
      elsif sendingData = '1' and to_integer(divider) = 0 and iDacClk = '1' then
        bitCounter(0)                        <= '0';
        bitCounter(bitCounter'left downto 1) <= bitCounter(bitCounter'left - 1 downto 0);
      end if;
    end if;
  end process;

  endSendingData <= bitCounter(bitCounter'left);

  dac_sdata_o <= dataSh(dataSh'left);
  dac_cs_n_o  <= not(sendingData);
  dac_sclk_o  <= iDacClk;


end syn;
