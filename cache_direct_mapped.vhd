library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity cache_direct_mapped is
    generic (
        ADDR_WIDTH   : integer := 32;
        WORD_WIDTH   : integer := 32;
        CACHE_LINES  : integer := 256  -- 2^8 linhas
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
end cache_direct_mapped;

architecture Behavioral of cache_direct_mapped is

    -- Constantes derivadas
    constant OFFSET_BITS : integer := 2; -- para alinhamento de 4 bytes
    constant INDEX_BITS  : integer := 8; -- 256 linhas = 2^8
    constant TAG_BITS    : integer := ADDR_WIDTH - OFFSET_BITS - INDEX_BITS;

    -- Tipos e arrays internos
    type data_array_type is array(0 to CACHE_LINES - 1) of std_logic_vector(WORD_WIDTH - 1 downto 0);
    type tag_array_type  is array(0 to CACHE_LINES - 1) of std_logic_vector(TAG_BITS - 1 downto 0);
    type valid_array_type is array(0 to CACHE_LINES - 1) of std_logic;

    signal data_array  : data_array_type;
    signal tag_array   : tag_array_type;
    signal valid_array : valid_array_type;

    -- Extração de partes do endereço
    signal index   : integer range 0 to CACHE_LINES - 1;
    signal tag     : std_logic_vector(TAG_BITS - 1 downto 0);

begin

    process(clk, reset)
    begin
        if reset = '1' then
            -- Invalida todas as linhas
            for i in 0 to CACHE_LINES - 1 loop
                data_array(i)  <= (others => '0');
                tag_array(i)   <= (others => '0');
                valid_array(i) <= '0';
            end loop;
            data_out <= (others => '0');
            hit      <= '0';
            miss     <= '0';

        elsif rising_edge(clk) then

            -- Extrair tag e índice do endereço
            index <= to_integer(unsigned(addr(OFFSET_BITS + INDEX_BITS - 1 downto OFFSET_BITS)));
            tag   <= addr(ADDR_WIDTH - 1 downto ADDR_WIDTH - TAG_BITS);

            -- Acesso à cache
            if rd_en = '1' then
                if valid_array(index) = '1' and tag_array(index) = tag then
                    -- Hit
                    data_out <= data_array(index);
                    hit      <= '1';
                    miss     <= '0';
                else
                    -- Miss
                    data_out <= (others => '0');
                    hit      <= '0';
                    miss     <= '1';
                end if;

            elsif wr_en = '1' then
                -- Política write-through (escreve na cache, sem write-back)
                data_array(index)  <= data_in;
                tag_array(index)   <= tag;
                valid_array(index) <= '1';
                hit                <= '0';
                miss               <= '0';
            end if;
        end if;
    end process;

end Behavioral;
