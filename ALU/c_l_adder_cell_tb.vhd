library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;


entity c_l_adder_cell_tb is
end c_l_adder_cell_tb;

architecture Behavioral of c_l_adder_cell_tb is
        constant WIDTH : NATURAL :=4;
        signal x_in  :STD_LOGIC_VECTOR((WIDTH-1) DOWNTO 0);
		signal y_in  :  STD_LOGIC_VECTOR((WIDTH-1) DOWNTO 0);
		signal c_in  : STD_LOGIC;
		signal sum   :  STD_LOGIC_VECTOR((WIDTH-1) DOWNTO 0);
		signal c_out :  STD_LOGIC;
		signal g_out :  STD_LOGIC;
		signal p_out :  STD_LOGIC;
begin

addr: entity work.c_l_adder_cell(Behavioral)
generic map (WIDTH => WIDTH)
port map(
    x_in=>x_in,
    y_in=>y_in,
    c_in=>c_in,
    sum=>sum,
    c_out=>c_out,
    g_out=>g_out,
    p_out=>p_out);
    
c_in <= '0', '1' after 1000 ns;
x_in <= conv_std_logic_vector(5,WIDTH),conv_std_logic_vector(2,WIDTH) after 100ns,conv_std_logic_vector(15,WIDTH) after 200ns,conv_std_logic_vector(15,WIDTH) after 300ns,conv_std_logic_vector(15,WIDTH) after 400ns;
y_in <= conv_std_logic_vector(2,WIDTH),conv_std_logic_vector(5,WIDTH) after 100ns,conv_std_logic_vector(0,WIDTH) after 200ns,conv_std_logic_vector(1,WIDTH) after 300ns,conv_std_logic_vector(2,WIDTH) after 400ns;

    
end Behavioral;
