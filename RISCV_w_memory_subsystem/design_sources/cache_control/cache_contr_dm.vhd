library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use work.cache_pkg.all;

entity cache_contr_dm is
generic (PHY_ADDR_SPACE : natural := 512*1024*1024; -- 512 MB
			BLOCK_SIZE : natural := 64;
			LVL1_CACHE_SIZE : natural := 1048;
			LVL2_CACHE_SIZE : natural := 4096);
	port (clk : in std_logic;
			reset : in std_logic;
			-- controller drives ce for RISC
			data_ready_o : out std_logic;
			instr_ready_o : out std_logic;
			-- NOTE Just for test bench, to simulate real memory
			addr_phy_o 			: out std_logic_vector(clogb2(PHY_ADDR_WIDTH)-1 downto 0);
			dread_phy_i 		: in std_logic_vector(31 downto 0);
			dwrite_phy_o		: out std_logic_vector(31 downto 0);
         we_phy_o				: out std_logic_vector(3 downto 0);
			-- Level 1 caches
			-- Instruction cache
			rst_instr_cache_i : in std_logic;
			en_instr_cache_i  : in std_logic;
			addr_instr_i 		: in std_logic_vector(clogb2(PHY_ADDR_WIDTH)-1 downto 0);
			dread_instr_o 		: out std_logic_vector(31 downto 0);
			-- Data cache
			addr_data_i			: in std_logic_vector(clogb2(PHY_ADDR_WIDTH)-1 downto 0);
			dread_data_o 		: out std_logic_vector(31 downto 0);
			dwrite_data_i		: in std_logic_vector(31 downto 0);
         we_data_i			: in std_logic_vector(3 downto 0);
         re_data_i			: in std_logic
			);
end entity;

