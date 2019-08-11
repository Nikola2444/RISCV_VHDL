library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity BRAM is
   generic
      (
         WADDR : natural := 10
         );
   port
      (
         clk		: in std_logic;
         en_a_i	: in std_logic;
         en_b_i	: in std_logic;
         data_a_i	: in std_logic_vector(31 downto 0);
         data_b_i	: in std_logic_vector(31 downto 0);
         addr_a_i	: in std_logic_vector(WADDR - 1 downto 0);
         addr_b_i	: in std_logic_vector(WADDR - 1 downto 0);
         we_a_i	: in std_logic;
         we_b_i	: in std_logic;
         data_a_o	: out std_logic_vector(31 downto 0);
         data_b_o	: out std_logic_vector(31 downto 0)
         );

end BRAM;

architecture behavioral of BRAM is
   
   type ram_type is array(0 to 4*(2**WADDR)) of std_logic_vector(7 downto 0);
   signal ram_s : ram_type := (others => (others => '0'));
   
begin

   -- Port A
   process(clk, en_a_i, we_a_i, addr_a_i, ram_s)
   begin
      if(rising_edge(clk)) then
         if(en_b_i='1') then
            if(we_b_i = '1') then
               ram_s(to_integer(unsigned(addr_b_i))) <= data_b_i(31 downto 24);
               ram_s(to_integer(unsigned(addr_b_i)+1)) <= data_b_i(23 downto 16);
               ram_s(to_integer(unsigned(addr_b_i)+2)) <= data_b_i(15 downto 8);
               ram_s(to_integer(unsigned(addr_b_i)+3)) <= data_b_i(7 downto 0);
            end if;
         end if;
         if(en_a_i='1') then
            if(we_a_i = '1') then
               ram_s(to_integer(unsigned(addr_a_i))) <= data_a_i(31 downto 24);
               ram_s(to_integer(unsigned(addr_a_i)+1)) <= data_a_i(23 downto 16);
               ram_s(to_integer(unsigned(addr_a_i)+2)) <= data_a_i(15 downto 8);
               ram_s(to_integer(unsigned(addr_a_i)+3)) <= data_a_i(7 downto 0);               
            end if;
         end if;
      end if;
      if(en_a_i='1') then
            if(we_a_i = '0') then
               data_a_o(31 downto 24) <= ram_s(to_integer(unsigned(addr_a_i)));
               data_a_o(23 downto 16) <= ram_s(to_integer(unsigned(addr_a_i)+1));
               data_a_o(15 downto 8) <= ram_s(to_integer(unsigned(addr_a_i)+2));
               data_a_o(7 downto 0) <= ram_s(to_integer(unsigned(addr_a_i)+3));
            end if;
      end if;
      if(en_b_i='1') then
         if(we_b_i = '0') then
            data_b_o(31 downto 24) <= ram_s(to_integer(unsigned(addr_b_i)));
            data_b_o(23 downto 16) <= ram_s(to_integer(unsigned(addr_b_i)+1));
            data_b_o(15 downto 8) <= ram_s(to_integer(unsigned(addr_b_i)+2));
            data_b_o(7 downto 0) <= ram_s(to_integer(unsigned(addr_b_i)+3));
         end if;
      end if;     
   end process;

end behavioral;
