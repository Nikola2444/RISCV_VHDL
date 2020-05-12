library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use work.ram_pkg.all;

entity RISCV_w_BRAMs is
	port (clk : in std_logic;
			reset : in std_logic;
			--Instruction cache
			dread_instr: out std_logic_vector(31 downto 0);
			--Data cache
			dread_data: out std_logic_vector(31 downto 0);
			--Level 2 cache
			dread_l2c: out std_logic_vector(31 downto 0)
			);
end entity;

architecture Behavioral of RISCV_w_BRAMs is

	-- Other signals
		signal ce_s : std_logic;

   -- Instruction cache signals
		signal clk_instr_cache_s : std_logic;
		signal addr_instr_cache_s : std_logic_vector((clogb2(L1_CACHE_SIZE)-1) downto 0);
		signal addr_instr_32_cache_s : std_logic_vector(31 downto 0);
		signal dwrite_instr_contr_s : std_logic_vector(L1C_NUM_COL*L1C_COL_WIDTH-1 downto 0);
		signal dwrite_instr_cache_s : std_logic_vector(L1C_NUM_COL*L1C_COL_WIDTH-1 downto 0);
		signal dread_instr_contr_s : std_logic_vector(L1C_NUM_COL*L1C_COL_WIDTH-1 downto 0);
		signal dread_instr_cache_s : std_logic_vector(L1C_NUM_COL*L1C_COL_WIDTH-1 downto 0);
		signal we_instr_contr_s : std_logic_vector(L1C_NUM_COL-1 downto 0);
		signal we_instr_cache_s : std_logic_vector(L1C_NUM_COL-1 downto 0);
		signal en_instr_cache_s : std_logic;
		signal rst_instr_cache_s : std_logic;
		signal regce_instr_cache_s : std_logic;

	-- Instruction cache tag store singals
		signal din_instr_tag_s : std_logic_vector(L1C_TAG_AWIDTH + L1C_BKK_AWIDTH - 1 downto 0);
		signal dout_instr_tag_s : std_logic_vector(L1C_TAG_AWIDTH + L1C_BKK_AWIDTH - 1 downto 0);
		signal addr_instr_tag_s : std_logic_vector(clogb2(L1C_NB_BLOCKS)-1 downto 0);
		signal en_instr_tag_s : std_logic;
		signal regce_instr_tag_s : std_logic;
		signal clk_instr_tag_s : std_logic;
		signal rst_instr_tag_s : std_logic;
		signal we_instr_tag_s : std_logic;

	-- Data cache signals
		signal clk_data_cache_s : std_logic;
		signal addr_data_cache_s : std_logic_vector((clogb2(L1_CACHE_SIZE)-1) downto 0);
		signal addr_data_32_cache_s : std_logic_vector(31 downto 0);
		signal dwrite_data_contr_s : std_logic_vector(L1C_NUM_COL*L1C_COL_WIDTH-1 downto 0);
		signal dwrite_data_cache_s : std_logic_vector(L1C_NUM_COL*L1C_COL_WIDTH-1 downto 0);
		signal dread_data_contr_s : std_logic_vector(L1C_NUM_COL*L1C_COL_WIDTH-1 downto 0);
		signal dread_data_cache_s : std_logic_vector(L1C_NUM_COL*L1C_COL_WIDTH-1 downto 0); 
		signal we_data_contr_s : std_logic_vector(L1C_NUM_COL-1 downto 0);
		signal we_data_cache_s : std_logic_vector(L1C_NUM_COL-1 downto 0);
		signal en_data_cache_s : std_logic; 
		signal rst_data_cache_s : std_logic; 
		signal regce_data_cache_s : std_logic;

	-- Data cache tag store singals
		signal din_data_tag_s : std_logic_vector(L1C_TAG_AWIDTH + L1C_BKK_AWIDTH - 1 downto 0);
		signal dout_data_tag_s : std_logic_vector(L1C_TAG_AWIDTH + L1C_BKK_AWIDTH - 1 downto 0);
		signal addr_data_tag_s : std_logic_vector(clogb2(L1C_NB_BLOCKS)-1 downto 0);
		signal en_data_tag_s : std_logic;
		signal regce_data_tag_s : std_logic;
		signal clk_data_tag_s : std_logic;
		signal rst_data_tag_s : std_logic;
		signal we_data_tag_s : std_logic;

	-- Level 2 cache signals
		signal clk_l2_cache_s : std_logic;
		signal addr_l2_cache_s : std_logic_vector((clogb2(L2_CACHE_SIZE)-1) downto 0);
		signal dwrite_l2_cache_s : std_logic_vector(L2C_NUM_COL*L2C_COL_WIDTH-1 downto 0);
		signal dread_l2_cache_s : std_logic_vector(L2C_NUM_COL*L2C_COL_WIDTH-1 downto 0);
		signal we_l2_cache_s : std_logic_vector(L2C_NUM_COL-1 downto 0);
		signal en_l2_cache_s : std_logic;
		signal rst_l2_cache_s : std_logic;
		signal regce_l2_cache_s : std_logic;

	-- Level 2 cache tag store singnals
		signal din_l2_tag_s : std_logic_vector(L1C_TAG_AWIDTH + L1C_BKK_AWIDTH - 1 downto 0);
		signal dout_l2_tag_s : std_logic_vector(L1C_TAG_AWIDTH + L1C_BKK_AWIDTH - 1 downto 0);
		signal addr_l2_tag_s : std_logic_vector(clogb2(L1C_NB_BLOCKS)-1 downto 0);
		signal en_l2_tag_s : std_logic;
		signal regce_l2_tag_s : std_logic;
		signal clk_l2_tag_s : std_logic;
		signal rst_l2_tag_s : std_logic;
		signal we_l2_tag_s : std_logic;
