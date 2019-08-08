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

   
   type ram_type1 is array(0 to 2**WADDR - 1) of std_logic_vector(WDATA - 1 downto 0);
   

   shared variable ram_s : ram_type1:= (others => (others =>'0'));   
begin

   -- Port A
   a:process(clk_a)is
   begin
      if(rising_edge(clk_a)) then
         if(en_a_i = '1') then
            if(we_a_i = '1') then
               ram_s(to_integer(unsigned(addr_a_i))) := data_a_i;
            else
               data_a_o <= ram_s(to_integer(unsigned(addr_a_i)));
            end if;
         end if;
      end if;
   end process;
   
   -- Port B
   b:process(clk_b)is
   begin
      if(rising_edge(clk_b)) then
         if(en_b_i = '1') then
            if(we_b_i = '1') then
               ram_s(to_integer(unsigned(addr_b_i))) := data_b_i;
            else
               data_b_o <= ram_s(to_integer(unsigned(addr_b_i)));
            end if;
         end if;
      end if;
   end process;
end behavioral;
