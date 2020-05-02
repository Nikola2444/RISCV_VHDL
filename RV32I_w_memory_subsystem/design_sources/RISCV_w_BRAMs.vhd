library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use work.ram_pkg.all;

entity RISCV_w_BRAMs is
	port (clk : in std_logic;
			reset : in std_logic;
			--Instruction memory
			dread_instr: out std_logic_vector(31 downto 0);
			--Data memory
			dread_data: out std_logic_vector(31 downto 0)
			);
end entity;

architecture Behavioral of RISCV_w_BRAMs is
   -- Signals
		constant RAM_DEPTH : integer := 1024;
		constant NB_COL : integer := 4;
		constant COL_WIDTH : integer := 8;

	-- Other signals
		signal ce_s : std_logic;

   -- Instruction memory signals
		signal clk_instr_cache_s : std_logic;                       			  -- Port A RAM Enable, for additional power savings, disable port when not in use
		signal addr_instr_cache_s : std_logic_vector((clogb2(RAM_DEPTH)-1) downto 0);     -- Port A Address bus, width determined from RAM_DEPTH
		signal addr_instr_32_cache_s : std_logic_vector(31 downto 0);     -- Port A Address bus, width determined from RAM_DEPTH
		signal dwrite_instr_contr_s : std_logic_vector(NB_COL*COL_WIDTH-1 downto 0);		  -- Port A RAM input data
		signal dwrite_instr_cache_s : std_logic_vector(NB_COL*COL_WIDTH-1 downto 0);		  -- Port A RAM input data
		signal dread_instr_contr_s : std_logic_vector(NB_COL*COL_WIDTH-1 downto 0);   --  Port A RAM output data
		signal dread_instr_cache_s : std_logic_vector(NB_COL*COL_WIDTH-1 downto 0);   --  Port A RAM output data
		signal we_instr_contr_s : std_logic_vector(NB_COL-1 downto 0);	  -- Port A Write enable
		signal we_instr_cache_s : std_logic_vector(NB_COL-1 downto 0);	  -- Port A Write enable
		signal en_instr_cache_s : std_logic;                       			  -- Port A RAM Enable, for additional power savings, disable port when not in use
		signal rst_instr_cache_s : std_logic;               			  -- Port A RAM Enable, for additional power savings, disable port when not in use
		signal regce_instr_cache_s : std_logic;                       			  -- Port A Output register enable

	-- Data memory signals
		signal clk_data_cache_s : std_logic;                       			  -- Port A RAM Enable, for additional power savings, disable port when not in use
		signal addr_data_cache_s : std_logic_vector((clogb2(RAM_DEPTH)-1) downto 0);     -- Port A Address bus, width determined from RAM_DEPTH
		signal addr_data_32_cache_s : std_logic_vector(31 downto 0);     -- Port A Address bus, width determined from RAM_DEPTH
		signal dwrite_data_contr_s : std_logic_vector(NB_COL*COL_WIDTH-1 downto 0);		  -- Port A RAM input data
		signal dwrite_data_cache_s : std_logic_vector(NB_COL*COL_WIDTH-1 downto 0);		  -- Port A RAM input data
		signal dread_data_contr_s : std_logic_vector(NB_COL*COL_WIDTH-1 downto 0);   --  Port A RAM output data
		signal dread_data_cache_s : std_logic_vector(NB_COL*COL_WIDTH-1 downto 0);   --  Port A RAM output data
		signal we_data_contr_s : std_logic_vector(NB_COL-1 downto 0);	  -- Port A Write enable
		signal we_data_cache_s : std_logic_vector(NB_COL-1 downto 0);	  -- Port A Write enable
		signal en_data_cache_s : std_logic;                       			  -- Port A RAM Enable, for additional power savings, disable port when not in use
		signal rst_data_cache_s : std_logic;             			  -- Port A RAM Enable, for additional power savings, disable port when not in use
		signal regce_data_cache_s : std_logic;                       			  -- Port A Output register enable
