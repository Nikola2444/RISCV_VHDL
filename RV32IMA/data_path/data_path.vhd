library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity data_path is
  generic (WIDTH: positive := 32);
  port(clk: in std_logic;
       reset: in std_logic;
       instruction: in std_logic_vector(WIDTH - 1 downto 0);
       data_in: in std_logic_vector(WIDTH - 1 downto 0);
       data_out: out std_logic_vector(WIDTH - 1 downto 0));
  
-- ********* control signals need to be added *********
  
-- ****************************************************
end entity;

architecture Behavioral of data_path is
begin
  
end architecture;

