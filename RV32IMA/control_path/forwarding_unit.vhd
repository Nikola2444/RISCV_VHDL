library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity forwarding_unit is
   port (
      -- ex_mem inputs
      reg_write_mem_i: in std_logic;
      rd_reg_mem_i: in std_logic_vector(4 downto 0);
      
      -- mem_wb inputs
      write_reg_wb_i: in std_logic;
      rd_reg_wb_i: in std_logic_vector(4 downto 0);

      -- id_ex inputs
      rs1_reg_ex_i: in std_logic_vector(4 downto 0);
      rs2_reg_ex_i: in std_logic_vector(4 downto 0);

      --if_id inputs
      rs1_reg_id_i: in std_logic_vector(4 downto 0);
      rs2_reg_id_i: in std_logic_vector(4 downto 0);
      --forward control outputs
      forward_a: out std_logic_vector (1 downto 0);
      forward_b: out std_logic_vector(1 downto 0);
      --forward control outputs
      --They control multiplexers infront of equality test
      forward_branch_a: out std_logic_vector (1 downto 0); -- mux a 
      forward_branch_b: out std_logic_vector(1 downto 0)-- mux b
      );
end entity;

architecture Behavioral of forwarding_unit is
   constant zero_c: std_logic_vector (31 downto 0) := std_logic_vector(to_unsigned(0, 32));
begin

   
   --process that checks whether forwarding for instructions in EX stage is needed or not.
   -- forwarding from MEM stage has advantage over forwading information from WB
   -- stage, because information contained there is more fresh than in WB.
   forward_proc:process(reg_write_mem_i, rd_reg_mem_i, write_reg_wb_i, rd_reg_wb_i,
                        rs1_reg_ex_i, rs2_reg_ex_i)is
   begin
      forward_a <= "00";
      forward_b <= "00";
      -- forwarding from WB stage
      if (write_reg_wb_i = '1' and rd_reg_wb_i /= zero_c)then
         if (rd_reg_wb_i = rs1_reg_ex_i)then
            forward_a <= "01";
         elsif(rd_reg_wb_i = rs2_reg_ex_i)then
            forward_b <= "01";            
         end if;   
      end if;
      -- forwarding from MEM stage
      if (reg_write_mem_i = '1' and rd_reg_mem_i /= zero_c)then
         if (rd_reg_mem_i = rs1_reg_ex_i)then
            forward_a <= "10";
         elsif (rd_reg_mem_i = rs2_reg_ex_i)then
            forward_b <= "10";
         end if;
      end if;      
   end process;


   --process that checks whether forwarding is needed for branch instructions in
   --ID stage or not.
   -- forwarding from MEM stage has advantage over forwading information from WB
   -- stage, because information contained there is more fresh than in WB.
   forward_branch_proc:process(reg_write_mem_i, rd_reg_mem_i, write_reg_wb_i, rd_reg_wb_i,
                               rs1_reg_id_i, rs2_reg_id_i)is
   begin
      forward_branch_b <= "00";
      forward_branch_a <= "00";
      -- forwarding from WB stage
      if (write_reg_wb_i = '1' and rd_reg_wb_i /= zero_c)then
         if (rd_reg_wb_i = rs1_reg_id_i)then
            forward_branch_a <= "01";
         elsif(rd_reg_wb_i = rs2_reg_id_i)then
            forward_branch_b <= "01";
         end if;   
      end if;
      -- forwarding from MEM stage
      if (reg_write_mem_i = '1' and rd_reg_mem_i /= zero_c)then
         if (rd_reg_mem_i = rs1_reg_id_i)then
            forward_branch_a <= "10";
         elsif (rd_reg_mem_i = rs2_reg_id_i)then
            forward_branch_b <= "10";
         end if;
      end if;      
   end process;
end architecture;
