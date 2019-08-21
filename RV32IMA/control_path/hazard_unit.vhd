library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity hazard_unit is
   port (
      clk: in std_logic;
      reset : in std_logic;
      
      id_ex_reg_write_i: in std_logic;
      id_ex_mem_read_i:in std_logic;
      id_ex_reg_rd_i: in std_logic_vector(4 downto 0);

      if_id_reg_rs1_i: in std_logic_vector(4 downto 0);
      if_id_reg_rs2_i: in std_logic_vector(4 downto 0);

      -- inputs needed to deal with branch data hazards
      branch_id_i: in std_logic_vector(1 downto 0);
      --control outputs
      pc_write_o: out std_logic;--controls program counter
      if_dwrite_o: out std_logic;--controls istruction fetch 
      control_stall_o: out std_logic -- controls mux that sets all the control
    -- signals to zero if stall is needed
      );
end entity;


architecture behavioral of hazard_unit is
   type stall_enum is (stall_1_clk, stall_2_clk);
   signal state_reg, state_next: stall_enum;
   signal control_group_s:std_logic_vector(2 downto 0):=(others =>'0');
begin
   process (clk)is
   begin
      if (rising_edge(clk))then
         if (reset = '0') then
            state_reg <= stall_1_clk;
         else
            state_reg <= state_next;
         end if;
      end if;
   end process;
   
   process (id_ex_mem_read_i, id_ex_reg_rd_i, id_ex_reg_write_i,
            if_id_reg_rs1_i, if_id_reg_rs2_i, branch_id_i, state_reg, state_next)is
   begin
      control_group_s <= (others =>'0');
      state_next <= state_reg;

      case state_reg is
         when stall_1_clk=>
            --non load instruction in EX, but in ID is a branch instruction. 1
            --clk stall maybe needed
            if(id_ex_reg_write_i = '1' and id_ex_mem_read_i = '0')then
               if (id_ex_reg_rd_i = if_id_reg_rs1_i and (branch_id_i = "01" or branch_id_i = "11"))then
                  control_group_s <= (others =>'1');
               elsif (id_ex_reg_rd_i = if_id_reg_rs2_i and branch_id_i = "01")then
                  control_group_s <= (others =>'1');
               end if;
               state_next <= stall_1_clk;
            end if;
            --load instruction in EX and branch instruction in ID. 2 clk stall
            --maybe needed
            if(id_ex_mem_read_i = '1' and branch_id_i /= "10")then
               control_group_s <= (others =>'1');
               state_next <= stall_2_clk;
            end if;

            --load in EX, but in ID is a non branch instruction. 1
            --clk stall maybe needed
            if (id_ex_mem_read_i = '1' and branch_id_i = "00")then               
               if((id_ex_reg_rd_i = if_id_reg_rs1_i) or (id_ex_reg_rd_i = if_id_reg_rs2_i))then
                  control_group_s <= (others =>'1');
               end if;
               state_next <= stall_1_clk;
            end if;

         when stall_2_clk=> 
            control_group_s <= (others =>'1');
            state_next <= stall_1_clk;
      end case;
   end process;

   pc_write_o <= control_group_s(0);
   if_dwrite_o <= control_group_s(1);
   control_stall_o <= control_group_s(2);
               
end architecture;
