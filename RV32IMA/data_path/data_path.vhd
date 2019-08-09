library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity data_path is
   generic (DATA_WIDTH: positive := 32);
   port(
      -- ********* Sync ports *****************************
      clk: in std_logic;
      reset: in std_logic;      
      -- ********* INSTRUCTION memory i/o *******************
      pc_o: out std_logic_vector (DATA_WIDTH - 1 downto 0);      
      instruction_i: in std_logic_vector(31 downto 0);
      -- ********* DATA memory i/o **************************

      ext_data_address_o: out std_logic_vector(DATA_WIDTH - 1 downto 0);
      write_ext_data_o: out std_logic_vector(DATA_WIDTH - 1 downto 0);
      read_ext_data_i: in std_logic_vector (DATA_WIDTH - 1 downto 0);      
      -- ********* control signals **************************
      
      branch_i: in std_logic;
      mem_read_i: in std_logic;
      mem_to_reg_i: in std_logic;
      alu_op_i: in std_logic_vector (4 downto 0);      
      --mem_write: in std_logic;-- data_path doenst need it
      alu_src_i: in std_logic;      
      reg_write_i: in std_logic
    -- ******************************************************
      );
   
end entity;


architecture Behavioral of data_path is
   --**************REGISTERS*********************************
   
   signal pc_reg, pc_next: std_logic_vector (31 downto 0);
   
   --********************************************************


   --**************SIGNALS*********************************
   
   signal read_data1_s, read_data2_s, write_data_s: std_logic_vector (DATA_WIDTH - 1 downto 0);
   signal immediate_extended_s: std_logic_vector(DATA_WIDTH - 1 downto 0);

   -- Alu signals   
   signal alu_zero_s, alu_of_o_s: std_logic;
   signal b_i_s, a_i_s: std_logic_vector(DATA_WIDTH - 1 downto 0);
   signal alu_result_s: std_logic_vector(DATA_WIDTH - 1 downto 0);
   
--********************************************************
begin

   --***********Sequential logic******************
   
   pc_proc:process (clk) is
   begin
      if (rising_edge(clk)) then
         if (reset = '0')then
            pc_reg <= (others => '0');
         else
            pc_reg <= pc_next;
         end if;
      end if;      
   end process;

   --*********************************************

   
   --***********Combinational logic***************
   
   -- PC_reg update
   pc_next <= std_logic_vector(unsigned(immediate_extended_s) + unsigned(pc_reg)) when (branch_i = '1' and alu_zero_s = '1') else
              std_logic_vector(unsigned(pc_reg) + to_unsigned(4, DATA_WIDTH));

   -- update of alu inputs
   b_i_s <= read_data2_s when alu_src_i = '1' else
            immediate_extended_s;
   a_i_s <= read_data1_s;

   -- Reg_bank write_data_o update
   write_data_s <= read_ext_data_i when mem_to_reg_i = '1' else
                   alu_result_s;
   
   --********************************************
   

   --***********Register bank instance***********
   register_bank_1: entity work.register_bank
      generic map (
         WIDTH => DATA_WIDTH)
      port map (
         clk        => clk,
         reset      => reset,
         reg_write_i  => reg_write_i,
         read_reg1_i  => instruction_i(19 downto 15),
         read_reg2_i  => instruction_i(24 downto 20),
         read_data1_o => read_data1_s,
         read_data2_o => read_data2_s,
         write_reg_i  => instruction_i(11 downto 7),
         write_data_i => write_data_s);

   --*********************************************
   
   
   --***********Immediate unit instance***********
   
   immediate_1: entity work.immediate
      port map (
         instruction_i        => instruction_i,
         immediate_extended_o => immediate_extended_s);
   
   --********************************************

   --***********ALU unit instance****************
   ALU_1: entity work.ALU
      generic map (
         WIDTH => DATA_WIDTH)
      port map (
         a_i    => a_i_s,
         b_i    => b_i_s,
         op_i   => alu_op_i,
         res_o  => alu_result_s,
         zero_o => alu_zero_s,
         of_o   => alu_of_o_s);
   --********************************************    


   --***********Outputs**************************
   pc_o <= pc_reg;
   ext_data_address_o <= alu_result_s;
   write_ext_data_o <= read_data2_s;
   
end architecture;


