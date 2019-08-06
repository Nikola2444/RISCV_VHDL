library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TOP_RISCV is
  generic (WIDTH: positive := 32);
  port(clk: in std_logic;
       reset: in std_logic;
       instruction: in std_logic_vector(WIDTH - 1 downto 0);
       data_in: in std_logic_vector(WIDTH - 1 downto 0);
       data_out: out std_logic_vector(WIDTH - 1 downto 0));
end entity;

architecture structural of TOP_RISCV is
begin
  -- Data_path will be instantiated here
  data_path_1: entity work.data_path
    generic map (
      WIDTH => WIDTH)
    port map (
      clk         => clk,
      reset       => reset,
      instruction => instruction,
      data_in     => data_in,
      data_out    => data_out);
  
  --************************************

  -- Control_path will be instantiated here
  c_path: entity work.control_path(Behavioral)
    port map(clk => clk,
             reset => reset,
             opcode => instruction(6 downto 0));

  

  --************************************
end architecture;