architecture Behavioral of cache_contr_dm is

	-- DERIVE 2nd ORDER CONSTANTS
	constant PHY_ADDR_WIDTH : integer := clogb2(PHY_ADDR_SPACE);
	constant BLOCK_ADDR_WIDTH : integer := clogb2(BLOCK_SIZE);
	constant LVL1C_ADDR_WIDTH : integer := clogb2(LVL1_CACHE_SIZE);
	constant LVL1C_INDEX_WIDTH : integer := LVL1C_ADDR_WIDTH - BLOCK_ADDR_WIDTH;
	constant LVL1C_TAG_WIDTH : integer := PHY_ADDR_WIDTH - LVL1C_ADDR_WIDTH;
	constant LVL1DC_BKK_WIDTH : integer := 2;
	constant LVL1IC_BKK_WIDTH : integer := 2;
	constant LVL2C_ADDR_WIDTH : integer := clogb2(LVL2_CACHE_SIZE);
	constant LVL2C_INDEX_WIDTH : integer := LVL2C_ADDR_WIDTH - BLOCK_ADDR_WIDTH;
	constant LVL2C_TAG_WIDTH : integer := PHY_ADDR_WIDTH - LVL2C_ADDR_WIDTH;
	constant LVL2C_BKK_WIDTH : integer := 2;


	-- SIGNALS FOR INTERACTION WITH RAMS
	--*******************************************************************************************
	-- Level 1 cache signals


	-- Instruction cache signals
	signal addra_instr_cache_s : std_logic_vector((clogb2(LVL1_CACHE_SIZE)-1) downto 0);
	signal dwritea_instr_cache_s : std_logic_vector(LVL1C_NUM_COL*LVL1C_COL_WIDTH-1 downto 0);
	signal dreada_instr_cache_s : std_logic_vector(LVL1C_NUM_COL*LVL1C_COL_WIDTH-1 downto 0);
	signal wea_instr_cache_s : std_logic_vector(LVL1C_NUM_COL-1 downto 0);
	signal ena_instr_cache_s : std_logic;
	signal rsta_instr_cache_s : std_logic;
	signal regcea_instr_cache_s : std_logic;

	-- Instruction cache tag store singals
	-- port A
	signal dwritea_instr_tag_s : std_logic_vector(LVL1C_TAG_WIDTH + LVL1IC_BKK_WIDTH - 1 downto 0);
	signal dreada_instr_tag_s : std_logic_vector(LVL1C_TAG_WIDTH + LVL1IC_BKK_WIDTH - 1 downto 0);
	signal addra_instr_tag_s : std_logic_vector(clogb2(LVL1C_NB_BLOCKS)-1 downto 0);
	signal ena_instr_tag_s : std_logic;
	signal wea_instr_tag_s : std_logic;
	-- port B TODO left here if needed
	--signal dwriteb_instr_tag_s : std_logic_vector(LVL1C_TAG_WIDTH + LVL1IC_BKK_WIDTH - 1 downto 0);
	--signal dreadb_instr_tag_s : std_logic_vector(LVL1C_TAG_WIDTH + LVL1IC_BKK_WIDTH - 1 downto 0);
	--signal addrb_instr_tag_s : std_logic_vector(clogb2(LVL1C_NB_BLOCKS)-1 downto 0);
	--signal enb_instr_tag_s : std_logic;
	--signal web_instr_tag_s : std_logic;


	-- Data cache signals
	signal clk_data_cache_s : std_logic;
	signal addra_data_cache_s : std_logic_vector((clogb2(LVL1_CACHE_SIZE)-1) downto 0);
	signal dwritea_data_cache_s : std_logic_vector(LVL1C_NUM_COL*LVL1C_COL_WIDTH-1 downto 0);
	signal dreada_data_cache_s : std_logic_vector(LVL1C_NUM_COL*LVL1C_COL_WIDTH-1 downto 0); 
	signal wea_data_cache_s : std_logic_vector(LVL1C_NUM_COL-1 downto 0);
	signal ena_data_cache_s : std_logic; 
	signal rsta_data_cache_s : std_logic; 
	signal regcea_data_cache_s : std_logic;

	-- Data cache tag store singals
	-- port A
	signal dwritea_data_tag_s : std_logic_vector(LVL1C_TAG_WIDTH + LVL1DC_BKK_WIDTH - 1 downto 0);
	signal dreada_data_tag_s : std_logic_vector(LVL1C_TAG_WIDTH + LVL1DC_BKK_WIDTH - 1 downto 0);
	signal addra_data_tag_s : std_logic_vector(clogb2(LVL1C_NB_BLOCKS)-1 downto 0);
	signal ena_data_tag_s : std_logic;
	signal regcea_data_tag_s : std_logic;
	signal rsta_data_tag_s : std_logic;
	signal wea_data_tag_s : std_logic;
	-- port B
	--signal dwriteb_data_tag_s : std_logic_vector(LVL1C_TAG_WIDTH + LVL1DC_BKK_WIDTH - 1 downto 0);
	--signal dreadb_data_tag_s : std_logic_vector(LVL1C_TAG_WIDTH + LVL1DC_BKK_WIDTH - 1 downto 0);
	--signal addrb_data_tag_s : std_logic_vector(clogb2(LVL1C_NB_BLOCKS)-1 downto 0);
	--signal enb_data_tag_s : std_logic;
	--signal regceb_data_tag_s : std_logic;
	--signal rstb_data_tag_s : std_logic;
	--signal web_data_tag_s : std_logic;


	-- Level 2 cache signals
	-- port A
	signal addra_lvl2_cache_s : std_logic_vector((clogb2(LVL2_CACHE_SIZE)-1) downto 0);
	signal dwritea_lvl2_cache_s : std_logic_vector(LVL2C_NUM_COL*LVL2C_COL_WIDTH-1 downto 0);
	signal dreada_lvl2_cache_s : std_logic_vector(LVL2C_NUM_COL*LVL2C_COL_WIDTH-1 downto 0);
	signal wea_lvl2_cache_s : std_logic_vector(LVL2C_NUM_COL-1 downto 0);
	signal ena_lvl2_cache_s : std_logic;
	signal rsta_lvl2_cache_s : std_logic;
	signal regcea_lvl2_cache_s : std_logic;
	-- port B
	signal addrb_lvl2_cache_s : std_logic_vector((clogb2(LVL2_CACHE_SIZE)-1) downto 0);
	signal dwriteb_lvl2_cache_s : std_logic_vector(LVL2C_NUM_COL*LVL2C_COL_WIDTH-1 downto 0);
	signal dreadb_lvl2_cache_s : std_logic_vector(LVL2C_NUM_COL*LVL2C_COL_WIDTH-1 downto 0);
	signal web_lvl2_cache_s : std_logic_vector(LVL2C_NUM_COL-1 downto 0);
	signal enb_lvl2_cache_s : std_logic;
	signal rstb_lvl2_cache_s : std_logic;
	signal regceb_lvl2_cache_s : std_logic;

	-- Level 2 cache tag store singnals
	-- port A
	signal dwritea_lvl2_tag_s : std_logic_vector(LVL2C_TAG_WIDTH + LVL2C_BKK_WIDTH - 1 downto 0);
	signal dreada_lvl2_tag_s : std_logic_vector(LVL2C_TAG_WIDTH + LVL2C_BKK_WIDTH - 1 downto 0);
	signal addra_lvl2_tag_s : std_logic_vector(clogb2(LVL2C_NB_BLOCKS)-1 downto 0);
	signal ena_lvl2_tag_s : std_logic;
	signal rsta_lvl2_tag_s : std_logic;
	signal wea_lvl2_tag_s : std_logic;
	-- port B
	signal dwriteb_lvl2_tag_s : std_logic_vector(LVL2C_TAG_WIDTH + LVL2C_BKK_WIDTH - 1 downto 0);
	signal dreadb_lvl2_tag_s : std_logic_vector(LVL2C_TAG_WIDTH + LVL2C_BKK_WIDTH - 1 downto 0);
	signal addrb_lvl2_tag_s : std_logic_vector(clogb2(LVL2C_NB_BLOCKS)-1 downto 0);
	signal enb_lvl2_tag_s : std_logic;
	signal rstb_lvl2_tag_s : std_logic;
	signal web_lvl2_tag_s : std_logic;
