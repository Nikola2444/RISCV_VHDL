LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;


entity register_bank is
   generic (WIDTH: positive:= 32);
   port (clk: in std_logic;
         reset: in std_logic;

         reg_write_i: in std_logic;
         
         read_reg1_i: in std_logic_vector(4 downto 0);
         read_reg2_i: in std_logic_vector(4 downto 0);

         read_data1_o: out std_logic_vector(WIDTH - 1 downto 0);
         read_data2_o: out std_logic_vector(WIDTH - 1 downto 0);

         write_reg_i: in std_logic_vector(4 downto 0);
         write_data_i: in std_logic_vector(WIDTH - 1 downto 0));
   
end entity;

architecture Behavioral of register_bank is
   type reg_bank is array  (0 to 31) of std_logic_vector(31 downto 0);
   signal reg_bank_s: reg_bank;
   
begin

   reg_bank_write: process (clk) is
   begin
      if (falling_edge(clk))then      
         if (reset = '0')then
            reg_bank_s <= (others => (others => '0'));
         elsif (reg_write_i = '1') then
            reg_bank_s(to_integer(unsigned(write_reg_i))) <= write_data_i;
         end if;
      end if;      
   end process;

   reg_bank_read: process (read_reg1_i,read_reg2_i,reg_bank_s) is
   begin

      if(to_integer(unsigned(read_reg1_i))=0) then
         read_data1_o <= std_logic_vector(to_unsigned(0,WIDTH));
      else
         read_data1_o <= reg_bank_s(to_integer(unsigned(read_reg1_i)));
      end if;

      if(to_integer(unsigned(read_reg2_i))=0) then
         read_data2_o <= std_logic_vector(to_unsigned(0,WIDTH));
      else
         read_data2_o <= reg_bank_s(to_integer(unsigned(read_reg2_i)));
      end if;

   end process;

end architecture;
