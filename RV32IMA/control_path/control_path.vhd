library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.controlpath_signals_pkg.all;

entity control_path is
   port (clk: in std_logic;
         reset: in std_logic;
         -- from top
         instruction_i: in std_logic_vector (31 downto 0);
         -- to datapath
         branch_o: out std_logic_vector(1 downto 0);
         mem_read_o: out std_logic;
         mem_to_reg_o: out std_logic_vector(1 downto 0);
         mem_write_o: out std_logic;
         alu_src_b_o: out std_logic;
         alu_src_a_o: out std_logic;
         reg_write_o: out std_logic;
         alu_a_zero_o: out std_logic;
         alu_op_o: out std_logic_vector(4 downto 0)
         );  
end entity;


architecture behavioral of control_path is
   signal alu_2bit_op_s: std_logic_vector(1 downto 0);
begin

   
   read_reg1_id_s <= instruction_i(19 downto 15);
   read_reg2_id_s <= instruction_i(24 downto 20);
   write_reg_id_s <= instruction_i(11 downto 7);

   funct7_id_s <= instruction_i(31 downto 25);
   funct3_id_s <= instruction_i(14 downto 12);
   --*********** ID/EX register ******************
   id_ex:process (clk) is
   begin
      if (rising_edge(clk)) then
         if (reset = '0')then
            funct3_ex_s <= (others => '0');
            funct7_ex_s <= (others => '0');
            alu_a_zero_ex_s  <= '0';
            alu_src_a_ex_s <= '0';
            alu_src_b_ex_s <= '0';
            mem_to_reg_ex_s <= (others => '0');
            mem_read_ex_s <= '0';
            alu_2bit_op_ex_s <= (others => '0');
            read_reg1_ex_s <= (others => '0');
            read_reg2_ex_s <= (others => '0');
            write_reg_ex_s <= (others => '0');
            reg_write_ex_s <= '0';
         else
            funct7_ex_s <= funct7_id_s;
            funct3_ex_s <= funct3_id_s;
            alu_a_zero_ex_s  <= alu_a_zero_id_s;
            alu_src_a_ex_s <=  alu_src_a_id_s;
            alu_src_b_ex_s <= alu_src_b_id_s;
            mem_to_reg_ex_s <= mem_to_reg_id_s;
            mem_read_ex_s <= mem_read_id_s;
            alu_2bit_op_ex_s <= alu_2bit_op_id_s;
            read_reg1_ex_s <= read_reg1_id_s;
            read_reg2_ex_s <= read_reg2_id_s;
            write_reg_ex_s <= write_reg_id_s;
            reg_write_ex_s <= reg_write_id_s;
         end if;
      end if;      
   end process;

   --*********** EX/MEM register ******************
   ex_mem:process (clk) is
   begin
      if (rising_edge(clk)) then
         if (reset = '0')then

            mem_write_mem_s <= '0';
            reg_write_mem_s <= '0';
            mem_to_reg_mem_s<= (others => '0');
            mem_read_mem_s <= '0';
            write_reg_mem_s <= (others => '0');
         else
            mem_write_mem_s <= mem_write_ex_s;
            reg_write_mem_s <= reg_write_ex_s;
            mem_to_reg_mem_s <= mem_to_reg_ex_s;
            mem_read_mem_s <= mem_read_ex_s;
            write_reg_mem_s <= write_reg_ex_s;
         end if;
      end if;      
   end process;

   --*********** MEM/WB register ******************
   mem_wb:process (clk) is
   begin
      if (rising_edge(clk)) then
         if (reset = '0')then
            reg_write_wb_s <= '0';
            mem_to_reg_wb_s <= (others => '0');
            write_reg_wb_s <= (others => '0');
         else
            reg_write_wb_s <= reg_write_mem_s;
            mem_to_reg_wb_s <= mem_to_reg_mem_s;
            write_reg_wb_s <= write_reg_mem_s;
         end if;
      end if;      
   end process;

   ctrl_dec: entity work.ctrl_decoder(behavioral)
      port map(
         opcode_i => instruction_i(6 downto 0),
         branch_o => branch_o,
         mem_read_o => mem_read_id_s,
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

   mem_read_o <= mem_read_mem_s;
   mem_to_reg_o <= mem_to_reg_wb_s;
   mem_write_o <= mem_write_mem_s;
   alu_src_b_o <= alu_src_b_ex_s;
   alu_src_a_o <= alu_src_a_ex_s;
   alu_a_zero_o <= alu_a_zero_ex_s;
   reg_write_o <= reg_write_wb_s;

end architecture;

