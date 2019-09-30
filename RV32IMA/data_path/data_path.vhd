library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity data_path is
   generic (DATA_WIDTH: positive := 32);
   port(
      -- ********* Sync ports *******************************
      clk: in std_logic;
      reset: in std_logic;      
      -- ********* INSTRUCTION memory i/o *******************
      instr_mem_addr_o: out std_logic_vector (31 downto 0);      
      instr_mem_read_i: in std_logic_vector(31 downto 0);
      -- ********* DATA memory i/o **************************
      data_mem_addr_o: out std_logic_vector(31 downto 0);
      data_mem_write_o: out std_logic_vector(31 downto 0);
      data_mem_read_i: in std_logic_vector (31 downto 0);      
      -- ********* CONTROL SIGNALS **************************      
      branch_i: in std_logic;
      mem_to_reg_i: in std_logic;
      alu_op_i: in std_logic_vector (4 downto 0);      
      alu_src_i: in std_logic;      
      rd_we_i: in std_logic
    -- ******************************************************
      );
   
end entity;


architecture Behavioral of data_path is
   --**************REGISTERS*********************************   
   signal pc_reg, pc_next: std_logic_vector (31 downto 0);   
   --********************************************************
   --**************SIGNALS*********************************
   signal pc_adder_s: std_logic_vector(31 downto 0);
   signal branch_adder_s: std_logic_vector(31 downto 0);
   signal rs1_data_s, rs2_data_s, rd_data_s: std_logic_vector (31 downto 0);
   signal immediate_extended_s, extended_data_s: std_logic_vector(31 downto 0);
   -- Alu signals   
   signal alu_zero_s, alu_of_o_s: std_logic;
   signal b_s, a_s: std_logic_vector(31 downto 0);
   signal alu_result_s: std_logic_vector(31 downto 0);
   --branch condition complement 
   signal bcc : std_logic;   
   --*****************************************************
   --**************CONSTANTS******************************
   constant zero_24bit_c: std_logic_vector(23 downto 0):= std_logic_vector(to_unsigned(0,24));
   constant zero_16bit_c: std_logic_vector(15 downto 0):= std_logic_vector(to_unsigned(0,16));
   --*****************************************************
   
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
   bcc <= instr_mem_read_i(12);

   
   pc_adder_s <= std_logic_vector(unsigned(pc_reg) + to_unsigned(4, DATA_WIDTH));
   branch_adder_s <= std_logic_vector(unsigned(immediate_extended_s) + unsigned(pc_reg));

   -- PC_next update. If jump doesn' take place pc is incremented by 4.
   pc_next <=  branch_adder_s when (branch_i = '1' and (alu_zero_s xor bcc) = '0') else
               pc_adder_s;

   -- update of alu inputs
   b_s <= rs2_data_s when alu_src_i = '0' else
            immediate_extended_s;
   a_s <= rs1_data_s;

   -- Reg_bank rd_data_s update
   rd_data_s <= extended_data_s when mem_to_reg_i = '1' else
                alu_result_s;

   -- Selects to load 1,2 or 4 bytes by detecting which type of load took place.
   with instr_mem_read_i(14 downto 12) select
      extended_data_s <= (31 downto 8 => data_mem_read_i(7)) & data_mem_read_i(7 downto 0) when "000", --signed load of 1 byte
                         (31 downto 16 => data_mem_read_i(15)) & data_mem_read_i(15 downto 0) when "001", --signed load of 2 bytes
                         zero_24bit_c & data_mem_read_i(7 downto 0) when "100", --unsigned load of 1 byte
                         zero_16bit_c & data_mem_read_i(15 downto 0) when "101",--unsigned load of 2 bytes
                         data_mem_read_i when others;
   --********************************************

   --***********Register bank instance***********
   register_bank_1: entity work.register_bank
      generic map (
         WIDTH => 32)
      port map (
         clk        => clk,
         reset      => reset,
         rd_we_i  => rd_we_i,
         rs1_address_i  => instr_mem_read_i (19 downto 15),
         rs2_address_i  => instr_mem_read_i (24 downto 20),
         rs1_data_o => rs1_data_s,
         rs2_data_o => rs2_data_s,
         rd_address_i  => instr_mem_read_i (11 downto 7),
         rd_data_i => rd_data_s);

   --*********************************************
   
   --***********Immediate unit instance***********   
   immediate_1: entity work.immediate
      port map (
         instr_mem_read_i        => instr_mem_read_i,
         immediate_extended_o => immediate_extended_s);   
   --********************************************

   --***********ALU unit instance****************
   ALU_1: entity work.ALU
      generic map (
         WIDTH => DATA_WIDTH)
      port map (
         a_i    => a_s,
         b_i    => b_s,
         op_i   => alu_op_i,
         res_o  => alu_result_s,
         zero_o => alu_zero_s,
         of_o   => alu_of_o_s);
   --********************************************    

   --***********Outputs**************************
   instr_mem_addr_o <= pc_reg;
   data_mem_addr_o <= alu_result_s;
   data_mem_write_o <= rs2_data_s;
   
end architecture;