--*******************************************************************************************


	-- SIGNALS FOR SEPARATING INPUT PORTS INTO FIELDS
	-- 'tag', 'index', 'byte in block' and 'tag store address' fields for data cache
	signal lvl1d_c_tag_s : std_logic_vector(LVL1C_TAG_WIDTH-1 downto 0);
	signal lvl1d_c_idx_s : std_logic_vector(LVL1C_INDEX_WIDTH-1 downto 0);
	signal lvl1d_c_bib_s : std_logic_vector(BLOCK_ADDR_WIDTH-1 downto 0);
	signal lvl1d_c_addr_s : std_logic_vector(LVL1C_ADDR_WIDTH-1 downto 0);
	-- 'tag' and 'bookkeeping bits: MSB - valid, LSB -dirty' fields from data tag store
	signal lvl1da_ts_tag_s : std_logic_vector(LVL1C_TAG_WIDTH-1 downto 0);
	signal lvl1da_ts_bkk_s : std_logic_vector(LVL1DC_BKK_WIDTH-1 downto 0);
	--signal lvl1db_ts_tag_s : std_logic_vector(LVL1C_TAG_WIDTH-1 downto 0);
	--signal lvl1db_ts_bkk_s : std_logic_vector(LVL1DC_BKK_WIDTH-1 downto 0);
	-- 'tag', 'index', 'byte in block' and 'tag store address' fields for instruction cache
	signal lvl1i_c_tag_s : std_logic_vector(LVL1C_TAG_WIDTH-1 downto 0);
	signal lvl1i_c_idx_s : std_logic_vector(LVL1C_INDEX_WIDTH-1 downto 0);
	signal lvl1i_c_bib_s : std_logic_vector(BLOCK_ADDR_WIDTH-1 downto 0);
	signal lvl1i_c_addr_s : std_logic_vector(LVL1C_ADDR_WIDTH-1 downto 0);
	-- 'tag' and 'bookkeeping bits: MSB - valid, LSB -dirty' fields from instruction tag store
	signal lvl1ia_ts_tag_s : std_logic_vector(LVL1C_TAG_WIDTH-1 downto 0);
	signal lvl1ia_ts_bkk_s : std_logic_vector(LVL1IC_BKK_WIDTH-1 downto 0);
	--signal lvl1ib_ts_tag_s : std_logic_vector(LVL1C_TAG_WIDTH-1 downto 0);
	--signal lvl1ib_ts_bkk_s : std_logic_vector(LVL1IC_BKK_WIDTH-1 downto 0);
	-- TODO check if these will be used, or signal values will be derived directly from some other signal
	-- 'tag', 'index', 'byte in block' and 'tag store address' fields for levelvl2 cache
	signal lvl2a_c_tag_s : std_logic_vector(LVL2C_TAG_WIDTH-1 downto 0);
	signal lvl2a_c_idx_s : std_logic_vector(LVL2C_INDEX_WIDTH-1 downto 0);
	signal lvl2a_c_bib_s : std_logic_vector(BLOCK_ADDR_WIDTH-1 downto 0);
	signal lvl2a_c_addr_s : std_logic_vector(LVL2C_ADDR_WIDTH-1 downto 0);
	-- 'tag', 'index', 'byte in block' and 'tag store address' fields for levelvl2 cache
	signal lvl2b_c_tag_s : std_logic_vector(LVL2C_TAG_WIDTH-1 downto 0);
	signal lvl2b_c_idx_s : std_logic_vector(LVL2C_INDEX_WIDTH-1 downto 0);
	signal lvl2b_c_bib_s : std_logic_vector(BLOCK_ADDR_WIDTH-1 downto 0);
	signal lvl2b_c_addr_s : std_logic_vector(LVL2C_ADDR_WIDTH-1 downto 0);
	-- 'tag' and 'bookkeeping bits: MSB - dirty, LSB - valid' fields from level 2 tag store
	signal lvl2a_ts_tag_s : std_logic_vector(LVL2C_TAG_WIDTH-1 downto 0);
	signal lvl2a_ts_bkk_s : std_logic_vector(LVL2C_BKK_WIDTH-1 downto 0);
	-- 'tag' and 'bookkeeping bits: MSB - dirty, LSB - valid' fields from level 2 tag store
	signal lvl2b_ts_tag_s : std_logic_vector(LVL2C_TAG_WIDTH-1 downto 0);
	signal lvl2b_ts_bkk_s : std_logic_vector(LVL2C_BKK_WIDTH-1 downto 0);


	-- SIGNALS FOR COMPARING TAG VALUES
	signal lvl1ii_tag_cmp_s  : std_logic; -- incoming instruction address VS instruction tag store (hit in instruction cache)
	--signal lvl1id_tag_cmp_s  : std_logic; -- incoming instruction address VS data tag store (check for duplicate block in data)
	signal lvl1dd_tag_cmp_s  : std_logic; -- incoming data address VS data tag store (hit in data cache)
	--signal lvl1di_tag_cmp_s  : std_logic; -- incoming data address VS instruction tag store (check for duplicate in instr)
	signal lvl2a_tag_cmp_s  : std_logic; -- incoming address from missed lvl1 i/d cache VS lvl2 tag store
	signal lvl2b_tag_cmp_s  : std_logic; -- interconnect
	-- SIGNALS TO INDICATE CACHE HITS/MISSES
	signal lvl1d_c_hit_s  : std_logic; -- hit in data cache
	--signal lvl1d_c_dup_s  : std_logic; -- addressing block in data cache that has duplicate in instruction cache
	signal lvl1i_c_hit_s  : std_logic; -- hit in instruction cache
	--signal lvl1i_c_dup_s  : std_logic; -- addressing block in instruction cache that has duplicate in data cache
	signal lvl2a_c_hit_s  : std_logic; -- hit in lvl 2 cache
	signal lvl2b_c_hit_s  : std_logic; -- hit in lvl 2 cache


	-- Cache controler state
	type cc_state is (idle, check_lvl2_isntr, check_lvl2_data, fetch_instr, fetch_data, flush_data);
	-- cc -  cache controller fsm
	signal cc_state_reg, cc_state_next: cc_state;
	-- cc -  cache controller counter
	signal cc_counter_reg, cc_counter_incr, cc_counter_next: std_logic_vector(BLOCK_ADDR_WIDTH-3 downto 0);
	constant counter_max : std_logic_vector(BLOCK_ADDR_WIDTH-3 downto 0) := (others =>'1');


