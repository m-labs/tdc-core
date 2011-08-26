-------------------------------------------------------------------------------
-- TDC Core / CERN
-------------------------------------------------------------------------------
--
-- unit name: tb_controller
--
-- author: Sebastien Bourdeauducq, sebastien@milkymist.org
--
-- description: Test bench for the controller
--
-- references: http://www.ohwr.org/projects/tdc-core
--
-------------------------------------------------------------------------------
-- last changes:
-- 2011-08-26 SB Created file
-------------------------------------------------------------------------------

-- Copyright (C) 2011 Sebastien Bourdeauducq

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.tdc_package.all;

entity tb_controller is
    generic(
        g_RAW_COUNT      : positive := 9;
        g_FP_COUNT       : positive := 13;
        g_FCOUNTER_WIDTH : positive := 10
    );
end entity;

architecture tb of tb_controller is

signal clk        : std_logic;
signal reset      : std_logic;
signal ready      : std_logic;
signal cs_next    : std_logic;
signal cs_last    : std_logic;
signal calib_sel  : std_logic;
signal lut_a      : std_logic_vector(g_RAW_COUNT-1 downto 0);
signal lut_we     : std_logic;
signal lut_d_w    : std_logic_vector(g_FP_COUNT-1 downto 0);
signal c_detect   : std_logic;
signal c_raw      : std_logic_vector(g_RAW_COUNT-1 downto 0);
signal his_a      : std_logic_vector(g_RAW_COUNT-1 downto 0);
signal his_we     : std_logic;
signal his_d_w    : std_logic_vector(g_FP_COUNT-1 downto 0);
signal his_d_r    : std_logic_vector(g_FP_COUNT-1 downto 0);
signal oc_start   : std_logic;
signal oc_ready   : std_logic;
signal oc_freq    : std_logic_vector(g_FCOUNTER_WIDTH-1 downto 0);
signal oc_store   : std_logic;
signal oc_sfreq   : std_logic_vector(g_FCOUNTER_WIDTH-1 downto 0);
signal freeze_req : std_logic;
signal freeze_ack : std_logic;

signal end_simulation : boolean := false;

begin
    cmp_dut: tdc_controller
        generic map(
            g_RAW_COUNT      => g_RAW_COUNT,
            g_FP_COUNT       => g_FP_COUNT,
            g_FCOUNTER_WIDTH => g_FCOUNTER_WIDTH
        )
        port map(
            clk_i        => clk,
            reset_i      => reset,
            ready_o      => ready,
            next_o       => cs_next,
            last_i       => cs_last,
            calib_sel_o  => calib_sel,
            lut_a_o      => lut_a,
            lut_we_o     => lut_we,
            lut_d_o      => lut_d_w,
            c_detect_i   => c_detect,
            c_raw_i      => c_raw,
            his_a_o      => his_a,
            his_we_o     => his_we,
            his_d_o      => his_d_w,
            his_d_i      => his_d_r,
            oc_start_o   => oc_start,
            oc_ready_i   => oc_ready,
            oc_freq_i    => oc_freq,
            oc_store_o   => oc_store,
            oc_sfreq_i   => oc_sfreq,
            freeze_req_i => freeze_req,
            freeze_ack_o => freeze_ack
        );
    
    process
    begin
        clk <= '0';
        wait for 4 ns;
        clk <= '1';
        wait for 4 ns;
        if end_simulation then
            wait;
        end if;
    end process;
    
    process
    begin
        reset <= '1';
        wait until rising_edge(clk);
        reset <= '0';
        wait until rising_edge(clk);
        

        
        report "Test passed.";
        end_simulation <= true;
        wait;
    end process;
end architecture;
