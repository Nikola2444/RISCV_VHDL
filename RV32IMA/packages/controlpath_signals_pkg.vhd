library ieee;
use ieee.std_logic_1164.all;

package controlpath_signals_pkg is

   --********** REGISTER CONTROL ***************
   signal if_id_en_s        : std_logic;   
   signal if_id_flush_s     : std_logic;   
   signal id_ex_flush_s     : std_logic;   
   
   --*********  INSTRUCTION DECODE **************
   signal branch_type_id_s  : std_logic_vector(1 downto 0);
   signal funct3_id_s       : std_logic_vector(2 downto 0);
   signal funct7_id_s       : std_logic_vector(6 downto 0);
   signal alu_2bit_op_id_s  : std_logic_vector(1 downto 0);
   signal set_a_zero_id_s   : std_logic;   
   
   signal control_pass_s    : std_logic;
   signal rs1_in_use_id_s   : std_logic;
   signal rs2_in_use_id_s   : std_logic;
   signal alu_src_a_id_s    : std_logic;
   signal alu_src_b_id_s    : std_logic;

   signal data_mem_we_id_s  : std_logic;
   signal rd_we_id_s        : std_logic;
   signal mem_to_reg_id_s   : std_logic_vector(1 downto 0);
   signal rs1_address_id_s  : std_logic_vector (4 downto 0);
   signal rs2_address_id_s  : std_logic_vector (4 downto 0);
   signal rd_address_id_s   : std_logic_vector (4 downto 0);
   signal bcc_id_s          : std_logic;

   --*********       EXECUTE       **************
   signal branch_type_ex_s  : std_logic_vector(1 downto 0);
   signal funct3_ex_s       : std_logic_vector(2 downto 0);
   signal funct7_ex_s       : std_logic_vector(6 downto 0);
   signal alu_2bit_op_ex_s  : std_logic_vector(1 downto 0);
   signal set_a_zero_ex_s   : std_logic;

   signal alu_src_a_ex_s    : std_logic;
   signal alu_src_b_ex_s    : std_logic;

   signal data_mem_we_ex_s  : std_logic;
   signal rd_we_ex_s        : std_logic;
   signal mem_to_reg_ex_s   : std_logic_vector(1 downto 0);


   signal rs1_address_ex_s  : std_logic_vector (4 downto 0);
   signal rs2_address_ex_s  : std_logic_vector (4 downto 0);
   signal rd_address_ex_s   : std_logic_vector (4 downto 0);

   --*********       MEMORY        **************
   signal funct3_mem_s      : std_logic_vector(2 downto 0);
   signal data_mem_we_mem_s : std_logic;
   signal rd_we_mem_s       : std_logic;
   signal mem_to_reg_mem_s  : std_logic_vector(1 downto 0);

   signal rd_address_mem_s  : std_logic_vector (4 downto 0);

   --*********      WRITEBACK      **************
   signal funct3_wb_s       : std_logic_vector(2 downto 0);
   signal rd_we_wb_s        : std_logic;
   signal mem_to_reg_wb_s   : std_logic_vector(1 downto 0);
   signal rd_address_wb_s   : std_logic_vector (4 downto 0);


end package controlpath_signals_pkg;
