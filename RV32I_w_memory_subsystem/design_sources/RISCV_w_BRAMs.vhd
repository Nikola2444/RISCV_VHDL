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
			dread_lvl2c: out std_logic_vector(31 downto 0)
			);
end entity;

architecture Behavioral of RISCV_w_BRAMs is

	-- Other signals
		signal ce_s : std_logic;

   -- Instruction cache signals
		signal clk_instr_cache_s : std_logic;
		signal addr_instr_cache_s : std_logic_vector((clogb2(LVL1_CACHE_SIZE)-1) downto 0);
		signal addr_instr_32_cache_s : std_logic_vector(31 downto 0);
		signal dwrite_instr_contr_s : std_logic_vector(LVL1C_NUM_COL*LVL1C_COL_WIDTH-1 downto 0);
		signal dwrite_instr_cache_s : std_logic_vector(LVL1C_NUM_COL*LVL1C_COL_WIDTH-1 downto 0);
		signal dread_instr_contr_s : std_logic_vector(LVL1C_NUM_COL*LVL1C_COL_WIDTH-1 downto 0);
		signal dread_instr_cache_s : std_logic_vector(LVL1C_NUM_COL*LVL1C_COL_WIDTH-1 downto 0);
		signal we_instr_contr_s : std_logic_vector(LVL1C_NUM_COL-1 downto 0);
		signal we_instr_cache_s : std_logic_vector(LVL1C_NUM_COL-1 downto 0);
		signal en_instr_cache_s : std_logic;
		signal rst_instr_cache_s : std_logic;
		signal regce_instr_cache_s : std_logic;

	-- Instruction cache tag store singals
		signal dwrite_instr_tag_s : std_logic_vector(LVL1C_TAG_WIDTH + LVL1C_BKK_WIDTH - 1 downto 0);
		signal dread_instr_tag_s : std_logic_vector(LVL1C_TAG_WIDTH + LVL1C_BKK_WIDTH - 1 downto 0);
		signal addr_instr_tag_s : std_logic_vector(clogb2(LVL1C_NB_BLOCKS)-1 downto 0);
		signal en_instr_tag_s : std_logic;
		signal regce_instr_tag_s : std_logic;
		signal clk_instr_tag_s : std_logic;
		signal rst_instr_tag_s : std_logic;
		signal we_instr_tag_s : std_logic;

	-- Data cache signals
		signal clk_data_cache_s : std_logic;
		signal addr_data_cache_s : std_logic_vector((clogb2(LVL1_CACHE_SIZE)-1) downto 0);
		signal addr_data_32_cache_s : std_logic_vector(31 downto 0);
		signal dwrite_data_contr_s : std_logic_vector(LVL1C_NUM_COL*LVL1C_COL_WIDTH-1 downto 0);
		signal dwrite_data_cache_s : std_logic_vector(LVL1C_NUM_COL*LVL1C_COL_WIDTH-1 downto 0);
		signal dread_data_contr_s : std_logic_vector(LVL1C_NUM_COL*LVL1C_COL_WIDTH-1 downto 0);
		signal dread_data_cache_s : std_logic_vector(LVL1C_NUM_COL*LVL1C_COL_WIDTH-1 downto 0); 
		signal we_data_contr_s : std_logic_vector(LVL1C_NUM_COL-1 downto 0);
		signal we_data_cache_s : std_logic_vector(LVL1C_NUM_COL-1 downto 0);
		signal en_data_cache_s : std_logic; 
		signal rst_data_cache_s : std_logic; 
		signal regce_data_cache_s : std_logic;

	-- Data cache tag store singals
		signal dwrite_data_tag_s : std_logic_vector(LVL1C_TAG_WIDTH + LVL1C_BKK_WIDTH - 1 downto 0);
		signal dread_data_tag_s : std_logic_vector(LVL1C_TAG_WIDTH + LVL1C_BKK_WIDTH - 1 downto 0);
		signal addr_data_tag_s : std_logic_vector(clogb2(LVL1C_NB_BLOCKS)-1 downto 0);
		signal en_data_tag_s : std_logic;
		signal regce_data_tag_s : std_logic;
		signal clk_data_tag_s : std_logic;
		signal rst_data_tag_s : std_logic;
		signal we_data_tag_s : std_logic;

	-- Level 2 cache signals
		signal clk_lvl2_cache_s : std_logic;
		signal addr_lvl2_cache_s : std_logic_vector((clogb2(LVL2_CACHE_SIZE)-1) downto 0);
		signal dwrite_lvl2_cache_s : std_logic_vector(LVL2C_NUM_COL*LVL2C_COL_WIDTH-1 downto 0);
		signal dread_lvl2_cache_s : std_logic_vector(LVL2C_NUM_COL*LVL2C_COL_WIDTH-1 downto 0);
		signal we_lvl2_cache_s : std_logic_vector(LVL2C_NUM_COL-1 downto 0);
		signal en_lvl2_cache_s : std_logic;
		signal rst_lvl2_cache_s : std_logic;
		signal regce_lvl2_cache_s : std_logic;

	-- Level 2 cache tag store singnals
		signal dwrite_lvl2_tag_s : std_logic_vector(LVL1C_TAG_WIDTH + LVL1C_BKK_WIDTH - 1 downto 0);
		signal dread_lvl2_tag_s : std_logic_vector(LVL1C_TAG_WIDTH + LVL1C_BKK_WIDTH - 1 downto 0);
		signal addr_lvl2_tag_s : std_logic_vector(clogb2(LVL1C_NB_BLOCKS)-1 downto 0);
		signal en_lvl2_tag_s : std_logic;
		signal regce_lvl2_tag_s : std_logic;
		signal clk_lvl2_tag_s : std_logic;
		signal rst_lvl2_tag_s : std_logic;
		signal we_lvl2_tag_s : std_logic;
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
			LVL1_CACHE_SIZE => LVL1_CACHE_SIZE,
			LVL2_CACHE_SIZE => LVL2_CACHE_SIZE
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
			addr_instr_tag_o =>  addr_instr_tag_s,
			dwrite_instr_tag_o => dwrite_instr_tag_s,
			we_instr_tag_o => we_instr_tag_s,
			en_instr_tag_o => en_instr_tag_s,
			dread_instr_tag_i => dread_instr_tag_s,
			-- Data cache
			dread_data_i => dread_data_contr_s,
			dread_data_o => dread_data_cache_s,
			dwrite_data_i => dwrite_data_contr_s,
			dwrite_data_o => dwrite_data_cache_s,
			addr_data_i => addr_data_32_cache_s,
			we_data_i => we_data_contr_s,
			-- Data tag store and bookkeeping
			addr_data_tag_o => addr_data_tag_s,
			dwrite_data_tag_o => dwrite_data_tag_s,
			we_data_tag_o => we_data_tag_s,
			en_data_tag_o => en_data_tag_s,
			dread_data_tag_i => dread_data_tag_s,
			-- Level 2 cache
			dread_lvl2_i => dread_lvl2_cache_s,
			dwrite_lvl2_o => dwrite_lvl2_cache_s,
			addr_lvl2_o => addr_lvl2_cache_s,
			we_lvl2_o => we_lvl2_cache_s,
			-- Level 2 tag store and bookkeeping
			addr_lvl2_tag_o => addr_lvl2_tag_s,
			dwrite_lvl2_tag_o => dwrite_lvl2_tag_s,
			we_lvl2_tag_o => we_lvl2_tag_s,
			en_lvl2_tag_o => en_lvl2_tag_s,
			dread_lvl2_tag_i => dread_lvl2_tag_s
		);


	--********** LEVEL 1 CACHE  **************
	-- INSTRUCTION CACHE
	-- Port A singals
	clk_instr_cache_s <= clk;
	-- TODO double check this address logic, change if unaligned accesses are implemented
	-- TODO CC shouldn't send 32 bit adress if it will be cut here, send the minimum bits needed
	-- TODO decide if cutting 2 LSB bits is done here or in cache controller
	addr_instr_cache_s <= addr_instr_32_cache_s((clogb2(LVL1_CACHE_SIZE)-1) downto 2);
	we_instr_contr_s <= "0000";
	regce_instr_cache_s <= '0';
	-- Instantiation of instruction cache
	instruction_cache : entity work.BRAM_sp_rf_bw(rtl)
		generic map (
			NB_COL => LVL1C_NUM_COL,
			COL_WIDTH => LVL1C_COL_WIDTH,
			RAM_DEPTH => LVL1C_DEPTH,
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
			RAM_WIDTH => LVL1C_TAG_WIDTH + LVL1C_BKK_WIDTH,
			RAM_DEPTH => LVL1C_NB_BLOCKS
		)
		port map(
			addra => addr_instr_tag_s,
			dina => dwrite_instr_tag_s,
			clka => clk_instr_tag_s,
			ena => en_instr_tag_s,
			rsta => rst_instr_tag_s,
			regcea => regce_instr_tag_s,
			douta => dread_instr_tag_s,
			wea => we_instr_tag_s
		);

	-- DATA CACHE
	-- Port A signals
	clk_data_cache_s <= clk;
	-- TODO double check this address logic!, change if unaligned accesses are implemented
	-- TODO CC shouldn't send 32 bit adress if it will be cut here, send the minimum bits needed
	-- TODO decide if cutting 2 LSB bits is done here or in cache controller
	addr_data_cache_s <= addr_data_32_cache_s((clogb2(LVL1_CACHE_SIZE)-1) downto 2);
	rst_data_cache_s <= reset;
	en_data_cache_s <= '1';
	regce_data_cache_s <= '0';
	-- Instantiation of data cache
	data_cache : entity work.BRAM_sp_rf_bw(rtl)
		generic map (
				NB_COL => LVL1C_NUM_COL,
				COL_WIDTH => LVL1C_COL_WIDTH,
				RAM_DEPTH => LVL1C_DEPTH,
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
			RAM_WIDTH => LVL1C_TAG_WIDTH + LVL1C_BKK_WIDTH,
			RAM_DEPTH => LVL1C_NB_BLOCKS
		)
		port map(
			addra => addr_data_tag_s,
			dina => dwrite_data_tag_s,
			clka => clk_data_tag_s,
			ena => en_data_tag_s,
			rsta => rst_data_tag_s,
			regcea => regce_data_tag_s,
			douta => dread_data_tag_s,
			wea => we_data_tag_s
		);



	--********** LEVEL 2 CACHE  **************
	-- Port A signals
	clk_lvl2_cache_s <= clk;
	rst_lvl2_cache_s <= reset;
	en_lvl2_cache_s <= '1';
	regce_lvl2_cache_s <= '0';
	-- TODO in this type of bram, 2 LSB bits are removed, implement this here or in cache controller!!!
	-- Instantiation of level 2 cache
	level_2_cache : entity work.BRAM_sp_rf_bw(rtl)
		generic map (
			NB_COL => LVL2C_NUM_COL,
			COL_WIDTH => LVL2C_COL_WIDTH,
			RAM_DEPTH => LVL2C_DEPTH,
			RAM_PERFORMANCE => "LOW_LATENCY",
			INIT_FILE => "" 
		)
		port map  (
			addra  => addr_lvl2_cache_s,
			dina   => dwrite_lvl2_cache_s,
			clk   => clk_lvl2_cache_s,
			wea    => we_lvl2_cache_s,
			ena    => en_lvl2_cache_s,
			rsta   => rst_lvl2_cache_s,
			regcea => regce_lvl2_cache_s,
			douta  => dread_lvl2_cache_s
		);
	--dummy for synth
	dread_lvl2c <= dread_lvl2_cache_s;



	clk_lvl2_tag_s <= clk;
	rst_lvl2_tag_s <= reset;
	regce_lvl2_tag_s <= '1';
	-- tag store for Level 2 cache
	level_2_tag_store: entity work.ram_sp_ar(rtl)
		generic map (
			 RAM_WIDTH => LVL2C_TAG_WIDTH + LVL2C_BKK_WIDTH,
			 RAM_DEPTH => LVL2C_NB_BLOCKS
		)
		port map(
			addra => addr_lvl2_tag_s,
			dina => dwrite_lvl2_tag_s,
			clka => clk_lvl2_tag_s,
			ena => en_lvl2_tag_s,
			rsta => rst_lvl2_tag_s,
			regcea => regce_lvl2_tag_s,
			douta => dread_lvl2_tag_s,
			wea => we_lvl2_tag_s
		);


end architecture;