begin

   -- Top Moule - RISCV processsor core instance
   TOP_RISCV_1 : entity work.TOP_RISCV
      port map (
         clk => clk,
         ce => ce_s,
         reset => reset,

         instr_mem_read_i    => dread_instr_contr_s,
         instr_mem_address_o => addr_instr_32_cache_s,
         instr_mem_flush_o   => rst_instr_cache_s,
         instr_mem_en_o      => en_instr_cache_s,

         data_mem_we_o      => we_data_contr_s,
         data_mem_address_o => addr_data_32_cache_s,
         data_mem_read_i    => dread_data_contr_s,
         data_mem_write_o   => dwrite_data_contr_s);




cc_directly_mapped: entity work.cache_contr_dm(behavioral)
	generic map (
		BLOCK_WIDTH => 3,
		CACHE_WIDTH => 8
	)
	port map(
		clk => clk,
		ce_o => ce_s,
		reset => reset,
		-- Instruction memory
		dread_instr_i => dread_instr_contr_s,
		dread_instr_o => dread_instr_cache_s,
		dwrite_instr_i => dwrite_instr_contr_s,
		dwrite_instr_o => dwrite_instr_cache_s,
		addr_instr_i => addr_instr_32_cache_s,
		we_instr_i => we_instr_contr_s,
		we_instr_o => we_instr_cache_s,
		-- Data memory
		-- Instruction memory
		dread_data_i => dread_data_contr_s,
		dread_data_o => dread_data_cache_s,
		dwrite_data_i => dwrite_data_contr_s,
		dwrite_data_o => dwrite_data_cache_s,
		addr_data_i => addr_data_32_cache_s,
		we_data_i => we_data_contr_s,
		we_data_o => we_data_cache_s
	);


-- INSTRUCTION CACHE
--Port A singals
clk_instr_cache_s <= clk;
addr_instr_cache_s <= addr_instr_32_cache_s((clogb2(RAM_DEPTH)+1) downto 2);
we_instr_contr_s <= "0000";
regce_instr_cache_s <= '0';
-- Instantiation of instruction memory
instruction_cache : entity work.BRAM_sp_rf_bw(rtl)
	generic map (
			NB_COL => NB_COL,
			COL_WIDTH => COL_WIDTH,
			RAM_DEPTH => RAM_DEPTH,
			RAM_PERFORMANCE => "LOW_LATENCY",
			INIT_FILE => "assembly_code.txt" 
	)
	port map  (
			addra  => addr_instr_cache_s,
			dina   => dwrite_instr_cache_s,
			clk   => clk_instr_cache_s,
			wea    => we_instr_cache_s,
			ena    => en_instr_cache_s,
			rsta   => rst_instr_cache_s,
			regcea => regce_instr_cache_s,
			douta  => dread_instr_cache_s
	);

--dummy for synth
dread_instr <= dread_instr_cache_s;

--DATA CACHE
--Port A signals
clk_data_cache_s <= clk;
addr_data_cache_s <= addr_data_32_cache_s((clogb2(RAM_DEPTH)+1) downto 2);
rst_data_cache_s <= '0';
en_data_cache_s <= '1';
regce_data_cache_s <= '0';
-- Instantiation of data memory

data_cache : entity work.BRAM_sp_rf_bw(rtl)
generic map (
		NB_COL => NB_COL,
		COL_WIDTH => COL_WIDTH,
		RAM_DEPTH => RAM_DEPTH,
		RAM_PERFORMANCE => "LOW_LATENCY",
		INIT_FILE => "" 
)
port map  (
		addra  => addr_data_cache_s,
		dina   => dwrite_data_cache_s,
		clk   => clk_data_cache_s,
		wea    => we_data_cache_s,
		ena    => en_data_cache_s,
		rsta   => rst_data_cache_s,
		regcea => regce_data_cache_s,
		douta  => dread_data_cache_s
);

--dummy for synth
dread_data <= dread_data_cache_s;
end architecture;
