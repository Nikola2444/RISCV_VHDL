library ieee;
use ieee.std_logic_1164.all;
use work.clogb2_pkg.all;


entity vector_lane_tb is
   generic (DATA_WIDTH: natural:= 32 );
end entity;


architecture beh of vector_lane_tb is
   signal clk                  : std_logic;
   signal reset                : std_logic;
   signal vrf_type_of_access_s : std_logic_vector(1 downto 0);
   signal alu_op_s             : std_logic_vector(4 downto 0);
   signal mem_to_vrf_s         : std_logic_vector(1 downto 0);
   signal vector_snstruction_s : std_logic_vector(31 downto 0);
   signal mem_data_s           : std_logic_vector(DATA_WIDTH - 1 downto 0);
   signal ready_s              : std_logic;
begin
   vector_lane_1: entity work.vector_lane
      generic map (
         DATA_WIDTH        => DATA_WIDTH,
         MAX_VECTOR_LENGTH => MAX_VECTOR_LENGTH,
         NUM_OF_LANES      => NUM_OF_LANES)
      port map (
         clk                  => clk,
         reset                => reset,
         vrf_type_of_access_i => vrf_type_of_access_s,
         alu_op_i             => alu_op_s,
         mem_to_vrf_i         => mem_to_vrf_s,
         vector_instruction_s => vector_instruction_s,
         mem_data_i           => mem_data_s,
         ready_o              => ready_s);

   
end architecture;


