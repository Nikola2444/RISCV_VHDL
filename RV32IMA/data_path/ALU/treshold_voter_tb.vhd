
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.math_real.ceil;
USE ieee.math_real.log2;
USE work.ft_pkg.all;

ENTITY treshold_voter_tb IS
END treshold_voter_tb;



ARCHITECTURE behavioral of treshold_voter_tb IS

      signal input_s  :  STD_LOGIC_VECTOR(6 downto 0);
      signal output_s :  STD_LOGIC_VECTOR(31 downto 0);
BEGIN

   
      
   dut: entity work.treshold_voter(behavioral)
   port map ( valid_reg_i  => input_s,
              voter_res_o  => output_s); 

   input_s <= "0000000", "10000000" after 100 ns,"0000001" after 200 ns,"1000001" after 300 ns,"1000001" after 400 ns,"1001001" after 500 ns,"1001011" after 600 ns,"1101001" after 700 ns,"1111111" after 800 ns,"1000011" after 900 ns,"1111111" after 1000 ns;


END behavioral;
