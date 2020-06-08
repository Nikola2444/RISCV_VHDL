library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use work.cache_pkg.all;

entity cache_contr_dm is
generic (BLOCK_SIZE : natural := 64;
			LVL1_CACHE_SIZE : natural := 1048;
			LVL2_CACHE_SIZE : natural := 4096);
	port (clk : in std_logic;
			reset : in std_logic;
			-- controller drives ce for RISC
			data_ready_o : out std_logic;
			instr_ready_o : out std_logic;
			-- Level 1 caches
			-- Instruction cache
			rst_instr_cache_i : in std_logic;
			en_instr_cache_i  : in std_logic;
			addr_instr_i 		: in std_logic_vector(31 downto 0);
			dread_instr_o 		: out std_logic_vector(31 downto 0);
			-- Data cache
			addr_data_i			: in std_logic_vector(31 downto 0);
			dread_data_o 		: out std_logic_vector(31 downto 0);
			dwrite_data_i		: in std_logic_vector(31 downto 0);
         we_data_i			: in std_logic_vector(3 downto 0);
         re_data_i			: in std_logic
			);
end entity;

architecture Behavioral of cache_contr_dm is

	-- DERIVE 2nd ORDER CONSTANTS
	constant BLOCK_ADDR_WIDTH : integer := clogb2(BLOCK_SIZE);
	constant LVL1C_ADDR_WIDTH : integer := clogb2(LVL1_CACHE_SIZE);
	constant LVL1C_INDEX_WIDTH : integer := LVL1C_ADDR_WIDTH - BLOCK_ADDR_WIDTH;
	constant LVL1C_TAG_WIDTH : integer := 32 - LVL1C_ADDR_WIDTH;
	constant LVL1DC_BKK_WIDTH : integer := 2;
	constant LVL1IC_BKK_WIDTH : integer := 1;
	constant LVL2C_ADDR_WIDTH : integer := clogb2(LVL2_CACHE_SIZE);
	constant LVL2C_INDEX_WIDTH : integer := LVL2C_ADDR_WIDTH - BLOCK_ADDR_WIDTH;
	constant LVL2C_TAG_WIDTH : integer := 32 - LVL2C_ADDR_WIDTH;
	constant LVL2C_BKK_WIDTH : integer := 2;


	-- SIGNALS FOR INTERACTION WITH RAMS
	--*******************************************************************************************
	-- Level 1 cache signals


	-- Instruction cache signals
	signal addr_instr_cache_s : std_logic_vector((clogb2(LVL1_CACHE_SIZE)-1) downto 0);
	signal dwrite_instr_cache_s : std_logic_vector(LVL1C_NUM_COL*LVL1C_COL_WIDTH-1 downto 0);
	signal dread_instr_cache_s : std_logic_vector(LVL1C_NUM_COL*LVL1C_COL_WIDTH-1 downto 0);
	signal we_instr_cache_s : std_logic_vector(LVL1C_NUM_COL-1 downto 0);
	signal en_instr_cache_s : std_logic;
	signal rst_instr_cache_s : std_logic;
	signal regce_instr_cache_s : std_logic;

	-- Instruction cache tag store singals
	-- port A
	signal dwritea_instr_tag_s : std_logic_vector(LVL1C_TAG_WIDTH + LVL1IC_BKK_WIDTH - 1 downto 0);
	signal dreada_instr_tag_s : std_logic_vector(LVL1C_TAG_WIDTH + LVL1IC_BKK_WIDTH - 1 downto 0);
	signal addra_instr_tag_s : std_logic_vector(clogb2(LVL1C_NB_BLOCKS)-1 downto 0);
	signal ena_instr_tag_s : std_logic;
	signal wea_instr_tag_s : std_logic;
	-- port B
	signal dwriteb_instr_tag_s : std_logic_vector(LVL1C_TAG_WIDTH + LVL1IC_BKK_WIDTH - 1 downto 0);
	signal dreadb_instr_tag_s : std_logic_vector(LVL1C_TAG_WIDTH + LVL1IC_BKK_WIDTH - 1 downto 0);
	signal addrb_instr_tag_s : std_logic_vector(clogb2(LVL1C_NB_BLOCKS)-1 downto 0);
	signal enb_instr_tag_s : std_logic;
	signal web_instr_tag_s : std_logic;


	-- Data cache signals
	signal clk_data_cache_s : std_logic;
	signal addr_data_cache_s : std_logic_vector((clogb2(LVL1_CACHE_SIZE)-1) downto 0);
	signal dwrite_data_cache_s : std_logic_vector(LVL1C_NUM_COL*LVL1C_COL_WIDTH-1 downto 0);
	signal dread_data_cache_s : std_logic_vector(LVL1C_NUM_COL*LVL1C_COL_WIDTH-1 downto 0); 
	signal we_data_cache_s : std_logic_vector(LVL1C_NUM_COL-1 downto 0);
	signal en_data_cache_s : std_logic; 
	signal rst_data_cache_s : std_logic; 
	signal regce_data_cache_s : std_logic;

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
	signal dwriteb_data_tag_s : std_logic_vector(LVL1C_TAG_WIDTH + LVL1DC_BKK_WIDTH - 1 downto 0);
	signal dreadb_data_tag_s : std_logic_vector(LVL1C_TAG_WIDTH + LVL1DC_BKK_WIDTH - 1 downto 0);
	signal addrb_data_tag_s : std_logic_vector(clogb2(LVL1C_NB_BLOCKS)-1 downto 0);
	signal enb_data_tag_s : std_logic;
	signal regceb_data_tag_s : std_logic;
	signal rstb_data_tag_s : std_logic;
	signal web_data_tag_s : std_logic;


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
	signal lvl1db_ts_tag_s : std_logic_vector(LVL1C_TAG_WIDTH-1 downto 0);
	signal lvl1db_ts_bkk_s : std_logic_vector(LVL1DC_BKK_WIDTH-1 downto 0);
	-- 'tag', 'index', 'byte in block' and 'tag store address' fields for instruction cache
	signal lvl1i_c_tag_s : std_logic_vector(LVL1C_TAG_WIDTH-1 downto 0);
	signal lvl1i_c_idx_s : std_logic_vector(LVL1C_INDEX_WIDTH-1 downto 0);
	signal lvl1i_c_bib_s : std_logic_vector(BLOCK_ADDR_WIDTH-1 downto 0);
	signal lvl1i_c_addr_s : std_logic_vector(LVL1C_ADDR_WIDTH-1 downto 0);
	-- 'tag' and 'bookkeeping bits: MSB - valid, LSB -dirty' fields from instruction tag store
	signal lvl1ia_ts_tag_s : std_logic_vector(LVL1C_TAG_WIDTH-1 downto 0);
	signal lvl1ia_ts_bkk_s : std_logic_vector(LVL1IC_BKK_WIDTH-1 downto 0);
	signal lvl1ib_ts_tag_s : std_logic_vector(LVL1C_TAG_WIDTH-1 downto 0);
	signal lvl1ib_ts_bkk_s : std_logic_vector(LVL1IC_BKK_WIDTH-1 downto 0);
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
	-- 'tag' and 'bookkeeping bits: MSB - valid, LSB -dirty' fields from level 2 tag store
	signal lvl2a_ts_tag_s : std_logic_vector(LVL2C_TAG_WIDTH-1 downto 0);
	signal lvl2a_ts_bkk_s : std_logic_vector(LVL2C_BKK_WIDTH-1 downto 0);
	-- 'tag' and 'bookkeeping bits: MSB - valid, LSB -dirty' fields from level 2 tag store
	signal lvl2b_ts_tag_s : std_logic_vector(LVL2C_TAG_WIDTH-1 downto 0);
	signal lvl2b_ts_bkk_s : std_logic_vector(LVL2C_BKK_WIDTH-1 downto 0);


	-- SIGNALS FOR COMPARING TAG VALUES
	signal lvl1ii_tag_cmp_s  : std_logic; -- incoming instruction address VS instruction tag store (hit in instruction cache)
	signal lvl1id_tag_cmp_s  : std_logic; -- incoming instruction address VS data tag store (check for duplicate block in data)
	signal lvl1dd_tag_cmp_s  : std_logic; -- incoming data address VS data tag store (hit in data cache)
	signal lvl1di_tag_cmp_s  : std_logic; -- incoming data address VS instruction tag store (check for duplicate in instr)
	signal lvl2_tag_cmp_s  : std_logic; -- incoming address from missed lvl1 i/d cache VS lvl2 tag store
	-- SIGNALS TO INDICATE CACHE HITS/MISSES
	signal lvl1d_c_hit_s  : std_logic; -- hit in data cache
	signal lvl1d_c_dup_s  : std_logic; -- addressing block in data cache that has duplicate in instruction cache
	signal lvl1i_c_hit_s  : std_logic; -- hit in instruction cache
	signal lvl1i_c_dup_s  : std_logic; -- addressing block in instruction cache that has duplicate in data cache
	signal lvl2_c_hit_s  : std_logic; -- hit in lvl 2 cache


	-- TODO everything below this magical line is hot garbage and needs to be double checked and/or reworked ***************************************

	-- Cache control state
	type cc_state is (idle, fetch, flush, wait4lvl2);
	-- dcc - data cache controller
	signal icc_state_reg, icc_state_next: cc_state;
	signal dcc_state_reg, dcc_state_next: cc_state;
	-- icc - instruction cache controller
	signal icc_counter_reg, icc_counter_incr, icc_counter_next: std_logic_vector(BLOCK_ADDR_WIDTH-3 downto 0);
	signal dcc_counter_reg, dcc_counter_incr, dcc_counter_next: std_logic_vector(BLOCK_ADDR_WIDTH-3 downto 0);
	constant counter_max : std_logic_vector(BLOCK_ADDR_WIDTH-3 downto 0) := (others =>'1');


