library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
--use work.txt_util.all;

entity RISCV_w_BRAMs_tb is
end entity;

architecture Behavioral of RISCV_w_BRAMs_tb is
	signal clk_s : std_logic;
	signal reset_s : std_logic;

   signal dread_instr_s : std_logic_vector(31 downto 0);		  -- Port B RAM input data
   signal dread_data_s : std_logic_vector(31 downto 0);		  -- Port B RAM input data

begin

	duv: entity work.RISCV_w_BRAMs(Behavioral)
	port map (
		clk => clk_s,
		reset => reset_s,
		dread_instr => dread_instr_s,
		dread_data => dread_data_s
		);

 clk_proc : process
 begin    
	  clk_s <= '1', '0' after 5 ns;
	  wait for 10 ns;
 end process;

 reset_s <= '0','1' after 50 ns;

end architecture;
