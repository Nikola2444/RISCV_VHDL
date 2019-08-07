library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TOP_RISCV is
   generic (DATA_WIDTH: positive := 32;
            INSTRUCTION_WIDTH: positive := 32);
   port(
      -- ********* Sync ports *****************************
      clk: in std_logic;
      reset: in std_logic;
      -- ********* INSTRUCTION memory i/o *******************       
      instruction: in std_logic_vector(INSTRUCTION_WIDTH - 1 downto 0);
      pc: out std_logic_vector(INSTRUCTION_WIDTH - 1 downto 0);
      -- ********* DATA memory i/o **************************
      mem_write: out std_logic; -- 
      data_address: out std_logic_vector(DATA_WIDTH - 1 downto 0);
      read_data: in std_logic;
      write_data: out std_logic_vector(DATA_WIDTH - 1 downto 0));


end entity;

architecture structural of TOP_RISCV is
   signal branch_s: std_logic;
   signal mem_read_s: std_logic;
   signal mem_to_reg_s: std_logic;
   signal ALU_op_s: std_logic_vector (4 downto 0);
   signal mem_write_s: std_logic;
   signal ALU_src_s: std_logic;
   signal reg_write_s: std_logic;
begin
   -- Data_path will be instantiated here
   --************************************
   data_path_1: entity work.data_path
      generic map (
         DATA_WIDTH        => DATA_WIDTH,
         INSTRUCTION_WIDTH => INSTRUCTION_WIDTH)
      port map (
         clk          => clk,
         reset        => reset,
         pc           => pc,
         instruction  => instruction,
         data_address => data_address,
         write_data   => write_data,
         read_data    => read_data,
         branch       => branch,
         mem_read     => mem_read,
         mem_to_reg   => mem_to_reg,
         ALU_op       => ALU_op,
         --mem_write    => mem_write, -- this comes from control_path
         ALU_src      => ALU_src,
         reg_write    => reg_write);
   -- Control_path will be instantiated here
   c_path: entity work.control_path(Behavioral)
      port map(clk => clk,
               reset => reset,
               instruction => instruction);

   

--************************************
end architecture;
