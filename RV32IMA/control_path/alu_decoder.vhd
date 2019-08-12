library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.alu_ops_pkg.all;

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
begin 

   alu_dec:process(alu_2bit_op_i,funct3_i,funct7_i)is
   begin
      --default
      alu_op_o <= "00000";

      case alu_2bit_op_i is
         when "00" => 
            alu_op_o <= add_op;
         when "01" =>
            case(funct3(2 downto 1))is
            when "00" =>
               alu_op_o <= sub_op;
            when "10" =>
               alu_op_o <= slt_op;
            when others =>
               alu_op_o <= sltu_op;
            end case;
         when others =>
            case funct3_i is
            when "000" =>
               alu_op_o <= add_op;
               if(alu_2bit_op_i = "10") then 
                  if(funct7_i(5)='1')then
                     alu_op_o <= sub_op;
                  elsif(funct7_i(0)='1')then
                     alu_op_o <= mul_op;
                  end if;
               end if;
            when "001" =>
               alu_op_o <= sll_op;
               if(alu_2bit_op_i = "10" and funct7_i(0)='1') then 
                     alu_op_o <= mulh_op;
               end if;
            when "010" =>
               alu_op_o <= slt_op;
               if(alu_2bit_op_i = "10" and funct7_i(0)='1') then 
                     alu_op_o <= mulhsu_op;
               end if;
            when "011" =>
               alu_op_o <= sltu_op;
               if(alu_2bit_op_i = "10" and funct7_i(0)='1') then 
                     alu_op_o <= mulhu_op;
               end if;
            when "100" =>
               alu_op_o <= xor_op;
               if(alu_2bit_op_i = "10" and funct7_i(0)='1') then 
                     alu_op_o <= div_op;
               end if;
            when "101" =>
               alu_op_o <= srl_op;
               if(funct7_i(5)='1')then
                  alu_op_o <= sra_op;
               end if;
               if(alu_2bit_op_i = "10" and funct7_i(0)='1') then 
                     alu_op_o <= divu_op;
               end if;
            when "110" =>
               alu_op_o <= or_op;
               if(alu_2bit_op_i = "10" and funct7_i(0)='1') then 
                     alu_op_o <= rem_op;
               end if;
            when others =>
               alu_op_o <= and_op;
               if(alu_2bit_op_i = "10" and funct7_i(0)='1') then 
                     alu_op_o <= rem_op;
               end if;
            end case;
      end case;
   end process;

end architecture;
