
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.math_real.ceil;
USE ieee.math_real.log2;
USE work.ft_pkg.all;

ENTITY treshold_voter IS
   GENERIC(
      NUM_MODULES: NATURAL := 8
      );
   PORT(
      voter_res_i   :  IN   array32_t(0 to NUM_MODULES-1);
      valid_reg_i   :  IN   STD_LOGIC_VECTOR(NUM_MODULES-1 downto 0);
      voter_res_o   :  OUT  STD_LOGIC_VECTOR(31 downto 0));
END treshold_voter;



ARCHITECTURE behavioral of treshold_voter IS

   constant TRESHOLD_W : integer := (integer(ceil(log2(real(NUM_MODULES)))) + integer(1));
   signal treshold_s,sum_s : std_logic_vector(TRESHOLD_W-1 downto 0);
   type voter_tmp_t is array (0 to 31) of std_logic_vector (NUM_MODULES-1 downto 0); 
   signal voter_tmp_s : voter_tmp_t;

BEGIN

   
   -- TRESHOLD
   -- this command calls function "number_of_ones", and based on it finds appropriate treshold for voter
   -- treshold = number of working units / 2 (division by two = shift right by one)
   sum_s <= count_ones_recursive(valid_reg_i);
   treshold_s <= '0' & sum_s (TRESHOLD_W-1 downto 1);

   -- swap: converts alu_sw array to format more suitable for count_ones function
   swap:
   process(voter_res_i) is
   begin
   for i in 0 to 31 loop
      for m in 0 to NUM_MODULES-1 loop
         voter_tmp_s(i)(m) <= voter_res_i(m)(i);         
      end loop;
   end loop;
   end process;

   -- find_optimal_result: generates result from multiple inputs as the most common one
   find_optimal_result:
   process (voter_tmp_s, treshold_s) is
   begin
      for i in 0 to 31 loop
         if(count_ones_recursive(voter_tmp_s(i)) > treshold_s)then
            voter_res_o(i) <= '1';
         else
            voter_res_o(i) <= '0';
         end if;
      end loop;
   end process;


END behavioral;
