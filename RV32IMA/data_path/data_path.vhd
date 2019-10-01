library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity data_path is
   generic (DATA_WIDTH: positive := 32);
   port(
      -- ********* Sync ports *******************************
      clk: in std_logic;
      reset: in std_logic;      
      -- ********* Interfejs za prihvat instrukcije *********
      instr_mem_addr_o: out std_logic_vector (31 downto 0);      
      instr_mem_read_i: in std_logic_vector(31 downto 0);
      -- ********* Interfejs za prihvat i upis podataka *****
      data_mem_addr_o: out std_logic_vector(31 downto 0);
      data_mem_write_o: out std_logic_vector(31 downto 0);
      data_mem_read_i: in std_logic_vector (31 downto 0);      
      -- ********* Kontrolni signali ************************      
      branch_i: in std_logic;
      mem_to_reg_i: in std_logic;
      alu_op_i: in std_logic_vector (4 downto 0);      
      alu_src_i: in std_logic;      
      rd_we_i: in std_logic
    -- ******************************************************
      );
   
end entity;


architecture Behavioral of data_path is
   --**************REGISTRI*********************************   
   signal pc_reg, pc_next: std_logic_vector (31 downto 0);   
   --********************************************************
   --**************SIGNALI*********************************
   signal pc_adder_s: std_logic_vector(31 downto 0);
   signal branch_adder_s: std_logic_vector(31 downto 0);
   signal rs1_data_s, rs2_data_s, rd_data_s: std_logic_vector (31 downto 0);
   signal immediate_extended_s, extended_data_s: std_logic_vector(31 downto 0);
   -- AlU signali   
   signal alu_zero_s, alu_of_o_s: std_logic;
   signal b_s, a_s: std_logic_vector(31 downto 0);
   signal alu_result_s: std_logic_vector(31 downto 0);
   --Signali grananja (eng. branch signals).
   signal branch_condition_s: std_logic;
   signal bcc : std_logic;   
   --*****************************************************   
begin

   --***********Sekvencijalna logika******************   
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

   --***********Kombinaciona logika***************
   bcc <= instr_mem_read_i(12);

   
   pc_adder_s <= std_logic_vector(unsigned(pc_reg) + to_unsigned(4, DATA_WIDTH));
   branch_adder_s <= std_logic_vector(unsigned(immediate_extended_s) + unsigned(pc_reg));

   -- Komparator jednakosti. Neophodan za BEQ instrukciju.
   branch_condition_s <= '1' when a_s = b_s else
                         '0';
   
   -- MUX koji odredjuje Sledecu vrednost za PC_next.
   -- Ako se ne desi skok programski brojac se uvecava za 4.
   pc_next <=  branch_adder_s when (branch_i = '1' and branch_condition_s = '1') else
               pc_adder_s;
   
   -- MUX koji odredjuje Sledecu vrednost za b ulaz ALU jedinice.
   b_s <= rs2_data_s when alu_src_i = '0' else
          immediate_extended_s;
   -- Sledeca vrednost za a ulaz alu jedinice
   a_s <= rs1_data_s;

   -- MUX koji odredjuje Sledecu vrednost za rd_data_s ulaz registarske banke.
   rd_data_s <= data_mem_read_i when mem_to_reg_i = '1' else
                alu_result_s;
   
   --***********Registarska banka***********
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

   --***********Aritmeticko logicka jedinica*****
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

   --***********Sledeca vrednost Izlaza**********
   instr_mem_addr_o <= pc_reg;
   data_mem_addr_o <= alu_result_s;
   data_mem_write_o <= rs2_data_s;
   
end architecture;


