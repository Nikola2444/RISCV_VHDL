library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity immediate is
   generic (DATA_WIDTH: positive := 32;
            INSTRUCTION_WIDTH: positive := 32);
  port (instruction: in std_logic_vector (INSTRUCTION_WIDTH - 1 downto 0);
        immediate_extended: out std_logic_vector (DATA_WIDTH - 1 downto 0));
end entity;


architecture Behavioral of immediate is
   signal opcode: std_logic_vector(6 downto 0);
   -- for the signal below 12 is the length of immediate field
   signal extension: std_logic_vector(DATA_WIDTH - 12 - 1 downto 0);
   constant i_type_instruction: std_logic_vector(6 downto 0):= std_logic_vector(to_unsigned(3, 7));
   constant s_type_instruction: std_logic_vector(6 downto 0):= std_logic_vector(to_unsigned(35, 7));
begin
   opcode <= instruction(6 downto 0);
   extension <= (others => instruction(INSTRUCTION_WIDTH - 1));
   process (instruction, extension) is
   begin
      -- opcode can be optimized so we only check for two bits in it and not 7
      case opcode is
         when i_type_instruction =>
            immediate_extended <= extension & instruction(31 downto 20);
         when s_type_instruction =>
            --shift left 1 was not included because our processors instructions
            --have 4 bytes offset architecture.
            immediate_extended <= extension & instruction(31 downto 25) & instruction(11 downto 7);
         when others => null;
      end case;
   end process;
end architecture;
