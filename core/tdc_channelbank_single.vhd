-------------------------------------------------------------------------------
-- TDC Core / CERN
-------------------------------------------------------------------------------
--
-- unit name: tdc_channelbank_single
--
-- author: Sebastien Bourdeauducq, sebastien@milkymist.org
--
-- description: Channel bank (single-channel)
--
-- references: http://www.ohwr.org/projects/tdc-core
--
-------------------------------------------------------------------------------
-- last changes:
-- 2011-11-05 SB Added extra histogram bits support
-- 2011-10-25 SB Created file
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
-- Simplified version of tdc_channelbank_multi for the single-channel case.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.tdc_package.all;
use work.genram_pkg.all;

entity tdc_channelbank_single is
    generic(
        g_CARRY4_COUNT   : positive;
        g_RAW_COUNT      : positive;
        g_FP_COUNT       : positive;
        g_EXHIS_COUNT    : positive;
        g_COARSE_COUNT   : positive;
        g_RO_LENGTH      : positive;
        g_FCOUNTER_WIDTH : positive;
        g_FTIMER_WIDTH   : positive
    );
    port(
        clk_i       : in std_logic;
        reset_i     : in std_logic;
         
        -- Control.
        cc_rst_i    : in std_logic;
        cc_cy_o     : out std_logic;
        next_i      : in std_logic;
        last_o      : out std_logic;
        calib_sel_i : in std_logic;
        
        -- Per-channel deskew inputs.
        deskew_i    : in std_logic_vector(g_COARSE_COUNT+g_FP_COUNT-1 downto 0);
        
        -- Per-channel signal inputs.
        signal_i    : in std_logic;
        calib_i     : in std_logic;
        
         -- Per-channel detection outputs.
        detect_o    : out std_logic;
        polarity_o  : out std_logic;
        raw_o       : out std_logic_vector(g_RAW_COUNT-1 downto 0);
        fp_o        : out std_logic_vector(g_COARSE_COUNT+g_FP_COUNT-1 downto 0);
         
        -- LUT access.
        lut_a_i     : in std_logic_vector(g_RAW_COUNT-1 downto 0);
        lut_we_i    : in std_logic;
        lut_d_i     : in std_logic_vector(g_FP_COUNT-1 downto 0);
        lut_d_o     : out std_logic_vector(g_FP_COUNT-1 downto 0);
        
        -- Histogram.
        c_detect_o  : out std_logic;
        c_raw_o     : out std_logic_vector(g_RAW_COUNT-1 downto 0);
        his_a_i     : in std_logic_vector(g_RAW_COUNT-1 downto 0);
        his_we_i    : in std_logic;
        his_d_i     : in std_logic_vector(g_FP_COUNT+g_EXHIS_COUNT-1 downto 0);
        his_d_o     : out std_logic_vector(g_FP_COUNT+g_EXHIS_COUNT-1 downto 0);
        
        -- Online calibration.
        oc_start_i  : in std_logic;
        oc_ready_o  : out std_logic;
        oc_freq_o   : out std_logic_vector(g_FCOUNTER_WIDTH-1 downto 0);
        oc_store_i  : in std_logic;
        oc_sfreq_o  : out std_logic_vector(g_FCOUNTER_WIDTH-1 downto 0)
    );
end entity;

architecture rtl of tdc_channelbank_single is
signal detect                 : std_logic;
signal raw                    : std_logic_vector(g_RAW_COUNT-1 downto 0);
signal coarse_counter         : std_logic_vector(g_COARSE_COUNT-1 downto 0);
signal ro_clk                 : std_logic;
signal freq                   : std_logic_vector(g_FCOUNTER_WIDTH-1 downto 0);
signal sfreq_s                : std_logic_vector(g_FCOUNTER_WIDTH-1 downto 0);
begin
    -- Per-channel processing.
    cmp_channel: tdc_channel
        generic map(
            g_CARRY4_COUNT => g_CARRY4_COUNT,
            g_RAW_COUNT    => g_RAW_COUNT,
            g_FP_COUNT     => g_FP_COUNT,
            g_COARSE_COUNT => g_COARSE_COUNT,
            g_RO_LENGTH    => g_RO_LENGTH
        )
        port map(
            clk_i       => clk_i,
            reset_i     => reset_i,
        
            coarse_i    => coarse_counter,
            deskew_i    => deskew_i,

            signal_i    => signal_i,
            calib_i     => calib_i,
            calib_sel_i => calib_sel_i,

            detect_o    => detect,
            polarity_o  => polarity_o,
            raw_o       => raw,
            fp_o        => fp_o,

            lut_a_i     => lut_a_i,
            lut_we_i    => lut_we_i,
            lut_d_i     => lut_d_i,
            lut_d_o     => lut_d_o,

            ro_en_i     => '1',
            ro_clk_o    => ro_clk
        );
    detect_o <= detect;
    raw_o <= raw;
    c_detect_o <= detect;
    c_raw_o <= raw;
    
    -- Histogram memory.
    cmp_histogram: generic_spram
        generic map(
            g_data_width               => g_FP_COUNT+g_EXHIS_COUNT,
            g_size                     => 2**g_RAW_COUNT,
            g_with_byte_enable         => false,
            g_init_file                => "",
            g_addr_conflict_resolution => "read_first"
        )
        port map(
            rst_n_i => '1',
            clk_i   => clk_i,
            bwe_i   => (others => '0'),
            we_i    => his_we_i,
            a_i     => his_a_i,
            d_i     => his_d_i,
            q_o     => his_d_o
        );
    
    -- Frequency counter.
    cmp_freqc: tdc_freqc
        generic map(
            g_COUNTER_WIDTH => g_FCOUNTER_WIDTH,
            g_TIMER_WIDTH   => g_FTIMER_WIDTH
        )
        port map(
            clk_i   => clk_i,
            reset_i => reset_i,
            
            clk_m_i => ro_clk,
            start_i => oc_start_i,
            ready_o => oc_ready_o,
            freq_o  => freq
        );
    oc_freq_o <= freq;
    
    -- Coarse counter.
    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if (reset_i = '1') or (cc_rst_i = '1') then
                coarse_counter <= (coarse_counter'range => '0');
                cc_cy_o <= '0';
            else
                coarse_counter <= std_logic_vector(unsigned(coarse_counter) + 1);
                if coarse_counter = (coarse_counter'range => '1') then
                    cc_cy_o <= '1';
                else
                    cc_cy_o <= '0';
                end if;
            end if;
        end if;
    end process;
    
    -- Store and retrieve per-channel ring oscillator frequencies.
    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if oc_store_i = '1' then
                sfreq_s <= freq;
            end if;
        end if;
    end process;
    oc_sfreq_o <= sfreq_s;
    
    -- Generate channel selection signals.
    last_o <= '1';
end architecture;
