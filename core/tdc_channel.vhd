-------------------------------------------------------------------------------
-- TDC Core / CERN
-------------------------------------------------------------------------------
--
-- unit name: tdc_channel
--
-- author: Sebastien Bourdeauducq, sebastien@milkymist.org
--
-- description: Per-channel processing
--
-- references: http://www.ohwr.org/projects/tdc-core
--
-------------------------------------------------------------------------------
-- last changes:
-- 2011-08-03 SB Created file
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
-- This contains the elements needed for each channel:
--  * Delay line
--  * Encoder
--  * LUT
--  * Deskew stage
--  * Online calibration ring oscillator

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.tdc_package.all;
use work.genram_pkg.all;

entity tdc_channel is
    generic(
        -- Number of CARRY4 elements.
        g_CARRY4_COUNT : positive;
        -- Number of raw output bits.
        g_RAW_COUNT    : positive;
        -- Number of fractional part bits.
        g_FP_COUNT     : positive;
        -- Number of coarse counter bits.
        g_COARSE_COUNT : positive;
        -- Length of the ring oscillator.
        g_RO_LENGTH    : positive
    );
    port(
        clk_i        : in std_logic;
        reset_i      : in std_logic;

        -- Coarse counter and deskew inputs.
        coarse_i    : in std_logic_vector(g_COARSE_COUNT-1 downto 0);
        deskew_i    : in std_logic_vector((g_COARSE_COUNT+g_FP_COUNT)-1 downto 0);

        -- Signal input.
        signal_i    : in std_logic;
        calib_i     : in std_logic;
        calib_sel_i : in std_logic;

        -- Detection outputs.
        detect_o    : out std_logic;
        polarity_o  : out std_logic;
        raw_o       : out std_logic_vector(g_RAW_COUNT-1 downto 0);
        fp_o        : out std_logic_vector((g_COARSE_COUNT+g_FP_COUNT)-1 downto 0);

        -- LUT access.
        lut_a_i     : in std_logic_vector(g_RAW_COUNT-1 downto 0);
        lut_we_i    : in std_logic;
        lut_d_i     : in std_logic_vector(g_FP_COUNT-1 downto 0);
        lut_d_o     : out std_logic_vector(g_FP_COUNT-1 downto 0);

        -- Calibration ring oscillator.
        ro_en_i     : in std_logic;
        ro_clk_o    : out std_logic
    );
end entity;

architecture rtl of tdc_channel is
signal calib_sel_d  : std_logic;
signal muxed_signal : std_logic;
signal taps         : std_logic_vector(4*g_CARRY4_COUNT-1 downto 0);
signal polarity     : std_logic;
signal polarity_d1  : std_logic;
signal polarity_d2  : std_logic;
signal detect_d1    : std_logic;
signal raw          : std_logic_vector(g_RAW_COUNT-1 downto 0);
signal raw_d1       : std_logic_vector(g_RAW_COUNT-1 downto 0);
signal raw_d2       : std_logic_vector(g_RAW_COUNT-1 downto 0);
signal lut          : std_logic_vector(g_FP_COUNT-1 downto 0);
begin
    -- register calibration select signal to avoid glitches
    process(clk_i)
    begin
        if rising_edge(clk_i) then
            calib_sel_d <= calib_sel_i;
        end if;
    end process;
    with calib_sel_d select
        muxed_signal <= calib_i when '1', signal_i when others;
    
    cmp_delayline: tdc_delayline
        generic map(
            g_WIDTH => g_CARRY4_COUNT
        )
        port map(
             clk_i        => clk_i,
             reset_i      => reset_i,
             signal_i     => muxed_signal,
             taps_o       => taps
        );
    
    -- TODO: reorder bits by increasing delays
    
    cmp_lbc: tdc_lbc
        generic map(
            g_N     => g_RAW_COUNT,
            g_NIN   => g_CARRY4_COUNT*4
        )
        port map(
             clk_i        => clk_i,
             reset_i      => reset_i,
             d_i          => taps,
             polarity_o   => polarity,
             count_o      => raw
        );
    
    cmp_lut: generic_dpram
        generic map(
            g_data_width               => g_FP_COUNT,
            g_size                     => 2**g_RAW_COUNT,
            g_with_byte_enable         => false,
            g_addr_conflict_resolution => "read_first",
            g_init_file                => "",
            g_dual_clock               => false
        )
        port map(
            clka_i => clk_i,
            clkb_i => '0',
            
            wea_i  => '0',
            bwea_i => (others => '0'),
            aa_i   => raw,
            da_i   => (others => '0'),
            qa_o   => lut,
            
            web_i  => lut_we_i,
            bweb_i => (others => '0'),
            ab_i   => lut_a_i,
            db_i   => lut_d_i,
            qb_o   => lut_d_o
        );
    
    cmp_ringosc: tdc_ringosc
        generic map(
            g_LENGTH => g_RO_LENGTH
        )
        port map(
            en_i  => ro_en_i,
            clk_o => ro_clk_o
        );

    detect_d1 <= polarity_d1 xor polarity_d2;
    
    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                detect_o <= '0';
                polarity_d1 <= '1';
                polarity_d2 <= '1';
                raw_d1 <= (others => '0');
                raw_d2 <= (others => '0');
            else
                detect_o <= detect_d1;
                polarity_d1 <= polarity;
                raw_d1 <= raw;
                if detect_d1 = '1' then
                    polarity_d2 <= polarity_d1;
                    raw_d2 <= raw_d1;
                end if;
            end if;
        end if;
    end process;
    polarity_o <= polarity_d2;
    raw_o <= raw_d2;
    
    -- Combine coarse counter value and deskew.
    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                fp_o <= (others => '0');
            else
                if detect_d1 = '1' then
                    fp_o <= std_logic_vector(
                        unsigned(coarse_i & (lut'range => '0'))
                        - unsigned(lut)
                        + unsigned(deskew_i));
                end if;
            end if;
        end if;
    end process;

end architecture;
