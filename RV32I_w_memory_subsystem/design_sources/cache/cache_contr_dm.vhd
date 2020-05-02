library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use work.ram_pkg.all;

entity cache_contr_dm is
generic (BLOCK_WIDTH : natural := 3;
			CACHE_WIDTH : natural := 8);
	port (clk : in std_logic;
			reset : in std_logic;
			-- controller drives ce for RISC
			ce_o : out std_logic;
			-- Instruction memory
			dread_instr_i: in std_logic_vector(31 downto 0);
			dread_instr_o: out std_logic_vector(31 downto 0);
			dwrite_instr_i: in std_logic_vector(31 downto 0);
			dwrite_instr_o: out std_logic_vector(31 downto 0);
			addr_instr_i: in std_logic_vector(31 downto 0);
         we_instr_i: in std_logic_vector(3 downto 0);
         we_instr_o: out std_logic_vector(3 downto 0);
			-- Data memory
			dread_data_i: in std_logic_vector(31 downto 0);
			dread_data_o: out std_logic_vector(31 downto 0);
			dwrite_data_i: in std_logic_vector(31 downto 0);
			dwrite_data_o: out std_logic_vector(31 downto 0);
			addr_data_i: in std_logic_vector(31 downto 0);
         we_data_i: in std_logic_vector(3 downto 0);
         we_data_o: out std_logic_vector(3 downto 0)
			);
end entity;

architecture Behavioral of cache_contr_dm is

	constant INDEX_WIDTH : integer := CACHE_WIDTH - BLOCK_WIDTH;
	constant TAG_WIDTH : integer := 32 - CACHE_WIDTH;
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
