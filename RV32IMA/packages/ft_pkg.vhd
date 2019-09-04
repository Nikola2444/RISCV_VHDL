library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
USE ieee.math_real.ceil;
USE ieee.math_real.log2;

package ft_pkg is

   type array32_t is array (integer range <>) of std_logic_vector(31 downto 0);
   
   
   -- counts number of ones in std_logic_vector and returns it in binary (unary to binary converter)
   -- serial -> function is implemented as a simple loop, good readability bad performance
   function count_ones_serial    (vector : std_logic_vector) return std_logic_vector;
   -- recursive -> function is implemented as a binary tree in hope of better timing result
   function count_ones_recursive (vector : std_logic_vector; RETURN_W : natural) return std_logic_vector;

end package ft_pkg;




package body ft_pkg is


   function count_ones_serial (vector : std_logic_vector) return std_logic_vector is
      constant RETURN_W : integer := (integer(ceil(log2(real(vector'length)))) + integer(1));
      variable count : std_logic_vector(RETURN_W-1 downto 0);
   begin

      count := (others => '0');

      for i in 0 to (vector'length-1) loop
         if(vector(i) = '1') then
            count := std_logic_vector(unsigned(count) + (to_unsigned(1,RETURN_W)));
         else
            count := std_logic_vector(unsigned(count) + (to_unsigned(0,RETURN_W)));
         end if;
      end loop;

      return count;

   end count_ones_serial;


   function count_ones_recursive (vector : std_logic_vector; RETURN_W: natural) return std_logic_vector is
      --constant RETURN_W : integer := (integer(ceil(log2(real(vector'length)))) + integer(1));
      variable count : std_logic_vector(RETURN_W-1 downto 0);
      variable res_upper,res_lower : unsigned(RETURN_W-1 downto 0);
   begin
         if(vector'length = 1)then
            return std_logic_vector(to_unsigned(to_integer(unsigned(vector)),RETURN_W));
         end if;

         res_upper := unsigned(count_ones_recursive(vector(vector'length downto vector'length/2),RETURN_W));
         res_lower := unsigned(count_ones_recursive(vector(vector'length/2-1 downto 0),RETURN_W));
         count := std_logic_vector(res_upper + res_lower);

         return count;
   end count_ones_recursive;

end package body ft_pkg;
