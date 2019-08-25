
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.datapath_signals_pkg.all;


entity data_path is
   generic (DATA_WIDTH: positive := 32);
   port(
      -- ********* Sync ports *****************************
      clk: in std_logic;
      reset: in std_logic;      

      -- ********* INSTRUCTION memory i/o *******************
      instr_mem_address_o: out std_logic_vector (DATA_WIDTH - 1 downto 0);      
      instr_mem_read_i: in std_logic_vector(DATA_WIDTH - 1 downto 0);

      -- ********* DATA memory i/o **************************
      data_mem_address_o: out std_logic_vector(DATA_WIDTH - 1 downto 0);
      data_mem_write_o: out std_logic_vector(DATA_WIDTH - 1 downto 0);
      data_mem_read_i: in std_logic_vector (DATA_WIDTH - 1 downto 0);      

      -- ********* control signals **************************
      branch_i: in std_logic_vector(1 downto 0);
      mem_read_i: in std_logic;
      mem_to_reg_i: in std_logic_vector(1 downto 0);
      alu_op_i: in std_logic_vector (4 downto 0);      
      alu_src_a_i: in std_logic;
      alu_src_b_i: in std_logic;
      alu_forward_a_i: in std_logic_vector (1 downto 0);
      alu_forward_b_i: in std_logic_vector (1 downto 0);
      branch_forward_a_i: in std_logic_vector (1 downto 0); 
      branch_forward_b_i: in std_logic_vector(1 downto 0);
      --if_id_write_i: in std_logic;      
      reg_write_i: in std_logic;     
      alu_a_zero_i: in std_logic;
      instruction_mem_flush_o: out std_logic;
      pc_write_i: out std_logic;--controls program counter      
      
      if_id_write_i: in std_logic
      );
   
end entity;


