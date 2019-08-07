library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu_decoder is
  port ( -- from data_path
        alu_2bit_op_i: in std_logic_vector(1 downto 0);
        funct3_i: in std_logic_vector (2 downto 0);
        funct7_i: in std_logic_vector (6 downto 0);
         -- to data_path
        alu_op_o: out std_logic_vector(4 downto 0)
        );  
end entity;

architecture behavioral of alu_decoder is
   constant add_op: std_logic_vector (4 downto 0):="00010";
   constant sub_op: std_logic_vector (4 downto 0):="00110";
   constant and_op: std_logic_vector (4 downto 0):="00000";
   constant or_op: std_logic_vector (4 downto 0):="00001";
begin

   alu_dec:process(alu_2bit_op_i,funct3_i,funct7_i)is
   begin
      --default
      alu_op_o <= "00000";

      case alu_2bit_op_i is
         when "00" => 
            alu_op_o <= add_op;
         when "01" =>
            alu_op_o <= sub_op;
         when others =>
            if(funct3_i = "000") then
               if(funct7_i(5)='1') then
                  alu_op_o <= add_op;
               else
                  alu_op_o <= sub_op;
               end if;
            elsif(funct3_i = "111") then
               alu_op_o <= and_op;
            else
               alu_op_o <= or_op;
            end if;
      end case;
   end process;

end architecture;
