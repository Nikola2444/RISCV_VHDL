library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TOP_RISCV is
   generic (DATA_WIDTH: positive := 32);
   port(
      -- ********* Sync ports *****************************
      clk: in std_logic;
      reset: in std_logic;
      -- ********* INSTRUCTION memory i/o *******************       
      instr_mem_addr_o: out std_logic_vector (31 downto 0);      
      instr_mem_read_i: in std_logic_vector(31 downto 0);
      -- ********* DATA memory i/o **************************
      data_mem_we_o: out std_logic;  
      data_mem_addr_o: out std_logic_vector(31 downto 0);
      data_mem_write_o: out std_logic_vector(31 downto 0);
      data_mem_read_i: in std_logic_vector (31 downto 0));
end entity;

architecture structural of TOP_RISCV is
   signal branch_s: std_logic;
   --signal mem_read_s: std_logic;
   signal mem_to_reg_s: std_logic;
   signal alu_op_s: std_logic_vector (4 downto 0);
   signal mem_write_s: std_logic;
   signal alu_src_s: std_logic;
   signal rd_we_s: std_logic;
begin
   -- Data_path will be instantiated here
   --************************************
   data_path_1: entity work.data_path
      generic map (
         DATA_WIDTH => DATA_WIDTH)
      port map (
         clk                => clk,
         reset              => reset,
         instr_mem_addr_o   => instr_mem_addr_o,
         instr_mem_read_i   => instr_mem_read_i,
         data_mem_addr_o     => data_mem_addr_o,
         data_mem_write_o   => data_mem_write_o,
         data_mem_read_i    => data_mem_read_i,
         branch_i           => branch_s,         
         mem_to_reg_i       => mem_to_reg_s,
         alu_op_i           => alu_op_s,
         alu_src_i          => alu_src_s,
         rd_we_i            => rd_we_s);
   -- Control_path will be instantiated here
   control_path_1: entity work.control_path
      port map (
         clk           => clk,
         reset         => reset,
         instr_mem_read_i => instr_mem_read_i,
         branch_o      => branch_s,   
         mem_to_reg_o  => mem_to_reg_s,
         mem_write_o   => data_mem_we_o,
         alu_src_o     => alu_src_s,
         rd_we_o   => rd_we_s,
         alu_op_o      => alu_op_s);

   

--************************************
end architecture;
