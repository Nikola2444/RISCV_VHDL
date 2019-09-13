library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ctrl_decoder is
   port ( -- from data_path
      opcode_i: in std_logic_vector (6 downto 0);
      -- to data_path
      branch_o: out std_logic_vector(1 downto 0);
      --mem_read_o: out std_logic;
      mem_to_reg_o: out std_logic_vector(1 downto 0);
      mem_write_o: out std_logic;
      alu_src_b_o: out std_logic;
      alu_src_a_o: out std_logic;
      reg_write_o: out std_logic;
      alu_a_zero_o: out std_logic;
      stall_rs1_o: out std_logic;
      stall_rs2_o: out std_logic;
      alu_2bit_op_o: out std_logic_vector(1 downto 0)
      
      );  
end entity;

architecture behavioral of ctrl_decoder is
begin

   contol_dec:process(opcode_i)is
   begin
      --default
      branch_o <= "00";
      --mem_read_o <= '0';
      mem_to_reg_o <= "00";
      mem_write_o <= '0';
      alu_src_b_o <= '0';
      alu_src_a_o <= '0';
      reg_write_o <= '0';
      alu_2bit_op_o <= "00";
      alu_a_zero_o <='0';
      stall_rs1_o <= '0';
      stall_rs2_o <= '0';
      case opcode_i is
         when "0000011" => --LOAD, 5v ~ funct3
            alu_2bit_op_o <= "00";
            --mem_read_o <= '1';
            mem_to_reg_o <= "10";
            alu_src_b_o <= '1';
            reg_write_o <= '1';
            stall_rs1_o <= '1';
         when "0100011" => --STORE, 3v ~ funct3
            alu_2bit_op_o <= "00";
            mem_write_o <= '1';
            alu_src_b_o <= '1';
            stall_rs1_o <= '1';
            stall_rs2_o <= '1';
         when "0110011" => --R type, 
            alu_2bit_op_o <= "10";
            reg_write_o <= '1';
            stall_rs1_o <= '1';
            stall_rs2_o <= '1';
         when "0010011" => --I type
            alu_2bit_op_o <= "11";
            alu_src_b_o <= '1';
            reg_write_o <= '1';
            stall_rs1_o <= '1';
         when "1100011" => --B type BEQ,BNE ~ funct3
            alu_2bit_op_o <= "01";
            branch_o <= "01";
         when "1101111" => -- JAL instruction
            reg_write_o <= '1';
            mem_to_reg_o <= "01";
            branch_o <= "10";      
         when "1100111" => -- JALR instruction
            mem_to_reg_o <= "01";
            reg_write_o <= '1';
            alu_src_b_o <= '1';
            branch_o <= "11";
         when "0010111" => -- AUIPC instruction
            alu_2bit_op_o <= "00";
            reg_write_o <= '1';
            alu_src_b_o <= '1';
            alu_src_a_o <= '1';
         when "0110111" => -- LUI
            alu_2bit_op_o <= "00";
            alu_a_zero_o <='1';
            reg_write_o <= '1';
            alu_src_b_o <= '1';
         when others =>
      end case;
   end process;

end architecture;
