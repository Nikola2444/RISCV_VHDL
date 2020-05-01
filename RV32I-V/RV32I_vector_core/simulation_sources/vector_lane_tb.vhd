library ieee;
use ieee.std_logic_1164.all;
use work.custom_functions_pkg.all;
use work.txt_util.all;

entity vector_lane_tb is
   generic (DATA_WIDTH: natural:= 32 );
end entity;


architecture beh of vector_lane_tb is

   signal instructions_array   : instructions_mem:=read_instr_from_file("../../../../../RV32I_vector_core/simulation_sources/assembly_code.txt");
   
   signal clk                     : std_logic;
   signal reset                   : std_logic;
   signal vector_instruction_i    : std_logic_vector(31 downto 0);
   signal data_from_mem_i         : std_logic_vector(DATA_WIDTH - 1 downto 0);
   signal load_fifo_we_i          : std_logic;
   signal store_fifo_re_i         : std_logic;
   signal alu_op_i                : std_logic_vector(4 downto 0);
   signal mem_to_vrf_i            : std_logic_vector(1 downto 0);
   signal store_fifo_we_i         : std_logic;
   signal vrf_type_of_access_i    : std_logic_vector(1 downto 0);
   signal load_fifo_re_i          : std_logic;
   signal data_to_mem_o           : std_logic_vector (DATA_WIDTH - 1 downto 0);
   signal ready_o                 : std_logic;
   signal load_fifo_almostmpty_o  : std_logic;
   signal load_fifo_almostfull_o  : std_logic;
   signal load_fifo_empty_o       : std_logic;
   signal load_fifo_full_o        : std_logic;
   signal load_fifo_rdcount_o     : std_logic_vector(8 downto 0);
   signal load_fifo_rderr_o       : std_logic;
   signal load_fifo_wrcount_o     : std_logic_vector(8 downto 0);
   signal load_fifo_wrerr_o       : std_logic;
   signal store_fifo_almostmpty_o : std_logic;
   signal store_fifo_almostfull_o : std_logic;
   signal store_fifo_empty_o      : std_logic;
   signal store_fifo_full_o       : std_logic;
   signal store_fifo_rdcount_o    : std_logic_vector(8 downto 0);
   signal store_fifo_rderr_o      : std_logic;
   signal store_fifo_wrcount_o    : std_logic_vector(8 downto 0);
   signal store_fifo_wrerr_o      : std_logic;

begin
   
   
   vector_lane_1: entity work.vector_lane
      generic map (
         DATA_WIDTH        => 32,
         VECTOR_LENGTH => 64)
      port map (
         clk                     => clk,
         reset                   => reset,
         vector_instruction_i    => vector_instruction_i,
         data_from_mem_i         => data_from_mem_i,
         load_fifo_we_i          => load_fifo_we_i,
         store_fifo_re_i         => store_fifo_re_i,
         alu_op_i                => alu_op_i,
         mem_to_vrf_i            => mem_to_vrf_i,
         store_fifo_we_i         => store_fifo_we_i,
         vrf_type_of_access_i    => vrf_type_of_access_i,
         load_fifo_re_i          => load_fifo_re_i,
         data_to_mem_o           => data_to_mem_o,
         ready_o                 => ready_o,

         
         load_fifo_almostmpty_o  => load_fifo_almostmpty_o,
         load_fifo_almostfull_o  => load_fifo_almostfull_o,
         load_fifo_empty_o       => load_fifo_empty_o,
         load_fifo_full_o        => load_fifo_full_o,
         load_fifo_rdcount_o     => load_fifo_rdcount_o,
         load_fifo_rderr_o       => load_fifo_rderr_o,
         load_fifo_wrcount_o     => load_fifo_wrcount_o,
         load_fifo_wrerr_o       => load_fifo_wrerr_o,
         store_fifo_almostmpty_o => store_fifo_almostmpty_o,
         store_fifo_almostfull_o => store_fifo_almostfull_o,
         store_fifo_empty_o      => store_fifo_empty_o,
         store_fifo_full_o       => store_fifo_full_o,
         store_fifo_rdcount_o    => store_fifo_rdcount_o,
         store_fifo_rderr_o      => store_fifo_rderr_o,
         store_fifo_wrcount_o    => store_fifo_wrcount_o,
         store_fifo_wrerr_o      => store_fifo_wrerr_o);

   alu_op_i <= "00010";
   vrf_type_of_access_i <= "00";
   mem_to_vrf_i         <= "00";
   store_fifo_we_i      <= '0';
   load_fifo_re_i       <= '0';
   vector_instruction_i <= instructions_array(0);
   reset <= '0', '1' after 300 ns;
   clk_gen:process
   begin
      clk <= '1', '0' after 10 ns;
      wait for 20 ns;
   end process;
end architecture;


