library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.controlpath_signals_pkg.all;

entity control_path is
   port (clk: in std_logic;
         reset: in std_logic;
         -- from top
         instruction_i: in std_logic_vector (31 downto 0);
         --to datapath
         --mem_read_o: out std_logic;
         mem_to_reg_o: out std_logic_vector(1 downto 0);
         mem_write_o: out std_logic_vector(3 downto 0);
         load_type_o: out std_logic_vector(2 downto 0); 
         alu_src_b_o: out std_logic;
         alu_src_a_o: out std_logic;
         reg_write_o: out std_logic;
         alu_a_zero_o: out std_logic;        
         alu_op_o: out std_logic_vector(4 downto 0);
         --forwarding interface
         alu_forward_a_o: out std_logic_vector (1 downto 0);
         alu_forward_b_o: out std_logic_vector (1 downto 0);
         branch_forward_a_o: out std_logic_vector (1 downto 0); -- mux a 
         branch_forward_b_o: out std_logic_vector(1 downto 0); -- mux b

         branch_condition_i: in std_logic;

         pc_next_sel_o: out std_logic_vector(1 downto 0);
         if_id_flush_o: out std_logic;
         id_ex_flush_o: out std_logic;

         pc_write_o : out std_logic;
         if_id_write_o : out std_logic
         );  
end entity;


