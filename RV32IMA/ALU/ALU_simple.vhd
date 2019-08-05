LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
--USE ieee.std_logic_arith.ALL;
USE ieee.numeric_std.ALL;
use ieee.math_real.all;

-- Arithmetic Logic Unit (ALU)
-- OP:
-- 00000 -> bitwise and
-- 00001 -> bitwise or
-- 00010 -> bitwise xor
-- 00011 -> add a_i and b_i
-- 10011 -> sub a_i and b_i
-- 10100 -> set less than signed
-- 10101 -> set less than unsigned
-- 00110 -> shift left logic
-- 00111 -> shift right logic
-- 01000 -> shift right arithmetic

ENTITY ALU IS
	GENERIC(
		WIDTH : NATURAL := 32);
	PORT(
		a_i  :  IN   STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0); --first input
		b_i  :  IN   STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0); --second input
		op_i  :  IN   STD_LOGIC_VECTOR(4 DOWNTO 0); --operation select
		res_o   :  OUT  STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0); --result
		zero_o   :  OUT  STD_LOGIC; --zero flag
		of_o   :  OUT  STD_LOGIC); --overflow flag
END ALU;

ARCHITECTURE behavioral OF ALU IS

	SIGNAL    lts_res,ltu_res,add_res,sub_res,or_res,and_res,res_s,xor_res  :  STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
	SIGNAL    sll_res,srl_res,sra_res : STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
   constant l2WIDTH : natural := integer(ceil(log2(real(WIDTH))));

BEGIN

	
		

	-- addition
	add_res <= std_logic_vector(unsigned(a_i) + unsigned(b_i));
	-- subtraction
	sub_res <= std_logic_vector(unsigned(a_i) - unsigned(b_i));
	-- and gate
	and_res <= a_i and b_i;
	-- or gate
	or_res <= a_i or b_i;
	-- xor gate
	xor_res <= a_i xor b_i;
	-- less then signed
	lts_res <= std_logic_vector(to_unsigned(1,WIDTH)) when (signed(a_i) < signed(b_i)) else
	           std_logic_vector(to_unsigned(0,WIDTH));
	-- less then unsigned
	ltu_res <= std_logic_vector(to_unsigned(1,WIDTH)) when (unsigned(a_i) < unsigned(b_i)) else
	           std_logic_vector(to_unsigned(0,WIDTH));
	--shift results
	sll_res <= std_logic_vector(shift_left(unsigned(a_i), to_integer(unsigned(b_i(l2WIDTH downto 0)))));
	srl_res <= std_logic_vector(shift_right(unsigned(a_i), to_integer(unsigned(b_i(l2WIDTH downto 0)))));
	sra_res <= std_logic_vector(shift_right(signed(a_i), to_integer(unsigned(b_i(l2WIDTH downto 0)))));

	-- SELECT RESULT
	res_o <= res_s;
	with op_i select
		res_s <= and_res when "00000", --and
					or_res when "00001", --or
					xor_res when "00010", --xor
					add_res when "00011", --add
					sub_res when "10011", --sub
					lts_res when "10100", -- set less than signed
					ltu_res when "10101", -- set less than unsigned
					sll_res when "00110", -- shift left logic
					srl_res when "00111", -- shift right logic
					sra_res when others; -- shift right arithmetic


	-- FLAG OUTPUTS
	-- set zero output flag when result is zero
	zero_o <= '1' when res_s = std_logic_vector(to_unsigned(0,WIDTH)) else
				 '0';
	-- overflow happens when inputs have same sign, and output has different
	of_o <= '1' when ((op_i="00011" and (a_i(WIDTH-1)=b_i(WIDTH-1)) and ((a_i(WIDTH-1) xor res_s(WIDTH-1))='1')) or (op_i="10011" and (a_i(WIDTH-1)=res_s(WIDTH-1)) and ((a_i(WIDTH-1) xor b_i(WIDTH-1))='1'))) else
			  '0';


END behavioral;
