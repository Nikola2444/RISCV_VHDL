library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity BRAM is
   generic
      (
         WDATA : natural := 32;
         WADDR : natural := 10
         );
   port
      (
         clk_a		: in std_logic;
         clk_b		: in std_logic;
         en_a_i		: in std_logic;
         en_b_i		: in std_logic;
         data_a_i	: in std_logic_vector(WDATA-1 downto 0);
         data_b_i	: in std_logic_vector(WDATA-1 downto 0);
         addr_a_i	: in std_logic_vector(WADDR-1 downto 0);
         addr_b_i	: in std_logic_vector(WADDR-1 downto 0);
         we_a_i	: in std_logic;
         we_b_i	: in std_logic;
         data_a_o	: out std_logic_vector(WDATA-1 downto 0);
         data_b_o	: out std_logic_vector(WDATA-1 downto 0)
         );

end BRAM;

architecture behavioral of BRAM is

   
   type ram_type is array(0 to 2**WADDR) of std_logic_vector(WDATA - 1 downto 0);
   

   signal ram_s : ram_type := (others => (others => '0'));
   
begin

   -- Port A
   process(clk_a,en_a_i)
   begin
      if(en_a_i='1') then
         if(rising_edge(clk_a)) then
            if(we_a_i = '1') then
               ram_s(to_integer(unsigned(addr_a_i))) <= data_a_i;
            else
               data_a_o <= ram_s(to_integer(unsigned(addr_a_i)));
            end if;
         end if;
      end if;
   end process;
   -- Port B
   process(clk_b,en_b_i)
   begin
      if(en_b_i='1') then
         if(rising_edge(clk_b)) then
            if(we_b_i = '1') then
               ram_s(to_integer(unsigned(addr_b_i))) <= data_b_i;
            else
               data_b_o <= ram_s(to_integer(unsigned(addr_b_i)));
            end if;
         end if;
      end if;
   end process;
end behavioral;
