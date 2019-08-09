library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity immediate is
   port (instruction_i: in std_logic_vector (31 downto 0);
         immediate_extended_o: out std_logic_vector (31 downto 0));
end entity;


architecture Behavioral of immediate is
   signal opcode: std_logic_vector(6 downto 0);
   signal instruction_type: std_logic_vector(2 downto 0);
   signal signed_unsigned: std_logic;
   -- for the signal below 12 is the length of immediate field
   signal extension: std_logic_vector(19 downto 0);
   
   constant r_type_instruction: std_logic_vector(2 downto 0):= "010";
   constant i_type_instruction: std_logic_vector(2 downto 0):= "000";
   constant s_type_instruction: std_logic_vector(2 downto 0):= "001";
   constant b_type_instruction: std_logic_vector(2 downto 0):= "011";
   constant u_type_instruction: std_logic_vector(2 downto 0):= "100";
   constant j_type_instruction: std_logic_vector(2 downto 0):= "101";

begin
   opcode <= instruction_i(6 downto 0);
   extension <= (others => instruction_i(31)) when signed_unsigned='1' else
                (others => '0');
   
   --TODO nece sve instrukcije tretirati immediate kao signed, potrebno nekada prosiriti nulama, implementirati logiku za signed_unsigned bit
   signed_unsigned <= '1';
   
   process (opcode) is
   begin
      -- opcode can be optimized so we only check for two bits in it and not 7
      case opcode is
         when "0110011" =>
            instruction_type <= r_type_instruction;
         when "0000011" =>
            instruction_type <= i_type_instruction;
         when "0010011" =>
            instruction_type <= i_type_instruction;
         when "1100011" =>
            instruction_type <= b_type_instruction;
         when "0100011" =>
            instruction_type <= b_type_instruction;
         when others =>
            instruction_type <= j_type_instruction;
      end case;
   end process;
   
   process (instruction_i, extension) is
   begin
      -- opcode can be optimized so we only check for two bits in it and not 7
      case instruction_type is
         when i_type_instruction =>
            immediate_extended_o <= extension & instruction_i(31 downto 20);
         when b_type_instruction =>
            immediate_extended_o <= extension(18 downto 0) & instruction_i(31) & instruction_i(7) &
                                   instruction_i(30 downto 25) & instruction_i(11 downto 8) & '0';
         when s_type_instruction =>
            immediate_extended_o <= extension(18 downto 0) & instruction_i(31 downto 25) & instruction_i(11 downto 7);
         when u_type_instruction =>
            immediate_extended_o <= instruction_i(31 downto 12) & std_logic_vector(to_unsigned(0,12));
         when j_type_instruction =>
            immediate_extended_o <= extension(9 downto 0) & instruction_i(31) &  instruction_i(19 downto 12) &
                                    instruction_i(20) & instruction_i(30 downto 21) & '0';
         when others =>
            immediate_extended_o <= (others =>'0');
      end case;
   end process;
end architecture;
