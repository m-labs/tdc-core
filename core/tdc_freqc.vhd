-------------------------------------------------------------------------------
-- TDC Core / CERN
-------------------------------------------------------------------------------
--
-- unit name: tdc_freqm
--
-- author: Sebastien Bourdeauducq, sebastien@milkymist.org
--
-- description: Frequency counter
--
-- references: http://www.ohwr.org/projects/tdc-core
--
-------------------------------------------------------------------------------
-- last changes:
-- 2011-08-13 SB Created file
-------------------------------------------------------------------------------

-- Copyright (C) 2011 Sebastien Bourdeauducq

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.tdc_package.all;

entity tdc_freqc is
    generic(
        g_COUNTER_WIDTH : positive;
        g_TIMER_WIDTH   : positive
    );
    port(
        clk_i   : in std_logic;
        reset_i : in std_logic;
        
        clk_m_i : in std_logic;
        start_i : in std_logic;
        ready_o : out std_logic;
        freq_o  : out std_logic_vector(g_COUNTER_WIDTH-1 downto 0)
    );
end entity;

architecture rtl of tdc_freqc is
-- clk_m domain
signal m_counter : std_logic_vector(g_COUNTER_WIDTH-1 downto 0);
signal m_start   : std_logic;
signal m_stop    : std_logic;
signal m_started : std_logic;
-- clk domain
signal start       : std_logic;
signal stop        : std_logic;
signal stop_ack    : std_logic;
signal counter_r   : std_logic_vector(g_COUNTER_WIDTH-1 downto 0);
signal timer       : std_logic_vector(g_TIMER_WIDTH-1 downto 0);
signal timer_start : std_logic;
signal timer_done  : std_logic;
type t_state is (IDLE, MEASURING, TERMINATING);
signal state       : t_state;
-- Prevent inference of a SRL* primitive, which does not
-- have good metastability resistance.
attribute keep: string;
attribute keep of counter_r: signal is "true";
begin
    -- clk_m clock domain.
    process(clk_m_i)
    begin
        if rising_edge(clk_m_i) then
            if (m_started = '1') and (m_stop = '0') then
                m_counter <= std_logic_vector(unsigned(m_counter) + 1);
            end if;
            if m_start = '1' then
                m_started <= '1';
                m_counter <= (m_counter'range => '0');
            end if;
            if m_stop = '1' then
                m_started <= '0';
            end if;
        end if;
    end process;
    
    -- Synchronisers.
    cmp_sync_start: tdc_psync
        port map(
            clk_src_i => clk_i,
            p_i       => start,
            clk_dst_i => clk_m_i,
            p_o       => m_start
        );
    cmp_sync_stop: tdc_psync
        port map(
            clk_src_i => clk_i,
            p_i       => stop,
            clk_dst_i => clk_m_i,
            p_o       => m_stop
        );
    
    cmp_sync_stop_ack: tdc_psync
        port map(
            clk_src_i => clk_m_i,
            p_i       => m_stop,
            clk_dst_i => clk_i,
            p_o       => stop_ack
        );
    process(clk_i)
    begin
        if rising_edge(clk_i) then
            counter_r <= m_counter;
            freq_o <= counter_r;
        end if;
    end process;
    
    -- Controller.
    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if timer_start = '1' then
                timer <= (timer'range => '1');
            elsif timer_done = '0' then
                timer <= std_logic_vector(unsigned(timer) - 1);
            end if;
        end if;
    end process;
    timer_done <= '1' when (timer = (timer'range => '0')) else '0';
    
    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                state <= IDLE;
            else
                case state is
                    when IDLE =>
                        if start_i = '1' then
                            state <= MEASURING;
                        end if;
                    when MEASURING =>
                        if timer_done = '1' then
                            state <= TERMINATING;
                        end if;
                    when TERMINATING =>
                        if stop_ack = '1' then
                            state <= IDLE;
                        end if;
                end case;
            end if;
        end if;
    end process;
    
    process(state, start_i, timer_done, stop_ack)
    begin
        ready_o <= '0';
        start <= '0';
        stop <= '0';
        timer_start <= '0';
        case state is
            when IDLE =>
                ready_o <= '1';
                if start_i = '1' then
                    start <= '1';
                    timer_start <= '1';
                end if;
            when MEASURING =>
                if timer_done = '1' then
                    stop <= '1';
                end if;
            when TERMINATING =>
                null;
        end case;
    end process;
    
end architecture;
