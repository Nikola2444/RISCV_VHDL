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
      
      branch_i: in std_logic_vector(1 downto 0);
      mem_read_i: in std_logic;
      mem_to_reg_i: in std_logic_vector(1 downto 0);
      alu_op_i: in std_logic_vector (4 downto 0);      
      --mem_write: in std_logic;-- data_path doenst need it
      alu_src_b_i: in std_logic;
      alu_src_a_i: in std_logic;

      reg_write_i: in std_logic
    -- ******************************************************
      );
   
end entity;


architecture Behavioral of data_path is
   --**************REGISTERS*********************************
   
   signal pc_reg, pc_next: std_logic_vector (31 downto 0);
   
   --********************************************************


   --**************SIGNALS*********************************
   
   signal read_data1_s, read_data2_s, write_data_s, extended_data_s: std_logic_vector (DATA_WIDTH - 1 downto 0);
   signal immediate_extended_s: std_logic_vector(DATA_WIDTH - 1 downto 0);

   -- Alu signals   
   signal alu_zero_s, alu_of_o_s: std_logic;
   signal b_i_s, a_i_s: std_logic_vector(DATA_WIDTH - 1 downto 0);
   signal alu_result_s: std_logic_vector(DATA_WIDTH - 1 downto 0);

   signal bcc : std_logic; --branch condition complement

   --pc_adder_s signal
   signal pc_adder_s: std_logic_vector (31 downto 0);
   --branch_adder signal
   signal branch_adder_s: std_logic_vector (31 downto 0);
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
   bcc <= instruction_i(12);

   --pc_adder_s update
   pc_adder_s <= std_logic_vector(unsigned(pc_reg) + to_unsigned(4, DATA_WIDTH));

   --branch_adder update
   branch_adder_s <= std_logic_vector(unsigned(immediate_extended_s) + unsigned(pc_reg));
   -- PC_reg update

   --this mux covers conditional and unconditional branches
   -- TODO: maybe insert more control signals to chose between jumps
   pc_next <= branch_adder_s when (branch_i = "01" and ((alu_zero_s xor bcc) = '0' )) else --conditional_branches
              branch_adder_s when (branch_i = "10") else --jal_instruction
              alu_result_s when (branch_i = "11") else ----jarl_instruction
              pc_adder_s;
   
   -- update of alu inputs
   b_i_s <= read_data2_s when alu_src_b_i = '0' else
            immediate_extended_s;
   a_i_s <= read_data1_s when alu_src_a_i = '0' else
            pc_reg;

   -- Reg_bank write_data_o update
   write_data_s <= pc_adder_s when mem_to_reg_i = "01" else
                   extended_data_s when mem_to_reg_i = "10"else
                   alu_result_s;
   --********************************************

   with instruction_i(14 downto 12) select
      extended_data_s <= (31 downto 8 => read_ext_data_i(7)) & read_ext_data_i(7 downto 0) when "000",
      (31 downto 16 => read_ext_data_i(15)) & read_ext_data_i(15 downto 0) when "001",
      std_logic_vector(to_unsigned(0,24)) & read_ext_data_i(7 downto 0) when "100",
      std_logic_vector(to_unsigned(0,16)) & read_ext_data_i(15 downto 0) when "101",
      read_ext_data_i when others;

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


