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
			-- LVL 1 CACHES
			-- Instruction cache
			dread_instr_i: in std_logic_vector(31 downto 0);
			dread_instr_o: out std_logic_vector(31 downto 0);
			dwrite_instr_i: in std_logic_vector(31 downto 0);
			dwrite_instr_o: out std_logic_vector(31 downto 0);
			addr_instr_i: in std_logic_vector(31 downto 0);
         we_instr_i: in std_logic_vector(3 downto 0);
         we_instr_o: out std_logic_vector(3 downto 0);
			-- Data cache
			dread_data_i: in std_logic_vector(31 downto 0);
			dread_data_o: out std_logic_vector(31 downto 0);
			dwrite_data_i: in std_logic_vector(31 downto 0);
			dwrite_data_o: out std_logic_vector(31 downto 0);
			addr_data_i: in std_logic_vector(31 downto 0);
         we_data_i: in std_logic_vector(3 downto 0);
         we_data_o: out std_logic_vector(3 downto 0);
			--  Instruction cache tag store and bookkeeping
			addra_instr_tag_o : out std_logic_vector((clogb2(L1_CACHE_SIZE)-1) downto 0);
			dina_instr_tag_o  : out std_logic_vector(32-clogb2(L1_CACHE_SIZE)+1 downto 0);
			wea_instr_tag_o   : out std_logic;
			ena_instr_tag_o   : out std_logic;
			douta_isntr_tag_i : in std_logic_vector(32-clogb2(L1_CACHE_SIZE)+1 downto 0);
			--  Data cache tag store and bookkeeping
			addra_data_tag_o : out std_logic_vector((clogb2(L1_CACHE_SIZE)-1) downto 0);
			dina_data_tag_o  : out std_logic_vector(32-clogb2(L1_CACHE_SIZE)+1 downto 0);
			wea_data_tag_o   : out std_logic;
			ena_data_tag_o   : out std_logic;
			douta_data_tag_i : in std_logic_vector(32-clogb2(L1_CACHE_SIZE)+1 downto 0);
			-- LVL 2 CACHES
			dread_l2_i: in std_logic_vector(31 downto 0);
			dread_l2_o: out std_logic_vector(31 downto 0);
			dwrite_l2_i: in std_logic_vector(31 downto 0);
			dwrite_l2_o: out std_logic_vector(31 downto 0);
			addr_l2_i: in std_logic_vector(31 downto 0);
         we_l2_i: in std_logic_vector(3 downto 0);
         we_l2_o: out std_logic_vector(3 downto 0);
			--  Level 2 cache tag store and bookkeeping
			addra_instr_tag_o : out std_logic_vector((clogb2(L2_CACHE_SIZE)-1) downto 0);
			dina_instr_tag_o  : out std_logic_vector(32-clogb2(L2_CACHE_SIZE)+1 downto 0);
			wea_instr_tag_o   : out std_logic;
			ena_instr_tag_o   : out std_logic;
			douta_isntr_tag_i : in std_logic_vector(32-clogb2(L2_CACHE_SIZE)+1 downto 0)
			);
end entity;

architecture Behavioral of cache_contr_dm is

	constant BLOCK_AWIDTH : integer := clogb2(BLOCK_SIZE);
	constant L1C_AWIDTH : integer := clogb2(L1_CACHE_SIZE);
	constant L1C_INDEX_AWIDTH : integer := L1C_AWIDTH - BLOCK_WIDTH;
	constant L1C_TAG_WIDTH : integer := 32 - L1C_AWIDTH;
	constant L2C_AWIDTH : integer := clogb2(L2_CACHE_SIZE);
	constant L2C_INDEX_AWIDTH : integer := L2C_AWIDTH - BLOCK_WIDTH;
	constant L2C_TAG_WIDTH : integer := 32 - L2C_AWIDTH;

begin


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