architecture Behavioral of data_path is
begin
   
   --*********** Sequential logic ******************
   --*********** Program Counter ******************
   pc_proc:process (clk) is
   begin
      if (rising_edge(clk)) then
         if (reset = '0')then
            pc_reg_if_s <= (others => '0');
         else
            if (if_id_write_i = '0') then
               pc_reg_if_s <= pc_next_if_s;
            end if;
         end if;
      end if;      
   end process;

   --*********** IF/ID register ******************

   if_id:process (clk) is
   begin
      if (rising_edge(clk)) then
         --if(if_id_write_i)then
            if (reset = '0' or if_id_reg_flush_s = '1')then
               pc_reg_id_s <= (others => '0');
               pc_adder_id_s <= (others => '0');
            else
               if (if_id_write_i = '0') then
                  pc_reg_id_s <= pc_reg_if_s;
                  pc_adder_id_s <= pc_adder_if_s;
               end if;
            end if;
         --end if;
      end if;      
   end process;
   
   --*********** ID/EX register ******************
   id_ex:process (clk) is
   begin
      if (rising_edge(clk)) then
         if (reset = '0')then
            pc_adder_ex_s <= (others => '0');
            read_data1_ex_s <= (others => '0');
            read_data2_ex_s <= (others => '0');
            immediate_extended_ex_s <= (others => '0');
            write_reg_ex_s <= (others => '0');
         else
            pc_adder_ex_s <= pc_adder_id_s;
            read_data1_ex_s <= read_data1_id_s;
            read_data2_ex_s <= read_data2_id_s;
            immediate_extended_ex_s <= immediate_extended_id_s;
            write_reg_ex_s <= write_reg_id_s;
         end if;
      end if;      
   end process;

   --*********** EX/MEM register ******************
   ex_mem:process (clk) is
   begin
      if (rising_edge(clk)) then
         if (reset = '0')then
            alu_result_mem_s <= (others => '0');
            read_data2_mem_s  <= (others => '0');
            pc_adder_mem_s <= (others => '0');
            write_reg_mem_s <= (others => '0');
            pc_reg_ex_s <= (others => '0');
         else
            alu_result_mem_s <= alu_result_ex_s;
            read_data2_mem_s  <= read_data2_ex_s;
            pc_adder_mem_s <= pc_adder_ex_s;
            write_reg_mem_s <= write_reg_ex_s;
            pc_reg_ex_s <= pc_reg_id_s;
         end if;
      end if;      
   end process;

   --*********** MEM/WB register ******************
   mem_wb:process (clk) is
   begin
      if (rising_edge(clk)) then
         if (reset = '0')then
            alu_result_wb_s <= (others => '0');
            pc_adder_wb_s <= (others => '0');
            write_reg_wb_s <= (others => '0');
         else
            alu_result_wb_s <= alu_result_mem_s;
            pc_adder_wb_s <= pc_adder_mem_s; 
            write_reg_wb_s <= write_reg_mem_s;
         end if;
      end if;      
   end process;

   --***********Combinational logic***************
   bcc_id_s <= instr_mem_read_i(12);

   --pc_adder_s update
   pc_adder_if_s <= std_logic_vector(unsigned(pc_reg_if_s) + to_unsigned(4, DATA_WIDTH));

   --branch_adder update
   branch_adder_id_s <= std_logic_vector(unsigned(immediate_extended_id_s) + unsigned(pc_reg_id_s));
   
   --branch condition inputs update
   branch_condition_a_ex_s <= write_data_wb_s when branch_forward_a_i = "01" else
                           alu_result_mem_s when branch_forward_a_i = "10" else
                           read_data1_id_s;
   branch_condition_b_ex_s <= write_data_wb_s when branch_forward_b_i = "01" else
                           alu_result_mem_s when branch_forward_b_i = "10" else
                           read_data2_id_s;
                           
                           
   --check if branch condition is met
   branch_condition_id_s <= '1' when ((signed(branch_condition_a_ex_s) = signed(branch_condition_b_ex_s)) and instr_mem_read_i(14 downto 13) = "00") else
                            '1' when ((signed(branch_condition_a_ex_s) < signed(branch_condition_b_ex_s)) and instr_mem_read_i(14 downto 13) = "10") else
                            '1' when ((signed(branch_condition_a_ex_s) > signed(branch_condition_b_ex_s)) and instr_mem_read_i(14 downto 13) = "11") else
                            '0';

   
   --this mux covers conditional and unconditional branches
   -- TODO: maybe insert more control signals to chose between jumps
   if_branch:process(branch_adder_id_s, branch_i, branch_condition_id_s, bcc_id_s,
                     alu_result_ex_s, pc_adder_if_s,pc_adder_if_s)
   begin
      if (branch_i = "01" and ((branch_condition_id_s xor bcc_id_s) = '1'))then
         if_id_reg_flush_s <= '1';
         pc_next_if_s <= branch_adder_id_s;
      elsif(branch_i = "10")then
         if_id_reg_flush_s <= '1';
         pc_next_if_s <= branch_adder_id_s;
      elsif(branch_i = "11") then
         if_id_reg_flush_s <= '1';
         pc_next_if_s <= alu_result_ex_s;
      else
         if_id_reg_flush_s <= '0';
         pc_next_if_s <= pc_adder_if_s;
      end if;
   end process;
      
   --forwarding muxes
   alu_forward_a_ex_s <= write_data_wb_s when alu_forward_a_i = "01" else
                     alu_result_mem_s when alu_forward_a_i = "10" else
                     read_data1_ex_s;
   alu_forward_b_ex_s <= write_data_wb_s when alu_forward_b_i = "01" else
                     alu_result_mem_s when alu_forward_b_i = "10" else
                     read_data2_ex_s;
   -- update of alu inputs
   
   b_ex_s <= immediate_extended_ex_s when alu_src_b_i = '1' else
             alu_forward_b_ex_s;

   a_ex_s <= (others=>'0') when alu_a_zero_i = '1' else
             pc_reg_ex_s when alu_src_a_i = '1' else
             alu_forward_a_ex_s;

   -- Reg_bank write_data update
   write_data_wb_s <= pc_adder_wb_s when mem_to_reg_i = "01" else
                      extended_data_wb_s when mem_to_reg_i = "10"else
                      alu_result_wb_s;


   -- extend data based on type of load instruction
   with instr_mem_read_i(14 downto 12) select
      extended_data_wb_s <=  (31 downto 8 => data_mem_read_i(7))   & data_mem_read_i(7 downto 0) when "000",
                             (31 downto 16 => data_mem_read_i(15)) & data_mem_read_i(15 downto 0) when "001",
                             std_logic_vector(to_unsigned(0,24))   & data_mem_read_i(7 downto 0) when "100",
                             std_logic_vector(to_unsigned(0,16))   & data_mem_read_i(15 downto 0) when "101",
                             data_mem_read_i when others;


   read_reg1_id_s <= instr_mem_read_i(19 downto 15);
   read_reg2_id_s <= instr_mem_read_i(24 downto 20);
   write_reg_id_s <= instr_mem_read_i(11 downto 7);
   --***********Register bank instance***********
   register_bank_1: entity work.register_bank
      generic map (
         WIDTH => DATA_WIDTH)
      port map (
         clk        => clk,
         reset      => reset,
         reg_write_i  => reg_write_i,
         read_reg1_i  => read_reg1_id_s,
         read_reg2_i  => read_reg2_id_s,
         read_data1_o => read_data1_id_s,
         read_data2_o => read_data2_id_s,
         write_reg_i  => write_reg_wb_s,
         write_data_i => write_data_wb_s);

   --*********************************************
   
   
   --***********Immediate unit instance***********
   
   immediate_1: entity work.immediate
      port map (
         instruction_i        => instr_mem_read_i,
         immediate_extended_o => immediate_extended_id_s);
   
   --********************************************

   --***********ALU unit instance****************
   ALU_1: entity work.ALU
      generic map (
         WIDTH => DATA_WIDTH)
      port map (
         a_i    => a_ex_s,
         b_i    => b_ex_s,
         op_i   => alu_op_i,
         res_o  => alu_result_ex_s,
         zero_o => alu_zero_ex_s,
         of_o   => alu_of_ex_s);
   --********************************************    


   --***********Outputs**************************
   -- Instruction memory
   instruction_mem_flush_o <= if_id_reg_flush_s;
   instr_mem_address_o <= pc_reg_if_s;
   -- Data memory
   data_mem_address_o <= alu_result_mem_s; 
   data_mem_write_o <= read_data2_mem_s;
   
end architecture;


