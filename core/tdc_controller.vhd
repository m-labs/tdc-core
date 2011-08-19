-------------------------------------------------------------------------------
-- TDC Core / CERN
-------------------------------------------------------------------------------
--
-- unit name: tdc_controller
--
-- author: Sebastien Bourdeauducq, sebastien@milkymist.org
--
-- description: Controller
--
-- references: http://www.ohwr.org/projects/tdc-core
--
-------------------------------------------------------------------------------
-- last changes:
-- 2011-08-19 SB Created file
-------------------------------------------------------------------------------

-- Copyright (C) 2011 Sebastien Bourdeauducq

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.tdc_package.all;

entity tdc_controller is
    generic(
        g_RAW_COUNT      : positive;
        g_FP_COUNT       : positive;
        g_FCOUNTER_WIDTH : positive
    );
    port(
        clk_i       : in std_logic;
        reset_i     : in std_logic;
        ready_o     : out std_logic;

        next_o      : out std_logic;
        last_i      : in std_logic;
        calib_sel_o : out std_logic;
        
        lut_a_o     : out std_logic_vector(g_RAW_COUNT-1 downto 0);
        lut_we_o    : out std_logic;
        lut_d_o     : out std_logic_vector(g_FP_COUNT-1 downto 0);
        
        c_detect_i  : in std_logic;
        c_raw_i     : in std_logic_vector(g_RAW_COUNT-1 downto 0);
        his_a_o     : out std_logic_vector(g_RAW_COUNT-1 downto 0);
        his_we_o    : out std_logic;
        his_d_o     : out std_logic_vector(g_FP_COUNT-1 downto 0);
        his_d_i     : in std_logic_vector(g_FP_COUNT-1 downto 0);

        oc_start_o  : out std_logic;
        oc_ready_i  : in std_logic;
        oc_freq_i   : in std_logic_vector(g_FCOUNTER_WIDTH-1 downto 0);
        oc_store_o  : out std_logic;
        oc_sfreq_i  : in std_logic_vector(g_FCOUNTER_WIDTH-1 downto 0)
    );
end entity;

architecture rtl of tdc_controller is
begin
end architecture;
