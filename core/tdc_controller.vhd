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
-- This is the controller for the channel bank. It is in charge of sequencing
-- and performing the startup and online calibrations for all channels.
-- It books the histograms and computes and loads the LUTs of the channels.

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
        clk_i        : in std_logic;
        reset_i      : in std_logic;
        ready_o      : out std_logic;

        next_o       : out std_logic;
        last_i       : in std_logic;
        calib_sel_o  : out std_logic;
        
        lut_a_o      : out std_logic_vector(g_RAW_COUNT-1 downto 0);
        lut_we_o     : out std_logic;
        lut_d_o      : out std_logic_vector(g_FP_COUNT-1 downto 0);
        
        c_detect_i   : in std_logic;
        c_raw_i      : in std_logic_vector(g_RAW_COUNT-1 downto 0);
        his_a_o      : out std_logic_vector(g_RAW_COUNT-1 downto 0);
        his_we_o     : out std_logic;
        his_d_o      : out std_logic_vector(g_FP_COUNT-1 downto 0);
        his_d_i      : in std_logic_vector(g_FP_COUNT-1 downto 0);

        oc_start_o   : out std_logic;
        oc_ready_i   : in std_logic;
        oc_freq_i    : in std_logic_vector(g_FCOUNTER_WIDTH-1 downto 0);
        oc_store_o   : out std_logic;
        oc_sfreq_i   : in std_logic_vector(g_FCOUNTER_WIDTH-1 downto 0);
        
        freeze_req_i : in std_logic;
        freeze_ack_o : out std_logic
    );
end entity;

architecture rtl of tdc_controller is

signal ready_p: std_logic;

signal hc_count : std_logic_vector(g_FP_COUNT-1 downto 0);
signal hc_reset : std_logic;
signal hc_dec   : std_logic;
signal hc_zero  : std_logic;

signal ha_count : std_logic_vector(g_RAW_COUNT-1 downto 0);
signal ha_reset : std_logic;
signal ha_inc   : std_logic;
signal ha_last  : std_logic;
signal ha_sel   : std_logic;

signal acc       : std_logic_vector(g_FP_COUNT-1 downto 0);
signal acc_reset : std_logic;
signal acc_en    : std_logic;

signal mul       : std_logic_vector(g_FP_COUNT+g_FCOUNTER_WIDTH-1 downto 0);
signal mul_d1    : std_logic_vector(g_FP_COUNT+g_FCOUNTER_WIDTH-1 downto 0);

signal div_start    : std_logic;
signal div_ready    : std_logic;
signal div_divisor  : std_logic_vector(g_FP_COUNT+g_FCOUNTER_WIDTH-1 downto 0);
signal div_quotient : std_logic_vector(g_FP_COUNT+g_FCOUNTER_WIDTH-1 downto 0);
signal div_qsat     : std_logic_vector(g_FP_COUNT-1 downto 0);

type t_state is (
        -- startup calibration
        SC_NEWCHANNEL, SC_CLEARHIST, SC_READ, SC_UPDATE, SC_STOREF0,
        -- online calibration
        OC_STARTM, OC_WAITM, OC_WAITMUL1, OC_WAITMUL2, OC_STARTDIV, OC_WAITDIV, OC_WRITELUT, OC_NEXTCHANNEL,
        -- freeze state (transfer control to debug interface)
        FREEZE
    );
signal state: t_state;

