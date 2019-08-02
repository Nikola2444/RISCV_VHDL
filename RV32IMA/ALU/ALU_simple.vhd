LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
-- Arithmetic Logic Unit (ALU)
-- OP:
-- 00 00 -> bitwise and
-- 00 01 -> bitwise or
-- 00 10 -> bitwise xor
-- 00 11 -> add a_i and b_i 
-- 10 11 -> sub a_i and b_i
-- 11 00 -> set less than signed
-- 11 01 -> set less than unsigned

ENTITY ALU IS
	GENERIC(
		WIDTH : NATURAL := 32);
	PORT(
		a_i  :  IN   STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0); --first input
		b_i  :  IN   STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0); --second input
		op_i  :  IN   STD_LOGIC_VECTOR(3 DOWNTO 0); --operation select
		res_o   :  OUT  STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0); --result
		zero_o   :  OUT  STD_LOGIC; --zero flag
		of_o   :  OUT  STD_LOGIC); --overflow flag
END ALU;

ARCHITECTURE behavioral OF ALU IS

	SIGNAL    lts_res,ltu_res,add_res,sub_res,or_res,and_res,res_s,xor_res  :  STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);

BEGIN

	
		

	-- addition
	add_res <= unsigned(a_i) + unsigned(b_i);
	-- subtraction
	sub_res <= unsigned(a_i) - unsigned(b_i);
	-- and gate
	and_res <= a_i and b_i;
	-- or gate
	or_res <= a_i or b_i;
	-- xor gate
	xor_res <= a_i xor b_i;
	-- less then signed
	lts_res <= conv_std_logic_vector(1,WIDTH) when (signed(a_i) < signed(b_i)) else
	           conv_std_logic_vector(0,WIDTH);
	-- less then unsigned
	ltu_res <= conv_std_logic_vector(1,WIDTH) when (unsigned(a_i) < unsigned(b_i)) else
	           conv_std_logic_vector(0,WIDTH);

	-- SELECT RESULT
	res_o <= res_s;
	with op_i select
		res_s <= and_res when "0000", --and
					or_res when "0001", --or
					xor_res when "0010", --xor
					add_res when "0011", --add
					sub_res when "1011", --sub
					lts_res when "1100", -- set less than signed
					ltu_res when others; -- set less than unsigned


	-- FLAG OUTPUTS
	-- set zero output flag when result is zero
	zero_o <= '1' when res_s = conv_std_logic_vector(0,WIDTH) else
				 '0';
	-- overflow happens when inputs have same sign, and output has different
	of_o <= '1' when op_i(1 downto 0)="11" and ((a_i(WIDTH-1)=b_i(WIDTH-1) and (a_i(WIDTH-1) xor add_res(WIDTH-1))='1') or (a_i(WIDTH-1)=sub_res(WIDTH-1) and (a_i(WIDTH-1) xor b_i(WIDTH-1))='1')) else
			  '0';


END behavioral;
