library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ctrl_decoder is
   port ( -- from data_path
      opcode_i: in std_logic_vector (6 downto 0);
      -- to data_path
      branch_o: out std_logic;
      mem_read_o: out std_logic;
      mem_to_reg_o: out std_logic_vector(1 downto 0);
      mem_write_o: out std_logic;
      alu_src_b_o: out std_logic;
      alu_src_a_o: out std_logic;
      reg_write_o: out std_logic;
      alu_2bit_op_o: out std_logic_vector(1 downto 0)
      );  
end entity;

architecture behavioral of ctrl_decoder is
begin

   contol_dec:process(opcode_i)is
   begin
      --default
      branch_o <= '0';
      mem_read_o <= '0';
      mem_to_reg_o <= "00";
      mem_write_o <= '0';
      alu_src_b_o <= '0';
      alu_src_a_o <= '0';
      reg_write_o <= '0';
      alu_2bit_op_o <= "00";

      case opcode_i(6 downto 2) is
         when "00000" => --LOAD, 5v ~ funct3
            alu_2bit_op_o <= "00";
            mem_read_o <= '1';
            mem_to_reg_o <= "10";
            alu_src_b_o <= '1';
            reg_write_o <= '1';
         when "01000" => --STORE, 3v ~ funct3
            alu_2bit_op_o <= "00";
            mem_write_o <= '1';
            alu_src_b_o <= '1';
         when "01100" => --R type, 
            alu_2bit_op_o <= "10";
            reg_write_o <= '1';
         when "00100" => --I type
            alu_2bit_op_o <= "11";
            alu_src_b_o <= '1';
            reg_write_o <= '1';
         when "11000" => --B type BEQ,BNE ~ funct3
            alu_2bit_op_o <= "01";
            branch_o <= '1';
         when "11011" => -- JAL instruction
            reg_write_o <= '1';
            mem_to_reg_o <= "01";
            branch_o <= '1';
         when "11001" => -- JALR instruction
            mem_to_reg_o <= "01";
            reg_write_o <= '1';
            alu_src_b_o <= '1';
            branch_o <= '1';
         when "00101" => -- AUIPC instruction
            alu_2bit_op_o <= "00";
            reg_write_o <= '1';
            alu_src_b_o <= '1';
            alu_src_a_o <= '1';
         when others =>
      end case;
   end process;

end architecture;
