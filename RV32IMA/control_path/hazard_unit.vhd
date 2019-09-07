library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity hazard_unit is
   port (
      rs1_address_id_i: in std_logic_vector(4 downto 0);
      rs2_address_id_i: in std_logic_vector(4 downto 0);
      branch_id_i: in std_logic_vector(1 downto 0);

      rd_address_ex_i: in std_logic_vector(4 downto 0);
      mem_to_reg_ex_i: in std_logic_vector(1 downto 0); --10 for load
      reg_write_ex_i: in std_logic;

      rd_address_mem_i: in std_logic_vector(4 downto 0);
      mem_to_reg_mem_i: in std_logic_vector(1 downto 0); --10 for load
      reg_write_mem_i: in std_logic; --

      --control outputs
      pc_write_o: out std_logic; --controls program counter
      if_id_write_o: out std_logic; --controls istruction fetch 
      control_stall_o: out std_logic -- controls mux that sets all the control signals to zero if stall is needed
      );
end entity;


architecture behavioral of hazard_unit is
   signal stall_s:std_logic:='0';
begin
   
   
   process (rs1_address_id_i, rs2_address_id_i, branch_id_i, rd_address_ex_i, reg_write_ex_i, rd_address_mem_i, mem_to_reg_ex_i, mem_to_reg_mem_i) is
   begin
      stall_s <= '0';
      if (branch_id_i = "00") then
        if((rs1_address_id_i = rd_address_ex_i) and mem_to_reg_ex_i = "10" and reg_write_ex_i = '1')then -- load in execution stage
            stall_s <='1';
         end if;
      elsif(branch_id_i = "01")then --branch in id phase
         if((rs1_address_id_i = rd_address_ex_i or rs2_address_id_i = rd_address_ex_i) and reg_write_ex_i = '1')then -- load or R-type in execution stage
            stall_s <='1';
         elsif((rs1_address_id_i = rd_address_mem_i or rs2_address_id_i = rd_address_mem_i) and mem_to_reg_mem_i = "10")then -- load in memory stage
            stall_s <='1';
         end if;
      --elsif(branch_id_i = "11")then --jalr in id phase TODO: proveri da li je potrebno 
       --  if((rs1_address_id_i = rd_address_ex_i) and reg_write_ex_i = '1')then -- load or R-type in execution stage 
         --   stall_s <='1';
      --   elsif((rs1_address_id_i = rd_address_mem_i) and mem_to_reg_mem_i = "10" and reg_write_mem_i = '1')then -- load in memory stage
       --     stall_s <='1';
       --  end if;
      end if;
   end process;

   pc_write_o <= not(stall_s);
   if_id_write_o <= not(stall_s);
   control_stall_o <= stall_s;
   
end architecture;
