library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity immediate is
  generic (WIDTH: positive := 32);
  port (instruction: in std_logic_vector (WIDTH - 1 downto 0);
        immediate_extended: out std_logic_vector (WIDTH - 1 downto 0));
end entity;


architecture Behavioral of immediate is
   signal opcode: std_logic_vector(6 downto 0);
   signal extension: std_logic_vector(19 downto 0);
   constant i_type_instruction: std_logic_vector(6 downto 0):= std_logic_vector(to_unsigned(3, 7));
   constant s_type_instruction: std_logic_vector(6 downto 0):= std_logic_vector(to_unsigned(35, 7));
begin
   opcode <= instruction(6 downto 0);
   extension <= (others => instruction(31));
   process (instruction, extension) is
   begin
      case opcode is
         when i_type_instruction =>
            immediate_extended <= extension & instruction(31 downto 20);
         when s_type_instruction =>
            immediate_extended <= extension & instruction(31 downto 25) & instruction (11 downto 7);
         when others => null;
      end case;
   end process;
end architecture;
