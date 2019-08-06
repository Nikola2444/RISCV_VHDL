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
		CELL_WIDTH : NATURAL := 8;
		CELL_NUM : NATURAL := 8);
	PORT(
		x_in  :  IN   STD_LOGIC_VECTOR(((CELL_NUM*CELL_WIDTH)-1) DOWNTO 0);
		y_in  :  IN   STD_LOGIC_VECTOR(((CELL_NUM*CELL_WIDTH)-1) DOWNTO 0);
		c_in  :  IN   STD_LOGIC;
		clk  :  IN   STD_LOGIC;
		sum   :  OUT  STD_LOGIC_VECTOR(((CELL_NUM*CELL_WIDTH)-1) DOWNTO 0);
		c_out :  OUT  STD_LOGIC);
end test_top;

architecture Behavioral of test_top is
        signal x_in_s  :    STD_LOGIC_VECTOR(((CELL_NUM*CELL_WIDTH)-1) DOWNTO 0);
		signal y_in_s  :  STD_LOGIC_VECTOR(((CELL_NUM*CELL_WIDTH)-1) DOWNTO 0);
		signal c_in_s  :  STD_LOGIC;
        signal sum_s   :    STD_LOGIC_VECTOR(((CELL_NUM*CELL_WIDTH)-1) DOWNTO 0);
		signal c_out_s :    STD_LOGIC;
begin
    
    
    
    addr: entity work.c_l_adder_top(Behavioral)
    generic map(CELL_WIDTH=>CELL_WIDTH,
                CELL_NUM=>CELL_NUM)
    port map(x_in=>x_in_s,
            y_in=>y_in_s,
            c_in=>c_in_s,
            sum => sum_s,
            c_out => c_out_s);
        
        
    klok: process(clk)
    begin
        if(rising_edge(clk))then
            x_in_s <= x_in;
            y_in_s<= y_in;
            c_in_s <= c_in;
            sum <= sum_s;
            c_out<= c_out_s;
        
    
        end if;
   
    end process;
    
    

end Behavioral;
