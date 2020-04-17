library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use work.txt_util.all;

entity RISCV_w_BRAMs_tb is
end entity;

architecture Behavioral of TOP_RISCV_tb is
	signal clk_s : std_logic;
   signal ce_s : std_logic;
	signal reset_s : std_logic;
begin

	duv: entity RISCV_w_BRAMs(Behavioral)
	port map (
		clk => clk_s,
		ce => ce_s,
		reset => reset_s);

 clk_proc : process
 begin    
	  clk_s <= '1', '0' after 100 ns;
	  wait for 200 ns;
 end process;

 ce_s <= '1';
 reset_s <= '1';

end architecture;
