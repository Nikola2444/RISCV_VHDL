library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use work.ram_pkg.all;

entity RISCV_w_BRAMs is
	port (clk : in std_logic;
			ce : in std_logic;
			reset : in std_logic);
end entity;

architecture Behavioral of RISCV_w_BRAMs is
   -- Signals
		constant RAM_DEPTH : integer := 1024;
		constant NB_COL : integer := 4;
		constant COL_WIDTH : integer := 8;
   -- Instruction memory signals
        signal addra_instr_s : std_logic_vector((clogb2(RAM_DEPTH)-1) downto 0);     -- Port A Address bus, width determined from RAM_DEPTH
        signal addra_instr_32_s : std_logic_vector(31 downto 0);     -- Port A Address bus, width determined from RAM_DEPTH
        signal addrb_instr_s : std_logic_vector((clogb2(RAM_DEPTH)-1) downto 0);     -- Port B Address bus, width determined from RAM_DEPTH
        signal dina_instr_s : std_logic_vector(NB_COL*COL_WIDTH-1 downto 0);		  -- Port A RAM input data
        signal dinb_instr_s : std_logic_vector(NB_COL*COL_WIDTH-1 downto 0);		  -- Port B RAM input data
        signal wea_instr_s : std_logic_vector(NB_COL-1 downto 0);	  -- Port A Write enable
        signal web_instr_s : std_logic_vector(NB_COL-1 downto 0); 	  -- Port B Write enable
        signal clk_instr_s : std_logic;                       			  -- Port A RAM Enable, for additional power savings, disable port when not in use
        signal ena_instr_s : std_logic;                       			  -- Port A RAM Enable, for additional power savings, disable port when not in use
        signal enb_instr_s : std_logic;                       			  -- Port B RAM Enable, for additional power savings, disable port when not in use
        signal rsta_instr_s : std_logic;               			  -- Port A RAM Enable, for additional power savings, disable port when not in use
        signal rstb_instr_s : std_logic;              			  -- Port A RAM Enable, for additional power savings, disable port when not in use
        signal regcea_instr_s : std_logic;                       			  -- Port A Output register enable
        signal regceb_instr_s : std_logic;                       			  -- Port B Output register enable
        signal douta_instr_s : std_logic_vector(NB_COL*COL_WIDTH-1 downto 0);   --  Port A RAM output data
        signal doutb_instr_s : std_logic_vector(NB_COL*COL_WIDTH-1 downto 0);   	--  Port B RAM output data

   -- Data memory signals
        signal addra_data_s : std_logic_vector((clogb2(RAM_DEPTH)-1) downto 0);     -- Port A Address bus, width determined from RAM_DEPTH
        signal addra_data_32_s : std_logic_vector(31 downto 0);     -- Port A Address bus, width determined from RAM_DEPTH
        signal addrb_data_s : std_logic_vector((clogb2(RAM_DEPTH)-1) downto 0);     -- Port B Address bus, width determined from RAM_DEPTH
        signal dina_data_s : std_logic_vector(NB_COL*COL_WIDTH-1 downto 0);		  -- Port A RAM input data
        signal dinb_data_s : std_logic_vector(NB_COL*COL_WIDTH-1 downto 0);		  -- Port B RAM input data
        signal wea_data_s : std_logic_vector(NB_COL-1 downto 0);	  -- Port A Write enable
        signal clk_data_s : std_logic;                       			  -- Port A RAM Enable, for additional power savings, disable port when not in use
        signal web_data_s : std_logic_vector(NB_COL-1 downto 0); 	  -- Port B Write enable
        signal ena_data_s : std_logic;                       			  -- Port A RAM Enable, for additional power savings, disable port when not in use
        signal enb_data_s : std_logic;                       			  -- Port B RAM Enable, for additional power savings, disable port when not in use
        signal rsta_data_s : std_logic;             			  -- Port A RAM Enable, for additional power savings, disable port when not in use
        signal rstb_data_s : std_logic;             			  -- Port A RAM Enable, for additional power savings, disable port when not in use
        signal regcea_data_s : std_logic;                       			  -- Port A Output register enable
        signal regceb_data_s : std_logic;                       			  -- Port B Output register enable
        signal douta_data_s : std_logic_vector(NB_COL*COL_WIDTH-1 downto 0);   --  Port A RAM output data
        signal doutb_data_s : std_logic_vector(NB_COL*COL_WIDTH-1 downto 0);   	--  Port B RAM output data
