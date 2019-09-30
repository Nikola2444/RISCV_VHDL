library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity hazard_unit is
   port (
      -- inputs
      rs1_address_id_i : in std_logic_vector(4 downto 0);
      rs2_address_id_i : in std_logic_vector(4 downto 0);
      rs1_in_use_i     : in std_logic;
      rs2_in_use_i     : in std_logic;
      branch_type_id_i : in std_logic_vector(1 downto 0);
      rd_address_ex_i  : in std_logic_vector(4 downto 0);
      mem_to_reg_ex_i  : in std_logic_vector(1 downto 0);
      rd_we_ex_i       : in std_logic;
      rd_address_mem_i : in std_logic_vector(4 downto 0);
      mem_to_reg_mem_i : in std_logic_vector(1 downto 0);
      --control outputs
      -- if '0' stalls pc register
      pc_en_o          : out std_logic; 
      -- if '0' stalls if/id register and instruction memory
      if_id_en_o       : out std_logic; 
      -- when pipeline needs to stall this output if set to '0' 
      --    flushes control signals in ID/EX stage to stop them from changing anything
      control_pass_o   : out std_logic 
      );
end entity;


architecture behavioral of hazard_unit is
   signal en_s:std_logic:='0';
   signal pass_ctrl_s:std_logic:='0';
begin

   
   -- stalls pipeline when hazard is detected by setting enable signals to zero
   process (rs1_address_id_i, rs2_address_id_i, branch_type_id_i, rd_address_ex_i, rd_we_ex_i,
            rd_address_mem_i, mem_to_reg_ex_i, mem_to_reg_mem_i, rs1_in_use_i, rs2_in_use_i) is
   begin
      en_s <= '1';
      if (branch_type_id_i = "00") then -- no branch in id
         if(((rs1_address_id_i = rd_address_ex_i and rs1_in_use_i = '1') or
            (rs2_address_id_i = rd_address_ex_i and rs2_in_use_i = '1')) and
            mem_to_reg_ex_i = "10" and rd_we_ex_i = '1')then -- load in execution stage
            en_s <='0';
         end if;
      elsif(branch_type_id_i = "01")then -- branch in id phase
         if((rs1_address_id_i = rd_address_ex_i or rs2_address_id_i = rd_address_ex_i)
            and rd_we_ex_i = '1')then -- load or R-type in execution stage
            en_s <='0';
         elsif((rs1_address_id_i = rd_address_mem_i or rs2_address_id_i = rd_address_mem_i)
            and mem_to_reg_mem_i = "10")then -- load in memory stage 
            en_s <='0';
         end if;
      elsif(branch_type_id_i = "11")then --jalr in id phase
         if((rs1_address_id_i = rd_address_ex_i) and rd_we_ex_i = '1')then -- load or R-type in execution stage 
            en_s <='0';
         end if;
      end if;
   end process;

   pc_en_o         <= en_s;
   if_id_en_o      <= en_s;
   control_pass_o  <= en_s;
   
end architecture;
