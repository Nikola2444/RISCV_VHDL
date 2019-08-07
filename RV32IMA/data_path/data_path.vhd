library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity data_path is
   generic (DATA_WIDTH: positive := 32;
            INSTRUCTION_WIDTH: positive := 32);
   port(
      -- ********* Sync ports *****************************
      clk: in std_logic;
      reset: in std_logic;      
      -- ********* INSTRUCTION memory i/o *******************
      pc: out std_logic_vector (DATA_WIDTH - 1 downto 0);      
      instruction: in std_logic_vector(INSTRUCTION_WIDTH - 1 downto 0);
      -- ********* DATA memory i/o **************************

      data_address: out std_logic_vector(DATA_WIDTH - 1 downto 0);
      write_data: out std_logic_vector(DATA_WIDTH - 1 downto 0);
      read_data: in std_logic_vector (DATA_WIDTH - 1 downto 0);      
      -- ********* control signals **************************
      
      branch: in std_logic;
      mem_read: in std_logic;
      mem_to_reg: in std_logic;
      ALU_op: in std_logic_vector (4 downto 0);      
      --mem_write: in std_logic;-- data_path doenst need it
      ALU_src: in std_logic;      
      reg_write: in std_logic
    -- ******************************************************
      );
   
end entity;


architecture Behavioral of data_path is
   --**************REGISTERS*********************************
   
   signal pc_reg, pc_next: std_logic_vector (INSTRUCTION_WIDTH - 1 downto 0);
   
   --********************************************************


   --**************SIGNALS*********************************
   
   signal read_data1_s, read_data2_s, write_data_s: std_logic_vector (DATA_WIDTH - 1 downto 0);
   signal immediate_extended_s: std_logic_vector(DATA_WIDTH - 1 downto 0);

   -- Alu signals   
   signal alu_zero_s, alu_of_o_s: std_logic;
   signal b_i_s, a_i_s: std_logic_vector(DATA_WIDTH - 1 downto 0);
   signal ALU_result_s: std_logic_vector(DATA_WIDTH - 1 downto 0);
   
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
   pc_next <= std_logic_vector(unsigned(immediate_extended_s) + unsigned(pc_reg)) when (branch = '1' and alu_zero_s = '1') else
              std_logic_vector(unsigned(pc_reg) + to_unsigned(4, DATA_WIDTH));

   -- update of alu inputs
   b_i_s <= read_data2_s when ALU_src = '1' else
            immediate_extended_s;
   a_i_s <= read_data1_s;

   -- Reg_bank write_data update
   write_data_s <= read_data when mem_to_reg = '1' else
                   ALU_result_s;
   
   --********************************************
   

   --***********Register bank instance***********
   register_bank_1: entity work.register_bank
      generic map (
         WIDTH => DATA_WIDTH)
      port map (
         clk        => clk,
         reset      => reset,
         reg_write  => reg_write,
         read_reg1  => instruction(19 downto 15),
         read_reg2  => instruction(24 downto 20),
         read_data1 => read_data1_s,
         read_data2 => read_data2_s,
         write_reg  => instruction(11 downto 7),
         write_data => write_data_s);

   --*********************************************
   
   
   --***********Immediate unit instance***********
   
   immediate_1: entity work.immediate
      generic map (
         DATA_WIDTH        => DATA_WIDTH,
         INSTRUCTION_WIDTH => INSTRUCTION_WIDTH)
      port map (
         instruction        => instruction,
         immediate_extended => immediate_extended_s);
   
   --********************************************

   --***********ALU unit instance****************
   ALU_1: entity work.ALU
      generic map (
         WIDTH => DATA_WIDTH)
      port map (
         a_i    => a_i_s,
         b_i    => b_i_s,
         op_i   => ALU_op,
         res_o  => ALU_result_s,
         zero_o => alu_zero_s,
         of_o   => alu_of_o_s);
   --********************************************    


   --***********Outputs**************************
   pc <= pc_reg;
   data_address <= ALU_result_s;
   write_data <= read_data2_s;
   
end architecture;