begin

	-- Separate input ports into fields for easier menagment
	-- From data cache
	lvl1d_c_tag_s <= addr_data_i(31 downto LVL1C_ADDR_WIDTH);
	lvl1d_c_idx_s <= addr_data_i(LVL1C_ADDR_WIDTH-1 downto BLOCK_ADDR_WIDTH);
	lvl1d_c_bib_s <= addr_data_i(BLOCK_ADDR_WIDTH-1 downto 0);
	lvl1d_c_addr_s <= addr_data_i(LVL1C_ADDR_WIDTH-1 downto 0);
	-- From instruction cache
	lvl1i_c_tag_s <= addr_instr_i(31 downto LVL1C_ADDR_WIDTH);
	lvl1i_c_idx_s <= addr_instr_i(LVL1C_ADDR_WIDTH-1 downto BLOCK_ADDR_WIDTH);
	lvl1i_c_bib_s <= addr_instr_i(BLOCK_ADDR_WIDTH-1 downto 0);
	lvl1i_c_addr_s <= addr_instr_i(LVL1C_ADDR_WIDTH-1 downto 0);
	-- From data cache
	lvl2a_c_tag_s <= addr_data_i(31 downto LVL2C_ADDR_WIDTH);
	lvl2a_c_idx_s <= addr_data_i(LVL2C_ADDR_WIDTH-1 downto BLOCK_ADDR_WIDTH);
	lvl2a_c_bib_s <= addr_data_i(BLOCK_ADDR_WIDTH-1 downto 0);
	lvl2a_c_addr_s <= addr_data_i(LVL2C_ADDR_WIDTH-1 downto 0);
	-- From instruction cache
	lvl2b_c_tag_s <= addr_instr_i(31 downto LVL2C_ADDR_WIDTH);
	lvl2b_c_idx_s <= addr_instr_i(LVL2C_ADDR_WIDTH-1 downto BLOCK_ADDR_WIDTH);
	lvl2b_c_bib_s <= addr_instr_i(BLOCK_ADDR_WIDTH-1 downto 0);
	lvl2b_c_addr_s <= addr_instr_i(LVL2C_ADDR_WIDTH-1 downto 0);

	-- Forward address and get tag + bookkeeping bits from tag store
	-- Data tag store
	addr_data_tag_o <= data_c_idx_s;
	data_ts_tag_s <= dread_data_tag_i(LVL1C_TAG_WIDTH-1 downto 0);
	data_ts_bkk_s <= dread_data_tag_i(LVL1C_TAG_WIDTH+LVL1DC_BKK_WIDTH-1 downto LVL1C_TAG_WIDTH);
	-- Instruction tag store
	addr_instr_tag_o <= instr_c_idx_s;
	instr_ts_tag_s <= dread_instr_tag_i(LVL1C_TAG_WIDTH-1 downto 0);
	instr_ts_bkk_s <= dread_instr_tag_i(LVL1C_TAG_WIDTH+LVL1IC_BKK_WIDTH-1 downto LVL1C_TAG_WIDTH);
	-- lvl2 tag store, for LVL1
	addra_lvl2_tag_o <= lvl2a_c_idx_s;
	lvl2a_ts_tag_s <= dreada_lvl2_tag_i(LVL2C_TAG_WIDTH-1 downto 0);
	lvl2a_ts_bkk_s <= dreada_lvl2_tag_i(LVL2C_TAG_WIDTH+LVL2C_BKK_WIDTH-1 downto LVL2C_TAG_WIDTH);
	-- lvl2 tag store, for intercone
	addrb_lvl2_tag_o <= lvl2b_c_idx_s;
	lvl2b_ts_tag_s <= dreadb_lvl2_tag_i(LVL2C_TAG_WIDTH-1 downto 0);
	lvl2b_ts_bkk_s <= dreadb_lvl2_tag_i(LVL2C_TAG_WIDTH+LVL2C_BKK_WIDTH-1 downto LVL2C_TAG_WIDTH);

	
	-- Compare tags
	data_tag_cmp_s <= '1' when data_c_tag_s = data_ts_tag_s else '0';
	instr_tag_cmp_s <= '1' when instr_c_tag_s = instr_ts_tag_s else '0';
	lvl2a_tag_cmp_s <= '1' when lvl2a_c_tag_s = lvl2a_ts_tag_s else '0'; 
	lvl2b_tag_cmp_s <= '1' when lvl2b_c_tag_s = lvl2b_ts_tag_s else '0'; 
	
	-- Cache hit/miss indicator flags => same tag + valid
	lvl1d_c_hit_s <= data_tag_cmp_s and data_ts_bkk_s(1); 
	lvl1i_c_hit_s <= instr_tag_cmp_s and instr_ts_bkk_s(1);
	lvl2a_c_hit_s <= lvl2a_tag_cmp_s and lvl2a_ts_bkk_s(1); 
	lvl2b_c_hit_s <= lvl2b_tag_cmp_s and lvl2b_ts_bkk_s(1);

	-- Adders for counters 
	dcc_counter_incr <= std_logic_vector(unsigned(dcc_counter_reg) + to_unsigned(1,BLOCK_ADDR_WIDTH));
	icc_counter_incr <= std_logic_vector(unsigned(icc_counter_reg) + to_unsigned(1,BLOCK_ADDR_WIDTH));

	-- Sequential logic - regs
	regs : process(clk)is
	begin
		if(rising_edge(clk))then
			if(reset= '0')then
				icc_state_reg <= idle;
				dcc_state_reg <= idle;
				icc_counter_reg <= (others => '0');
				dcc_counter_reg <= (others => '0');
			else
				icc_state_reg <= icc_state_next;
				dcc_state_reg <=  dcc_state_next;
				icc_counter_reg <=  icc_counter_next;
				dcc_counter_reg <=  dcc_counter_next;
			end if;
		end if;
	end process;


	-- TODO check this: if processor never writes to instr cache, it doesn't need dirty bit
	-- TODO second to that, level2 cache can leasurly be simple dual port RAM 
	-- TODO as one port will never change the contents of lvl2 Cache
	-- TODO check this: if processor never writes to instr cache, it doesnt need flush state
	-- TODO if this somehow saves logic in end product remove it
	-- FSM that controls communication between lvl1 instruction cache and lvl2 shared cache

	-- TODO burn down this entire FSM and start again, try to remove data/instruction ready signals out of it if you can
	fsm_instr : process(icc_state_reg, instr_c_hit_s) is
	begin
	we_instr_tag_o <= '0';
	dwrite_instr_tag_o <= (others => '0');

	icc_state_next <= idle;
	icc_counter_next <= (others => '0');

	instr_ready_o <= '0';
	dread_instr_o <= dread_instr_i;
	dwrite_instr_o <= dwrite_instr_i;
	we_instr_o <= we_instr_i;
	addr_instr_o <= addr_instr_i;
	addrb_lvl2_o <= lvl2b_c_idx_s & icc_counter_next & "00"; -- index addresses a block in cache, counter & 00 address 4 bytes at a time
		case (icc_state_reg) is
			when idle =>
				instr_ready_o <= '1';
				if(instr_c_hit_s = '0') then -- instr cache miss
					if(lvl2b_c_hit_s = '1')then
						icc_state_next <= fetch; -- fetch required data
					else
						icc_state_next <= wait4lvl2; -- lvl2 doesn't have data
					end if;
				end if;
			when fetch => 
				addr_instr_o <= instr_c_idx_s & icc_counter_reg & 00;
				dwrite_instr_o <= dreadb_lvl2_i;
				icc_counter_next <= icc_counter_incr;
				if(icc_counter_reg = icc_counter_max)then 
					-- finished with writing entire block
					icc_state_next <= idle;
					-- write new tag to tag store, set valid, reset dirty
					dwrite_instr_tag_o <= "10" & instr_c_tag_s;
					we_instr_tag_o <= '1';
				else
					icc_state_next <= fetch;
				end if;
			when wait4lvl2 =>
				--TODO implement logic
				-- fuck me why did i have to start this
		end case;
	end process;



	--********** LEVEL 1 CACHE  **************
	-- INSTRUCTION CACHE
	-- TODO double check this address logic, change if unaligned accesses are implemented
	-- TODO CC shouldn't send 32 bit address if it will be cut here, send the minimum bits needed
	-- TODO decide if cutting 2 LSB bits is done here or in cache controller
	addr_instr_cache_s <= addr_instr_i((clogb2(LVL1_CACHE_SIZE)-1) downto 2);
	we_instr_cache_s <= "0000";
	regce_instr_cache_s <= '0';
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
			addra  => addr_instr_cache_s,
			dina   => dwrite_instr_cache_s,
			wea    => we_instr_cache_s,
			ena    => en_instr_cache_s,
			rsta   => rst_instr_cache_s,
			regcea => regce_instr_cache_s,
			douta  => dread_instr_cache_s
		);

	-- TAG STORE FOR INSTRUCTION CACHE
 -- TODO @ system boot this entire memory needs to be set to 0
 -- TODO either implement reset and test its timing or make cc handle it @ boot
