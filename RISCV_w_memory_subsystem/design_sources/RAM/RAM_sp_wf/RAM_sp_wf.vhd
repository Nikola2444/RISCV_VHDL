
--  Xilinx True Dual Port RAM Byte Write Read First Single Clock
--  This code implements a parameterizable true dual port memory (both ports can read and write).
--  The behavior of this RAM is when data is written, the prior memory contents at the write
--  address are presented on the output port.  If the output data is
--  not needed during writes or the last read value is desired to be retained,
--  it is suggested to use a no change RAM as it is more power efficient.
--  If a reset or enable is not necessary, it may be tied off or removed from the code.
--  Modify the parameters for the desired RAM characteristics.

library ieee;
library work;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.cache_pkg.all;
USE std.textio.all;

entity RAM_sp_wf is
generic (

    RAM_WIDTH : integer := 32;                       
    RAM_DEPTH : integer := 1024;                    -- Specify RAM depth (number of entries)
    RAM_PERFORMANCE : string := "LOW_LATENCY";      -- Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
    INIT_FILE : string := "assembly_code.txt"            -- Specify name/location of RAM initialization file if using one (leave blank if not)
    );

port (
        addra : in std_logic_vector((clogb2(RAM_DEPTH)-1) downto 0);     -- Port A Address bus, width determined from RAM_DEPTH
        dina  : in std_logic_vector(RAM_WIDTH-1 downto 0);		  -- Port A RAM input data
        clk  : in std_logic;                       			  -- Clock
        wea   : in std_logic;	  -- Port A Write enable
        ena   : in std_logic;                       			  -- Port A RAM Enable, for additional power savings, disable port when not in use
        rsta  : in std_logic;                       			  -- Port A Output reset (does not affect memory contents)
        regcea: in std_logic;                       			  -- Port A Output register enable
        douta : out std_logic_vector(RAM_WIDTH-1 downto 0)   --  Port A RAM output data
    );

end RAM_sp_wf;

architecture rtl of RAM_sp_wf is


constant C_RAM_WIDTH : integer := RAM_WIDTH;
constant C_RAM_DEPTH : integer := RAM_DEPTH;
constant C_RAM_PERFORMANCE : string := RAM_PERFORMANCE;
constant C_INIT_FILE : string := INIT_FILE;


signal douta_reg : std_logic_vector(C_RAM_WIDTH-1 downto 0) := (others => '0');

type ram_type is array (0 to C_RAM_DEPTH-1) of std_logic_vector (C_RAM_WIDTH-1 downto 0);          -- 2D Array Declaration for RAM signal

signal ram_data_a : std_logic_vector(C_RAM_WIDTH-1 downto 0) ;
-- The folowing code either initializes the memory values to a specified file or to all zeros to match hardware

impure function initramfromfile (ramfilename : in string) return ram_type is
file ramfile	: text is in ramfilename;
variable ramfileline : line;
variable i : integer := 0;

variable ram_array	: ram_type;
variable bitvec : bit_vector(C_RAM_WIDTH-1 downto 0);
begin
	 ram_array := (others => (others => '0'));
    while not endfile(ramfile) loop
        readline (ramfile, ramfileline);
        read (ramfileline, bitvec);
        ram_array(i) := to_stdlogicvector(bitvec);
        i:=i+1;
    end loop;
    return ram_array;
end function;

impure function init_from_file_or_zeroes(ramfile : string) return ram_type is
begin
    if ramfile = "assembly_code.txt" then
        return InitRamFromFile("/home/fouste/Uni/RISCV_VHDL/RV32I/simulation_sources/assembly_code.txt") ;
    else
        return (others => (others => '0'));
    end if;
end;




-- Following code defines RAM
signal ram_array : ram_type := init_from_file_or_zeroes(C_INIT_FILE);
attribute ram_style : string;
attribute ram_style of ram_array : signal is "distributed";



begin


process(clk)
begin
    if(clk'event and clk = '1') then
        if(ena = '1') then
            if(wea = '1') then
                ram_array(to_integer(unsigned(addra))) <= dina;
                ram_data_a <= dina;
            else
                ram_data_a <= ram_array(to_integer(unsigned(addra)));
            end if;
        end if;
    end if;
end process;

--  Following code generates LOW_LATENCY (no output register)
--  Following is a 1 clock cycle read latency at the cost of a longer clock-to-out timing

no_output_register : if C_RAM_PERFORMANCE = "LOW_LATENCY" generate
    douta <= ram_data_a;
end generate;

--  Following code generates HIGH_PERFORMANCE (use output register)
--  Following is a 2 clock cycle read latency with improved clock-to-out timing

output_register : if C_RAM_PERFORMANCE = "HIGH_PERFORMANCE"  generate
process(clk)
begin
    if(clk'event and clk = '1') then
        if(rsta = '1') then
            douta_reg <= (others => '0');
        elsif(regcea = '1') then
            douta_reg <= ram_data_a;
        end if;
    end if;
end process;
douta <= douta_reg;

end generate;
end rtl;


							
							
