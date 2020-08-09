library ieee;
use ieee.std_logic_1164.all;

package vector_alu_ops_pkg is

   -- ALU OP CODE
   -- constant and_op: std_logic_vector (4 downto 0):="00000"; ---> bitwise and
   -- constant or_op: std_logic_vector (4 downto 0):="00001"; ---> bitwise or
   -- constant add_op: std_logic_vector (4 downto 0):="00010"; ---> add a_i and b_i
   -- constant xor_op: std_logic_vector (4 downto 0):="00011"; ---> bitwise xor   
   -- constant sub_op: std_logic_vector (4 downto 0):="00100"; ---> sub a_i and b_i
   -- constant srl_op: std_logic_vector (4 downto 0):="00101"; ---> shift right logic
   -- constant sra_op: std_logic_vector (4 downto 0):="00110"; ---> shift right arithmetic
   -- constant mulu_op: std_logic_vector (4 downto 0):="00111"; ---> multiply lower_unsigned
   -- constant mulhs_op: std_logic_vector (4 downto 0):="01000"; ---> multiply higher signed
   -- constant mulhsu_op: std_logic_vector (4 downto 0):="01001"; ---> multiply higher signed and unsigned
   -- constant mulhu_op: std_logic_vector (4 downto 0):="01010"; ---> multiply higher unsigned
   -- constant divu_op: std_logic_vector (4 downto 0):="01011"; ---> divide unsigned
   -- constant divs_op: std_logic_vector (4 downto 0):="01100"; ---> divide signed
   -- constant remu_op: std_logic_vector (4 downto 0):="01101"; ---> reminder unsigned
   -- constant rems_op: std_logic_vector (4 downto 0):="01110"; ---> reminder signed
   -- constant muls_op: std_logic_vector (4 downto 0):="01111"; ---> multiply lower_signed   
   -- constant slt_op: std_logic_vector (4 downto 0):="10000"; ---> set less than signed
   -- constant sltu_op: std_logic_vector (4 downto 0):="10001"; ---> set less than unsigned
   -- constant sll_op: std_logic_vector (4 downto 0):="10010"; ---> shift left logic      
   -- constant eq_op: std_logic_vector (4 downto 0):="10011"; --->  set equal
   -- constant neq_op: std_logic_vector (4 downto 0):="10100"; --->  set not equal
   -- constant sleu_op:std_logic_vector (4 downto 0):="10101"; --->  set less then_or_equal_signed
   -- constant sle_op:std_logic_vector (4 downto 0):="10110"; --->  set less then_or_equal_unsigned
   -- constant sgtu_op:std_logic_vector (4 downto 0):="10111"; --->  set less then_or_equal_signed
   -- constant sgt_op:std_logic_vector (4 downto 0):="11000"; --->  set less then_or_equal_unsigne
   -- constant min_op:std_logic_vector (4 downto 0):="11001"; --->  set less then_or_equal_signed
   -- constant minu_op:std_logic_vector (4 downto 0):="11010"; --->  set less then_or_equal_unsigne
   
   type vector_alu_ops_t is (and_op, or_op, add_op, xor_op, sub_op, srl_op, sra_op, mulu_op, mulhs_op, mulhsu_op, mulhu_op, divu_op, divs_op, remu_op, rems_op, muls_op, slt_op, sltu_op, sll_op, eq_op, neq_op, sleu_op, sle_op, sgtu_op, sgt_op, min_op, minu_op);
   
   
   
   
   
   



end package vector_alu_ops_pkg;
