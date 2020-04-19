library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.clogb2_pkg.all;



entity vector_core_tb is

end entity;

architecture beh of vector_core_tb is
   signal clk            : std_logic:= '0';
   signal reset          : std_logic;
   signal instruction_s  : std_logic_vector(31 downto 0);
   signal vector_stall_s : std_logic;
begin
   vector_core_1: entity work.vector_core
      generic map (
         DATA_WIDTH        => DATA_WIDTH,
         MAX_VECTOR_LENGTH => MAX_VECTOR_LENGTH,
         NUM_OF_LANES      => NUM_OF_LANES)
      port map (
         clk            => clk,
         reset          => reset,
         instruction_i  => instruction_s,
         vector_stall_o => vector_stall_s);


   clk_gen:process
   begin
      clk <= '1', '0' after 10 ns;
      wait for 20 ns;
   end process;


   instruction_s <= x"00000000"
end architecture;