--	rst_instr_tag_s <= reset;
	--instantiation of tag store
	instruction_tag_store: entity work.ram_tdp_ar(rtl)
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
			wea => wea_instr_tag_s,
			--port b
			addrb => addrb_instr_tag_s,
			dinb => dwriteb_instr_tag_s,
			enb => enb_instr_tag_s,
			doutb => dreadb_instr_tag_s,
			web => web_instr_tag_s
		);

	-- DATA CACHE
	-- Port A signals
	-- TODO double check this address logic!, change if unaligned accesses are implemented
	-- TODO CC shouldn't send 32 bit address if it will be cut here, send the minimum bits needed
	-- TODO decide if cutting 2 LSB bits is done here or in cache controller
	addr_data_cache_s <= addr_data_i((clogb2(LVL1_CACHE_SIZE)-1) downto 2);
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


	-- TAG STORE FOR DATA CACHE
 -- TODO @ system boot this entire memory needs to be set to 0
 -- TODO either implement reset and test its timing or make cc handle it @ boot
	--rst_data_tag_s <= reset;
	-- Instantiation of tag store
	data_tag_store: entity work.ram_tdp_ar(rtl)
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
			ena => ena_data_tag_s,
			--port b
			doutb => dreadb_data_tag_s,
			addrb => addrb_data_tag_s,
			dinb => dwriteb_data_tag_s,
			web => web_data_tag_s,
			enb => ena_data_tag_s
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
