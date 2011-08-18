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
-- 2011-08-18 SB Added histogram
-- 2011-08-17 SB Added frequency counter
-- 2011-08-08 SB Created file
-------------------------------------------------------------------------------

-- Copyright (C) 2011 Sebastien Bourdeauducq

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.tdc_package.all;
use work.genram_pkg.all;

entity tdc_channelbank is
    generic(
        -- Number of channels.
        g_CHANNEL_COUNT  : positive;
        -- Number of CARRY4 elements per channel.
        g_CARRY4_COUNT   : positive;
        -- Number of raw output bits.
        g_RAW_COUNT      : positive;
        -- Number of fractional part bits.
        g_FP_COUNT       : positive;
        -- Number of coarse counter bits.
        g_COARSE_COUNT   : positive;
        -- Length of each ring oscillator.
        g_RO_LENGTH      : positive;
        -- Frequency counter width.
        g_FCOUNTER_WIDTH : positive;
        -- Frequency counter timer width.
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
        
        -- Histogram.
        c_detect_o  : out std_logic;
        c_raw_o     : out std_logic_vector(g_RAW_COUNT-1 downto 0);
        his_a_i     : in std_logic_vector(g_RAW_COUNT-1 downto 0);
        his_we_i    : in std_logic;
        his_d_i     : in std_logic_vector(g_FP_COUNT-1 downto 0);
        his_d_o     : out std_logic_vector(g_FP_COUNT-1 downto 0);
        
        -- Online calibration.
        oc_start_i  : in std_logic;
        oc_ready_o  : out std_logic;
        oc_freq_o   : out std_logic_vector(g_FCOUNTER_WIDTH-1 downto 0);
        oc_store_i  : in std_logic;
        oc_sfreq_o  : out std_logic_vector(g_FCOUNTER_WIDTH-1 downto 0)
    );
end entity;