begin

   -- Top Moule - RISCV processsor core instance
   TOP_RISCV_1 : entity work.TOP_RISCV
      port map (
         clk => clk,
         ce => ce,
         reset => reset,

         instr_mem_read_i    => douta_instr_s,
         instr_mem_address_o => addra_instr_32_s,
         instr_mem_flush_o   => rsta_instr_s,
         instr_mem_en_o      => ena_instr_s,

         data_mem_we_o      => wea_data_s,
         data_mem_address_o => addra_data_32_s,
         data_mem_read_i    => douta_data_s,
         data_mem_write_o   => dina_data_s);

-- INSTRUCTION CACHE
--Port A singals
clk_instr_s <= clk;
addra_instr_s <= addra_instr_32_s((clogb2(RAM_DEPTH)+1) downto 2);
wea_instr_s <= "0000";
regcea_instr_s <= '0';
--Port B singals
addrb_instr_s <= (others=>'0');
dinb_instr_s <= (others=>'0');
web_instr_s <= (others=>'0');
enb_instr_s <= '0';
rstb_instr_s <= '0';
regceb_instr_s <= '0';
-- Instantiation of instruction memory
instruction_cache : entity work.BRAM_tdp_rf_bw(rtl)
generic map (
		NB_COL => NB_COL,
		COL_WIDTH => COL_WIDTH,
		RAM_DEPTH => RAM_DEPTH,
		RAM_PERFORMANCE => "LOW_LATENCY",
		INIT_FILE => "assembly_code.txt" 
)
port map  (
		addra  => addra_instr_s,
		addrb  => addrb_instr_s,
		dina   => dina_instr_s,
		dinb   => dinb_instr_s,
		clk   => clk_instr_s,
		wea    => wea_instr_s,
		web    => web_instr_s,
		ena    => ena_instr_s,
		enb    => enb_instr_s,
		rsta   => rsta_instr_s,
		rstb   => rstb_instr_s,
		regcea => regcea_instr_s,
		regceb => regceb_instr_s,
		douta  => douta_instr_s,
		doutb  => doutb_instr_s
);

--DATA CACHE
--Port A signals
clk_data_s <= clk;
addra_data_s <= addra_data_32_s((clogb2(RAM_DEPTH)+1) downto 2);
rsta_data_s <= '0';
ena_data_s <= '1';
regcea_data_s <= '0';
--Port B singals
addrb_data_s <= (others=>'0');
dinb_data_s <= (others=>'0');
web_data_s <= (others=>'0');
enb_data_s <= '0';
rstb_data_s <= '0';
regceb_data_s <= '0';
-- Instantiation of data memory
data_cache : entity work.BRAM_tdp_rf_bw(rtl)
generic map (
		NB_COL => NB_COL,
		COL_WIDTH => COL_WIDTH,
		RAM_DEPTH => RAM_DEPTH,
		RAM_PERFORMANCE => "LOW_LATENCY",
		INIT_FILE => "" 
)
port map  (
		addra  => addra_data_s,
		addrb  => addrb_data_s,
		dina   => dina_data_s,
		dinb   => dinb_data_s,
		clk   => clk_data_s,
		wea    => wea_data_s,
		web    => web_data_s,
		ena    => ena_data_s,
		enb    => enb_data_s,
		rsta   => rsta_data_s,
		rstb   => rstb_data_s,
		regcea => regcea_data_s,
		regceb => regceb_data_s,
		douta  => douta_data_s,
		doutb  => doutb_data_s
);
end architecture;
