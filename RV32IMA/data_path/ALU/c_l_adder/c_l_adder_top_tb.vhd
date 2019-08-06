library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;


entity c_l_adder_top_tb is
end c_l_adder_top_tb;

architecture Behavioral of c_l_adder_top_tb is
        constant WIDTH : NATURAL :=64;
        signal x_in  :STD_LOGIC_VECTOR((WIDTH-1) DOWNTO 0);
		signal y_in  :  STD_LOGIC_VECTOR((WIDTH-1) DOWNTO 0);
		signal c_in  : STD_LOGIC;
		signal sum   :  STD_LOGIC_VECTOR((WIDTH-1) DOWNTO 0);
		signal c_out :  STD_LOGIC;

begin

addr: entity work.c_l_adder_top(Behavioral)
generic map (CELL_WIDTH => 8,
             CELL_NUM => 8)
port map(
    x_in=>x_in,
    y_in=>y_in,
    c_in=>c_in,
    sum=>sum,
    c_out=>c_out);
    
c_in <= '0', '1' after 250 ns;
x_in <= conv_std_logic_vector(500,WIDTH),conv_std_logic_vector(1245,WIDTH) after 100ns,(others=>'1') after 200ns,(others=>'1') after 300ns,(others=>'1') after 400ns;
y_in <= conv_std_logic_vector(900,WIDTH),conv_std_logic_vector(1212,WIDTH) after 100ns,conv_std_logic_vector(0,WIDTH) after 200ns,conv_std_logic_vector(1,WIDTH) after 300ns,conv_std_logic_vector(2,WIDTH) after 400ns;

    
end Behavioral;
