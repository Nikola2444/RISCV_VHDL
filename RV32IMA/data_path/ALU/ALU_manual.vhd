LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
--USE ieee.std_logic_arith.ALL;
--USE ieee.unsigned.ALL
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
-- 01000-> shift right arithmetic

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

	SIGNAL    binv_cin_s : STD_LOGIC;
	SIGNAL    op_s      : STD_LOGIC_VECTOR(3 DOWNTO 0);
	SIGNAL 	 carry, of_s : STD_LOGIC;
	SIGNAL    lts_res,ltu_res,adder_res,or_res,and_res,res_s,xor_res  :  STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
	SIGNAL    sll_res,srl_res,sra_res : STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);

	SIGNAL 	 adder_res_tmp : UNSIGNED(WIDTH DOWNTO 0);
	SIGNAL    a_s,b_s   :    STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
   constant l2WIDTH : natural := integer(ceil(log2(real(WIDTH))));
BEGIN

	-- control signals
	binv_cin_s<=op_i(4); --signal for inverting b input, and carry_in to adder at the same time
	op_s<=op_i(3 downto 0);
	-- semantics
	a_s <= a_i;
	--invert b_s depending on binv signal
	b_s <= b_i when binv_cin_s = '0' else
			 not b_i;
	

	-- GENERATE ARITHMETIC OPERATIONS
	adder_res_tmp <= unsigned('0' & a_s) + unsigned('0' & b_s) +  unsigned(to_unsigned(0,WIDTH-1) & binv_cin_s);
	carry <= adder_res_tmp(WIDTH);
	adder_res <= std_logic_vector(adder_res_tmp(WIDTH-1 downto 0));
	-- and gate
	and_res <= a_s and b_s;
	-- or gate
	or_res <= a_s or b_s;
	-- xor gate
	xor_res <= a_s xor b_s;
	-- a_i is less than b_i if the result of their subtraction is negative and no ovorflow occured [SIGNED]
	lts_res <= std_logic_vector(to_unsigned(1,WIDTH)) when (adder_res(WIDTH-1) = '1' and of_s = '0') else
					std_logic_vector(to_unsigned(0,WIDTH));
	-- a_i is less than b_i if the result of their subtraction is negative [UNSIGNED]
	ltu_res <= std_logic_vector(to_unsigned(1,WIDTH)) when (adder_res(WIDTH-1) = '1') else
					std_logic_vector(to_unsigned(0,WIDTH));
	--shift results
	sll_res <= std_logic_vector(shift_left(unsigned(a_s), to_integer(unsigned(b_s(l2WIDTH downto 0)))));
	srl_res <= std_logic_vector(shift_right(unsigned(a_s), to_integer(unsigned(b_s(l2WIDTH downto 0)))));
	sra_res <= std_logic_vector(shift_right(signed(a_s), to_integer(unsigned(b_s(l2WIDTH downto 0)))));
					

	-- SELECT RESULT
	res_o <= res_s;
	with op_s select
		res_s <= and_res when "0000", --and
					or_res when "0001", --or
					xor_res when "0010", --xor
					adder_res when "0011", --add, sub
					lts_res when "0100", -- set less than signed
					ltu_res when "0101", -- set less than unsigned
					sll_res when "0110", -- shift left logic
					srl_res when "0111", -- shift right logic
					sra_res when others; -- shift right arithmetic


	-- FLAG OUTPUTS
	-- set zero output flag when result is zero
	zero_o <= '1' when res_s = std_logic_vector(to_unsigned(0,WIDTH)) else
				 '0';
	--overflow
	of_o <= of_s;
	-- overflow happens when inputs are of same sign, and output is of different
	of_s <= '1' when ((a_s(WIDTH-1) = b_s(WIDTH-1)) and (a_s(WIDTH-1) xor adder_res(WIDTH-1))='1') else
			  '0';


END behavioral;