architecture behavioral of control_path is
begin

   bcc_id_s <= instruction_i(12);
   --this mux covers conditional and unconditional branches
   pc_next_if_s:process(branch_id_s,branch_ex_s,branch_condition_i,bcc_id_s)
   begin
      if_id_flush_s <= '0';
      id_ex_flush_s <= '0';
      pc_next_sel_o <= "00";
      if (branch_id_s = "01" and ((branch_condition_i xor bcc_id_s) = '1'))then
         pc_next_sel_o <= "01";
         if_id_flush_s <= '1';
      end if;
      if(branch_id_s = "10")then
         pc_next_sel_o <= "10";
         if_id_flush_s <= '1';
      end if;
      if(branch_ex_s = "11") then
         pc_next_sel_o <= "11";
         if_id_flush_s <= '1';
         id_ex_flush_s <= '1';
      end if;
   end process;
   
   if_id_flush_o <= if_id_flush_s;
   id_ex_flush_o <= id_ex_flush_s;
   

   load_type_o <= funct3_wb_s;
   
   rs1_address_id_s <= instruction_i(19 downto 15);
   rs2_address_id_s <= instruction_i(24 downto 20);
   rd_address_id_s <= instruction_i(11 downto 7);

   funct7_id_s <= instruction_i(31 downto 25);
   funct3_id_s <= instruction_i(14 downto 12);

   
   --*********** ID/EX register ******************
   id_ex:process (clk) is
   begin
      if (rising_edge(clk)) then
         if (reset = '0' or control_stall_s='1' or id_ex_flush_s='1')then
            branch_ex_s <= (others => '0');
            funct3_ex_s <= (others => '0');
            funct7_ex_s <= (others => '0');
            alu_a_zero_ex_s  <= '0';
            alu_src_a_ex_s <= '0';
            alu_src_b_ex_s <= '0';
            mem_to_reg_ex_s <= (others => '0');
            --mem_read_ex_s <= '0';
            alu_2bit_op_ex_s <= (others => '0');
            rs1_address_ex_s <= (others => '0');
            rs2_address_ex_s <= (others => '0');
            rd_address_ex_s <= (others => '0');
            reg_write_ex_s <= '0';
            mem_write_ex_s <= '0';
            -- FORMAL VERIG LOGIC

         else
            branch_ex_s <= branch_id_s;
            funct7_ex_s <= funct7_id_s;
            funct3_ex_s <= funct3_id_s;
            alu_a_zero_ex_s  <= alu_a_zero_id_s;
            alu_src_a_ex_s <=  alu_src_a_id_s;
            alu_src_b_ex_s <= alu_src_b_id_s;
            mem_to_reg_ex_s <= mem_to_reg_id_s;
            --mem_read_ex_s <= mem_read_id_s;
            alu_2bit_op_ex_s <= alu_2bit_op_id_s;
            rs1_address_ex_s <= rs1_address_id_s; rs2_address_ex_s <= rs2_address_id_s;
            rd_address_ex_s <= rd_address_id_s;
            reg_write_ex_s <= reg_write_id_s;
            mem_write_ex_s <= mem_write_id_s;
            -- FORMAL VERIG LOGIC


         end if;
      end if;      
   end process;



   --*********** EX/MEM register ******************
   ex_mem:process (clk) is
   begin
      if (rising_edge(clk)) then
         if (reset = '0')then
            funct3_mem_s <= (others => '0');
            mem_write_mem_s <= '0';
            reg_write_mem_s <= '0';
            mem_to_reg_mem_s<= (others => '0');
            --mem_read_mem_s <= '0';
            rd_address_mem_s <= (others => '0');
         else
            funct3_mem_s <= funct3_ex_s;
            mem_write_mem_s <= mem_write_ex_s;
            reg_write_mem_s <= reg_write_ex_s;
            mem_to_reg_mem_s <= mem_to_reg_ex_s;
            --mem_read_mem_s <= mem_read_ex_s;
            rd_address_mem_s <= rd_address_ex_s;
         end if;
      end if;      
   end process;

   --*********** MEM/WB register ******************
   mem_wb:process (clk) is
   begin
      if (rising_edge(clk)) then
         if (reset = '0')then
            funct3_wb_s <= (others => '0');
            reg_write_wb_s <= '0';
            mem_to_reg_wb_s <= (others => '0');
            rd_address_wb_s <= (others => '0');
         else
            funct3_wb_s <= funct3_mem_s;
            reg_write_wb_s <= reg_write_mem_s;
            mem_to_reg_wb_s <= mem_to_reg_mem_s;
            rd_address_wb_s <= rd_address_mem_s;
         end if;
      end if;      
   end process;

   ctrl_dec: entity work.ctrl_decoder(behavioral)
      port map(
         opcode_i => instruction_i(6 downto 0),
         branch_o => branch_id_s,
         --mem_read_o => mem_read_id_s,
         mem_to_reg_o => mem_to_reg_id_s,
         mem_write_o => mem_write_id_s,
         alu_src_b_o => alu_src_b_id_s,
         alu_src_a_o => alu_src_a_id_s,
         alu_a_zero_o => alu_a_zero_id_s,
         reg_write_o => reg_write_id_s,
         alu_2bit_op_o => alu_2bit_op_id_s);

   alu_dec: entity work.alu_decoder(behavioral)
      port map(
         alu_2bit_op_i => alu_2bit_op_ex_s,
         funct3_i => funct3_ex_s,
         funct7_i => funct7_ex_s,
         alu_op_o => alu_op_o);
     
   
   forwarding_unit_1: entity work.forwarding_unit(behavioral)
      port map (
         reg_write_mem_i    => reg_write_mem_s,
         rd_address_mem_i    => rd_address_mem_s,
         reg_write_wb_i     => reg_write_wb_s,
         rd_address_wb_i     => rd_address_wb_s,
         rs1_address_ex_i     => rs1_address_ex_s,
         rs2_address_ex_i     => rs2_address_ex_s,
         rs1_address_id_i     => rs1_address_id_s,
         rs2_address_id_i     => rs2_address_id_s,
         alu_forward_a_o    => alu_forward_a_s,
         alu_forward_b_o    => alu_forward_b_s,
         branch_forward_a_o => branch_forward_a_o,
         branch_forward_b_o => branch_forward_b_o);

   hazard_unit_1: entity work.hazard_unit(behavioral)
      port map (
      
      rs1_address_id_i => rs1_address_id_s,
      rs2_address_id_i => rs2_address_id_s,
      branch_id_i => branch_id_s,

      rd_address_ex_i => rd_address_ex_s,
      mem_to_reg_ex_i => mem_to_reg_ex_s,
      reg_write_ex_i => reg_write_ex_s,

      rd_address_mem_i => rd_address_mem_s,
      mem_to_reg_mem_i => mem_to_reg_mem_s,
      reg_write_mem_i => reg_write_mem_s,

      --control outputs
      pc_write_o => pc_write_o,
      if_id_write_o => if_id_write_s,
      control_stall_o => control_stall_s);

   if_id_write_o <= if_id_write_s;
   --mem_read_o <= mem_read_mem_s;
   mem_to_reg_o <= mem_to_reg_wb_s;


   alu_forward_a_o <= alu_forward_a_s;
   alu_forward_b_o <= alu_forward_b_s;
   alu_src_b_o <= alu_src_b_ex_s;
   alu_src_a_o <= alu_src_a_ex_s;
   alu_a_zero_o <= alu_a_zero_ex_s;
   reg_write_o <= reg_write_wb_s;
   mem_write_o <= "0001" when mem_write_mem_s = '1' and funct3_mem_s = "000" else
                  "0011" when mem_write_mem_s = '1' and funct3_mem_s = "001" else
                  "1111" when mem_write_mem_s = '1' and funct3_mem_s = "010" else
                  "0000";


   -- FORMAL_STALL_CHECKER_MODULE

   stall_checker_inst: entity work.stall_checker
     port map (clk => clk,
               reset => reset,
               rs1 => instruction_i(19 downto 15),
               rs2 => instruction_i(24 downto 20),
               opcode => instruction_i(6 downto 0),               
               stall => control_stall_s,               
               branch_id_s => branch_id_s,
               rd_ex_s => rd_address_ex_s,
               funct3 => funct3_id_s
               );
   ----**********************FU CHECKER************************
   forwarding_unit_checker:entity work.forwarding_unit_checker
     port map (
       clk => clk,
       reset => reset,
       reg_write_mem_i    => reg_write_mem_s,
       rd_address_mem_i    => rd_address_mem_s,
       reg_write_wb_i     => reg_write_wb_s,
       rd_address_wb_i     => rd_address_wb_s,
       rs1_address_ex_i     => rs1_address_ex_s,
       rs2_address_ex_i     => rs2_address_ex_s,
       rs1_address_id_i     => rs1_address_id_s,
       rs2_address_id_i     => rs2_address_id_s,
       alu_forward_a_o    => alu_forward_a_s,
       alu_forward_b_o    => alu_forward_b_s,
       branch_forward_a_o => branch_forward_a_o,
       branch_forward_b_o => branch_forward_b_o);
   ----******************************************************

end architecture;
















