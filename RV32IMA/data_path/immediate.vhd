library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity immediate is
   generic (DATA_WIDTH: positive := 32);
   port (instruction_i: in std_logic_vector (31 downto 0);
         immediate_extended_o: out std_logic_vector (DATA_WIDTH - 1 downto 0));
end entity;


architecture Behavioral of immediate is
   signal opcode: std_logic_vector(6 downto 0);
   -- for the signal below 12 is the length of immediate field
   signal extension: std_logic_vector(DATA_WIDTH - 12 - 1 downto 0);
   constant i_type_instruction: std_logic_vector(6 downto 0):= "0000011";
   constant s_type_instruction: std_logic_vector(6 downto 0):= "1100011";
begin
   opcode <= instruction_i(6 downto 0);
   extension <= (others => instruction_i(31));
   process (instruction_i, extension, opcode) is
   begin
      -- opcode can be optimized so we only check for two bits in it and not 7
      case opcode is
         when i_type_instruction =>
            immediate_extended_o <= extension & instruction_i(31 downto 20);
         when s_type_instruction =>
            immediate_extended_o <= extension(DATA_WIDTH - 12 - 2 downto 0) & instruction_i(31) &
                                  instruction_i(29 downto 24) & instruction_i(11 downto 8) & instruction_i(30) & '0';
         when others =>
            immediate_extended_o <= (others =>'0');
      end case;
   end process;
end architecture;