begin

	--********** PROCESSOR CORE **************
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




	--********** Cache controller **************
	cc_directly_mapped: entity work.cache_contr_dm(behavioral)
		generic map (
			BLOCK_SIZE => BLOCK_SIZE,
			L1_CACHE_SIZE => L1_CACHE_SIZE,
			L2_CACHE_SIZE => L2_CACHE_SIZE
		)
		port map(
			clk => clk,
			ce_o => ce_s,
			reset => reset,
			-- Instruction cache
			dread_instr_i => dread_instr_contr_s,
			dread_instr_o => dread_instr_cache_s,
			dwrite_instr_i => dwrite_instr_contr_s,
			dwrite_instr_o => dwrite_instr_cache_s,
			addr_instr_i => addr_instr_32_cache_s,
			we_instr_i => we_instr_contr_s,
			we_instr_o => we_instr_cache_s,
			-- Instruction tag store and bookkeeping
			addra_instr_tag_o =>  addr_instr_tag_s,
			dina_instr_tag_o => din_instr_tag_s,
			wea_instr_tag_o => we_instr_tag_s,
			ena_instr_tag_o => en_instr_tag_s,
			douta_instr_tag_i => dout_instr_tag_s,
			-- Data cache
			dread_data_i => dread_data_contr_s,
			dread_data_o => dread_data_cache_s,
			dwrite_data_i => dwrite_data_contr_s,
			dwrite_data_o => dwrite_data_cache_s,
			addr_data_i => addr_data_32_cache_s,
			we_data_i => we_data_contr_s,
			-- Data tag store and bookkeeping
			addra_data_tag_o => addr_data_tag_s,
			dina_data_tag_o => din_data_tag_s,
			wea_data_tag_o => we_data_tag_s,
			ena_data_tag_o => en_data_tag_s,
			douta_data_tag_i => dout_data_tag_s,
			-- Level 2 cache
			dread_l2_i => dread_l2_cache_s,
			dwrite_l2_o => dwrite_l2_cache_s,
			addr_l2_i => addr_l2_cache_s,
			we_l2_o => we_l2_cache_s,
			-- Level 2 tag store and bookkeeping
			addra_l2_tag_o => addr_l2_tag_s,
			dina_l2_tag_o => din_l2_tag_s,
			wea_l2_tag_o => we_l2_tag_s,
			ena_l2_tag_o => en_l2_tag_s,
			douta_l2_tag_i => dout_l2_tag_s
		);


	--********** LEVEL 1 CACHE  **************
	-- INSTRUCTION CACHE
	-- Port A singals
	clk_instr_cache_s <= clk;
	addr_instr_cache_s <= addr_instr_32_cache_s((clogb2(L1_CACHE_SIZE)-1) downto 2);
	we_instr_contr_s <= "0000";
	regce_instr_cache_s <= '0';
	-- Instantiation of instruction cache
	instruction_cache : entity work.BRAM_sp_rf_bw(rtl)
		generic map (
			NB_COL => L1C_NUM_COL,
			COL_WIDTH => L1C_COL_WIDTH,
			RAM_DEPTH => L1C_DEPTH,
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
	-- dummy for synth
	dread_instr <= dread_instr_cache_s;

	-- TAG STORE FOR INSTRUCTION CACHE
	clk_instr_tag_s <= clk;
	rst_instr_tag_s <= reset;
	regce_instr_cache_s <='1';
	--instantiation of tag store
	instruction_tag_store: entity work.ram_sp_ar(rtl)
		generic map (
			RAM_WIDTH => L1C_TAG_AWIDTH + L1C_BKK_AWIDTH,
			RAM_DEPTH => L1C_NB_BLOCKS
		)
		port map(
			addra => addr_instr_tag_s,
			dina => din_instr_tag_s,
			clka => clk_instr_tag_s,
			ena => en_instr_tag_s,
			rsta => rst_instr_tag_s,
			regcea => regce_instr_tag_s,
			douta => dout_instr_tag_s,
			wea => we_instr_tag_s
		);

	-- DATA CACHE
	-- Port A signals
	clk_data_cache_s <= clk;
	addr_data_cache_s <= addr_data_32_cache_s((clogb2(L1_CACHE_SIZE)-1) downto 2);
	rst_data_cache_s <= reset;
	en_data_cache_s <= '1';
	regce_data_cache_s <= '0';
	-- Instantiation of data cache
	data_cache : entity work.BRAM_sp_rf_bw(rtl)
		generic map (
				NB_COL => L1C_NUM_COL,
				COL_WIDTH => L1C_COL_WIDTH,
				RAM_DEPTH => L1C_DEPTH,
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

	-- dummy for synth
	dread_data <= dread_data_cache_s;

	-- TAG STORE FOR DATA CACHE
	clk_data_tag_s <= clk;
	rst_data_tag_s <= reset;
	regce_data_tag_s <= '1';
	-- Instantiation of tag store
	data_tag_store: entity work.ram_sp_ar(rtl)
		generic map (
			RAM_WIDTH => L1C_TAG_AWIDTH + L1C_BKK_AWIDTH,
			RAM_DEPTH => L1C_NB_BLOCKS
		)
		port map(
			addra => addr_data_tag_s,
			dina => din_data_tag_s,
			clka => clk_data_tag_s,
			ena => en_data_tag_s,
			rsta => rst_data_tag_s,
			regcea => regce_data_tag_s,
			douta => dout_data_tag_s,
			wea => we_data_tag_s
		);



	--********** LEVEL 2 CACHE  **************
	-- Port A signals
	clk_l2_cache_s <= clk;
	rst_l2_cache_s <= reset;
	en_l2_cache_s <= '1';
	regce_l2_cache_s <= '0';
	-- Instantiation of level 2 cache
	level_2_cache : entity work.BRAM_sp_rf_bw(rtl)
		generic map (
			NB_COL => L2C_NUM_COL,
			COL_WIDTH => L2C_COL_WIDTH,
			RAM_DEPTH => L2C_DEPTH,
			RAM_PERFORMANCE => "LOW_LATENCY",
			INIT_FILE => "" 
		)
		port map  (
			addra  => addr_l2_cache_s,
			dina   => dwrite_l2_cache_s,
			clk   => clk_l2_cache_s,
			wea    => we_l2_cache_s,
			ena    => en_l2_cache_s,
			rsta   => rst_l2_cache_s,
			regcea => regce_l2_cache_s,
			douta  => dread_l2_cache_s
		);
	--dummy for synth
	dread_l2c <= dread_l2_cache_s;



	clk_l2_tag_s <= clk;
	rst_l2_tag_s <= reset;
	regce_l2_tag_s <= '1';
	-- tag store for Level 2 cache
	level_2_tag_store: entity work.ram_sp_ar(rtl)
		generic map (
			 RAM_WIDTH => L2C_TAG_AWIDTH + L2C_BKK_AWIDTH,
			 RAM_DEPTH => L2C_NB_BLOCKS
		)
		port map(
			addra => addr_l2_tag_s,
			dina => din_l2_tag_s,
			clka => clk_l2_tag_s,
			ena => en_l2_tag_s,
			rsta => rst_l2_tag_s,
			regcea => regce_l2_tag_s,
			douta => dout_l2_tag_s,
			wea => we_l2_tag_s
		);


end architecture;
