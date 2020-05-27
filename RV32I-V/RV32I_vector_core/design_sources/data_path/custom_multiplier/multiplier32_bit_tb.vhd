library ieee;
use ieee.std_logic_1164.all;
use work.custom_functions_pkg.all;
use ieee.numeric_std.all;

entity multiplier32_bit_tb is
     generic (DATA_WIDTH : natural := 32);
end entity;


architecture beh of multiplier32_bit_tb is
   signal clk     : std_logic:= '0';
   signal reset_s : std_logic;
   signal a       : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others =>'0');
   signal b       : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others =>'0');
   signal c       : std_logic_vector(2*DATA_WIDTH - 1 downto 0) := (others =>'0');
   signal c_2_comp_s : std_logic_vector(2*DATA_WIDTH - 1 downto 0) := (others =>'0');
begin
   multiplier32_bit_1: entity work.multiplier32_bit
      generic map (
         DATA_WIDTH => DATA_WIDTH)
      port map (
         clk     => clk,
         reset => reset_s,
         a       => a,
         b       => b,
         c       => c);

   
   a <= x"ffff"&x"ffff";
   b<= x"ffff"&x"ffff";

   c_2_comp_s <= std_logic_vector(unsigned(not c) + to_unsigned(1, 64));
   reset_s <= '0', '1' after 300 ns;
   clk_gen: process
   begin
      clk <= '0', '1' after 100 ns;
      wait for 200 ns;
   end process;
   
end architecture;
