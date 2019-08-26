library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity hazard_unit is
   port (
      read_reg1_id_i: in std_logic_vector(4 downto 0);
      read_reg2_id_i: in std_logic_vector(4 downto 0);
      branch_id_i: in std_logic_vector(1 downto 0);

      mem_read_ex_i:in std_logic;
      write_reg_ex_i: in std_logic_vector(4 downto 0);
      reg_write_ex_i: in std_logic;

      --mem_read_mem_i:in std_logic;
      write_reg_mem_i: in std_logic_vector(4 downto 0);
      mem_to_reg_mem_i: in std_logic_vector(1 downto 0); --10 for load

      --control outputs
      pc_write_o: out std_logic;--controls program counter
      if_id_write_o: out std_logic;--controls istruction fetch 
      control_stall_o: out std_logic -- controls mux that sets all the control signals to zero if stall is needed
      );
end entity;


architecture behavioral of hazard_unit is
   signal stall_s:std_logic:='0';
begin
   
   
   process (read_reg1_id_i, read_reg2_id_i, branch_id_i, write_reg_ex_i, reg_write_ex_i, write_reg_mem_i, mem_to_reg_mem_i) is
   begin
      stall_s <= '0';
      if (branch_id_i = "00" and mem_read_ex_i = '1') then
         if(read_reg1_id_i = write_reg_ex_i or read_reg2_id_i = write_reg_ex_i) then
            stall_s <='1';            
         end if;
      elsif(branch_id_i = "01")then --branch in id phase
         if((read_reg1_id_i = write_reg_ex_i or read_reg2_id_i = write_reg_ex_i) and reg_write_ex_i = '1')then -- load or R-type in execution stage
            stall_s <='1';
         elsif((read_reg1_id_i = write_reg_mem_i or read_reg2_id_i = write_reg_mem_i) and mem_to_reg_mem_i = "10")then -- load in memory stage
            stall_s <='1';
         end if;
      elsif(branch_id_i = "11")then --jalr in id phase
         if((read_reg1_id_i = write_reg_ex_i) and reg_write_ex_i = '1')then -- load or R-type in execution stage
            stall_s <='1';
         elsif((read_reg1_id_i = write_reg_mem_i) and mem_to_reg_mem_i = "10")then -- load in memory stage
            stall_s <='1';
         end if;
      end if;
   end process;

   pc_write_o <= stall_s;
   if_id_write_o <= stall_s;
   control_stall_o <= stall_s;
   
end architecture;
