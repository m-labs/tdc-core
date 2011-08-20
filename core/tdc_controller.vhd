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

type t_state is (
        -- startup calibration
        SC_NEWCHANNEL, SC_CLEARHIST, SC_READ, SC_UPDATE, SC_STOREF0,
        -- online calibration
        OC_STARTM, OC_WAITM, OC_NEXTCHANNEL
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
    
    -- main FSM
    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                state <= SC_NEWCHANNEL;
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
                            state <= OC_NEXTCHANNEL;
                        end if;
                    when OC_NEXTCHANNEL =>
                        state <= OC_STARTM;
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
        
        next_o <= '0';
        calib_sel_o <= '0';
        lut_we_o <= '0';
        his_we_o <= '0';
        oc_start_o <= '0';
        oc_store_o <= '0';
        
        case state is
            when SC_NEWCHANNEL =>
                hc_reset <= '1';
                ha_reset <= '1';
            when SC_CLEARHIST =>
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
            when OC_WAITM =>
                null;
            when OC_NEXTCHANNEL =>
                next_o <= '1';
                if last_i = '1' then
                    ready_p <= '1';
                end if;
        end case;
    end process;
end architecture;
