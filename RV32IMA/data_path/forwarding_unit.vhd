library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity forwarding_unit is
   port (
      -- ex_mem inputs
      ex_mem_reg_write: in std_logic;
      ex_mem_reg_rd: in std_logic_vector(4 downto 0);
      
      -- mem_wb inputs
      mem_wb_reg_write: in std_logic;
      mem_wb_reg_rd: in std_logic_vector(4 downto 0);

      -- id_ex inputs
      id_ex_reg_rs1: in std_logic_vector(4 downto 0);
      id_ex_reg_rs2: in std_logic_vector(4 downto 0);

      --if_id inputs
      if_id_reg_rs1: in std_logic_vector(4 downto 0);
      if_id_reg_rs2: in std_logic_vector(4 downto 0);
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
   forward_proc:process(ex_mem_reg_write, ex_mem_reg_rd, mem_wb_reg_write, mem_wb_reg_rd,
                        id_ex_reg_rs1, id_ex_reg_rs2)is
   begin
      forward_a <= "00";
      forward_b <= "00";
      -- forwarding from WB stage
      if (mem_wb_reg_write = '1' and mem_wb_reg_rd /= zero_c)then
         if (mem_wb_reg_rd = id_ex_reg_rs1)then
            forward_a <= "01";
         elsif(mem_wb_reg_rd = id_ex_reg_rs2)then
            forward_b <= "01";            
         end if;   
      end if;
      -- forwarding from MEM stage
      if (ex_mem_reg_write = '1' and ex_mem_reg_rd /= zero_c)then
         if (ex_mem_reg_rd = id_ex_reg_rs1)then
            forward_a <= "10";
         elsif (ex_mem_reg_rd = id_ex_reg_rs2)then
            forward_b <= "10";
         end if;
      end if;      
   end process;


   --process that checks whether forwarding is needed for branch instructions in
   --ID stage or not.
   -- forwarding from MEM stage has advantage over forwading information from WB
   -- stage, because information contained there is more fresh than in WB.
   forward_branch_proc:process(ex_mem_reg_write, ex_mem_reg_rd, mem_wb_reg_write, mem_wb_reg_rd,
                               if_id_reg_rs1, if_id_reg_rs2)is
   begin
      forward_branch_b <= "00";
      forward_branch_a <= "00";
      -- forwarding from WB stage
      if (mem_wb_reg_write = '1' and mem_wb_reg_rd /= zero_c)then
         if (mem_wb_reg_rd = if_id_reg_rs1)then
            forward_branch_a <= "01";
         elsif(mem_wb_reg_rd = if_id_reg_rs2)then
            forward_branch_b <= "01";
         end if;   
      end if;
      -- forwarding from MEM stage
      if (ex_mem_reg_write = '1' and ex_mem_reg_rd /= zero_c)then
         if (ex_mem_reg_rd = if_id_reg_rs1)then
            forward_branch_a <= "10";
         elsif (ex_mem_reg_rd = if_id_reg_rs2)then
            forward_branch_b <= "10";
         end if;
      end if;      
   end process;
end architecture;
