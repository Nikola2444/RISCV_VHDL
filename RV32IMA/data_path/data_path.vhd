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
      --mem_read_i: in std_logic;
      mem_to_reg_i: in std_logic_vector(1 downto 0);
      load_type_i :in std_logic_vector(2 downto 0);
      alu_op_i: in std_logic_vector (4 downto 0);      
      alu_src_a_i: in std_logic;
      alu_src_b_i: in std_logic;
      alu_forward_a_i: in std_logic_vector (1 downto 0);
      alu_forward_b_i: in std_logic_vector (1 downto 0);
      branch_forward_a_i: in std_logic_vector (1 downto 0); 
      branch_forward_b_i: in std_logic_vector(1 downto 0);
      branch_condition_o: out std_logic;     

      pc_next_sel_i: in std_logic_vector(1 downto 0);

      reg_write_i: in std_logic;     
      alu_a_zero_i: in std_logic;

      if_id_flush_i: in std_logic;
      id_ex_flush_i: in std_logic;
      id_ex_write_i: in std_logic;

      pc_write_i: in std_logic;--controls program counter      
      if_id_write_i: in std_logic;
      
      ft_stall_o: out std_logic
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
         elsif (pc_write_i = '1') then
            pc_reg_if_s <= pc_next_if_s;
         end if;
      end if;      
   end process;

   --*********** IF/ID register ******************

   if_id:process (clk) is
   begin
      if (rising_edge(clk)) then
         if(if_id_write_i='1')then
            if (reset = '0' or if_id_flush_i = '1')then
               pc_reg_id_s <= (others => '0');
               pc_adder_id_s <= (others => '0');
            else
               pc_reg_id_s <= pc_reg_if_s;
               pc_adder_id_s <= pc_adder_if_s;            
            end if;
         end if;
      end if;      
   end process;
   
   --*********** ID/EX register ******************
   id_ex:process (clk) is
   begin
      if (rising_edge(clk)) then
         if (reset = '0' or id_ex_flush_i = '1')then
            pc_adder_ex_s <= (others => '0');
            rs1_data_ex_s <= (others => '0');
            rs2_data_ex_s <= (others => '0');
            immediate_extended_ex_s <= (others => '0');
            rd_address_ex_s <= (others => '0');
         elsif(id_ex_write_i='1')then
            pc_adder_ex_s <= pc_adder_id_s;
            rs1_data_ex_s <= rs1_data_id_s;
            rs2_data_ex_s <= rs2_data_id_s;
            immediate_extended_ex_s <= immediate_extended_id_s;
            rd_address_ex_s <= rd_address_id_s;
         end if;
      end if;      
   end process;

   --*********** EX/MEM register ******************
   ex_mem:process (clk) is
   begin
      if (rising_edge(clk)) then
         if (reset = '0')then
            alu_result_mem_s <= (others => '0');
            rs2_data_mem_s  <= (others => '0');
            pc_adder_mem_s <= (others => '0');
            rd_address_mem_s <= (others => '0');
            pc_reg_ex_s <= (others => '0');
         else
            alu_result_mem_s <= alu_result_ex_s;
            rs2_data_mem_s  <= alu_forward_b_ex_s;
            pc_adder_mem_s <= pc_adder_ex_s;
            rd_address_mem_s <= rd_address_ex_s;
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
            rd_address_wb_s <= (others => '0');
         else
            alu_result_wb_s <= alu_result_mem_s;
            pc_adder_wb_s <= pc_adder_mem_s; 
            rd_address_wb_s <= rd_address_mem_s;
         end if;
      end if;      
   end process;

   --***********Combinational logic***************

   --pc_adder_s update
   pc_adder_if_s <= std_logic_vector(unsigned(pc_reg_if_s) + to_unsigned(4, DATA_WIDTH));

   --branch_adder update
   branch_adder_id_s <= std_logic_vector(signed(immediate_extended_id_s) + signed(pc_reg_id_s));
   
   --branch condition inputs update
   branch_condition_a_ex_s <= rd_data_wb_s when branch_forward_a_i = "01" else
                              alu_result_mem_s when branch_forward_a_i = "10" else
                              rs1_data_id_s;
   branch_condition_b_ex_s <= rd_data_wb_s when branch_forward_b_i = "01" else
                              alu_result_mem_s when branch_forward_b_i = "10" else
                              rs2_data_id_s;
   
   
   --check if branch condition is met
   branch_condition_o <= '1' when ((signed(branch_condition_a_ex_s) = signed(branch_condition_b_ex_s)) and instr_mem_read_i(14 downto 13) = "00") else
                         '1' when ((signed(branch_condition_a_ex_s) < signed(branch_condition_b_ex_s)) and instr_mem_read_i(14 downto 13) = "10") else
                         '1' when ((signed(branch_condition_a_ex_s) > signed(branch_condition_b_ex_s)) and instr_mem_read_i(14 downto 13) = "11") else
                         '0';

   
   --pc_next mux
   with pc_next_sel_i select
      pc_next_if_s <= pc_adder_if_s when "00",
      alu_result_ex_s when "11",
      branch_adder_id_s when others;

   
   --forwarding muxes
   alu_forward_a_ex_s <= rd_data_wb_s when alu_forward_a_i = "01" else
                         alu_result_mem_s when alu_forward_a_i = "10" else
                         rs1_data_ex_s;
   alu_forward_b_ex_s <= rd_data_wb_s when alu_forward_b_i = "01" else
                         alu_result_mem_s when alu_forward_b_i = "10" else
                         rs2_data_ex_s;
   -- update of alu inputs
   
   b_ex_s <= immediate_extended_ex_s when alu_src_b_i = '1' else
             alu_forward_b_ex_s;

   a_ex_s <= (others=>'0') when alu_a_zero_i = '1' else
             pc_reg_ex_s when alu_src_a_i = '1' else
             alu_forward_a_ex_s;

   -- Reg_bank rd_data update
   rd_data_wb_s <= pc_adder_wb_s when mem_to_reg_i = "01" else
                   extended_data_wb_s when mem_to_reg_i = "10"else
                   alu_result_wb_s;


   -- extend data based on type of load instruction
   with load_type_i select --TODO Greska
      extended_data_wb_s <=  (31 downto 8 => data_mem_read_i(7))   & data_mem_read_i(7 downto 0) when "000",
      (31 downto 16 => data_mem_read_i(15)) & data_mem_read_i(15 downto 0) when "001",
      std_logic_vector(to_unsigned(0,24))   & data_mem_read_i(7 downto 0) when "100",
      std_logic_vector(to_unsigned(0,16))   & data_mem_read_i(15 downto 0) when "101",
      data_mem_read_i when others;


   rs1_address_id_s <= instr_mem_read_i(19 downto 15);
   rs2_address_id_s <= instr_mem_read_i(24 downto 20);
   rd_address_id_s <= instr_mem_read_i(11 downto 7);
   --***********Register bank instance***********
   register_bank_1: entity work.register_bank
      generic map (
         WIDTH => DATA_WIDTH)
      port map (
         clk        => clk,
         reset      => reset,
         reg_write_i  => reg_write_i,
         rs1_address_i  => rs1_address_id_s,
         rs2_address_i  => rs2_address_id_s,
         rs1_data_o => rs1_data_id_s,
         rs2_data_o => rs2_data_id_s,
         rd_address_i  => rd_address_wb_s,
         rd_data_i => rd_data_wb_s);

   --*********************************************
   
   
   --***********Immediate unit instance***********
   
   immediate_1: entity work.immediate
      port map (
         instruction_i        => instr_mem_read_i,
         immediate_extended_o => immediate_extended_id_s);
   
   --********************************************

   --***********ALU unit instance****************
   ALU_1: entity work.ALU_ft
      generic map (
      --WIDTH => DATA_WIDTH)
         NUM_MODULES => 4)
      port map (
         clk    => clk,
         reset  => reset,
         stall_o => ft_stall_o,
         a_i    => a_ex_s,
         b_i    => b_ex_s,
         op_i   => alu_op_i,
         res_o  => alu_result_ex_s,
         zero_o => alu_zero_ex_s,
         of_o   => alu_of_ex_s);
   --********************************************    


   --***********Outputs**************************
   -- Instruction memory
   instr_mem_address_o <= pc_reg_if_s;
   -- Data memory
   data_mem_address_o <= alu_result_mem_s; 
   data_mem_write_o <= rs2_data_mem_s;
   
end architecture;


