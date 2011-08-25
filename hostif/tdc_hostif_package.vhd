-------------------------------------------------------------------------------
-- TDC Core / CERN
-------------------------------------------------------------------------------
--
-- unit name: tdc_hostif_package
--
-- author: Sebastien Bourdeauducq, sebastien@milkymist.org
--
-- description: Component declarations for the TDC core host interface
--
-- references: http://www.ohwr.org/projects/tdc-core
--
-------------------------------------------------------------------------------
-- last changes:
-- 2011-08-25 SB Created file
-------------------------------------------------------------------------------

-- Copyright (C) 2011 Sebastien Bourdeauducq

library ieee;
use ieee.std_logic_1164.all;

package tdc_hostif_package is

component tdc_wb is
  port (
    rst_n_i                                  : in     std_logic;
    wb_clk_i                                 : in     std_logic;
    wb_addr_i                                : in     std_logic_vector(7 downto 0);
    wb_data_i                                : in     std_logic_vector(31 downto 0);
    wb_data_o                                : out    std_logic_vector(31 downto 0);
    wb_cyc_i                                 : in     std_logic;
    wb_sel_i                                 : in     std_logic_vector(3 downto 0);
    wb_stb_i                                 : in     std_logic;
    wb_we_i                                  : in     std_logic;
    wb_ack_o                                 : out    std_logic;
    wb_irq_o                                 : out    std_logic;
-- Port for MONOSTABLE field: 'Reset' in reg: 'Control and status'
    tdc_cs_rst_o                             : out    std_logic;
-- Port for BIT field: 'Ready' in reg: 'Control and status'
    tdc_cs_rdy_i                             : in     std_logic;
-- Port for std_logic_vector field: 'High word value' in reg: 'Deskew value for channel 0 (high word)'
    tdc_desh0_o                              : out    std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Low word value' in reg: 'Deskew value for channel 0 (low word)'
    tdc_desl0_o                              : out    std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'High word value' in reg: 'Deskew value for channel 1 (high word)'
    tdc_desh1_o                              : out    std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Low word value' in reg: 'Deskew value for channel 1 (low word)'
    tdc_desl1_o                              : out    std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'High word value' in reg: 'Deskew value for channel 2 (high word)'
    tdc_desh2_o                              : out    std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Low word value' in reg: 'Deskew value for channel 2 (low word)'
    tdc_desl2_o                              : out    std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'High word value' in reg: 'Deskew value for channel 3 (high word)'
    tdc_desh3_o                              : out    std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Low word value' in reg: 'Deskew value for channel 3 (low word)'
    tdc_desl3_o                              : out    std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'High word value' in reg: 'Deskew value for channel 4 (high word)'
    tdc_desh4_o                              : out    std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Low word value' in reg: 'Deskew value for channel 4 (low word)'
    tdc_desl4_o                              : out    std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'High word value' in reg: 'Deskew value for channel 5 (high word)'
    tdc_desh5_o                              : out    std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Low word value' in reg: 'Deskew value for channel 5 (low word)'
    tdc_desl5_o                              : out    std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'High word value' in reg: 'Deskew value for channel 6 (high word)'
    tdc_desh6_o                              : out    std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Low word value' in reg: 'Deskew value for channel 6 (low word)'
    tdc_desl6_o                              : out    std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'High word value' in reg: 'Deskew value for channel 7 (high word)'
    tdc_desh7_o                              : out    std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Low word value' in reg: 'Deskew value for channel 7 (low word)'
    tdc_desl7_o                              : out    std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'High word value' in reg: 'Deskew value for channel 8 (high word)'
    tdc_desh8_o                              : out    std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Low word value' in reg: 'Deskew value for channel 8 (low word)'
    tdc_desl8_o                              : out    std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'High word value' in reg: 'Deskew value for channel 9 (high word)'
    tdc_desh9_o                              : out    std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Low word value' in reg: 'Deskew value for channel 9 (low word)'
    tdc_desl9_o                              : out    std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'High word value' in reg: 'Deskew value for channel 10 (high word)'
    tdc_desh10_o                             : out    std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Low word value' in reg: 'Deskew value for channel 10 (low word)'
    tdc_desl10_o                             : out    std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'High word value' in reg: 'Deskew value for channel 11 (high word)'
    tdc_desh11_o                             : out    std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Low word value' in reg: 'Deskew value for channel 11 (low word)'
    tdc_desl11_o                             : out    std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'High word value' in reg: 'Deskew value for channel 12 (high word)'
    tdc_desh12_o                             : out    std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Low word value' in reg: 'Deskew value for channel 12 (low word)'
    tdc_desl12_o                             : out    std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'High word value' in reg: 'Deskew value for channel 13 (high word)'
    tdc_desh13_o                             : out    std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Low word value' in reg: 'Deskew value for channel 13 (low word)'
    tdc_desl13_o                             : out    std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'High word value' in reg: 'Deskew value for channel 14 (high word)'
    tdc_desh14_o                             : out    std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Low word value' in reg: 'Deskew value for channel 14 (low word)'
    tdc_desl14_o                             : out    std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'High word value' in reg: 'Deskew value for channel 15 (high word)'
    tdc_desh15_o                             : out    std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Low word value' in reg: 'Deskew value for channel 15 (low word)'
    tdc_desl15_o                             : out    std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'High word value' in reg: 'Deskew value for channel 16 (high word)'
    tdc_desh16_o                             : out    std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Low word value' in reg: 'Deskew value for channel 16 (low word)'
    tdc_desl16_o                             : out    std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'High word value' in reg: 'Deskew value for channel 17 (high word)'
    tdc_desh17_o                             : out    std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Low word value' in reg: 'Deskew value for channel 17 (low word)'
    tdc_desl17_o                             : out    std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'High word value' in reg: 'Deskew value for channel 18 (high word)'
    tdc_desh18_o                             : out    std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Low word value' in reg: 'Deskew value for channel 18 (low word)'
    tdc_desl18_o                             : out    std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'High word value' in reg: 'Deskew value for channel 19 (high word)'
    tdc_desh19_o                             : out    std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Low word value' in reg: 'Deskew value for channel 19 (low word)'
    tdc_desl19_o                             : out    std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'High word value' in reg: 'Deskew value for channel 20 (high word)'
    tdc_desh20_o                             : out    std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Low word value' in reg: 'Deskew value for channel 20 (low word)'
    tdc_desl20_o                             : out    std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'High word value' in reg: 'Deskew value for channel 21 (high word)'
    tdc_desh21_o                             : out    std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Low word value' in reg: 'Deskew value for channel 21 (low word)'
    tdc_desl21_o                             : out    std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'High word value' in reg: 'Deskew value for channel 22 (high word)'
    tdc_desh22_o                             : out    std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Low word value' in reg: 'Deskew value for channel 22 (low word)'
    tdc_desl22_o                             : out    std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'High word value' in reg: 'Deskew value for channel 23 (high word)'
    tdc_desh23_o                             : out    std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Low word value' in reg: 'Deskew value for channel 23 (low word)'
    tdc_desl23_o                             : out    std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'High word value' in reg: 'Deskew value for channel 24 (high word)'
    tdc_desh24_o                             : out    std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Low word value' in reg: 'Deskew value for channel 24 (low word)'
    tdc_desl24_o                             : out    std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'High word value' in reg: 'Deskew value for channel 25 (high word)'
    tdc_desh25_o                             : out    std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Low word value' in reg: 'Deskew value for channel 25 (low word)'
    tdc_desl25_o                             : out    std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'High word value' in reg: 'Deskew value for channel 26 (high word)'
    tdc_desh26_o                             : out    std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Low word value' in reg: 'Deskew value for channel 26 (low word)'
    tdc_desl26_o                             : out    std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'High word value' in reg: 'Deskew value for channel 27 (high word)'
    tdc_desh27_o                             : out    std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Low word value' in reg: 'Deskew value for channel 27 (low word)'
    tdc_desl27_o                             : out    std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'High word value' in reg: 'Deskew value for channel 28 (high word)'
    tdc_desh28_o                             : out    std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Low word value' in reg: 'Deskew value for channel 28 (low word)'
    tdc_desl28_o                             : out    std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'High word value' in reg: 'Deskew value for channel 29 (high word)'
    tdc_desh29_o                             : out    std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Low word value' in reg: 'Deskew value for channel 29 (low word)'
    tdc_desl29_o                             : out    std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Value' in reg: 'Detected polarities'
    tdc_pol_i                                : in     std_logic_vector(29 downto 0);
-- Port for std_logic_vector field: 'Value' in reg: 'Raw measured value for channel 0'
    tdc_raw0_i                               : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'High word value' in reg: 'Fixed point measurement for channel 0 (high word)'
    tdc_mesh0_i                              : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Low word value' in reg: 'Fixed point measurement for channel 0 (low word)'
    tdc_mesl0_i                              : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Value' in reg: 'Raw measured value for channel 1'
    tdc_raw1_i                               : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'High word value' in reg: 'Fixed point measurement for channel 1 (high word)'
    tdc_mesh1_i                              : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Low word value' in reg: 'Fixed point measurement for channel 1 (low word)'
    tdc_mesl1_i                              : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Value' in reg: 'Raw measured value for channel 2'
    tdc_raw2_i                               : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'High word value' in reg: 'Fixed point measurement for channel 2 (high word)'
    tdc_mesh2_i                              : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Low word value' in reg: 'Fixed point measurement for channel 2 (low word)'
    tdc_mesl2_i                              : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Value' in reg: 'Raw measured value for channel 3'
    tdc_raw3_i                               : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'High word value' in reg: 'Fixed point measurement for channel 3 (high word)'
    tdc_mesh3_i                              : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Low word value' in reg: 'Fixed point measurement for channel 3 (low word)'
    tdc_mesl3_i                              : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Value' in reg: 'Raw measured value for channel 4'
    tdc_raw4_i                               : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'High word value' in reg: 'Fixed point measurement for channel 4 (high word)'
    tdc_mesh4_i                              : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Low word value' in reg: 'Fixed point measurement for channel 4 (low word)'
    tdc_mesl4_i                              : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Value' in reg: 'Raw measured value for channel 5'
    tdc_raw5_i                               : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'High word value' in reg: 'Fixed point measurement for channel 5 (high word)'
    tdc_mesh5_i                              : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Low word value' in reg: 'Fixed point measurement for channel 5 (low word)'
    tdc_mesl5_i                              : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Value' in reg: 'Raw measured value for channel 6'
    tdc_raw6_i                               : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'High word value' in reg: 'Fixed point measurement for channel 6 (high word)'
    tdc_mesh6_i                              : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Low word value' in reg: 'Fixed point measurement for channel 6 (low word)'
    tdc_mesl6_i                              : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Value' in reg: 'Raw measured value for channel 7'
    tdc_raw7_i                               : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'High word value' in reg: 'Fixed point measurement for channel 7 (high word)'
    tdc_mesh7_i                              : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Low word value' in reg: 'Fixed point measurement for channel 7 (low word)'
    tdc_mesl7_i                              : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Value' in reg: 'Raw measured value for channel 8'
    tdc_raw8_i                               : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'High word value' in reg: 'Fixed point measurement for channel 8 (high word)'
    tdc_mesh8_i                              : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Low word value' in reg: 'Fixed point measurement for channel 8 (low word)'
    tdc_mesl8_i                              : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Value' in reg: 'Raw measured value for channel 9'
    tdc_raw9_i                               : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'High word value' in reg: 'Fixed point measurement for channel 9 (high word)'
    tdc_mesh9_i                              : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Low word value' in reg: 'Fixed point measurement for channel 9 (low word)'
    tdc_mesl9_i                              : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Value' in reg: 'Raw measured value for channel 10'
    tdc_raw10_i                              : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'High word value' in reg: 'Fixed point measurement for channel 10 (high word)'
    tdc_mesh10_i                             : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Low word value' in reg: 'Fixed point measurement for channel 10 (low word)'
    tdc_mesl10_i                             : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Value' in reg: 'Raw measured value for channel 11'
    tdc_raw11_i                              : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'High word value' in reg: 'Fixed point measurement for channel 11 (high word)'
    tdc_mesh11_i                             : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Low word value' in reg: 'Fixed point measurement for channel 11 (low word)'
    tdc_mesl11_i                             : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Value' in reg: 'Raw measured value for channel 12'
    tdc_raw12_i                              : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'High word value' in reg: 'Fixed point measurement for channel 12 (high word)'
    tdc_mesh12_i                             : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Low word value' in reg: 'Fixed point measurement for channel 12 (low word)'
    tdc_mesl12_i                             : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Value' in reg: 'Raw measured value for channel 13'
    tdc_raw13_i                              : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'High word value' in reg: 'Fixed point measurement for channel 13 (high word)'
    tdc_mesh13_i                             : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Low word value' in reg: 'Fixed point measurement for channel 13 (low word)'
    tdc_mesl13_i                             : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Value' in reg: 'Raw measured value for channel 14'
    tdc_raw14_i                              : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'High word value' in reg: 'Fixed point measurement for channel 14 (high word)'
    tdc_mesh14_i                             : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Low word value' in reg: 'Fixed point measurement for channel 14 (low word)'
    tdc_mesl14_i                             : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Value' in reg: 'Raw measured value for channel 15'
    tdc_raw15_i                              : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'High word value' in reg: 'Fixed point measurement for channel 15 (high word)'
    tdc_mesh15_i                             : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Low word value' in reg: 'Fixed point measurement for channel 15 (low word)'
    tdc_mesl15_i                             : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Value' in reg: 'Raw measured value for channel 16'
    tdc_raw16_i                              : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'High word value' in reg: 'Fixed point measurement for channel 16 (high word)'
    tdc_mesh16_i                             : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Low word value' in reg: 'Fixed point measurement for channel 16 (low word)'
    tdc_mesl16_i                             : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Value' in reg: 'Raw measured value for channel 17'
    tdc_raw17_i                              : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'High word value' in reg: 'Fixed point measurement for channel 17 (high word)'
    tdc_mesh17_i                             : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Low word value' in reg: 'Fixed point measurement for channel 17 (low word)'
    tdc_mesl17_i                             : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Value' in reg: 'Raw measured value for channel 18'
    tdc_raw18_i                              : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'High word value' in reg: 'Fixed point measurement for channel 18 (high word)'
    tdc_mesh18_i                             : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Low word value' in reg: 'Fixed point measurement for channel 18 (low word)'
    tdc_mesl18_i                             : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Value' in reg: 'Raw measured value for channel 19'
    tdc_raw19_i                              : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'High word value' in reg: 'Fixed point measurement for channel 19 (high word)'
    tdc_mesh19_i                             : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Low word value' in reg: 'Fixed point measurement for channel 19 (low word)'
    tdc_mesl19_i                             : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Value' in reg: 'Raw measured value for channel 20'
    tdc_raw20_i                              : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'High word value' in reg: 'Fixed point measurement for channel 20 (high word)'
    tdc_mesh20_i                             : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Low word value' in reg: 'Fixed point measurement for channel 20 (low word)'
    tdc_mesl20_i                             : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Value' in reg: 'Raw measured value for channel 21'
    tdc_raw21_i                              : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'High word value' in reg: 'Fixed point measurement for channel 21 (high word)'
    tdc_mesh21_i                             : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Low word value' in reg: 'Fixed point measurement for channel 21 (low word)'
    tdc_mesl21_i                             : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Value' in reg: 'Raw measured value for channel 22'
    tdc_raw22_i                              : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'High word value' in reg: 'Fixed point measurement for channel 22 (high word)'
    tdc_mesh22_i                             : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Low word value' in reg: 'Fixed point measurement for channel 22 (low word)'
    tdc_mesl22_i                             : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Value' in reg: 'Raw measured value for channel 23'
    tdc_raw23_i                              : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'High word value' in reg: 'Fixed point measurement for channel 23 (high word)'
    tdc_mesh23_i                             : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Low word value' in reg: 'Fixed point measurement for channel 23 (low word)'
    tdc_mesl23_i                             : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Value' in reg: 'Raw measured value for channel 24'
    tdc_raw24_i                              : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'High word value' in reg: 'Fixed point measurement for channel 24 (high word)'
    tdc_mesh24_i                             : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Low word value' in reg: 'Fixed point measurement for channel 24 (low word)'
    tdc_mesl24_i                             : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Value' in reg: 'Raw measured value for channel 25'
    tdc_raw25_i                              : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'High word value' in reg: 'Fixed point measurement for channel 25 (high word)'
    tdc_mesh25_i                             : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Low word value' in reg: 'Fixed point measurement for channel 25 (low word)'
    tdc_mesl25_i                             : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Value' in reg: 'Raw measured value for channel 26'
    tdc_raw26_i                              : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'High word value' in reg: 'Fixed point measurement for channel 26 (high word)'
    tdc_mesh26_i                             : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Low word value' in reg: 'Fixed point measurement for channel 26 (low word)'
    tdc_mesl26_i                             : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Value' in reg: 'Raw measured value for channel 27'
    tdc_raw27_i                              : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'High word value' in reg: 'Fixed point measurement for channel 27 (high word)'
    tdc_mesh27_i                             : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Low word value' in reg: 'Fixed point measurement for channel 27 (low word)'
    tdc_mesl27_i                             : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Value' in reg: 'Raw measured value for channel 28'
    tdc_raw28_i                              : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'High word value' in reg: 'Fixed point measurement for channel 28 (high word)'
    tdc_mesh28_i                             : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Low word value' in reg: 'Fixed point measurement for channel 28 (low word)'
    tdc_mesl28_i                             : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Value' in reg: 'Raw measured value for channel 29'
    tdc_raw29_i                              : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'High word value' in reg: 'Fixed point measurement for channel 29 (high word)'
    tdc_mesh29_i                             : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Low word value' in reg: 'Fixed point measurement for channel 29 (low word)'
    tdc_mesl29_i                             : in     std_logic_vector(31 downto 0);
    irq_ie0_i                                : in     std_logic;
    irq_ie1_i                                : in     std_logic;
    irq_ie2_i                                : in     std_logic;
    irq_ie3_i                                : in     std_logic;
    irq_ie4_i                                : in     std_logic;
    irq_ie5_i                                : in     std_logic;
    irq_ie6_i                                : in     std_logic;
    irq_ie7_i                                : in     std_logic;
    irq_ie8_i                                : in     std_logic;
    irq_ie9_i                                : in     std_logic;
    irq_ie10_i                               : in     std_logic;
    irq_ie11_i                               : in     std_logic;
    irq_ie12_i                               : in     std_logic;
    irq_ie13_i                               : in     std_logic;
    irq_ie14_i                               : in     std_logic;
    irq_ie15_i                               : in     std_logic;
    irq_ie16_i                               : in     std_logic;
    irq_ie17_i                               : in     std_logic;
    irq_ie18_i                               : in     std_logic;
    irq_ie19_i                               : in     std_logic;
    irq_ie20_i                               : in     std_logic;
    irq_ie21_i                               : in     std_logic;
    irq_ie22_i                               : in     std_logic;
    irq_ie23_i                               : in     std_logic;
    irq_ie24_i                               : in     std_logic;
    irq_ie25_i                               : in     std_logic;
    irq_ie26_i                               : in     std_logic;
    irq_ie27_i                               : in     std_logic;
    irq_ie28_i                               : in     std_logic;
    irq_ie29_i                               : in     std_logic;
    irq_isc_i                                : in     std_logic;
    irq_icc_i                                : in     std_logic;
-- Port for BIT field: 'Freeze request' in reg: 'Debug control'
    tdc_dctl_req_o                           : out    std_logic;
-- Port for BIT field: 'Freeze acknowledgement' in reg: 'Debug control'
    tdc_dctl_ack_i                           : in     std_logic;
-- Port for MONOSTABLE field: 'Switch to next channel' in reg: 'Channel selection'
    tdc_csel_next_o                          : out    std_logic;
-- Port for BIT field: 'Last channel reached' in reg: 'Channel selection'
    tdc_csel_last_i                          : in     std_logic;
-- Port for BIT field: 'Calibration signal select' in reg: 'Calibration signal selection'
    tdc_cal_o                                : out    std_logic;
-- Port for std_logic_vector field: 'Address' in reg: 'LUT read address'
    tdc_luta_o                               : out    std_logic_vector(15 downto 0);
-- Port for std_logic_vector field: 'Data' in reg: 'LUT read data'
    tdc_lutd_i                               : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Address' in reg: 'Histogram read address'
    tdc_hisa_o                               : out    std_logic_vector(15 downto 0);
-- Port for std_logic_vector field: 'Data' in reg: 'Histogram read data'
    tdc_hisd_i                               : in     std_logic_vector(31 downto 0);
-- Port for MONOSTABLE field: 'Measurement start' in reg: 'Frequency counter control and status'
    tdc_fcc_st_o                             : out    std_logic;
-- Port for BIT field: 'Measurement ready' in reg: 'Frequency counter control and status'
    tdc_fcc_rdy_i                            : in     std_logic;
-- Port for std_logic_vector field: 'Result' in reg: 'Frequency counter current value'
    tdc_fcr_i                                : in     std_logic_vector(31 downto 0);
-- Port for std_logic_vector field: 'Result' in reg: 'Frequency counter stored value'
    tdc_fcsr_i                               : in     std_logic_vector(31 downto 0)
  );
end component;

end package;
