
--  Xilinx Simple Dual Port Single Clock RAM
--  This code implements a parameterizable SDP single clock memory.
--  If a reset or enable is not necessary, it may be tied off or removed from the code.

library ieee;
use ieee.std_logic_1164.all;


library ieee;
library work;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.custom_functions_pkg.all;
use std.textio.all;

entity BRAM_18KB is
   generic (
      RAM_WIDTH       : integer := 64;  -- Specify RAM data width
      RAM_DEPTH       : integer := 512;  -- Specify RAM depth (number of entries)
      RAM_PERFORMANCE : string  := "LOW_LATENCY";  -- Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
      INIT_FILE       : string  := "RAM_INIT.dat"  -- Specify name/location of RAM initialization file if using one (leave blank if not)
      );

   port (
      write_addr_i  : in  std_logic_vector((clogb2(RAM_DEPTH)-1) downto 0);  -- Write address bus, width determined from RAM_DEPTH
      read_addr_i  : in  std_logic_vector((clogb2(RAM_DEPTH)-1) downto 0);  -- Read address bus, width determined from RAM_DEPTH
      write_data_i   : in  std_logic_vector(RAM_WIDTH-1 downto 0);  -- RAM input data
      clk   : in  std_logic;           -- Clock
      we_i    : in  std_logic;           -- Write enable
      re_i    : in  std_logic;  -- RAM Enable, for additional power savings, disable port when not in use
      rst_read_i   : in  std_logic;  -- Output reset (does not affect memory contents)
      output_reg_en_i : in  std_logic;           -- Output register enable
      read_data_o  : out std_logic_vector(RAM_WIDTH-1 downto 0)   -- RAM output data
      );

end BRAM_18KB;

architecture rtl of BRAM_18KB is

   constant C_RAM_WIDTH       : integer := RAM_WIDTH;
   constant C_RAM_DEPTH       : integer := RAM_DEPTH;
   constant C_RAM_PERFORMANCE : string  := RAM_PERFORMANCE;
   constant C_INIT_FILE       : string  := INIT_FILE;

   signal doutb_reg : std_logic_vector(C_RAM_WIDTH-1 downto 0) := (others => '0');
   type ram_type is array (C_RAM_DEPTH-1 downto 0) of std_logic_vector (C_RAM_WIDTH-1 downto 0);  -- 2D Array Declaration for RAM signal
   signal ram_data  : std_logic_vector(C_RAM_WIDTH-1 downto 0);

--**************** The folowing code either initializes the memory values to a specified file or to all zeros to match hardware*****************

   function initramfromfile (ramfilename : in string) return ram_type is
      file ramfile         : text is in ramfilename;
      variable ramfileline : line;
      variable ram_name    : ram_type;
      variable bitvec      : bit_vector(C_RAM_WIDTH-1 downto 0);

   begin
      for i in ram_type'range loop
         readline (ramfile, ramfileline);
         read (ramfileline, bitvec);
         ram_name(i) := to_stdlogicvector(bitvec);
      end loop;
      return ram_name;
   end function;

   function init_from_file_or_zeroes(ramfile : string) return ram_type is
   begin
      if ramfile = "RAM_INIT.dat" then
         return InitRamFromFile("RAM_INIT.dat");
      else
         return (others => (others => '0'));
      end if;
   end;

   function init_BRAM return ram_type is
      variable ram_v: ram_type;
   begin
      for i in ram_type'range loop
         ram_v(i) := std_logic_vector(to_unsigned(i, RAM_WIDTH));
      end loop;
      return ram_v;
   end;
   --*******************************************************************************************************************************************
   
--**************** Following code defines RAM***************************************************************************************************

   signal ram_name : ram_type := init_BRAM;

begin
   
   process(clk)
   begin
      if(clk'event and clk = '1') then
         if(we_i = '1') then
            ram_name(to_integer(unsigned(write_addr_i))) <= write_data_i;
         end if;
         if(re_i = '1') then
            ram_data <= ram_name(to_integer(unsigned(read_addr_i)));
         end if;
      end if;
   end process;

--  Following code generates LOW_LATENCY (no output register)
--  Following is a 1 clock cycle read latency at the cost of a longer clock-to-out timing

   no_output_register : if C_RAM_PERFORMANCE = "LOW_LATENCY" generate
      read_data_o <= ram_data;
   end generate;

--  Following code generates HIGH_PERFORMANCE (use output register)
--  Following is a 2 clock cycle read latency with improved clock-to-out timing

   output_register : if C_RAM_PERFORMANCE = "HIGH_PERFORMANCE" generate
      process(clk)
      begin
         if(clk'event and clk = '1') then
            if(rst_read_i = '1') then
               doutb_reg <= (others => '0');
            elsif(output_reg_en_i = '1') then
               doutb_reg <= ram_data;
            end if;
         end if;
      end process;

      read_data_o <= doutb_reg;

   end generate;

end rtl;

-- The following is an instantiation template for BRAM_18KB
-- Component Declaration
-- Uncomment the below component declaration when using
--component BRAM_18KB is
-- generic (
-- RAM_WIDTH : integer,
-- RAM_DEPTH : integer,
-- RAM_PERFORMANCE : string,
-- INIT_FILE : string
--);
--port
--(
-- write_addr_i : in std_logic_vector(clogb2(RAM_DEPTH)-1) downto 0);
-- read_addr_i : in std_logic_vector(clogb2(RAM_DEPTH)-1) downto 0);
-- write_data_i  : in std_logic_vector(RAM_WIDTH-1 downto 0);
-- clk  : in std_logic;
-- we_i   : in std_logic;
-- re_i   : in std_logic;
-- rst_read_i  : in std_logic;
-- output_reg_en_i: in std_logic;
-- read_data_o : out std_logic_vector(RAM_WIDTH-1 downto 0)
--);
--
--end component;
--
-- Instantiation
-- Uncomment the instantiation below when using
--<your_instance_name> : BRAM_18KB
-- generic map (
-- RAM_WIDTH => 18,
-- RAM_DEPTH => 1024,
-- RAM_PERFORMANCE => "HIGH_PERFORMANCE",
-- INIT_FILE => "" 
--)
--  port map  (
-- write_addr_i  => write_addr_i,
-- read_addr_i  => read_addr_i,
-- write_data_i   => write_data_i,
-- clk   => clk,
-- we_i    => we_i,
-- re_i    => re_i,
-- rsta   => rsta,
-- output_reg_en_i => output_reg_en_i,
-- read_data_o  => read_data_o
--);



