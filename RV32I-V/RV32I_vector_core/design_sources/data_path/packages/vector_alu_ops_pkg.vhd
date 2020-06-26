library ieee;
use ieee.std_logic_1164.all;

package vector_alu_ops_pkg is

   -- ALU OP CODE
   constant and_op: std_logic_vector (4 downto 0):="00000"; ---> bitwise and
   constant or_op: std_logic_vector (4 downto 0):="00001"; ---> bitwise or
   constant add_op: std_logic_vector (4 downto 0):="00010"; ---> add a_i and b_i
   constant xor_op: std_logic_vector (4 downto 0):="00011"; ---> bitwise xor   
   constant sub_op: std_logic_vector (4 downto 0):="00110"; ---> sub a_i and b_i
   constant srl_op: std_logic_vector (4 downto 0):="00111"; ---> shift right logic
   constant sra_op: std_logic_vector (4 downto 0):="01000"; ---> shift right arithmetic
   constant mulu_op: std_logic_vector (4 downto 0):="01001"; ---> multiply lower_unsigned
   constant mulhs_op: std_logic_vector (4 downto 0):="01010"; ---> multiply higher signed
   constant mulhsu_op: std_logic_vector (4 downto 0):="01011"; ---> multiply higher signed and unsigned
   constant mulhu_op: std_logic_vector (4 downto 0):="01100"; ---> multiply higher unsigned
   constant divu_op: std_logic_vector (4 downto 0):="01101"; ---> divide unsigned
   constant divs_op: std_logic_vector (4 downto 0):="01110"; ---> divide signed
   constant remu_op: std_logic_vector (4 downto 0):="01111"; ---> reminder unsigned
   constant rems_op: std_logic_vector (4 downto 0):="10000"; ---> reminder signed
   constant muls_op: std_logic_vector (4 downto 0):="10001"; ---> multiply lower_signed   
   constant lts_op: std_logic_vector (4 downto 0):="10100"; ---> set less than signed
   constant ltu_op: std_logic_vector (4 downto 0):="10101"; ---> set less than unsigned
   constant sll_op: std_logic_vector (4 downto 0):="10110"; ---> shift left logic      
   constant eq_op: std_logic_vector (4 downto 0):="10111"; --->  set equal
   constant neq_op: std_logic_vector (4 downto 0):="11000"; --->  set not equal
   constant sleu_op:std_logic_vector (4 downto 0):="11001"; --->  set less then_or_equal_signed
   constant sle_op:std_logic_vector (4 downto 0):="11010"; --->  set less then_or_equal_unsigned
   constant sgtu_op:std_logic_vector (4 downto 0):="11011"; --->  set less then_or_equal_signed
   constant sgt_op:std_logic_vector (4 downto 0):="11100"; --->  set less then_or_equal_unsigne
   constant min_op:std_logic_vector (4 downto 0):="11101"; --->  set less then_or_equal_signed
   constant minu_op:std_logic_vector (4 downto 0):="11110"; --->  set less then_or_equal_unsigne
   
   
   
   
   
   
   
   



end package vector_alu_ops_pkg;