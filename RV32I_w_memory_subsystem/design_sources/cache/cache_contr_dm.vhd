library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use work.ram_pkg.all;

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
			dread_instr_i 		: in std_logic_vector(31 downto 0);
			dread_instr_o 		: out std_logic_vector(31 downto 0);
			dwrite_instr_i 	: in std_logic_vector(31 downto 0);
			dwrite_instr_o 	: out std_logic_vector(31 downto 0);
			addr_instr_i 		: in std_logic_vector(31 downto 0);
			addr_instr_o 		: in std_logic_vector(31 downto 0);
         we_instr_i 			: in std_logic_vector(3 downto 0);
         we_instr_o 			: out std_logic_vector(3 downto 0);
			--  Instruction tag store and bookkeeping
			addr_instr_tag_o 		: out std_logic_vector((clogb2(LVL1_CACHE_SIZE/BLOCK_SIZE)-1) downto 0);
			dread_instr_tag_i 	: in std_logic_vector((32-clogb2(LVL1_CACHE_SIZE)+1) downto 0);
			we_instr_tag_o	   	: out std_logic;
			en_instr_tag_o	   	: out std_logic;
			dwrite_instr_tag_o 	: out std_logic_vector((32-clogb2(LVL1_CACHE_SIZE)+1) downto 0);
			-- Data cache
			dread_data_i 		: in std_logic_vector(31 downto 0);
			dread_data_o 		: out std_logic_vector(31 downto 0);
			dwrite_data_i		: in std_logic_vector(31 downto 0);
			dwrite_data_o		: out std_logic_vector(31 downto 0);
			addr_data_i			: in std_logic_vector(31 downto 0);
			addr_data_o			: in std_logic_vector(31 downto 0);
         we_data_i			: in std_logic_vector(3 downto 0);
         we_data_o			: out std_logic_vector(3 downto 0);
         re_data_i			: in std_logic;
			--  Data tag store and bookkeeping
			addr_data_tag_o 	: out std_logic_vector((clogb2(LVL1_CACHE_SIZE/BLOCK_SIZE)-1) downto 0);
			dread_data_tag_i 	: in std_logic_vector((32-clogb2(LVL1_CACHE_SIZE)+1) downto 0);
			we_data_tag_o   	: out std_logic;
			en_data_tag_o   	: out std_logic;
			dwrite_data_tag_o	: out std_logic_vector(32-clogb2(LVL1_CACHE_SIZE)+1 downto 0);
			-- Level 2 cache
			-- port A
			dreada_lvl2_i			: in std_logic_vector(31 downto 0);
			dwritea_lvl2_o 		: out std_logic_vector(31 downto 0);
			addra_lvl2_o 			: out std_logic_vector(31 downto 0);
         wea_lvl2_o 				: out std_logic_vector(3 downto 0);
			-- port B
			dreadb_lvl2_i			: in std_logic_vector(31 downto 0);
			dwriteb_lvl2_o 		: out std_logic_vector(31 downto 0);
			addrb_lvl2_o 			: out std_logic_vector(31 downto 0);
         web_lvl2_o 				: out std_logic_vector(3 downto 0);
			-- Level 2 cache tag store and bookkeeping
			-- port A
			addra_lvl2_tag_o 		: out std_logic_vector((clogb2(LVL2_CACHE_SIZE/BLOCK_SIZE)-1) downto 0);
			dreada_lvl2_tag_i 	: in std_logic_vector((32-clogb2(LVL2_CACHE_SIZE)+1) downto 0);
			wea_lvl2_tag_o   		: out std_logic;
			ena_lvl2_tag_o   		: out std_logic;
			dwritea_lvl2_tag_o 	: out std_logic_vector((32-clogb2(LVL2_CACHE_SIZE)+1) downto 0);
			-- port B
			addrb_lvl2_tag_o 		: out std_logic_vector((clogb2(LVL2_CACHE_SIZE/BLOCK_SIZE)-1) downto 0);
			dreadb_lvl2_tag_i 	: in std_logic_vector((32-clogb2(LVL2_CACHE_SIZE)+1) downto 0);
			web_lvl2_tag_o   		: out std_logic;
			enb_lvl2_tag_o   		: out std_logic;
			dwriteb_lvl2_tag_o 	: out std_logic_vector((32-clogb2(LVL2_CACHE_SIZE)+1) downto 0)
			);
end entity;

