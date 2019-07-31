library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;


entity ALU_tb is
end ALU_tb;

architecture Behavioral of ALU_tb is
	constant WIDTH : NATURAL := 64;
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
    
-- 00 00 -> bitwise and
-- 11 00 -> bitwise nor
-- 00 01 -> bitwise or
-- 11 01 -> bitwise nand
-- 00 10 -> add a_i and b_i 
-- 01 10 -> sub a_i and b_i
-- 01 11 -> set less than

op_i <= "0000", "1101" after 50 ns,"0001" after 100 ns,"1100" after 150 ns,"0010" after 200 ns,"0110" after 300 ns,"0111" after 400 ns;

a_i <= conv_std_logic_vector(65280,WIDTH),		conv_std_logic_vector(65280,WIDTH) after 175 ns,	
		  conv_std_logic_vector(3,WIDTH) after 200 ns,  conv_std_logic_vector(-3,WIDTH) after 225 ns,	 
		  conv_std_logic_vector(32767,WIDTH) after 250 ns, conv_std_logic_vector(-32768,WIDTH) after 275 ns,
		  conv_std_logic_vector(-32768,WIDTH) after 300 ns,conv_std_logic_vector(50,WIDTH) after 350 ns,
		  conv_std_logic_vector(15,WIDTH) after 400 ns, conv_std_logic_vector(-15,WIDTH) after 425 ns,
		  conv_std_logic_vector(-3,WIDTH) after 450 ns, conv_std_logic_vector(-7,WIDTH) after 475 ns;

b_i <= conv_std_logic_vector(61680,WIDTH),		conv_std_logic_vector(255,WIDTH) after 175 ns,		
		  conv_std_logic_vector(5,WIDTH) after 200 ns,	conv_std_logic_vector(-5,WIDTH) after 225 ns,	 
		  conv_std_logic_vector(32767,WIDTH) after 250 ns, conv_std_logic_vector(-32700,WIDTH) after 275 ns,
		  conv_std_logic_vector(-32768,WIDTH) after 300 ns,conv_std_logic_vector(60,WIDTH) after 350 ns,
		  conv_std_logic_vector(14,WIDTH) after 400 ns, conv_std_logic_vector(14,WIDTH) after 425 ns,
		  conv_std_logic_vector(-4,WIDTH) after 450 ns, conv_std_logic_vector(6,WIDTH) after 475 ns;

    
end Behavioral;
