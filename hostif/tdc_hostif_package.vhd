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
-- 2011-08-27 SB Reduced supported channel count to 8
-- 2011-08-25 SB Created file
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
-- This contains component declarations for all the modules of the TDC core
-- host interface.
-- It is used both internally to instantiate modules, and by the user to
-- instantiate the top-level "tdc_hostif" module.

library ieee;
use ieee.std_logic_1164.all;

package tdc_hostif_package is

component tdc_hostif is
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
end component;

component tdc_wb is
  port (
    rst_n_i                                  : in     std_logic;
    wb_clk_i                                 : in     std_logic;
    wb_addr_i                                : in     std_logic_vector(5 downto 0);
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
-- Port for std_logic_vector field: 'Value' in reg: 'Detected polarities'
    tdc_pol_i                                : in     std_logic_vector(7 downto 0);
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
    irq_ie0_i                                : in     std_logic;
    irq_ie1_i                                : in     std_logic;
    irq_ie2_i                                : in     std_logic;
    irq_ie3_i                                : in     std_logic;
    irq_ie4_i                                : in     std_logic;
    irq_ie5_i                                : in     std_logic;
    irq_ie6_i                                : in     std_logic;
    irq_ie7_i                                : in     std_logic;
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
