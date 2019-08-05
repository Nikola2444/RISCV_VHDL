----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/02/2019 02:15:07 PM
-- Design Name: 
-- Module Name: test_top - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity test_top is
    GENERIC(
		WIDTH : NATURAL := 32);
	PORT(
		clk   :  IN  STD_LOGIC; --zero flag
		a_i  :  IN   STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0); --first input
		b_i  :  IN   STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0); --second input
		op_i  :  IN   STD_LOGIC_VECTOR(4 DOWNTO 0); --operation select
		res_o   :  OUT  STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0); --result
		zero_o   :  OUT  STD_LOGIC; --zero flag
		of_o   :  OUT  STD_LOGIC); --overflow flag
end test_top;

architecture Behavioral of test_top is
		signal a_s  :  STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0); --first input
		signal b_s  :  STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0); --second input
		signal op_s  :  STD_LOGIC_VECTOR(4 DOWNTO 0); --operation select
		signal res_s   :  STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0); --result
		signal zero_s   :  STD_LOGIC; --zero flag
		signal of_s   :  STD_LOGIC; --overflow flag
begin
    
    
    
    addr: entity work.ALU(Behavioral)
    generic map(WIDTH=>WIDTH)
    port map(a_i=>a_s,
             b_i=>b_s,
             op_i=>op_s,
             res_o=> res_s,
             zero_o=> zero_s,
		     of_o=>of_s);
        
        
    klok: process(clk)
    begin
        if(rising_edge(clk))then
            a_s <= a_i;
            b_s<= b_i;
            op_s <= op_i;
            res_o <= res_s;
            zero_o <= zero_s;
            of_o <= of_s;
        end if;
    end process;
    
    

end Behavioral;
