library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ctrl_decoder is
  port ( -- from data_path
        opcode_i: in std_logic_vector (6 downto 0);
         -- to data_path
		  branch_o: out std_logic;
		  mem_read_o: out std_logic;
		  mem_to_reg_o: out std_logic;
        mem_write_o: out std_logic;
        alu_src_o: out std_logic;
        reg_write_o: out std_logic;
        alu_2bit_op_o: out std_logic_vector(1 downto 0)
        );  
end entity;

architecture behavioral of control_decoder is
begin

   contol_dec:process(opcode_i)is
   begin
      --default
      branch_o <= '0';
      mem_read_o <= '0';
      mem_to_reg_o <= '0';
      mem_write_o <= '0';
      alu_src_o <= '0';
      reg_write_o <= '0';
      alu_2bit_op_o <= "00";

      case opcode_i is
         when "0000000" => 
         when others =>
      end case;
   end process;

end architecture;
