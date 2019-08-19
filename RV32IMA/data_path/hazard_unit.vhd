library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity hazard_unit is
   port (

      id_ex_mem_read:in std_logic;
      id_ex_reg_rd: in std_logic_vector(4 downto 0);

      if_id_reg_rs1: in std_logic_vector(4 downto 0);
      if_id_reg_rs2: in std_logic_vector(4 downto 0);

      --control outputs
      pc_write: out std_logic;--controls program counter
      if_dwrite: out std_logic;--controls istruction fetch 
      control_stall: out std_logic -- controls mux that sets all the control
                                   -- signals to zero if stall is needed
      );
end entity;

architecture behavioral of hazard_unit is
begin
   hazard_proc:process(id_ex_mem_read, id_ex_reg_rd,
                       if_id_reg_rs1, if_id_reg_rs2)is
   begin
      pc_write <= '0';
      if_dwrite <= '0';
      control_stall <= '0';
      if (id_ex_mem_read = '1')then
         if(id_ex_reg_rd = if_id_reg_rs1)then
            pc_write <= '1';
            if_dwrite <= '1';
            control_stall <= '1';
         elsif(id_ex_reg_rd = if_id_reg_rs2)then
            pc_write <= '1';
            if_dwrite <= '1';
            control_stall <= '1';
         end if;
      end if;
   end process;      
end architecture;
