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

-- DESCRIPTION:
-- This test verifies the correct operation of the controller in the following
-- scenario:
-- 1. The test bench resets the controller, which begins to perform startup
-- calibration operations.
-- 2. The test bench sends a series of pulses with incrementing fine time
-- stamps into the controller.
-- 3. The test bench provides a model of the histogram memory to the
-- controller. Because of the continuously incrementing time stamps provided by
-- the test bench, the controller books a histogram with the same
-- 2^(g_FP_COUNT-g_RAW_COUNT) value everywhere.
-- 4. The controller reads the frequency of the calibration ring oscillator,
-- and the test bench returns 1.
-- 5. The controller performs a first round of online calibration. It reads
-- again the frequency of the ring oscillator, and the test bench returns 2.
-- This means that all delays should be halved.
-- 6. The controller builds the LUT. The test bench provides a model of the
-- memory for this purpose.
-- 7. The controller asserts the ready signal, and this terminates the
-- simulation.
--
-- The test bench then verifies that the LUT entries from i = 1 to 
-- i = 2^g_RAW_COUNT-1 all have the correct value, and reports a failed
-- assertion otherwise:
-- LUT(i) = 1/2 * (i-1) * 2^(g_FP_COUNT-g_RAW_COUNT)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.tdc_package.all;

entity tb_controller is
    generic(
        g_RAW_COUNT      : positive := 3;
        g_FP_COUNT       : positive := 5;
        g_FCOUNTER_WIDTH : positive := 3
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
signal c_raw      : std_logic_vector(g_RAW_COUNT-1 downto 0) := (others => '0');
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

type t_ctlmem is array(0 to 2**g_RAW_COUNT-1) of std_logic_vector(g_FP_COUNT-1 downto 0);
signal his_memory: t_ctlmem;
signal lut_memory: t_ctlmem;

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
    
    -- clock generator
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
    
    -- histogram memory
    process(clk)
    begin
        if rising_edge(clk) then
            if his_we = '1' then
                report "HIS WR: addr=" & integer'image(to_integer(unsigned(his_a)))
                    & " data=" & integer'image(to_integer(unsigned(his_d_w)));
                his_memory(to_integer(unsigned(his_a))) <= his_d_w;
            end if;
            his_d_r <= his_memory(to_integer(unsigned(his_a)));
        end if;
    end process;
    
    -- LUT memory
    process(clk)
    begin
        if rising_edge(clk) then
            if lut_we = '1' then
                report "LUT WR: addr=" & integer'image(to_integer(unsigned(lut_a)))
                    & " data=" & integer'image(to_integer(unsigned(lut_d_w)));
                lut_memory(to_integer(unsigned(lut_a))) <= lut_d_w;
            end if;
        end if;
    end process;
    
    -- pulse generator
    process
    begin
        c_detect <= '1';
        c_raw <= std_logic_vector(unsigned(c_raw) + 1);
        wait until rising_edge(clk);
        c_detect <= '0';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
    end process;
    
    -- frequency counter
    process(clk)
    begin
        if rising_edge(clk) then
            oc_ready <= '1';
            if oc_start = '1' then
                report "FRC: start measurement";
                oc_ready <= '0';
            end if;
            if oc_store = '1' then
                report "FRC: store measurement";
            end if;
        end if;
    end process;
    -- this should divide by 2.
    oc_freq <= (1 => '1', others => '0');
    oc_sfreq <= (0 => '1', others => '0');

    -- channel mux
    process(clk)
    begin
        if rising_edge(clk) then
            if cs_next = '1' then
                report "Next channel";
            end if;
        end if;
    end process;
    cs_last <= '1';
    
    process
    variable v_bin_width: integer;
    variable v_step: integer;
    begin
        reset <= '1';
        wait until rising_edge(clk);
        reset <= '0';
        wait until rising_edge(clk);
        
        wait until ready = '1';
        
        -- verify written LUT contents
        v_bin_width := 2**(g_FP_COUNT-g_RAW_COUNT);
        v_step := v_bin_width/2; -- divided by 2 by online calibration (see frequencies above)
        for i in 1 to 2**g_RAW_COUNT-1 loop
            assert to_integer(unsigned(lut_memory(i))) = v_step*(i-1) severity failure;
        end loop;
        
        report "Test passed.";
        end_simulation <= true;
        wait;
    end process;
end architecture;
