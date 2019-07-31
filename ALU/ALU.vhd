LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;
USE ieee.std_logic_arith.ALL;
-- Arithmetic Logic Unit (ALU)
-- OP:
-- 00 00 -> bitwise and
-- 11 00 -> bitwise nor
-- 00 01 -> bitwise or
-- 11 01 -> bitwise nand
-- 00 10 -> add a_i and b_i 
-- 01 10 -> sub a_i and b_i
-- 01 11 -> set less than

ENTITY ALU IS
	GENERIC(
		WIDTH : NATURAL := 64);
	PORT(
		a_i  :  IN   STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0); --first input
		b_i  :  IN   STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0); --second input
		op_i  :  IN   STD_LOGIC_VECTOR(3 DOWNTO 0); --operation select
		res_o   :  OUT  STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0); --result
		zero_o   :  OUT  STD_LOGIC; --zero flag
		of_o   :  OUT  STD_LOGIC); --overflow flag
END ALU;

ARCHITECTURE behavioral OF ALU IS

	SIGNAL    ainv_s,binv_s : STD_LOGIC;
	SIGNAL    op_s      : STD_LOGIC_VECTOR(1 DOWNTO 0);
	SIGNAL 	  carry, of_s : STD_LOGIC;
	SIGNAL    less_res,adder_res,or_res,and_res,res_s  :  STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
	SIGNAL    a_s,b_s   :    STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);

BEGIN
	ainv_s<=op_i(3);
	binv_s<=op_i(2);
	op_s<=op_i(1 downto 0);
	


	-- carry lookahead adder instaance
	cl_addr: entity work.c_l_adder_top(behavioral)
		generic map(CELL_WIDTH => 8,
						CELL_NUM => 8)
		port map(x_in=>a_s,
					y_in=>b_s,
					c_in=>binv_s,
					sum=>adder_res,
					c_out=>carry);

		
	--invert a depending on ainv signal
	a_s <= a_i when ainv_s = '0' else
			 not a_i;

	--invert b depending on binv signal
	b_s <= b_i when binv_s = '0' else
			 not b_i;

	-- and gate
	and_res <= a_s and b_s;

	-- or gate
	or_res <= a_s or b_s;

	-- a_i is less than b_i if the result of their subtraction is negative and no ovorflow occured
	less_res <= conv_std_logic_vector(1,WIDTH) when (adder_res(WIDTH-1) = '1' and of_s = '0') else
					conv_std_logic_vector(0,WIDTH);
					

	--result
	res_o <= res_s;
	-- result output mux
	with op_s select
		res_s <= and_res when "00", --and, nand
					or_res when "01", --or, nor
					adder_res when "10", --add, sub
					less_res when others; -- set less than

	-- set zero output flag when result is zero
	zero_o <= '1' when res_s = conv_std_logic_vector(0,WIDTH) else
				 '0';
	--overflow
	of_o <= of_s;
	-- overflow happens when inputs are of same sign, and output is of different
	of_s <= '1' when ((a_s(WIDTH-1)='1' and b_s(WIDTH-1)='1' and adder_res(WIDTH-1)='0') or (a_s(WIDTH-1)='0' and b_s(WIDTH-1)='0' and adder_res(WIDTH-1)='1')) else
			  '0';


END behavioral;