begin


	-- Separate input ports into fields for easier menagment
	-- From data cache
	lvl1d_c_tag_s <= addr_data_i(PHY_ADDR_WIDTH-1 downto LVL1C_ADDR_WIDTH);
	lvl1d_c_idx_s <= addr_data_i(LVL1C_ADDR_WIDTH-1 downto BLOCK_ADDR_WIDTH);
	lvl1d_c_bib_s <= addr_data_i(BLOCK_ADDR_WIDTH-1 downto 0);
	lvl1d_c_addr_s <= addr_data_i(LVL1C_ADDR_WIDTH-1 downto 0);
	-- From instruction cache 
	lvl1i_c_tag_s <= addr_instr_i(PHY_ADDR_WIDTH-1 downto LVL1C_ADDR_WIDTH);
	lvl1i_c_idx_s <= addr_instr_i(LVL1C_ADDR_WIDTH-1 downto BLOCK_ADDR_WIDTH);
	lvl1i_c_bib_s <= addr_instr_i(BLOCK_ADDR_WIDTH-1 downto 0);
	lvl1i_c_addr_s <= addr_instr_i(LVL1C_ADDR_WIDTH-1 downto 0);
	-- TODO this will be controlled by FSM
	-- From level1
	lvl2ia_c_tag_s <= addr_instr_i(PHY_ADDR_WIDTH-1 downto LVL2C_ADDR_WIDTH);
	lvl2ia_c_idx_s <= addr_instr_i(LVL2C_ADDR_WIDTH-1 downto BLOCK_ADDR_WIDTH);
	lvl2ia_c_bib_s <= addr_instr_i(BLOCK_ADDR_WIDTH-1 downto 0);
	lvl2ia_c_addr_s <= addr_instr_i(LVL2C_ADDR_WIDTH-1 downto 0);
	lvl2da_c_tag_s <= addr_data_i(PHY_ADDR_WIDTH-1 downto LVL2C_ADDR_WIDTH);
	lvl2da_c_idx_s <= addr_data_i(LVL2C_ADDR_WIDTH-1 downto BLOCK_ADDR_WIDTH);
	lvl2da_c_bib_s <= addr_data_i(BLOCK_ADDR_WIDTH-1 downto 0);
	lvl2da_c_addr_s <= addr_data_i(LVL2C_ADDR_WIDTH-1 downto 0);
	-- TODO this will be controlled by interprocessor module
	--lvl2b_c_tag_s <= addr_instr_i(PHY_ADDR_WIDTH-1 downto LVL2C_ADDR_WIDTH);
	--lvl2b_c_idx_s <= addr_instr_i(LVL2C_ADDR_WIDTH-1 downto BLOCK_ADDR_WIDTH);
	--lvl2b_c_bib_s <= addr_instr_i(BLOCK_ADDR_WIDTH-1 downto 0);
	--lvl2b_c_addr_s <= addr_instr_i(LVL2C_ADDR_WIDTH-1 downto 0);

	-- Forward address and get tag + bookkeeping bits from tag store
	-- Data tag store port A - data address
	addra_data_tag_s <= lvl1d_c_idx_s;
	lvl1da_ts_tag_s <= dreada_data_tag_s(LVL1C_TAG_WIDTH-1 downto 0);
	lvl1da_ts_bkk_s <= dreada_data_tag_s(LVL1C_TAG_WIDTH+LVL1DC_BKK_WIDTH-1 downto LVL1C_TAG_WIDTH);
	-- NOTE uncoment port B if there is a switch to dual port for tag store
	-- Data tag store port B - instruction address 
	--addrb_data_tag_s <= lvl1i_c_idx_s;
	--lvl1db_ts_tag_s <= dreada_instr_tag_s(LVL1C_TAG_WIDTH-1 downto 0);
	--lvl1db_ts_bkk_s <= dreada_instr_tag_s(LVL1C_TAG_WIDTH+LVL1IC_BKK_WIDTH-1 downto LVL1C_TAG_WIDTH);

	-- Instruction tag store port A - instruction address
	addra_instr_tag_s <= lvl1i_c_idx_s;
	lvl1ia_ts_tag_s <= dreada_instr_tag_s(LVL1C_TAG_WIDTH-1 downto 0);
	lvl1ia_ts_bkk_s <= dreada_instr_tag_s(LVL1C_TAG_WIDTH+LVL1IC_BKK_WIDTH-1 downto LVL1C_TAG_WIDTH);
	-- NOTE uncoment port B if there is a switch to dual port for tag store
	-- Instruction tag store port B  - data address
	--addrb_instr_tag_s <= lvl1d_c_idx_s;
	--lvl1ib_ts_tag_s <= dread_data_tag_s(LVL1C_TAG_WIDTH-1 downto 0);
	--lvl1ib_ts_bkk_s <= dread_data_tag_s(LVL1C_TAG_WIDTH+LVL1DC_BKK_WIDTH-1 downto LVL1C_TAG_WIDTH);

	-- lvl2 tag store, for LVL1
	--addra_lvl2_tag_s <= lvl2a_c_idx_s; -- TODO set either data or instruction cache address in FSM  (the one that missed)
	lvl2a_ts_tag_s <= dreada_lvl2_tag_s(LVL2C_TAG_WIDTH-1 downto 0);
	lvl2a_ts_bkk_s <= dreada_lvl2_tag_s(LVL2C_TAG_WIDTH+LVL2C_BKK_WIDTH-1 downto LVL2C_TAG_WIDTH);

	-- lvl2 tag store, for interconect
	--addrb_lvl2_tag_o <= lvl2b_c_idx_s;
	--lvl2b_ts_tag_s <= dreadb_lvl2_tag_i(LVL2C_TAG_WIDTH-1 downto 0);
	--lvl2b_ts_bkk_s <= dreadb_lvl2_tag_i(LVL2C_TAG_WIDTH+LVL2C_BKK_WIDTH-1 downto LVL2C_TAG_WIDTH);

	
	-- Compare tags
	lvl1dd_tag_cmp_s <= '1' when lvl1d_c_tag_s = lvl1da_ts_tag_s else '0';
	--lvl1di_tag_cmp_s <= '1' when lvl1d_c_tag_s = lvl1ib_ts_tag_s else '0';
	lvl1ii_tag_cmp_s <= '1' when lvl1i_c_tag_s = lvl1ia_ts_tag_s else '0';
	--lvl1id_tag_cmp_s <= '1' when lvl1i_c_tag_s = lvl1db_ts_tag_s else '0';
	lvl2a_tag_cmp_s <= '1' when lvl2a_c_tag_s = lvl2a_ts_tag_s else '0'; 
	--lvl2b_tag_cmp_s <= '1' when lvl2b_c_tag_s = lvl2b_ts_tag_s else '0'; 
	
	-- Cache hit/miss indicator flags => same tag + valid
	lvl1d_c_hit_s <= lvl1dd_tag_cmp_s and lvl1da_ts_bkk_s(0); 
	lvl1i_c_hit_s <= lvl1ii_tag_cmp_s and lvl1ia_ts_bkk_s(0);
	-- NOTE uncoment if explicit resolution of self modifying code is needed
	--lvl1d_c_dup_s <= lvl1di_tag_cmp_s and lvl1ib_ts_bkk_s(0);
	--lvl1i_c_dup_s <= lvl1id_tag_cmp_s and lvl1db_ts_bkk_s(0);
	--lvl1i_c_haz_s <= lvl1i_c_dup_s and lvl1db_ts_bkk_s(1);
	lvl2a_c_hit_s <= lvl2a_tag_cmp_s and lvl2a_ts_bkk_s(0); 
	--lvl2b_c_hit_s <= lvl2b_tag_cmp_s and lvl2b_ts_bkk_s(1);

	-- TODO check if this shit can even work outside of fsm
	data_ready_o <= lvl1d_c_hit_s;
	instr_ready_o <= lvl1i_c_hit_s;

	-- Adder for counters 
	cc_counter_incr <= std_logic_vector(unsigned(cc_counter_reg) + to_unsigned(1,BLOCK_ADDR_WIDTH));

	-- Sequential logic - regs
	regs : process(clk)is
	begin
		if(rising_edge(clk))then
			if(reset= '0')then
				cc_state_reg <= idle;
				cc_counter_reg <= (others => '0');
			else
				cc_state_reg <= cc_state_next;
				cc_counter_reg <=  cc_counter_next;
			end if;
		end if;
	end process;

	-- TODO everything below this magical line is hot garbage and needs to be double checked and/or reworked ***************************************


	-- TODO check this: if processor never writes to instr cache, it doesn't need dirty bit
	-- TODO second to that, level2 cache can leasurly be simple dual port RAM 
	-- TODO as one port will never change the contents of lvl2 Cache
	-- TODO check this: if processor never writes to instr cache, it doesnt need flush state
	-- TODO if this somehow saves logic in end product remove it
	-- FSM that controls communication between lvl1 instruction cache and lvl2 shared cache

	-- TODO burn down this entire FSM and start again, try to remove data/instruction ready signals out of it if you can
	fsm_instr : process(cc_state_reg) is
	begin
		-- for FSM
		cc_state_next <= idle;
		cc_counter_next <= (others => '0');
		-- Misc
		lvl2a_c_tag_s <= lvl2ia_c_tag_s;
		-- LVL1 instruction cache and tag
		wea_instr_tag_s <= '0';
		dwritea_instr_tag_s <= (others => '0');
		wea_instr_cache_s <= (others => '0');
		addra_instr_cache_s <= addr_instr_i;
		dwritea_instr_cache_s <= (others => '0');
		dread_instr_o <= dreada_instr_cache_s;
		-- LVL1 data cache and tag
		wea_data_tag_s <= '0';
		dwritea_data_tag_s <= (others => '0');
		wea_data_cache_s <= we_data_i;
		addra_data_cache_s <= addr_data_i;
		dwritea_data_cache_s <= dwrite_data_i;
		dread_data_o <= dreada_data_cache_s;
		-- LVL2 cache and tag
		addra_lvl2_cache_s <= (others => '0');
		wea_lvl2_cache_s <= (others => '0');
		dwritea_lvl2_cache_s <= (others => '0'); 
		dreada_lvl2_cache_s <= (others => '0'); 
		addra_lvl2_tag_s <= (others => '0');
		wea_lvl2_tag_s <= '0';
		dwritea_lvl2_tag_s <= (others => '0'); 
		dreada_lvl2_tag_s <= (others => '0'); 
		

		case (cc_state_reg) is
			when idle =>
				if(lvl1i_c_hit_s = '0') then -- instr cache miss
					cc_state_next <= check_lvl2_instr;
				end if;
				if(lvl1d_c_hit_s = '0') then -- data cache miss
					cc_state_next <= check_lvl2_data;
				end if;

			when check_lvl2_instr => 
				addra_lvl2_tag_s <= lvl2ia_c_idx_s;
				lvl2a_c_tag_s <= lvl2ia_c_tag_s;
				if (lvl2a_c_hit_s = '1') then
					cc_state_next <= fetch_instr;
				else
					cc_state_next <= check_lvl2_instr; -- stay here if lvl2 is not ready
				end if;
				addra_lvl2_cache_s <= lvl1i_c_idx_s & cc_counter_reg & 00;

			when check_lvl2_data => 
				addra_lvl2_tag_s <= lvl2da_c_idx_s;
				lvl2a_c_tag_s <= lvl2da_c_tag_s;
				if (lvl2a_c_hit_s = '1') then
					cc_state_next <= fetch_data;
				else
					cc_state_next <= check_lvl2_data; -- stay here if lvl2 is not ready
				end if;
				if(lvl1da_ts_bkk_s(1) = '1')then -- data in lvl1 is dirty
					cc_state_next <= flush_data;
				else
					cc_state_next <= fetch_data;
				end if;
				addra_lvl2_cache_s <= lvl1d_c_idx_s & cc_counter_reg & 00;

			when fetch_instr => 
				-- index addresses a block in cache, counter & 00 address 4 bytes at a time
				addra_lvl2_cache_s <= lvl1i_c_idx_s & cc_counter_reg & 00;
				dwritea_instr_cache_s <= dreada_lvl2_cache_s;
				wea_instr_cache_s <= "1111";
				cc_counter_next <= cc_counter_incr;
				if(cc_counter_reg = icc_counter_max)then 
					-- finished with writing entire block
					cc_state_next <= idle;
						-- write new tag to tag store, set valid, reset dirty
					dwritea_instr_tag_s <= "01" & lvl1i_c_tag_s; 
					we_instr_tag_s <= '1';
				else
					cc_state_next <= fetch_instr;
				end if;

			when fetch_data => 
				-- index addresses a block in cache, counter & 00 address 4 bytes at a time
				addra_lvl2_cache_s <= lvl1d_c_idx_s & cc_counter_reg & 00;
				dwritea_data_cache_s <= dreada_lvl2_cache_s;
				wea_data_cache_s <= "1111";
				cc_counter_next <= cc_counter_incr;
				if(cc_counter_reg = icc_counter_max)then 
					-- finished with writing entire block
					cc_state_next <= idle;
						-- write new tag to tag store, set valid, reset dirty
					dwritea_data_tag_s <= "01" & lvl1d_c_tag_s; 
					wea_data_tag_s <= '1';
				else
					cc_state_next <= fetch_data;
				end if;

			when flush_data => 
				-- index addresses a block in cache, counter & 00 address 4 bytes at a time
				-- TODO IMPLEMENT LOGIC FOR FLUSHING
				addra_lvl2_cache_s <= lvl1d_c_idx_s & cc_counter_reg & 00;
				dwritea_data_cache_s <= dreada_lvl2_cache_s;
				wea_data_cache_s <= "1111";
				cc_counter_next <= cc_counter_incr;
				if(cc_counter_reg = icc_counter_max)then 
					-- finished with writing entire block
					cc_state_next <= fetch_data;
						-- write new tag to tag store, set valid, reset dirty
					dwritea_data_tag_s <= "01" & lvl1d_c_tag_s; 
					wea_data_tag_s <= '1';
				else
					cc_state_next <= fetch_data;
				end if;

		end case;
	end process;



	--********** LEVEL 1 CACHE  **************
	-- INSTRUCTION CACHE
	-- TODO double check this address logic, change if unaligned accesses are implemented
	-- TODO 32 bit address will be cut here, send the minimum bits needed
	-- TODO decide if cutting 2 LSB bits is done here or in cache controller
	--we_instr_cache_s <= "0000"; NOTE nah
	addra_instr_cache_s <= addr_instr_i((clogb2(LVL1_CACHE_SIZE)-1) downto 2);
	regcea_instr_cache_s <= '0';
	ena_instr_cache_s <= en_instr_cache_i;
	rsta_instr_cache_s <= rst_instr_cache_i;
	-- TODO make a driver for dina, wea, douta
	-- Instantiation of instruction cache
	instruction_cache : entity work.BRAM_sp_rf_bw(rtl)
		generic map (
			NB_COL => LVL1C_NUM_COL,
			COL_WIDTH => LVL1C_COL_WIDTH,
			RAM_DEPTH => LVL1C_DEPTH,
			RAM_PERFORMANCE => "LOW_LATENCY",
			INIT_FILE => "" 
		)
		port map  (
			clk   => clk,
			addra  => addra_instr_cache_s,
			dina   => dwritea_instr_cache_s,
			wea    => wea_instr_cache_s,
			ena    => ena_instr_cache_s,
			rsta   => rsta_instr_cache_s,
			regcea => regcea_instr_cache_s,
			douta  => dreada_instr_cache_s
		);

 -- TAG STORE FOR INSTRUCTION CACHE
 -- TODO @ system boot this entire memory needs to be set to 0
 -- TODO either implement reset and test its timing or make cc handle it @ boot
 --	rst_instr_tag_s <= reset;
	--instantiation of tag store
	ena_instr_tag_s <= '1'; --NOTE right?
	instruction_tag_store: entity work.ram_sp_ar(rtl)
		generic map (
			RAM_WIDTH => LVL1C_TAG_WIDTH + LVL1IC_BKK_WIDTH,
			RAM_DEPTH => LVL1C_NB_BLOCKS
		)
		port map(
			--global
			clk => clk,
			--port a
			addra => addra_instr_tag_s,
			dina => dwritea_instr_tag_s,
			ena => ena_instr_tag_s,
			douta => dreada_instr_tag_s,
			wea => wea_instr_tag_s
			--port b
			--addrb => addrb_instr_tag_s,
			--dinb => dwriteb_instr_tag_s,
			--enb => enb_instr_tag_s,
			--doutb => dreadb_instr_tag_s,
			--web => web_instr_tag_s
		);

	-- DATA CACHE
	-- Port A signals
	-- TODO double check this address logic!, change if unaligned accesses are implemented
	-- TODO CC shouldn't send 32 bit address if it will be cut here, send the minimum bits needed
	-- TODO decide if cutting 2 LSB bits is done here or in cache controller
	addra_data_cache_s <= addr_data_i((clogb2(LVL1_CACHE_SIZE)-1) downto 2);
	rsta_data_cache_s <= reset;
	ena_data_cache_s <= '1';
	regcea_data_cache_s <= '0';
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
				clk   => clk,
				addra  => addra_data_cache_s,
				dina   => dwritea_data_cache_s,
				wea    => wea_data_cache_s,
				ena    => ena_data_cache_s,
				rsta   => rsta_data_cache_s,
				regcea => regcea_data_cache_s,
				douta  => dreada_data_cache_s
		);


	-- TAG STORE FOR DATA CACHE
 -- TODO @ system boot this entire memory needs to be set to 0
 -- TODO either implement reset and test its timing or make cc handle it @ boot
	--rst_data_tag_s <= reset;
	-- Instantiation of tag store
	ena_data_tag_s <= '1'; -- NOTE i think
	data_tag_store: entity work.ram_sp_ar(rtl)
		generic map (
			RAM_WIDTH => LVL1C_TAG_WIDTH + LVL1DC_BKK_WIDTH,
			RAM_DEPTH => LVL1C_NB_BLOCKS
		)
		port map(
			--global
			clk => clk,
			--port a
			addra => addra_data_tag_s,
			dina => dwritea_data_tag_s,
			douta => dreada_data_tag_s,
			wea => wea_data_tag_s,
			ena => ena_data_tag_s
			--port b
			--doutb => dreadb_data_tag_s,
			--addrb => addrb_data_tag_s,
			--dinb => dwriteb_data_tag_s,
			--web => web_data_tag_s,
			--enb => ena_data_tag_s
		);



	--********** LEVEL 2 CACHE  **************
	-- Port A signals
	rsta_lvl2_cache_s <= reset; -- TODO is it needed? this is not a real reset signal, more like output enable
	rstb_lvl2_cache_s <= reset; -- TODO is it needed?
	ena_lvl2_cache_s <= '1';
	enb_lvl2_cache_s <= '1';
	regcea_lvl2_cache_s <= '0'; -- TODO remove these if Vivado doesnt
	regceb_lvl2_cache_s <= '0'; -- TODO remove these if Vivado doesnt
	-- TODO in this type of bram, 2 LSB bits are removed, implement this here or in cache controller!!!
	-- Instantiation of level 2 cache
	level_2_cache : entity work.RAM_tdp_rf_bw(rtl)
		generic map (
			NB_COL => LVL2C_NUM_COL,
			COL_WIDTH => LVL2C_COL_WIDTH,
			RAM_DEPTH => LVL2C_DEPTH,
			RAM_PERFORMANCE => "LOW_LATENCY",
			INIT_FILE => "" 
		)
		port map  (
			--global
			clk    => clk,
			--port a
			addra  => addra_lvl2_cache_s,
			dina   => dwritea_lvl2_cache_s,
			douta  => dreada_lvl2_cache_s,
			wea    => wea_lvl2_cache_s,
			ena    => ena_lvl2_cache_s,
			rsta   => rsta_lvl2_cache_s,
			regcea => regcea_lvl2_cache_s,
			--port b
			addrb  => addrb_lvl2_cache_s,
			dinb   => dwriteb_lvl2_cache_s,
			web    => web_lvl2_cache_s,
			enb    => enb_lvl2_cache_s,
			rstb   => rstb_lvl2_cache_s,
			regceb => regceb_lvl2_cache_s,
			doutb  => dreadb_lvl2_cache_s
		);

 -- TODO @ system boot this entire memory needs to be set to 0
 -- TODO either implement reset and test its timing or make cc handle it @ boot
	-- tag store for Level 2 cache
	ena_lvl2_tag_s <= '1';
	enb_lvl2_tag_s <= '1';
	level_2_tag_store: entity work.ram_tdp_ar(rtl)
		generic map (
			 RAM_WIDTH => LVL2C_TAG_WIDTH + LVL2C_BKK_WIDTH,
			 RAM_DEPTH => LVL2C_NB_BLOCKS
		)
		port map(
			--global
			clk => clk,
			--port a
			addra => addra_lvl2_tag_s,
			dina => dwritea_lvl2_tag_s,
			douta => dreada_lvl2_tag_s,
			wea => wea_lvl2_tag_s,
			ena => ena_lvl2_tag_s,
			--port b
			dinb => dwriteb_lvl2_tag_s,
			addrb => addrb_lvl2_tag_s,
			doutb => dreadb_lvl2_tag_s,
			web => web_lvl2_tag_s,
			enb => enb_lvl2_tag_s
		);

end architecture;
