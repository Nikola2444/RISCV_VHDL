library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use work.ram_pkg.all;

entity cache_contr_dm is
generic (BLOCK_SIZE : natural := 64;
			L1_CACHE_SIZE : natural := 1048;
			L2_CACHE_SIZE : natural := 4096);
	port (clk : in std_logic;
			reset : in std_logic;
			-- controller drives ce for RISC
			ce_o : out std_logic;
			-- Level 1 caches
			-- Instruction cache
			dread_instr_i 		: in std_logic_vector(31 downto 0);
			dread_instr_o 		: out std_logic_vector(31 downto 0);
			dwrite_instr_i 	: in std_logic_vector(31 downto 0);
			dwrite_instr_o 	: out std_logic_vector(31 downto 0);
			addr_instr_i 		: in std_logic_vector(31 downto 0);
         we_instr_i 			: in std_logic_vector(3 downto 0);
         we_instr_o 			: out std_logic_vector(3 downto 0);
			--  Instruction tag store and bookkeeping
			addr_instr_tag_o 		: out std_logic_vector((clogb2(L1_CACHE_SIZE/BLOCK_SIZE)-1) downto 0);
			dread_instr_tag_i 	: in std_logic_vector((32-clogb2(L1_CACHE_SIZE)+1) downto 0);
			we_instr_tag_o	   	: out std_logic;
			en_instr_tag_o	   	: out std_logic;
			dwrite_instr_tag_o 	: out std_logic_vector((32-clogb2(L1_CACHE_SIZE)+1) downto 0);
			-- Data cache
			dread_data_i 		: in std_logic_vector(31 downto 0);
			dread_data_o 		: out std_logic_vector(31 downto 0);
			dwrite_data_i		: in std_logic_vector(31 downto 0);
			dwrite_data_o		: out std_logic_vector(31 downto 0);
			addr_data_i			: in std_logic_vector(31 downto 0);
         we_data_i			: in std_logic_vector(3 downto 0);
         we_data_o			: out std_logic_vector(3 downto 0);
			--  Data tag store and bookkeeping
			addr_data_tag_o 	: out std_logic_vector((clogb2(L1_CACHE_SIZE/BLOCK_SIZE)-1) downto 0);
			dread_data_tag_i 	: in std_logic_vector((32-clogb2(L1_CACHE_SIZE)+1) downto 0);
			we_data_tag_o   	: out std_logic;
			en_data_tag_o   	: out std_logic;
			dwrite_data_tag_o	: out std_logic_vector(32-clogb2(L1_CACHE_SIZE)+1 downto 0);
			-- Level 2 cache
			dread_l2_i			: in std_logic_vector(31 downto 0);
			dwrite_l2_o 		: out std_logic_vector(31 downto 0);
			addr_l2_o 			: out std_logic_vector(31 downto 0);
         we_l2_o 				: out std_logic_vector(3 downto 0);
			-- Level 2 cache tag store and bookkeeping
			addr_l2_tag_o 		: out std_logic_vector((clogb2(L2_CACHE_SIZE/BLOCK_SIZE)-1) downto 0);
			dread_l2_tag_i 	: in std_logic_vector((32-clogb2(L2_CACHE_SIZE)+1) downto 0);
			we_l2_tag_o   		: out std_logic;
			en_l2_tag_o   		: out std_logic;
			dwrite_l2_tag_o 	: out std_logic_vector((32-clogb2(L2_CACHE_SIZE)+1) downto 0)
			);
end entity;

