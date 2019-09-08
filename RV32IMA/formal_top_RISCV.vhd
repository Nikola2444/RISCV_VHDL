library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity formal_top_RISCV is
  generic (DATA_WIDTH: positive := 32);
  port(
    -- ********* Sync ports *****************************
    clk: in std_logic;
    reset: in std_logic;
    -- ********* INSTRUCTION memory i/o *******************       
    instr_mem_read_i: in std_logic_vector(31 downto 0);
    instr_mem_address_o: out std_logic_vector(31 downto 0);
    instruction_mem_flush_o:out std_logic;
    instruction_mem_en_o: out std_logic;
    -- ********* DATA memory i/o **************************
    mem_write_o: out std_logic_vector(3 downto 0);  
    data_mem_address_o: out std_logic_vector(DATA_WIDTH - 1 downto 0);
    data_mem_read_i: in std_logic_vector(DATA_WIDTH - 1 downto 0);
    data_mem_write_o: out std_logic_vector(DATA_WIDTH - 1 downto 0));end entity;


architecture behavioral of formal_top_RISCV is
  signal instr_mem_read_s:std_logic_vector(31 downto 0);
  signal instruction_mem_en_s:std_logic;
  signal instruction_mem_flush_s:std_logic;
begin
  
  TOP_RISCV_1: entity work.TOP_RISCV
    generic map (
      DATA_WIDTH => DATA_WIDTH)
    port map (
      clk                     => clk,
      reset                   => reset,
      instr_mem_read_i        => instr_mem_read_s,
      instr_mem_address_o     => instr_mem_address_o,
      instruction_mem_flush_o => instruction_mem_flush_s,
      instruction_mem_en_o    => instruction_mem_en_s,
      mem_write_o             => mem_write_o,
      data_mem_address_o      => data_mem_address_o,
      data_mem_read_i         => data_mem_read_i,
      data_mem_write_o        => data_mem_write_o);

  process(clk)is
  begin
    if (rising_edge(clk))then
      if (reset = '0') then
        instr_mem_read_s <= (others => '0');
      elsif (instruction_mem_en_s = '1')then
        instr_mem_read_s <= instr_mem_read_i;
        if (instruction_mem_flush_s = '1')then
          instr_mem_read_s <= (others => '0');
        end if;
      end if;        
    end if;
  end process;
  
  instruction_mem_en_o    <= instruction_mem_en_s;
  instruction_mem_flush_o <= instruction_mem_flush_s;
end architecture;
