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

-- Copyright (C) 2011 Sebastien Bourdeauducq

library ieee;
use ieee.std_logic_1164.all;

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
        -- Length of the ring oscillator.
        g_RO_LENGTH    : positive
    );
    port(
         clk_i        : in std_logic;
         reset_i      : in std_logic;
         
         -- Signal input.
         signal_i    : in std_logic;
         calib_i     : in std_logic;
         calib_sel_i : in std_logic;
         
         -- Detection outputs.
         detect_o    : out std_logic;
         polarity_o  : out std_logic;
         raw_o       : out std_logic_vector(g_RAW_COUNT-1 downto 0);
         fp_o        : out std_logic_vector(g_FP_COUNT-1 downto 0);
         
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
signal muxed_signal          : std_logic;
signal taps                  : std_logic_vector(4*g_CARRY4_COUNT-1 downto 0);
signal polarity, polarity_d1 : std_logic;
signal raw                   : std_logic_vector(g_RAW_COUNT-1 downto 0);
begin
    with calib_sel_i select
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
            qa_o   => fp_o,
            
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
    
    polarity_o <= polarity_d1;
    
    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                detect_o <= '0';
                polarity_d1 <= '1';
                raw_o <= (others => '0');
            else
                detect_o <= polarity xor polarity_d1;
                polarity_d1 <= polarity;
                raw_o <= raw;
            end if;
        end if;
    end process;

end architecture;
