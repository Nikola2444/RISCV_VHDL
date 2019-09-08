library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TOP_RISCV is
  generic (DATA_WIDTH: positive := 32);
  port(
    -- ********* Sync ports *****************************
    clk: in std_logic;
    reset: in std_logic;
    -- ********* INSTRUCTION memory i/o *******************       
    instr_mem_read_i: in std_logic_vector(31 downto 0);
    instr_mem_address_o: out std_logic_vector(31 downto 0);
    instruction_mem_flush_o:out std_logic;
    instruction_mem_en_o: out std_logic;
    -- ********* DATA memory i/o **************************
    mem_write_o: out std_logic_vector(3 downto 0);  
    data_mem_address_o: out std_logic_vector(DATA_WIDTH - 1 downto 0);
    data_mem_read_i: in std_logic_vector(DATA_WIDTH - 1 downto 0);
    data_mem_write_o: out std_logic_vector(DATA_WIDTH - 1 downto 0));
  

end entity;

architecture structural of TOP_RISCV is
  signal branch_s: std_logic_vector(1 downto 0);
  signal load_type_s: std_logic_vector(2 downto 0);
  signal mem_to_reg_s: std_logic_vector(1 downto 0);
  signal alu_op_s: std_logic_vector (4 downto 0);
  signal alu_src_b_s: std_logic;
  signal alu_src_a_s: std_logic;
  signal alu_a_zero_s: std_logic;
  signal reg_write_s: std_logic;
  signal if_id_flush_s: std_logic;
  signal id_ex_flush_s: std_logic;

  signal alu_forward_a_s    : std_logic_vector (1 downto 0);
  signal alu_forward_b_s    : std_logic_vector (1 downto 0);
  signal branch_forward_a_s : std_logic_vector (1 downto 0);
  signal branch_forward_b_s : std_logic_vector(1 downto 0);
  signal branch_condition_s : std_logic;
  signal pc_next_sel_s      : std_logic_vector(1 downto 0);

  signal pc_write_s:  std_logic;--controls program counter
  signal if_id_write_s:  std_logic;--controls istruction fetch

  
  --Logic needed for formal verif 
  signal pc_reg_s:std_logic_vector(31 downto 0);  
  
begin
  -- Data_path will be instantiated here
  --************************************
  data_path_1: entity work.data_path
    generic map (
      DATA_WIDTH => DATA_WIDTH)
    port map (
      clk                => clk,
      reset              => reset,
      instr_mem_address_o    => pc_reg_s,
      instr_mem_read_i      => instr_mem_read_i,
      data_mem_address_o => data_mem_address_o,
      data_mem_write_o   => data_mem_write_o,
      data_mem_read_i    => data_mem_read_i,
      alu_a_zero_i   => alu_a_zero_s,
      mem_to_reg_i       => mem_to_reg_s,
      load_type_i    => load_type_s,
      alu_op_i           => alu_op_s,
      alu_src_b_i          => alu_src_b_s,
      alu_src_a_i          => alu_src_a_s,
      reg_write_i        => reg_write_s,
      alu_forward_a_i => alu_forward_a_s,
      alu_forward_b_i => alu_forward_b_s,
      branch_forward_a_i => branch_forward_a_s,
      branch_forward_b_i => branch_forward_b_s,
      branch_condition_o => branch_condition_s,
      pc_next_sel_i => pc_next_sel_s,
      pc_write_i => pc_write_s,
      if_id_write_i => if_id_write_s,
      if_id_flush_i => if_id_flush_s,
      id_ex_flush_i => id_ex_flush_s
      ); 
  
  instruction_mem_flush_o <= if_id_flush_s;

  -- Control_path will be instantiated here
  control_path_1: entity work.control_path
    port map (
      clk           => clk,
      reset         => reset,
      instruction_i => instr_mem_read_i,
      alu_a_zero_o   => alu_a_zero_s,
      mem_to_reg_o  => mem_to_reg_s,
      mem_write_o   => mem_write_o,
      load_type_o    => load_type_s,
      alu_src_b_o     => alu_src_b_s,
      alu_src_a_o     => alu_src_a_s,
      reg_write_o   => reg_write_s,
      alu_op_o      => alu_op_s,
      alu_forward_a_o => alu_forward_a_s,
      alu_forward_b_o => alu_forward_b_s,
      branch_forward_a_o => branch_forward_a_s,
      branch_forward_b_o => branch_forward_b_s,
      branch_condition_i => branch_condition_s,
      pc_next_sel_o => pc_next_sel_s,
      if_id_flush_o => if_id_flush_s,
      id_ex_flush_o => id_ex_flush_s,
      pc_write_o => pc_write_s,
      if_id_write_o => if_id_write_s
      );
  
  

--************************************ 
  instr_mem_address_o <= pc_reg_s;
  instruction_mem_en_o <= if_id_write_s;

--************FORMAL_LOGIC***********

  
  pc_checker_inst: entity work.pc_checker
    port map (clk => clk,
              reset => reset,
              pc_reg => pc_reg_s,      
              opcode_id => instr_mem_read_i(6 downto 0));


end architecture;