architecture Behavioral of cache_contr_dm is

	-- DERIVE 2nd ORDER CONSTANTS
	constant BLOCK_ADDR_WIDTH : integer := clogb2(BLOCK_SIZE);
	constant LVL1C_ADDR_WIDTH : integer := clogb2(LVL1_CACHE_SIZE);
	constant LVL1C_INDEX_WIDTH : integer := LVL1C_ADDR_WIDTH - BLOCK_ADDR_WIDTH;
	constant LVL1C_TAG_WIDTH : integer := 32 - LVL1C_ADDR_WIDTH;
	constant LVL1C_BKK_WIDTH : integer := 2;
	constant LVL2C_ADDR_WIDTH : integer := clogb2(LVL2_CACHE_SIZE);
	constant LVL2C_INDEX_WIDTH : integer := LVL2C_ADDR_WIDTH - BLOCK_ADDR_WIDTH;
	constant LVL2C_TAG_WIDTH : integer := 32 - LVL2C_ADDR_WIDTH;
	constant LVL2C_BKK_WIDTH : integer := 2;

	-- SIGNALS FOR SEPARATING INPUT PORTS INTO FIELDS
	-- 'tag', 'index', 'byte in block' and 'tag store address' fields for data cache
	signal data_c_tag_s : std_logic_vector(LVL1C_TAG_WIDTH-1 downto 0);
	signal data_c_idx_s : std_logic_vector(LVL1C_INDEX_WIDTH-1 downto 0);
	signal data_c_bib_s : std_logic_vector(BLOCK_ADDR_WIDTH-1 downto 0);
	signal data_c_addr_s : std_logic_vector(LVL1C_ADDR_WIDTH-1 downto 0);
	-- 'tag' and 'bookkeeping bits: MSB - valid, LSB -dirty' fields from data tag store
	signal data_ts_tag_s : std_logic_vector(LVL1C_TAG_WIDTH-1 downto 0);
	signal data_ts_bkk_s : std_logic_vector(LVL1C_BKK_WIDTH-1 downto 0);
	-- 'tag', 'index', 'byte in block' and 'tag store address' fields for instruction cache
	signal instr_c_tag_s : std_logic_vector(LVL1C_TAG_WIDTH-1 downto 0);
	signal instr_c_idx_s : std_logic_vector(LVL1C_INDEX_WIDTH-1 downto 0);
	signal instr_c_bib_s : std_logic_vector(BLOCK_ADDR_WIDTH-1 downto 0);
	signal instr_c_addr_s : std_logic_vector(LVL1C_ADDR_WIDTH-1 downto 0);
	-- 'tag' and 'bookkeeping bits: MSB - valid, LSB -dirty' fields from instruction tag store
	signal instr_ts_tag_s : std_logic_vector(LVL1C_TAG_WIDTH-1 downto 0);
	signal instr_ts_bkk_s : std_logic_vector(LVL1C_BKK_WIDTH-1 downto 0);
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
	signal data_tag_cmp_s  : std_logic;
	signal instr_tag_cmp_s  : std_logic;
	signal lvl2a_tag_cmp_s  : std_logic;
	signal lvl2b_tag_cmp_s  : std_logic;
	-- SIGNALS TO INDICATE CACHE HITS/MISSES
	signal data_c_hit_s  : std_logic;
	signal instr_c_hit_s  : std_logic;
	signal lvl2a_c_hit_s  : std_logic;
	signal lvl2b_c_hit_s  : std_logic;

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
	data_c_tag_s <= addr_data_i(31 downto LVL1C_ADDR_WIDTH);
	data_c_idx_s <= addr_data_i(LVL1C_ADDR_WIDTH-1 downto BLOCK_ADDR_WIDTH);
	data_c_bib_s <= addr_data_i(BLOCK_ADDR_WIDTH-1 downto 0);
	data_c_addr_s <= addr_data_i(LVL1C_ADDR_WIDTH-1 downto 0);
	-- From instruction cache
	instr_c_tag_s <= addr_instr_i(31 downto LVL1C_ADDR_WIDTH);
	instr_c_idx_s <= addr_instr_i(LVL1C_ADDR_WIDTH-1 downto BLOCK_ADDR_WIDTH);
	instr_c_bib_s <= addr_instr_i(BLOCK_ADDR_WIDTH-1 downto 0);
	instr_c_addr_s <= addr_instr_i(LVL1C_ADDR_WIDTH-1 downto 0);
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
	data_ts_bkk_s <= dread_data_tag_i(LVL1C_TAG_WIDTH+LVL1C_BKK_WIDTH-1 downto LVL1C_TAG_WIDTH);
	-- Instruction tag store
	addr_instr_tag_o <= instr_c_idx_s;
	instr_ts_tag_s <= dread_instr_tag_i(LVL1C_TAG_WIDTH-1 downto 0);
	instr_ts_bkk_s <= dread_instr_tag_i(LVL1C_TAG_WIDTH+LVL1C_BKK_WIDTH-1 downto LVL1C_TAG_WIDTH);
	-- lvl2 tag store, data port
	addra_lvl2_tag_o <= lvl2a_c_idx_s;
	lvl2a_ts_tag_s <= dreada_lvl2_tag_i(LVL2C_TAG_WIDTH-1 downto 0);
	lvl2a_ts_bkk_s <= dreada_lvl2_tag_i(LVL2C_TAG_WIDTH+LVL2C_BKK_WIDTH-1 downto LVL2C_TAG_WIDTH);
	-- lvl2 tag store, instruction port
	addrb_lvl2_tag_o <= lvl2b_c_idx_s;
	lvl2b_ts_tag_s <= dreadb_lvl2_tag_i(LVL2C_TAG_WIDTH-1 downto 0);
	lvl2b_ts_bkk_s <= dreadb_lvl2_tag_i(LVL2C_TAG_WIDTH+LVL2C_BKK_WIDTH-1 downto LVL2C_TAG_WIDTH);

	
	-- Compare tags
	data_tag_cmp_s <= '1' when data_c_tag_s = data_ts_tag_s else '0';
	instr_tag_cmp_s <= '1' when instr_c_tag_s = instr_ts_tag_s else '0';
	lvl2a_tag_cmp_s <= '1' when lvl2a_c_tag_s = lvl2a_ts_tag_s else '0'; 
	lvl2b_tag_cmp_s <= '1' when lvl2b_c_tag_s = lvl2b_ts_tag_s else '0'; 
	
	-- Cache hit/miss indicator flags => same tag + valid
	data_c_hit_s <= data_tag_cmp_s and data_ts_bkk_s(1); 
	instr_c_hit_s <= instr_tag_cmp_s and instr_ts_bkk_s(1);
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
	addrb_lvl2_o <= lvl2b_c_idx_s & icc_counter_next & "00"; -- index adresses a block in cache, counter & 00 adress 4 bytes at a time
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

	fsm_data : process(icc_state_reg, instr_c_hit_s) is
	begin
	we_data_tag_o <= '0';
	dwrite_data_tag_o <= (others => '0');

	dcc_state_next <= idle;
	dcc_counter_next <= (others => '0');

	data_ready_o <= '0';

	dread_data_o <= dread_data_i;
	dwrite_data_o <= dwrite_data_i;
	we_data_o <= we_data_i;
	addr_data_o <= addr_data_i;
	addra_lvl2_o <= lvl2a_c_idx_s & dcc_counter_next & "00"; -- index adresses a block in cache, counter & 00 adress 4 bytes at a time
		case (dcc_state_reg) is
			when idle =>
				data_ready_o <= '1';
				if(data_c_hit_s = '1') then -- instr cache miss
					if(we_data_i /= "0000") then
						we_data_tag_o <= '1';
						dwrite_data_tag_o <= data_ts_bkk_s(1) & '1' & data_ts_tag_s; -- set dirty
					end if;
				else
					if(lvl2a_c_hit_s = '1')then
						if(data_ts_bkk(0)='1')then
							dcc_state_next <= flush;
						else
							dcc_state_next <= fetch;
						end if;
					else
						dcc_state_next <= wait4lvl2; -- lvl2 doesn't have data
					end if;
				end if;
			when flush => 
				if(dcc_counter_reg = dcc_counter_max)then 

					dcc_state_next <= fetch;
				else
					dcc_state_next <= flush;
				end if;
			when fetch => 
				addr_data_o <= data_c_idx_s & icc_counter_reg & 00;
				dwrite_data_o <= dreada_lvl2_i;
				dcc_counter_next <= dcc_counter_incr;
				if(dcc_counter_reg = dcc_counter_max)then 
					-- finished with writing entire block
					dcc_state_next <= idle;
					-- write new tag to tag store, set valid, reset dirty
					dwrite_data_tag_o <= "10" & data_c_tag_s;
					we_data_tag_o <= '1';
				else
					dcc_state_next <= fetch;
				end if;
			when wait4lvl2 =>
				--TODO implement logic
				-- fuck me why did i have to start this
		end case;
	end process;


	-- DEFAULTS, TEMPORARY, TODO WRITE CC LOGIC
	-- Defaults - instr mem
	dread_instr_o <= dread_instr_i;
	dwrite_instr_o <= dwrite_instr_i;
	we_instr_o <= we_instr_i;
	-- Defaults - data mem
	dread_data_o <= dread_data_i;
	dwrite_data_o <= dwrite_data_i;
	we_data_o <= we_data_i;

end architecture;
