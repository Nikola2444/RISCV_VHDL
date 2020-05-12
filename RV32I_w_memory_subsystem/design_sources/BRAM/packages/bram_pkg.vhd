library ieee;
use ieee.std_logic_1164.all;

-- TODO RAM initialization functions need to be defined in this package
-- TODO Paths in RAM initialization function need to be relative, so tcl scripting will work
package ram_pkg is
    function clogb2 (depth: in natural) return integer;

	-- Block size is 64 bytes, this can be changed, as long as it is power of 2
		constant BLOCK_SIZE : integer := 64;
	-- Number of bits needed to address all bytes inside the block
		constant BLOCK_AWIDTH : integer := clogb2(BLOCK_SIZE);

	-- Basic Level 1 cache parameters:
	-- This will be size of both instruction and data caches in bytes
		constant L1_CACHE_SIZE : integer := 4096; 
	-- Derived cache parameters:
	-- Number of blocks in cache
		constant L1C_NB_BLOCKS : integer := L1_CACHE_SIZE/BLOCK_SIZE; 
	-- Cache depth is size in bytes divided by word size in bytes
		constant L1C_DEPTH : integer := L1_CACHE_SIZE/4; 
		constant L1C_NUM_COL : integer := 4; -- fixed, word is 4 bytes
		constant L1C_COL_WIDTH : integer := 8; -- fixed, byte is 8 bits
	-- Number of bits needed to address all bytes inside the cache
		constant L1C_AWIDTH : integer := clogb2(L1_CACHE_SIZE);
	-- Number of bits needed to address all blocks inside the cache
		constant L1C_INDEX_AWIDTH : integer := L1C_AWIDTH - BLOCK_AWIDTH;
	-- Number of bits needed to represent which block is currently in cache
		constant L1C_TAG_AWIDTH : integer := 32 - L1C_AWIDTH;
	-- Number of bits needed to save bookkeeping, 1 for valid, 1 for dirty
		constant L1C_BKK_AWIDTH : integer := 2;


	-- Basic L2 cache parameters:
	-- This will be size of both instruction and data caches in bytes
		constant L2_CACHE_SIZE : integer := 4096; 
	-- Derived cache parameters:
	-- Number of blocks in cache
		constant L2C_NB_BLOCKS : integer := L2_CACHE_SIZE/BLOCK_SIZE; 
	-- Cache depth is size in bytes divided by word size in bytes
		constant L2C_DEPTH : integer := L2_CACHE_SIZE/4; 
		constant L2C_NUM_COL : integer := 4; -- fixed, word is 4 bytes
		constant L2C_COL_WIDTH : integer := 8; -- fixed, byte is 8 bits
	-- Number of bits needed to address all bytes inside the cache
		constant L2C_AWIDTH : integer := clogb2(L2_CACHE_SIZE);
	-- Number of bits needed to address all blocks inside the cache
		constant L2C_INDEX_AWIDTH : integer := L2C_AWIDTH - BLOCK_AWIDTH;
	-- Number of bits needed to represent which block is currently in cache
		constant L2C_TAG_AWIDTH : integer := 32 - L2C_AWIDTH;
	-- Number of bits needed to save bookkeeping, 1 for valid, 1 for dirty
		constant L2C_BKK_AWIDTH : integer := 2;

end ram_pkg;

package body ram_pkg is

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

end package body ram_pkg;
