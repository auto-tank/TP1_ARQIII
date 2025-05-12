# Configuração do Projeto

Trabalho Prático de Arquitetura de Computadores III:  Implementação de uma Hierarquia de Memória com um Nível de Cache.

## Instruções

### Pré-requisitos

Antes de começar, certifique-se de ter os seguintes itens instalados:

- [GHDL](https://github.com/ghdl/ghdl)
- [GTKWave](https://gtkwave.sourceforge.net/)
- [Git](https://git-scm.com/downloads)

Este trabalho foi testado apenas no sistema operacional **Ubuntu 24.04.2 LTS x86_64**, podem haver erros por conta disso.

### Passos

1. **Clonar o repositório**

    Baixe os arquivos do projeto em sua máquina local.

    ```bash
    git clone https://github.com/auto-tank/TP1_ARQIII
    cd TP1_ARQIII
    ```

2. **Executar as implementações de cache para o Mapeamento Direto**

    Rode os seguintes comandos:

    ```bash
    ghdl -a cache_direct_mapped.vhd
    ghdl -a tb_cache_direct_mapped.vhd
    ghdl -e tb_cache_direct_mapped
    ghdl -r tb_cache_direct_mapped --vcd=wave.vcd
    gtkwave wave.vcd
    ```

3. **Executar as implementações de cache para o Mapeamento Associativo de 4 Vias**

    Rode os seguintes comandos:

    ```bash
    ghdl -a cache_4way_associative.vhd
    ghdl -a tb_cache_4way_associative.vhd
    ghdl -e tb_cache_4way_associative
    ghdl -r tb_cache_4way_associative --vcd=wave4way.vcd
    gtkwave wave4way.vcd
    ```
