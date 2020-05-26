library ieee;
use ieee.std_logic_1164.all;
use work.custom_functions_pkg.all;


entity multiplier32_bit_tb is
     generic (DATA_WIDTH : natural := 32);
end entity;


architecture beh of multiplier32_bit_tb is
   signal clk     : std_logic:= '0';
   signal reset_s : std_logic;
   signal a       : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others =>'0');
   signal b       : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others =>'0');
   signal c       : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others =>'0');
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


   a <= x"1000"&x"0000", x"8100"&x"0000" after 500 ns;
   b<= x"0000"&x"0002";
   reset_s <= '0', '1' after 300 ns;
   clk_gen: process
   begin
      clk <= '0', '1' after 100 ns;
      wait for 200 ns;
   end process;
   
end architecture;
