library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_cache_4way_associative is
end tb_cache_4way_associative;

architecture test of tb_cache_4way_associative is
    -- Component under test
    component cache_4way_associative is
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

    -- Sinais para conexão
    signal clk      : std_logic := '0';
    signal reset    : std_logic := '1';
    signal addr     : std_logic_vector(31 downto 0) := (others => '0');
    signal data_in  : std_logic_vector(31 downto 0) := (others => '0');
    signal rd_en    : std_logic := '0';
    signal wr_en    : std_logic := '0';
    signal data_out : std_logic_vector(31 downto 0);
    signal hit      : std_logic;
    signal miss     : std_logic;

    constant CLK_PERIOD : time := 10 ns;

begin

    -- Instancia a cache
    uut: cache_4way_associative
        port map (
            clk      => clk,
            reset    => reset,
            addr     => addr,
            data_in  => data_in,
            rd_en    => rd_en,
            wr_en    => wr_en,
            data_out => data_out,
            hit      => hit,
            miss     => miss
        );

    -- Clock process
    clk_process : process
    begin
        clk <= '0';
        wait for CLK_PERIOD / 2;
        clk <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    -- Estímulos de teste
    stimulus : process
    begin
        -- Reset
        wait for 20 ns;
        reset <= '0';

        -- Escritas (cada uma deve ser um MISS)
        for i in 0 to 3 loop
            addr     <= std_logic_vector(to_unsigned(i * 4, 32));
            data_in  <= std_logic_vector(to_unsigned(100 + i, 32));
            wr_en    <= '1';
            rd_en    <= '0';
            wait for CLK_PERIOD;
        end loop;

        wr_en <= '0';
        wait for CLK_PERIOD;

        -- Leitura dos mesmos endereços (todos devem ser HITs)
        for i in 0 to 3 loop
            addr     <= std_logic_vector(to_unsigned(i * 4, 32));
            rd_en    <= '1';
            wr_en    <= '0';
            wait for CLK_PERIOD;
        end loop;

        rd_en <= '0';
        wait for CLK_PERIOD;

        -- Forçar substituição no mesmo conjunto (colisão de índice)
        -- Vamos usar endereços com o mesmo índice mas TAG diferente
        -- Exemplo: addr = base_addr + (offset << 12) mantém o índice
        for i in 4 to 7 loop
            addr     <= std_logic_vector(to_unsigned(i * 1024, 32));  -- mesma linha de índice
            data_in  <= std_logic_vector(to_unsigned(200 + i, 32));
            wr_en    <= '1';
            rd_en    <= '0';
            wait for CLK_PERIOD;
        end loop;

        wr_en <= '0';
        wait for CLK_PERIOD;

        -- Ler todos os endereços anteriores (0~3 devem gerar MISS se substituídos)
        for i in 0 to 7 loop
            if i < 4 then
                addr <= std_logic_vector(to_unsigned(i * 4, 32));
            else
                addr <= std_logic_vector(to_unsigned(i * 1024, 32));
            end if;
            rd_en <= '1';
            wait for CLK_PERIOD;
        end loop;

        rd_en <= '0';
        wait for CLK_PERIOD;

        -- Finaliza simulação
        wait for 50 ns;
        assert false report "Fim do teste" severity failure;
    end process;

end test;