architecture rtl of tdc_channelbank is
signal detect_o               : std_logic_vector(g_CHANNEL_COUNT-1 downto 0);
signal raw_o                  : std_logic_vector(g_CHANNEL_COUNT*g_RAW_COUNT-1 downto 0);
signal coarse_counter         : std_logic_vector(g_COARSE_COUNT-1 downto 0);
signal current_channel_onehot : std_logic_vector(g_CHANNEL_COUNT-1 downto 0);
signal current_channel        : std_logic_vector(f_log2_size(g_CHANNEL_COUNT)-1 downto 0);
signal lut_d_o_s              : std_logic_vector(g_CHANNEL_COUNT*g_FP_COUNT-1 downto 0);
signal his_full_a             : std_logic_vector(f_log2_size(g_CHANNEL_COUNT)+g_RAW_COUNT-1 downto 0);
signal ro_clk_s               : std_logic_vector(g_CHANNEL_COUNT-1 downto 0);
signal ro_clk                 : std_logic;
signal freq                   : std_logic_vector(g_FCOUNTER_WIDTH-1 downto 0);
signal sfreq_s                : std_logic_vector(g_CHANNEL_COUNT*g_FCOUNTER_WIDTH-1 downto 0);
begin
    -- Per-channel processing.
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

                detect_o    => detect(i),
                polarity_o  => polarity_o(i),
                raw_o       => raw((i+1)*g_RAW_COUNT-1 downto i*g_RAW_COUNT),
                fp_o        =>
                    fp_o((i+1)*(g_COARSE_COUNT+g_FP_COUNT)-1 downto i*(g_COARSE_COUNT+g_FP_COUNT)),

                lut_a_i     => lut_a_i,
                lut_we_i    => this_lut_we,
                lut_d_i     => lut_d_i,
                lut_d_o     => lut_d_o_s((i+1)*g_FP_COUNT-1 downto i*g_FP_COUNT),

                ro_en_i     => current_channel_onehot(i),
                ro_clk_o    => ro_clk_s(i)
            );
    end generate;
    detect_o <= detect;
    raw_o <= raw;
    
    -- Histogram memory.
    cmp_histogram: generic_spram
        generic map(
            g_data_width               => g_FP_COUNT,
            g_size                     => g_CHANNEL_COUNT*2**g_RAW_COUNT,
            g_with_byte_enable         => false,
            g_init_file                => "",
            g_addr_conflict_resolution => "read_first"
        )
        port map(
            rst_n_i => '1',
            clk_i   => clk_i,
            bwe_i   => (others => '0'),
            we_i    => his_we_i,
            a_i     => his_full_a,
            d_i     => his_d_i,
            q_o     => his_d_o
        );
    his_full_a <= current_channel & his_a_i;
    
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
    
    -- Combine LUT outputs.
    process(lut_d_o_s, current_channel_onehot)
    variable v_lut_d_o: std_logic_vector(g_FP_COUNT-1 downto 0);
    begin
        v_lut_d_o := (v_lut_d_o'range => '0');
        for i in 0 to g_CHANNEL_COUNT-1 loop
            if current_channel_onehot(i) = '1' then
                v_lut_d_o := v_lut_d_o or lut_d_o_s((i+1)*g_FP_COUNT-1 downto i*g_FP_COUNT);
            end if;
        end loop;
        lut_d_o <= v_lut_d_o;
    end process;
    
    -- Select detect and raw outputs for histogram generation.
    process(detect, raw, current_channel_onehot)
    variable v_c_detect_o : std_logic;
    variable v_c_raw_o    : std_logic_vector(g_RAW_COUNT-1 downto 0);
    begin
        v_c_detect_o := '0';
        v_c_raw_o := (v_c_raw_o'range => '0');
        for i in 0 to g_CHANNEL_COUNT-1 loop
            if current_channel_onehot(i) = '1' then
                v_c_detect_o := v_c_detect_o or detect(i);
                v_c_raw_o := v_c_raw_o or raw((i+1)*g_RAW_COUNT-1 downto i*g_RAW_COUNT);
            end if;
        end loop;
        c_detect_o <= v_c_detect_o;
        c_raw_o <= v_c_raw_o;
    end process;
    
    -- Combine ring oscillator outputs. When disabled, a ring oscillator
    -- outputs 0, so we can simply OR all outputs together.
    ro_clk <= '0' when (ro_clk_s = (ro_clk_s'range => '0')) else '1';
    
    -- Store and retrieve per-channel ring oscillator frequencies.
    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if oc_store_i = '1' then
                for i in 0 to g_CHANNEL_COUNT-1 loop
                    if current_channel_onehot(i) = '1' then
                        sfreq_s((i+1)*g_FCOUNTER_WIDTH-1 downto i*g_FCOUNTER_WIDTH) <= freq;
                    end if;
                end loop;
            end if;
        end if;
    end process;
    
    process(sfreq_s, current_channel_onehot)
    variable v_oc_sfreq_o: std_logic_vector(g_FCOUNTER_WIDTH-1 downto 0);
    begin
        v_oc_sfreq_o := (v_oc_sfreq_o'range => '0');
        for i in 0 to g_CHANNEL_COUNT-1 loop
            if current_channel_onehot(i) = '1' then
                v_oc_sfreq_o := v_oc_sfreq_o 
                    or sfreq_s((i+1)*g_FCOUNTER_WIDTH-1 downto i*g_FCOUNTER_WIDTH);
            end if;
        end loop;
        oc_sfreq_o <= v_oc_sfreq_o;
    end process;
    
    -- Generate channel selection signals.
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
    
    g_encode: if g_CHANNEL_COUNT > 1 generate
        process(current_channel_onehot)
        variable v_current_channel: std_logic_vector(f_log2_size(g_CHANNEL_COUNT)-1 downto 0);
        begin
            v_current_channel := (v_current_channel'range => '0');
            for i in 0 to g_CHANNEL_COUNT-1 loop
                if current_channel_onehot(i) = '1' then
                    v_current_channel := v_current_channel
                        or std_logic_vector(to_unsigned(i, v_current_channel'length));
                end if;
            end loop;
            current_channel <= v_current_channel;
        end process;
    end generate;

end architecture;
