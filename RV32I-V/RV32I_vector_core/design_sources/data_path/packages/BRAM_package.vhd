library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;

package custom_functions_pkg is
   constant MAX_INSTR_NUM_C                       :    integer := 32;
   type instructions_mem is array (0 to MAX_INSTR_NUM_C - 1) of std_logic_vector(31 downto 0);
   function clogb2 (depth                         : in natural) return integer;
   impure function read_instr_from_file (instr_file_name : in string) return instructions_mem;
end custom_functions_pkg;

package body custom_functions_pkg is

   function clogb2(depth : natural) return integer is
      variable temp    : integer := depth;
      variable ret_val : integer := 0;
   begin
      while temp > 1 loop
         ret_val := ret_val + 1;
         temp    := temp / 2;
      end loop;
      return ret_val;
   end function;


-- Read instructions from a file
   impure function read_instr_from_file (instr_file_name : in string) return instructions_mem is
      file instr_file             : text is in instr_file_name;
      variable instr_file_line    : line;
      variable instructions_array : instructions_mem;
      variable bitvec             : bit_vector(31 downto 0);
      variable i                  : integer := 0;
   begin
       while (not endfile(instr_file))loop
         readline (instr_file, instr_file_line);
         read (instr_file_line, bitvec);
         instructions_array(i) := to_stdlogicvector(bitvec);
         i                     := i + 1;
       end loop;
      return instructions_array;
   end function;



end package body custom_functions_pkg;