begin
    -- generate ready signal
    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                ready_o <= '0';
            else
                if ready_p = '1' then
                    ready_o <= '1';
                end if;
            end if;
        end if;
    end process;
    
    -- count histogram entries when recording
    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if hc_reset = '1' then
                hc_count <= (hc_count'range => '1');
            elsif hc_dec = '1' then
                hc_count <= std_logic_vector(unsigned(hc_count) - 1);
            end if;
        end if;
    end process;
    hc_zero <= '1' when (hc_count = (hc_count'range => '0')) else '0';
    
    -- generate histogram memory address and write data
    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if ha_reset = '1' then
                ha_count <= (ha_count'range => '0');
            elsif ha_inc = '1' then
                ha_count <= std_logic_vector(unsigned(ha_count) + 1);
            end if;
        end if;
    end process;
    ha_last <= '1' when (ha_count = (ha_count'range => '1')) else '0';
    his_a_o <= ha_count when (ha_sel = '1') else c_raw_i;
    his_d_o <= (his_d_o'range => '0') when (ha_sel = '1')
        else std_logic_vector(unsigned(his_d_i) + 1);
    
    -- accumulator
    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if acc_reset = '1' then
                acc <= (acc'range => '0');
            elsif acc_en = '1' then
                acc <= std_logic_vector(unsigned(acc) + unsigned(his_d_i));
            end if;
        end if;
    end process;
    
    -- multiplier
    process(clk_i)
    begin
        if rising_edge(clk_i) then
            mul <= std_logic_vector(unsigned(acc) * unsigned(oc_sfreq_i));
            mul_d1 <= mul;
        end if;
    end process;
    
    -- divider
    cmp_divider: tdc_divider
        generic map(
            g_WIDTH => g_FP_COUNT+g_FCOUNTER_WIDTH
        )
        port map(
            clk_i       => clk_i,
            reset_i     => reset_i,
            
            start_i     => div_start,
            dividend_i  => mul_d1,
            divisor_i   => div_divisor,
            
            ready_o     => div_ready,
            quotient_o  => div_quotient,
            remainder_o => open
        );
    div_divisor <= (g_FP_COUNT-1 downto 0 => '0') & oc_freq_i;
    process(div_quotient)
    begin
        if div_quotient(g_FP_COUNT+g_FCOUNTER_WIDTH-1 downto g_FP_COUNT)
            = (g_FCOUNTER_WIDTH-1 downto 0 => '0') then
            div_qsat <= div_quotient(g_FP_COUNT-1 downto 0);
        else -- saturate
            div_qsat <= (div_qsat'range => '1');
        end if;
    end process;
    
    -- generate LUT address and write data
    lut_a_o <= std_logic_vector(unsigned(ha_count) + 1);
    lut_d_o <= div_qsat;
    
    -- main FSM
    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                if freeze_req_i = '1' then
                    state <= FREEZE;
                else
                    state <= SC_NEWCHANNEL;
                end if;
            else
                case state is
                    when SC_NEWCHANNEL =>
                        state <= SC_CLEARHIST;
                    when SC_CLEARHIST =>
                        if ha_last = '1' then
                            state <= SC_READ;
                        end if;
                    when SC_READ =>
                        if c_detect_i = '1' then
                            state <= SC_UPDATE;
                        end if;
                    when SC_UPDATE =>
                        if hc_zero = '1' then
                            state <= SC_STOREF0;
                        else
                            state <= SC_READ;
                        end if;
                    when SC_STOREF0 =>
                        if oc_ready_i = '1' then
                            if last_i = '1' then
                                state <= OC_STARTM;
                            else
                                state <= SC_NEWCHANNEL;
                            end if;
                        end if;
                    
                    when OC_STARTM =>
                        state <= OC_WAITM;
                    when OC_WAITM =>
                        if oc_ready_i = '1' then
                            state <= OC_WAITMUL1;
                        end if;
                    when OC_WAITMUL1 =>
                        state <= OC_WAITMUL2;
                    when OC_WAITMUL2 =>
                        state <= OC_STARTDIV;
                    when OC_STARTDIV =>
                        state <= OC_WAITDIV;
                    when OC_WAITDIV =>
                        if div_ready = '1' then
                            state <= OC_WRITELUT;
                        end if;
                    when OC_WRITELUT =>
                        if ha_last = '1' then
                            state <= OC_NEXTCHANNEL;
                        else
                            state <= OC_WAITMUL1;
                        end if;
                    when OC_NEXTCHANNEL =>
                        if freeze_req_i = '1' then
                            state <= FREEZE;
                        else
                            state <= OC_STARTM;
                        end if;
                    
                    when FREEZE =>
                        if freeze_req_i = '0' then
                            state <= OC_STARTM;
                        end if;
                end case;
            end if;
        end if;
    end process;
    
    process(state, hc_zero, oc_ready_i, last_i)
    begin
        ready_p <= '0';
        
        hc_reset <= '0';
        hc_dec <= '0';
        
        ha_reset <= '0';
        ha_inc <= '0';
        ha_sel <= '0';
        
        acc_reset <= '0';
        acc_en <= '0';
        
        div_start <= '0';
        
        next_o <= '0';
        calib_sel_o <= '0';
        lut_we_o <= '0';
        his_we_o <= '0';
        oc_start_o <= '0';
        oc_store_o <= '0';
        freeze_ack_o <= '0';
        
        case state is
            when SC_NEWCHANNEL =>
                hc_reset <= '1';
                ha_reset <= '1';
            when SC_CLEARHIST =>
                calib_sel_o <= '1';
                ha_inc <= '1';
                ha_sel <= '1';
                his_we_o <= '1';
            when SC_READ =>
                calib_sel_o <= '1';
            when SC_UPDATE =>
                calib_sel_o <= '1';
                his_we_o <= '1';
                hc_dec <= '1';
                if hc_zero = '1' then
                    oc_start_o <= '1';
                end if;
            when SC_STOREF0 =>
                if oc_ready_i = '1' then
                    oc_store_o <= '1';
                    next_o <= '1';
                end if;
            
            when OC_STARTM =>
                oc_start_o <= '1';
                ha_reset <= '1';
                acc_reset <= '1';
            when OC_WAITM =>
                null;
            when OC_WAITMUL1 =>
                null;
            when OC_WAITMUL2 =>
                null;
            when OC_STARTDIV =>
                div_start <= '1';
            when OC_WAITDIV =>
                null;
            when OC_WRITELUT =>
                lut_we_o <= '1';
                acc_en <= '1';
                ha_inc <= '1';
            when OC_NEXTCHANNEL =>
                next_o <= '1';
                if last_i = '1' then
                    ready_p <= '1';
                end if;
            
            when FREEZE =>
                freeze_ack_o <= '1';
        end case;
    end process;
end architecture;
