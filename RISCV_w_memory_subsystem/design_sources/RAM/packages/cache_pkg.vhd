library ieee;
use ieee.std_logic_1164.all;

-- TODO RAM initialization functions need to be defined in this package
-- TODO Paths in RAM initialization function need to be relative, so tcl scripting will work
package cache_pkg is
    function clogb2 (depth: in natural) return integer;

	-- Physical adress size and width
		constant PHY_ADDR_SPACE : integer := 512*1024*1024;
		constant PHY_ADDR_WIDTH : integer := clogb2(PHY_ADDR_SPACE);
	-- Block size is 64 bytes, this can be changed, as long as it is power of 2
		constant BLOCK_SIZE : integer := 64;
	-- Number of bits needed to address all bytes inside the block
		constant BLOCK_ADDR_WIDTH : integer := clogb2(BLOCK_SIZE);

	-- Basic Level 1 cache parameters:
	-- This will be size of both instruction and data caches in bytes
		constant LVL1_CACHE_SIZE : integer := 4096; 
	-- Derived cache parameters:
	-- Number of blocks in cache
		constant LVL1C_NB_BLOCKS : integer := LVL1_CACHE_SIZE/BLOCK_SIZE; 
	-- Cache depth is size in bytes divided by word size in bytes
		constant LVL1C_DEPTH : integer := LVL1_CACHE_SIZE/4; 
		constant LVL1C_NUM_COL : integer := 4; -- fixed, word is 4 bytes
		constant LVL1C_COL_WIDTH : integer := 8; -- fixed, byte is 8 bits
	-- Number of bits needed to address all bytes inside the cache
		constant LVL1C_ADDR_WIDTH : integer := clogb2(LVL1_CACHE_SIZE);
	-- Number of bits needed to address all blocks inside the cache
		constant LVL1C_INDEX_WIDTH : integer := LVL1C_ADDR_WIDTH - BLOCK_ADDR_WIDTH;
	-- Number of bits needed to represent which block is currently in cache
		constant LVL1C_TAG_WIDTH : integer := 32 - LVL1C_ADDR_WIDTH;
	-- Number of bits needed to save bookkeeping, 1 for valid, 1 for dirty
		constant LVL1DC_BKK_WIDTH : integer := 2;
		constant LVL1IC_BKK_WIDTH : integer := 2;


	-- Basic LVL2 cache parameters:
	-- This will be size of both instruction and data caches in bytes
		constant LVL2_CACHE_SIZE : integer := 4*4096; 
	-- Derived cache parameters:
	-- Number of blocks in cache
		constant LVL2C_NB_BLOCKS : integer := LVL2_CACHE_SIZE/BLOCK_SIZE; 
	-- Cache depth is size in bytes divided by word size in bytes
		constant LVL2C_DEPTH : integer := LVL2_CACHE_SIZE/4; 
		constant LVL2C_NUM_COL : integer := 4; -- fixed, word is 4 bytes
		constant LVL2C_COL_WIDTH : integer := 8; -- fixed, byte is 8 bits
	-- Number of bits needed to address all bytes inside the cache
		constant LVL2C_ADDR_WIDTH : integer := clogb2(LVL2_CACHE_SIZE);
	-- Number of bits needed to address all blocks inside the cache
		constant LVL2C_INDEX_WIDTH : integer := LVL2C_ADDR_WIDTH - BLOCK_ADDR_WIDTH;
	-- Number of bits needed to represent which block is currently in cache
		constant LVL2C_TAG_WIDTH : integer := 32 - LVL2C_ADDR_WIDTH;
	-- Number of bits needed to save bookkeeping, 1 for valid, 1 for dirty
		constant LVL2C_BKK_WIDTH : integer := 2;

end cache_pkg;

package body cache_pkg is

	function clogb2 (depth: in natural) return integer is
	variable temp    : integer := depth;
	variable ret_val : integer := 0;
	begin
		 while temp > 1 loop
			  ret_val := ret_val + 1;
			  temp    := temp / 2;
		 end loop;
		 return ret_val;
	end function;

end package body cache_pkg;
