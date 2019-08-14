library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity control_path is
   port (clk: in std_logic;
         reset: in std_logic;
         -- from top
         instruction_i: in std_logic_vector (31 downto 0);
         -- to datapath
         branch_o: out std_logic;
         mem_read_o: out std_logic;
         mem_to_reg_o: out std_logic_vector(1 downto 0);
         mem_write_o: out std_logic;
         alu_src_b_o: out std_logic;
         alu_src_a_o: out std_logic;
         reg_write_o: out std_logic;
         alu_op_o: out std_logic_vector(4 downto 0)
         );  
end entity;


architecture behavioral of control_path is
   signal alu_2bit_op_s: std_logic_vector(1 downto 0);
begin

   ctrl_dec: entity work.ctrl_decoder(behavioral)
      port map(
         opcode_i => instruction_i(6 downto 0),
         branch_o => branch_o,
         mem_read_o => mem_read_o,
         mem_to_reg_o => mem_to_reg_o,
         mem_write_o => mem_write_o,
         alu_src_b_o => alu_src_b_o,
         alu_src_a_o => alu_src_a_o,
         reg_write_o => reg_write_o,
         alu_2bit_op_o => alu_2bit_op_s);

   alu_dec: entity work.alu_decoder(behavioral)
      port map(
         alu_2bit_op_i => alu_2bit_op_s,
         funct3_i => instruction_i(14 downto 12),
         funct7_i => instruction_i(31 downto 25),
         alu_op_o => alu_op_o);


end architecture;

