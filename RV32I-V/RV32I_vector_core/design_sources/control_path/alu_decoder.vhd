library ieee;
use ieee.std_logic_1164.all;
use work.custom_functions_pkg.all;
use work.alu_ops_pkg.all;
use work.instruction_fields_constants_pkg.all;

entity vector_alu_decoder is
    port(alu_2_bit_op_i: in std_logic_vector(1 downto 0);
         funct3_i: in std_logic_vector(5 downto 0);
         funct6_i: in std_logic_vector(5 downto 0);
         vm_i: in std_logic;
         immediate_sign_o: out std_logic;
         alu_src_a_i: out std_logic_vector(1 downto 0);
         type_of_masking_o: out std_logic;
         alu_op_o: out std_logic_vector(4 downto 0));
end entity;



architecture beh of vector_alu_decoder is

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
                
        end case;
    end process;
end beh;
