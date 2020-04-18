library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
--use work.txt_util.all;

entity RISCV_w_BRAMs_tb is
end entity;

architecture Behavioral of RISCV_w_BRAMs_tb is
	signal clk_s : std_logic;
   signal ce_s : std_logic;
	signal reset_s : std_logic;

   signal dinb_instr_s : std_logic_vector(31 downto 0);		  -- Port B RAM input data
   signal doutb_instr_s : std_logic_vector(31 downto 0);		  -- Port B RAM input data
   signal addrb_instr_s : std_logic_vector(9 downto 0);		  -- Port B RAM input data
   signal web_instr_s : std_logic_vector(3 downto 0);		  -- Port B RAM input data

   signal dinb_data_s : std_logic_vector(31 downto 0);		  -- Port B RAM input data
   signal doutb_data_s : std_logic_vector(31 downto 0);		  -- Port B RAM input data
   signal addrb_data_s : std_logic_vector(9 downto 0);		  -- Port B RAM input data
   signal web_data_s : std_logic_vector(3 downto 0);		  -- Port B RAM input data
begin

	duv: entity work.RISCV_w_BRAMs(Behavioral)
	port map (
		clk => clk_s,
		ce => ce_s,
		reset => reset_s,
		dinb_instr => dinb_instr_s,
		doutb_instr => doutb_instr_s,
		addrb_instr => addrb_instr_s,
		web_instr => web_instr_s,
		dinb_data => dinb_data_s,
		doutb_data => doutb_data_s,
		addrb_data => addrb_data_s,
		web_data => web_data_s
		);

 clk_proc : process
 begin    
	  clk_s <= '1', '0' after 5 ns;
	  wait for 10 ns;
 end process;

 ce_s <= '1';
 reset_s <= '0','1' after 50 ns;

 dinb_instr_s <= (others => '0');
 dinb_data_s <= (others => '0');
 addrb_instr_s <= (others => '0');
 addrb_data_s <= (others => '0');
 web_instr_s <= (others => '0');
 web_data_s <= (others => '0');

end architecture;
