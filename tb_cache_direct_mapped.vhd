library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_cache_direct_mapped is
end tb_cache_direct_mapped;

architecture sim of tb_cache_direct_mapped is

    -- Component declaration
    component cache_direct_mapped
        generic (
            ADDR_WIDTH  : integer := 32;
            WORD_WIDTH  : integer := 32;
            CACHE_LINES : integer := 256
        );
        port (
            clk      : in  std_logic;
            reset    : in  std_logic;
            addr     : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
            data_in  : in  std_logic_vector(WORD_WIDTH-1 downto 0);
            rd_en    : in  std_logic;
            wr_en    : in  std_logic;
            data_out : out std_logic_vector(WORD_WIDTH-1 downto 0);
            hit      : out std_logic;
            miss     : out std_logic
        );
    end component;

    -- Testbench signals
    signal clk_tb      : std_logic := '0';
    signal reset_tb    : std_logic := '0';
    signal addr_tb     : std_logic_vector(31 downto 0);
    signal data_in_tb  : std_logic_vector(31 downto 0);
    signal rd_en_tb    : std_logic := '0';
    signal wr_en_tb    : std_logic := '0';
    signal data_out_tb : std_logic_vector(31 downto 0);
    signal hit_tb      : std_logic;
    signal miss_tb     : std_logic;

    constant CLK_PERIOD : time := 10 ns;

begin

    -- Instancia o módulo de cache
    uut: cache_direct_mapped
        port map (
            clk      => clk_tb,
            reset    => reset_tb,
            addr     => addr_tb,
            data_in  => data_in_tb,
            rd_en    => rd_en_tb,
            wr_en    => wr_en_tb,
            data_out => data_out_tb,
            hit      => hit_tb,
            miss     => miss_tb
        );

    -- Geração do clock
    clk_process : process
    begin
        while true loop
            clk_tb <= '0';
            wait for CLK_PERIOD / 2;
            clk_tb <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
    end process;

    -- Estímulos de teste
    stim_proc: process
    begin
        -- Reset
        reset_tb <= '1';
        wait for 2 * CLK_PERIOD;
        reset_tb <= '0';
        wait for CLK_PERIOD;

        -- Escrita em 10 endereços distintos
        for i in 0 to 9 loop
            addr_tb    <= std_logic_vector(to_unsigned(i * 4, 32));  -- Alinhado a 4 bytes
            data_in_tb <= std_logic_vector(to_unsigned(i * 100, 32));
            wr_en_tb   <= '1';
            rd_en_tb   <= '0';
            wait for CLK_PERIOD;
        end loop;
        wr_en_tb <= '0';

        wait for CLK_PERIOD;

        -- Leitura nos mesmos endereços (espera-se HIT)
        for i in 0 to 9 loop
            addr_tb   <= std_logic_vector(to_unsigned(i * 4, 32));
            rd_en_tb  <= '1';
            wr_en_tb  <= '0';
            wait for CLK_PERIOD;
        end loop;
        rd_en_tb <= '0';

        wait for CLK_PERIOD;

        -- Leitura em novos endereços (espera-se MISS)
        for i in 10 to 14 loop
            addr_tb   <= std_logic_vector(to_unsigned(i * 4, 32));
            rd_en_tb  <= '1';
            wait for CLK_PERIOD;
        end loop;

        -- Fim da simulação
        wait for 5 * CLK_PERIOD;
        assert false report "Fim do Testbench" severity failure;
    end process;

end sim;
