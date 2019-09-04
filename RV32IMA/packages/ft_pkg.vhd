library ieee;
use ieee.std_logic_1164.all;
USE ieee.math_real.ceil;
USE ieee.math_real.log2;

package ft_pkg is

   type array32_t is array (integer range <>) of std_logic_vector(31 downto 0);
   
   
   -- counts number of ones in std_logic_vector and returns it in binary (unary to binary converter)
   -- serial -> function is implemented as a simple loop, good readability bad performance
   function count_ones_serial    (vector : std_logic_vector) return std_logic_vector;
   -- recursive -> function is implemented as a binary tree in hope of better timing result
   function count_ones_recursive (vector : std_logic_vector) return std_logic_vector;

end package ft_pkg;




package body ft_package is


   function count_ones_serial (vector : std_logic_vector) return std_logic_vector is
      constant RETURN_W : integer := integer(ceil(log2(real(vector'length)))+1);
      variable count : std_logic_vector(RETURN_W-1 downto 0);
      
   begin
      count := (others => '0');
      
      for i in 0 to (vector'length-1) loop
         count := std_logic_vector(unsigned(count) + to_unsigned(RETURN_W,vector(i)));
      end loop;

      return count;
   end count_ones_serial;

   function count_ones_recursive (vector : std_logic_vector) return std_logic_vector is
      constant RETURN_W : integer := integer(ceil(log2(real(vector'length)))+1);
      variable count : std_logic_vector(RETURN_W-1 downto 0);
      
   begin
         if(vector'lenght=1)then
            return vecotr(0);
         end if;

         count := std_logic_vector(unsigned(count_ones_recursive(vector(vector'length downto vector'length/2))) + unsigned(count_ones_recursive(vector'length/2-1 downto 0)));

         return count;
   end count_ones_recursive;

end package body ft_package;
