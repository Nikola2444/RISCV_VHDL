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
      instruction_i: in std_logic_vector(31 downto 0);
      pc_o: out std_logic_vector(31 downto 0);
      -- ********* DATA memory i/o **************************
      mem_ext_write_o: out std_logic;  
      ext_data_address_o: out std_logic_vector(DATA_WIDTH - 1 downto 0);
      read_ext_data_i: in std_logic_vector(DATA_WIDTH - 1 downto 0);
      write_ext_data_o: out std_logic_vector(DATA_WIDTH - 1 downto 0));


end entity;

architecture structural of TOP_RISCV is
   signal branch_s: std_logic;
   signal mem_read_s: std_logic;
   signal mem_to_reg_s: std_logic_vector(1 downto 0);
   signal alu_op_s: std_logic_vector (4 downto 0);
   signal mem_write_s: std_logic;
   signal alu_src_b_s: std_logic;
   signal alu_src_a_s: std_logic;
   signal reg_write_s: std_logic;
begin
   -- Data_path will be instantiated here
   --************************************
   data_path_1: entity work.data_path
      generic map (
         DATA_WIDTH => DATA_WIDTH)
      port map (
         clk                => clk,
         reset              => reset,
         pc_o               => pc_o,
         instruction_i      => instruction_i,
         ext_data_address_o => ext_data_address_o,
         write_ext_data_o   => write_ext_data_o,
         read_ext_data_i    => read_ext_data_i,
         branch_i           => branch_s,
         mem_read_i         => mem_read_s,
         mem_to_reg_i       => mem_to_reg_s,
         alu_op_i           => alu_op_s,
         alu_src_b_i          => alu_src_b_s,
         alu_src_a_i          => alu_src_a_s,
         reg_write_i        => reg_write_s);
   -- Control_path will be instantiated here
   control_path_1: entity work.control_path
      port map (
         clk           => clk,
         reset         => reset,
         instruction_i => instruction_i,
         branch_o      => branch_s,
         mem_read_o    => mem_read_s,
         mem_to_reg_o  => mem_to_reg_s,
         mem_write_o   => mem_ext_write_o,
         alu_src_b_o     => alu_src_b_s,
         alu_src_a_o     => alu_src_a_s,
         reg_write_o   => reg_write_s,
         alu_op_o      => alu_op_s);

   

--************************************
end architecture;
