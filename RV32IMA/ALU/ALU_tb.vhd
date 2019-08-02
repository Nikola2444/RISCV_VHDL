library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;


entity ALU_tb is
end ALU_tb;

architecture Behavioral of ALU_tb is
	constant WIDTH : NATURAL := 32;
	SIGNAL a_i  :  STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0); --first input
	SIGNAL b_i  :  STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0); --second input
	SIGNAL op_i  :  STD_LOGIC_VECTOR(3 DOWNTO 0); --operation select
	SIGNAL res_o   :  STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0); --result
	SIGNAL zero_o   :  STD_LOGIC; --zero flag
	SIGNAL of_o   :  STD_LOGIC; --overflow flag

begin

addr: entity work.ALU(Behavioral)
generic map (WIDTH => WIDTH)
port map(
		a_i=>a_i,
		b_i=>b_i,
		op_i=>op_i,
		res_o=>res_o,
		zero_o=>zero_o,
		of_o=>of_o);

-- Arithmetic Logic Unit (ALU)
-- OP:
-- 00 00 -> bitwise and
-- 00 01 -> bitwise or
-- 00 10 -> bitwise xor
-- 00 11 -> add a_i and b_i 
-- 10 11 -> sub a_i and b_i
-- 11 00 -> set less than signed
-- 11 01 -> set less than unsigned

op_i <= "0000", "001" after 50 ns,"0001" after 100 ns,"0010" after 150 ns,"0011" after 200 ns,"1011" after 350 ns,"1100" after 400 ns,"1101" after 500 ns;

a_i <= conv_std_logic_vector(65280,WIDTH),		conv_std_logic_vector(65280,WIDTH) after 175 ns,	
		  
		  conv_std_logic_vector(3,WIDTH) after 200 ns,  conv_std_logic_vector(-3,WIDTH) after 225 ns,	 
		  conv_std_logic_vector(-2147483647,WIDTH) after 250 ns, conv_std_logic_vector(-2147483648,WIDTH) after 275 ns,
		  conv_std_logic_vector( 2147483647,WIDTH) after 300 ns,conv_std_logic_vector(-10,WIDTH) after 350 ns,
		  
		  conv_std_logic_vector(7,WIDTH) after 400 ns, conv_std_logic_vector(5,WIDTH) after 425 ns,
		  conv_std_logic_vector(-7,WIDTH) after 450 ns, conv_std_logic_vector(6,WIDTH) after 475 ns,
		  conv_std_logic_vector(7,WIDTH) after 500 ns, conv_std_logic_vector(5,WIDTH) after 525 ns,
		  conv_std_logic_vector(-7,WIDTH) after 550 ns, conv_std_logic_vector(6,WIDTH) after 575 ns;

b_i <= conv_std_logic_vector(61680,WIDTH),		conv_std_logic_vector(65280,WIDTH) after 175 ns,		
		  
		  conv_std_logic_vector(5,WIDTH) after 200 ns,	conv_std_logic_vector(-5,WIDTH) after 225 ns,	 
		  conv_std_logic_vector(-2147483647,WIDTH) after 250 ns, conv_std_logic_vector(-2147483648,WIDTH) after 275 ns,
		  conv_std_logic_vector( 2147483647,WIDTH) after 300 ns,conv_std_logic_vector(-20,WIDTH) after 350 ns,
		  
		  conv_std_logic_vector(5,WIDTH) after 400 ns, conv_std_logic_vector(7,WIDTH) after 425 ns,
		  conv_std_logic_vector(6,WIDTH) after 450 ns, conv_std_logic_vector(-7,WIDTH) after 475 ns,
		  conv_std_logic_vector(5,WIDTH) after 500 ns, conv_std_logic_vector(7,WIDTH) after 525 ns,
		  conv_std_logic_vector(6,WIDTH) after 550 ns, conv_std_logic_vector(-7,WIDTH) after 575 ns;
    
end Behavioral;
