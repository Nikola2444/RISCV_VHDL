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
      --voter_res_i   :  IN   array32_t(0 to NUM_MODULES-1);
      valid_reg_i   :  IN   STD_LOGIC_VECTOR(NUM_MODULES-1 downto 0);
      voter_res_o   :  OUT  STD_LOGIC_VECTOR(31 downto 0));
END treshold_voter;



ARCHITECTURE behavioral of treshold_voter IS

   constant ADDER_W : natural := integer(ceil(log2(real(NUM_MODULES))))+1;
   signal treshold_s : std_logic_vector(ADDER_W-1 downto 0); 

BEGIN

   
      
   find_correct_result:
   process (valid_reg_i) is
   begin
      treshold_s <=  count_ones_serial(valid_reg_i);
   end process;

   voter_res_o <= (std_logic_vector(to_unsigned(0,32-ADDER_W)) & treshold_s);

   


END behavioral;
