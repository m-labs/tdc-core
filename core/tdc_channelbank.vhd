-------------------------------------------------------------------------------
-- TDC Core / CERN
-------------------------------------------------------------------------------
--
-- unit name: tdc_channelbank
--
-- author: Sebastien Bourdeauducq, sebastien@milkymist.org
--
-- description: Channel bank
--
-- references: http://www.ohwr.org/projects/tdc-core
--
-------------------------------------------------------------------------------
-- last changes:
-- 2011-08-08 SB Created file
-------------------------------------------------------------------------------

-- Copyright (C) 2011 Sebastien Bourdeauducq

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.tdc_package.all;

entity tdc_channelbank is
    generic(
        -- Number of channels.
        g_CHANNEL_COUNT : positive;
        -- Number of CARRY4 elements per channel.
        g_CARRY4_COUNT  : positive;
        -- Number of raw output bits.
        g_RAW_COUNT     : positive;
        -- Number of fractional part bits.
        g_FP_COUNT      : positive;
        -- Number of coarse counter bits.
        g_COARSE_COUNT  : positive;
        -- Length of each ring oscillator.
        g_RO_LENGTH     : positive
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
        
        -- Per-channel deskew input.
        deskew_i    : in std_logic_vector(g_CHANNEL_COUNT*(g_COARSE_COUNT+g_FP_COUNT)-1 downto 0);
        
        -- Per-channel signal inputs.
        signal_i    : in std_logic_vector(g_CHANNEL_COUNT-1 downto 0);
        calib_i     : in std_logic_vector(g_CHANNEL_COUNT-1 downto 0);
        
         -- Per-channel detection outputs.
        detect_o    : out std_logic_vector(g_CHANNEL_COUNT-1 downto 0);
        polarity_o  : out std_logic_vector(g_CHANNEL_COUNT-1 downto 0);
        raw_o       : out std_logic_vector(g_CHANNEL_COUNT*g_RAW_COUNT-1 downto 0);
        fp_o        : out std_logic_vector(g_CHANNEL_COUNT*(g_COARSE_COUNT+g_FP_COUNT)-1 downto 0);
         
        -- LUT access.
        lut_a_i     : in std_logic_vector(g_RAW_COUNT-1 downto 0);
        lut_we_i    : in std_logic;
        lut_d_i     : in std_logic_vector(g_FP_COUNT-1 downto 0);
        lut_d_o     : out std_logic_vector(g_FP_COUNT-1 downto 0);
         
        -- Online calibration ring oscillator.
        ro_clk_o    : out std_logic
    );
end entity;

architecture rtl of tdc_channelbank is
signal coarse_counter         : std_logic_vector(g_COARSE_COUNT-1 downto 0);
signal current_channel_onehot : std_logic_vector(g_CHANNEL_COUNT-1 downto 0);
signal lut_d_o_s              : std_logic_vector(g_CHANNEL_COUNT*g_FP_COUNT-1 downto 0);
signal ro_clk_o_s             : std_logic_vector(g_CHANNEL_COUNT-1 downto 0);
begin
    g_channels: for i in 0 to g_CHANNEL_COUNT-1 generate
    signal this_calib_sel : std_logic;
    signal this_lut_we    : std_logic;
    begin
        this_calib_sel <= current_channel_onehot(i) and calib_sel_i;
        this_lut_we <= current_channel_onehot(i) and lut_we_i;
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
                deskew_i    =>
                    deskew_i((i+1)*(g_COARSE_COUNT+g_FP_COUNT)-1 downto i*(g_COARSE_COUNT+g_FP_COUNT)),
    
                signal_i    => signal_i(i),
                calib_i     => calib_i(i),
                calib_sel_i => this_calib_sel,

                detect_o    => detect_o(i),
                polarity_o  => polarity_o(i),
                raw_o       => raw_o((i+1)*g_RAW_COUNT-1 downto i*g_RAW_COUNT),
                fp_o        =>
                    fp_o((i+1)*(g_COARSE_COUNT+g_FP_COUNT)-1 downto i*(g_COARSE_COUNT+g_FP_COUNT)),

                lut_a_i     => lut_a_i,
                lut_we_i    => this_lut_we,
                lut_d_i     => lut_d_i,
                lut_d_o     => lut_d_o_s((i+1)*g_FP_COUNT-1 downto i*g_FP_COUNT),

                ro_en_i     => current_channel_onehot(i),
                ro_clk_o    => ro_clk_o_s(i)
            );
    end generate;
    
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
    
    -- Combine LUT outputs.
    process(lut_d_o_s, current_channel_onehot)
    variable v_lut_d_o: std_logic_vector(g_FP_COUNT-1 downto 0);
    begin
        v_lut_d_o := (g_FP_COUNT-1 downto 0 => '0');
        for i in 0 to g_CHANNEL_COUNT-1 loop
            if current_channel_onehot(i) = '1' then
                v_lut_d_o := v_lut_d_o or lut_d_o_s((i+1)*g_FP_COUNT-1 downto i*g_FP_COUNT);
            end if;
        end loop;
        lut_d_o <= v_lut_d_o;
    end process;
    
    -- Combine ring oscillator outputs. When disabled, a ring oscillator
    -- outputs 0, so we can simply OR all outputs together.
    ro_clk_o <= '0' when (ro_clk_o_s = (ro_clk_o_s'range => '0')) else '1';
    
    -- Generate channel selection signal.
    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                current_channel_onehot <= (0 => '1', others => '0');
            else
                if next_i = '1' then
                    current_channel_onehot <=
                        std_logic_vector(rotate_left(unsigned(current_channel_onehot), 1));
                end if;
            end if;
        end if;
    end process;
    last_o <= current_channel_onehot(g_CHANNEL_COUNT-1);

end architecture;
