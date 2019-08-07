LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;


entity register_bank is
  generic (WIDTH: positive:= 32);
  port (clk: in std_logic;
        reset: in std_logic;

        reg_write: in std_logic;
        
        read_reg1: in std_logic_vector(4 downto 0);
        read_reg2: in std_logic_vector(4 downto 0);

        read_data1: out std_logic_vector(WIDTH - 1 downto 0);
        read_data2: out std_logic_vector(WIDTH - 1 downto 0);

        write_reg: in std_logic_vector(4 downto 0);
        write_data: in std_logic_vector(WIDTH - 1 downto 0));

  
end entity;

architecture Behavioral of register_bank is
  type reg_bank is array  (0 to 31) of std_logic_vector(31 downto 0);
  signal reg_bank_i: reg_bank := (others => (others => '0'));
  
begin

  reg_bank_write: process (clk) is
  begin
    if (falling_edge(clk))then      
        if (reg_write = '1') then
          reg_bank_i(to_integer(unsigned(write_reg))) <= write_data;
        end if;
      end if;      
  end process;

  reg_bank_read: process (clk) is
  begin
    if (rising_edge(clk))then
      if (reset = '0')then
        reg_bank_i <= (others => (others => '0'));
      else
        read_data1 <= reg_bank_i(to_integer(unsigned(read_reg1)));
        read_data2 <= reg_bank_i(to_integer(unsigned(read_reg2)));
      end if;
    end if;          
  end process;
  
end architecture;