architecture Behavioral of cache_contr_dm is

	-- DERIVE 2nd ORDER CONSTANTS
	constant BLOCK_ADDR_WIDTH : integer := clogb2(BLOCK_SIZE);
	constant L1C_ADDR_WIDTH : integer := clogb2(L1_CACHE_SIZE);
	constant L1C_INDEX_WIDTH : integer := L1C_ADDR_WIDTH - BLOCK_ADDR_WIDTH;
	constant L1C_TAG_WIDTH : integer := 32 - L1C_ADDR_WIDTH;
	constant L1C_BKK_WIDTH : integer := 2;
	constant L2C_ADDR_WIDTH : integer := clogb2(L2_CACHE_SIZE);
	constant L2C_INDEX_WIDTH : integer := L2C_ADDR_WIDTH - BLOCK_ADDR_WIDTH;
	constant L2C_TAG_WIDTH : integer := 32 - L2C_ADDR_WIDTH;
	constant L2C_BKK_WIDTH : integer := 2;

	-- SIGNALS FOR SEPARATING INPUT PORTS INTO FIELDS
	-- 'tag', 'index', 'byte in block' and 'tag store address' fields for data cache
	signal data_c_tag_s : std_logic_vector(L1C_TAG_WIDTH-1 downto 0);
	signal data_c_idx_s : std_logic_vector(L1C_INDEX_WIDTH-1 downto 0);
	signal data_c_bib_s : std_logic_vector(BLOCK_ADDR_WIDTH-1 downto 0);
	signal data_c_tsa_s : std_logic_vector(L1C_ADDR_WIDTH-1 downto 0);
	-- 'tag' and 'bookkeeping bits' fields from data tag store
	signal data_ts_tag_s : std_logic_vector(L1C_TAG_WIDTH-1 downto 0);
	signal data_ts_bkk_s : std_logic_vector(L1C_BKK_WIDTH-1 downto 0);
	-- 'tag', 'index', 'byte in block' and 'tag store address' fields for instruction cache
	signal instr_c_tag_s : std_logic_vector(L1C_TAG_WIDTH-1 downto 0);
	signal instr_c_idx_s : std_logic_vector(L1C_INDEX_WIDTH-1 downto 0);
	signal instr_c_bib_s : std_logic_vector(BLOCK_ADDR_WIDTH-1 downto 0);
	signal instr_c_tsa_s : std_logic_vector(L1C_ADDR_WIDTH-1 downto 0);
	-- 'tag' and 'bookkeeping bits' fields from instruction tag store
	signal instr_ts_tag_s : std_logic_vector(L1C_TAG_WIDTH-1 downto 0);
	signal instr_ts_bkk_s : std_logic_vector(L1C_BKK_WIDTH-1 downto 0);

	-- 'tag', 'index', 'byte in block' and 'tag store address' fields for level2 cache
	--signal l2c_tag_s : std_logic_vector(L2C_TAG_WIDTH-1 downto 0);
	--signal l2c_idx_s : std_logic_vector(L2C_INDEX_WIDTH-1 downto 0);
	--signal l2c_bib_s : std_logic_vector(BLOCK_ADDR_WIDTH-1 downto 0);
	--signal l2c_tsa_s : std_logic_vector(L2C_ADDR_WIDTH-1 downto 0);


begin

	-- Separate input ports into fields for easier menagment
	-- From data cache
	data_c_tag_s <= addr_data_i(31 downto L1C_ADDR_WIDTH);
	data_c_idx_s <= addr_data_i(L1C_ADDR_WIDTH-1 downto BLOCK_ADDR_WIDTH);
	data_c_bib_s <= addr_data_i(BLOCK_ADDR_WIDTH-1 downto 0);
	data_c_tsa_s <= addr_data_i(L1C_ADDR_WIDTH-1 downto 0);
	-- From instruction cache
	instr_c_tag_s <= addr_data_i(31 downto L1C_ADDR_WIDTH);
	instr_c_idx_s <= addr_data_i(L1C_ADDR_WIDTH-1 downto BLOCK_ADDR_WIDTH);
	instr_c_bib_s <= addr_data_i(BLOCK_ADDR_WIDTH-1 downto 0);
	instr_c_tsa_s <= addr_data_i(L1C_ADDR_WIDTH-1 downto 0);

	-- Forward adress and get tag + bookkeeping bits from tag store
	-- Data tag store
	addr_data_tag_o <= data_c_tsa_s;
	data_ts_tag_s <= dread_data_tag_i(L1C_TAG_WIDTH-1 downto 0);
	data_ts_bkk_s <= dread_data_tag_i(L1C_TAG_WIDTH+L1C_BKK_WIDTH-1 downto L1C_TAG_WIDTH);
	-- Instruction tag store
	addr_instr_tag_o <= instr_c_tsa_s;
	instr_ts_tag_s <= dread_instr_tag_i(L1C_TAG_WIDTH-1 downto 0);
	instr_ts_bkk_s <= dread_instr_tag_i(L1C_TAG_WIDTH+L1C_BKK_WIDTH-1 downto L1C_TAG_WIDTH);
	

	-- Defaults - instr mem
	dread_instr_o <= dread_instr_i;
	dwrite_instr_o <= dwrite_instr_i;
	we_instr_o <= we_instr_i;

	-- Defaults - data mem
	dread_data_o <= dread_data_i;
	dwrite_data_o <= dwrite_data_i;
	we_data_o <= we_data_i;

	-- Defaults - other signals
	ce_o <= '1';

end architecture;
