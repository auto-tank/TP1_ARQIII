library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity cache_4way_associative is
    generic (
        ADDR_WIDTH  : integer := 32;
        WORD_WIDTH  : integer := 32;
        CACHE_LINES : integer := 256  -- 64 sets x 4 ways
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
end cache_4way_associative;

architecture rtl of cache_4way_associative is
    constant NUM_SETS   : integer := 64;
    constant NUM_WAYS   : integer := 4;
    constant INDEX_BITS : integer := 6;  -- log2(64)
    constant OFFSET_BITS: integer := 2;  -- for 4-byte alignment
    constant TAG_BITS   : integer := ADDR_WIDTH - INDEX_BITS - OFFSET_BITS;

    type tag_array_type      is array(0 to NUM_SETS - 1, 0 to NUM_WAYS - 1) of std_logic_vector(TAG_BITS-1 downto 0);
    type valid_array_type    is array(0 to NUM_SETS - 1, 0 to NUM_WAYS - 1) of std_logic;
    type data_array_type     is array(0 to NUM_SETS - 1, 0 to NUM_WAYS - 1) of std_logic_vector(WORD_WIDTH-1 downto 0);
    type lru_counter_type    is array(0 to NUM_SETS - 1, 0 to NUM_WAYS - 1) of integer range 0 to NUM_WAYS-1;

    signal tag_array    : tag_array_type;
    signal valid_array  : valid_array_type;
    signal data_array   : data_array_type;
    signal lru_counter  : lru_counter_type;

    signal addr_tag     : std_logic_vector(TAG_BITS-1 downto 0);
    signal addr_index   : integer range 0 to NUM_SETS-1;
    signal hit_way      : integer range -1 to NUM_WAYS-1 := -1;
    signal hit_reg      : std_logic := '0';

begin
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                for i in 0 to NUM_SETS - 1 loop
                    for j in 0 to NUM_WAYS - 1 loop
                        valid_array(i, j) <= '0';
                        lru_counter(i, j) <= 0;
                        data_array(i, j)  <= (others => '0');
                        tag_array(i, j)   <= (others => '0');
                    end loop;
                end loop;
                data_out <= (others => '0');
                hit      <= '0';
                miss     <= '0';
                hit_way  <= -1;

            else
                -- Extrai TAG e INDEX do endereço
                addr_tag   <= addr(ADDR_WIDTH-1 downto ADDR_WIDTH - TAG_BITS);
                addr_index <= to_integer(unsigned(addr(ADDR_WIDTH - TAG_BITS - 1 downto OFFSET_BITS)));

                hit_way := -1;

                -- Verifica hit
                for i in 0 to NUM_WAYS - 1 loop
                    if valid_array(addr_index, i) = '1' and tag_array(addr_index, i) = addr_tag then
                        hit_way := i;
                    end if;
                end loop;

                if hit_way /= -1 then
                    -- HIT
                    hit <= '1';
                    miss <= '0';
                    if rd_en = '1' then
                        data_out <= data_array(addr_index, hit_way);
                    end if;
                    if wr_en = '1' then
                        data_array(addr_index, hit_way) <= data_in;
                    end if;

                    -- Atualiza LRU: zera o contador da via usada e incrementa os outros
                    for i in 0 to NUM_WAYS - 1 loop
                        if i = hit_way then
                            lru_counter(addr_index, i) <= 0;
                        else
                            if valid_array(addr_index, i) = '1' then
                                lru_counter(addr_index, i) <= lru_counter(addr_index, i) + 1;
                            end if;
                        end if;
                    end loop;

                else
                    -- MISS
                    hit <= '0';
                    miss <= '1';

                    -- Substituição: encontra a via com maior contador (LRU)
                    variable max_val : integer := -1;
                    variable lru_way : integer := 0;
                    for i in 0 to NUM_WAYS - 1 loop
                        if valid_array(addr_index, i) = '0' then
                            lru_way := i;
                            exit;
                        elsif lru_counter(addr_index, i) > max_val then
                            max_val := lru_counter(addr_index, i);
                            lru_way := i;
                        end if;
                    end loop;

                    -- Atualiza dados
                    valid_array(addr_index, lru_way) <= '1';
                    tag_array(addr_index, lru_way)   <= addr_tag;
                    data_array(addr_index, lru_way)  <= data_in;

                    -- Zera LRU da nova via e incrementa os outros
                    for i in 0 to NUM_WAYS - 1 loop
                        if i = lru_way then
                            lru_counter(addr_index, i) <= 0;
                        else
                            if valid_array(addr_index, i) = '1' then
                                lru_counter(addr_index, i) <= lru_counter(addr_index, i) + 1;
                            end if;
                        end if;
                    end loop;
                end if;
            end if;
        end if;
    end process;
end rtl;
