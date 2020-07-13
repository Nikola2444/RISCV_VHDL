library ieee;
use ieee.std_logic_1164.all;
use work.custom_functions_pkg.all;
use work.alu_ops_pkg.all;

entity vector_alu_decoder is
   port(alu_2_bit_op_i: in std_logic_vector(1 downto 0);
        funct6_i: in std_logic_vector(5 downto 0);
        alu_op_o: out std_logic_vector(4 downto 0));
end entity;



architecture beh of vector_alu_decoder is
   constant v_add_c: std_logic_vector(5 downto 0):= "000000";
   constant v_sub_c: std_logic_vector(5 downto 0):= "000010";
   constant v_and_c: std_logic_vector(5 downto 0):= "001001";
   constant v_or_c: std_logic_vector(5 downto 0) := "001010";
   constant v_xor_c: std_logic_vector(5 downto 0):= "001011";
begin

   alu_dec: process (alu_2_bit_op_i, funct6_i) is
   begin
      alu_op_o <= (others => '0');
      case alu_2_bit_op_i is
         when "00" =>
            alu_op_o <= add_op;
         when "01" =>
         when "10" =>
         when "11" =>
            case funct6_i is
               when v_add_c =>
                  alu_op_o <= add_op;
               when v_sub_c =>
                  alu_op_o <= sub_op;
               when v_and_c =>
                  alu_op_o <= and_op;
               when v_or_c =>
                  alu_op_o <= or_op;
               when v_xor_c =>
                  alu_op_o <= xor_op;
               when others =>
                  
            end case;                        
      end case;
   end process;
end beh;
