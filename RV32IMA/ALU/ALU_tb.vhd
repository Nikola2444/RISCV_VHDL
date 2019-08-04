library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.STD_LOGIC_UNSIGNED.ALL;
--use IEEE.STD_LOGIC_ARITH.ALL;
USE ieee.numeric_std.ALL;


entity ALU_tb is
end ALU_tb;

architecture Behavioral of ALU_tb is
	constant WIDTH : NATURAL := 32;
	SIGNAL a_i  :  STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0); --first input
	SIGNAL b_i  :  STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0); --second input
	SIGNAL op_i  :  STD_LOGIC_VECTOR(4 DOWNTO 0); --operation select
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

op_i <= "00000", "00001" after 50 ns,"00001" after 100 ns,"00010" after 150 ns,"00011" after 200 ns,"10011" after 350 ns,"10100" after 400 ns,"10101" after 500 ns,"00110" after 600 ns,"00111" after 630 ns, "01000" after 670 ns;

a_i <= std_logic_vector(to_unsigned(65280,WIDTH)),		std_logic_vector(to_unsigned(65280,WIDTH)) after 175 ns,	
		  
		  std_logic_vector(to_unsigned(3,WIDTH)) after 200 ns,  std_logic_vector(to_signed(-3,WIDTH)) after 225 ns,	 
		  std_logic_vector(to_signed(-2147483647,WIDTH)) after 250 ns, std_logic_vector(to_signed(-2147483648,WIDTH)) after 275 ns,
		  std_logic_vector(to_unsigned( 2147483647,WIDTH)) after 300 ns,std_logic_vector(to_signed(-10,WIDTH)) after 350 ns,
		  
		  std_logic_vector(to_unsigned(7,WIDTH)) after 400 ns, std_logic_vector(to_unsigned(5,WIDTH)) after 425 ns,
		  std_logic_vector(to_signed(-7,WIDTH)) after 450 ns, std_logic_vector(to_unsigned(6,WIDTH)) after 475 ns,
		  std_logic_vector(to_unsigned(7,WIDTH)) after 500 ns, std_logic_vector(to_unsigned(5,WIDTH)) after 525 ns,
		  std_logic_vector(to_signed(-7,WIDTH)) after 550 ns, std_logic_vector(to_unsigned(6,WIDTH)) after 575 ns,
		  (others=>'1') after 600 ns, std_logic_vector(to_signed(-65227,WIDTH)) after 700 ns;

b_i <= std_logic_vector(to_unsigned(61680,WIDTH)),		std_logic_vector(to_unsigned(65280,WIDTH)) after 175 ns,		
		  
		  std_logic_vector(to_unsigned(5,WIDTH)) after 200 ns,	std_logic_vector(to_signed(-5,WIDTH)) after 225 ns,	 
		  std_logic_vector(to_signed(-2147483647,WIDTH)) after 250 ns, std_logic_vector(to_signed(-2147483648,WIDTH)) after 275 ns,
		  std_logic_vector(to_unsigned( 2147483647,WIDTH)) after 300 ns,std_logic_vector(to_unsigned(2147483647,WIDTH)) after 350 ns,
		  
		  std_logic_vector(to_unsigned(5,WIDTH)) after 400 ns, std_logic_vector(to_unsigned(7,WIDTH)) after 425 ns,
		  std_logic_vector(to_unsigned(6,WIDTH)) after 450 ns, std_logic_vector(to_signed(-7,WIDTH)) after 475 ns,
		  std_logic_vector(to_unsigned(5,WIDTH)) after 500 ns, std_logic_vector(to_unsigned(7,WIDTH)) after 525 ns,
		  std_logic_vector(to_unsigned(6,WIDTH)) after 550 ns, std_logic_vector(to_signed(-7,WIDTH)) after 575 ns,
          std_logic_vector(to_unsigned(31,WIDTH)) after 600 ns, std_logic_vector(to_unsigned(32,WIDTH)) after 700 ns;

end Behavioral;
