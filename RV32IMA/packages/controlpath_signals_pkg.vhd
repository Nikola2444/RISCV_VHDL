library ieee;
use ieee.std_logic_1164.all;

package controlpath_signals_pkg is



   --*********  INSTRUCTION DECODE **************

   signal funct3_id_s : std_logic_vector(2 downto 0);
   signal funct7_id_s : std_logic_vector(6 downto 0);
   signal alu_2bit_op_id_s: std_logic_vector(1 downto 0);
   signal alu_a_zero_id_s : std_logic;

   signal alu_src_a_id_s : std_logic;
   signal alu_src_b_id_s : std_logic;

   signal mem_write_id_s : std_logic;
   signal reg_write_id_s : std_logic;
   signal mem_to_reg_id_s : std_logic_vector(1 downto 0);
   signal mem_read_id_s : std_logic;
   --register addresses
   signal read_reg1_id_s: std_logic_vector (4 downto 0);
   signal read_reg2_id_s: std_logic_vector (4 downto 0);
   signal write_reg_id_s: std_logic_vector (4 downto 0);

   --*********       EXECUTE       **************

   signal funct3_ex_s : std_logic_vector(2 downto 0);
   signal funct7_ex_s : std_logic_vector(6 downto 0);
   signal alu_2bit_op_ex_s: std_logic_vector(1 downto 0);
   signal alu_a_zero_ex_s : std_logic;

   signal alu_src_a_ex_s : std_logic;
   signal alu_src_b_ex_s : std_logic;

   signal mem_write_ex_s : std_logic;
   signal reg_write_ex_s : std_logic;
   signal mem_to_reg_ex_s : std_logic_vector(1 downto 0);
   signal mem_read_ex_s : std_logic;


   signal read_reg1_ex_s: std_logic_vector (4 downto 0);
   signal read_reg2_ex_s: std_logic_vector (4 downto 0);
   signal write_reg_ex_s: std_logic_vector (4 downto 0);

   --*********       MEMORY        **************

   signal mem_write_mem_s : std_logic;
   signal reg_write_mem_s : std_logic;
   signal mem_to_reg_mem_s : std_logic_vector(1 downto 0);
   signal mem_read_mem_s : std_logic;

   signal write_reg_mem_s: std_logic_vector (4 downto 0);

   --*********      WRITEBACK      **************

   signal reg_write_wb_s : std_logic;
   signal mem_to_reg_wb_s : std_logic_vector(1 downto 0);
   signal write_reg_wb_s: std_logic_vector (4 downto 0);



--********************************************************

end package controlpath_signals_pkg;
