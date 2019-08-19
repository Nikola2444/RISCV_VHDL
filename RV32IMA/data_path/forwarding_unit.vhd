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

      --forward control outputs
      forward_a: out std_logic_vector (1 downto 0);
      forward_b: out std_logic_vector(1 downto 0)                  
      );
end entity;

architecture Behavioral of forwarding_unit is
   constant zero_c: std_logic_vector (31 downto 0) := std_logic_vector(to_unsigned(0, 32));
begin
   forward_proc:process(ex_mem_reg_write, ex_mem_reg_rd, mem_wb_reg_write, mem_wb_reg_rd,
                        id_ex_reg_rs1, id_ex_reg_rs2)is
   begin
      forward_a <= "00";
      forward_b <= "00";
      if (mem_wb_reg_write = '1' and mem_wb_reg_rd /= zero_c)then
         if (mem_wb_reg_rd = id_ex_reg_rs1)then
            forward_a <= "01";
         elsif(mem_wb_reg_rd = id_ex_reg_rs2)then
            forward_b <= "01";            
         end if;   
      end if;
      if (ex_mem_reg_write = '1' and ex_mem_reg_rd /= zero_c)then
         if (ex_mem_reg_rd = id_ex_reg_rs1)then
            forward_a <= "10";
         elsif (ex_mem_reg_rd = id_ex_reg_rs2)then
            forward_b <= "10";
         end if;
      end if;
   end process;
end architecture;
