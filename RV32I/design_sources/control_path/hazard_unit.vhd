library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity hazard_unit is
   port (
      -- inputs
      rs1_address_id_i : in  std_logic_vector(4 downto 0);
      rs2_address_id_i : in  std_logic_vector(4 downto 0);
      rs1_in_use_i     : in  std_logic;
      rs2_in_use_i     : in  std_logic;
      rd_address_ex_i  : in  std_logic_vector(4 downto 0);
      mem_to_reg_ex_i  : in  std_logic_vector(1 downto 0);
		-- control outputs
      pc_en_o          : out std_logic;
      if_id_en_o       : out std_logic;
      control_pass_o   : out std_logic
      );
end entity;


architecture behavioral of hazard_unit is
   signal en_s        : std_logic := '0';
begin

   -- stalls pipeline when hazard is detected by setting enable signals to zero
   hazard_det: process (rs1_address_id_i, rs2_address_id_i, rd_address_ex_i, 
            mem_to_reg_ex_i, rs1_in_use_i, rs2_in_use_i) is
   begin
		-- Load in ex.st. 
		-- Its loading the value that is used in the next instruction (id.st.)
		-- => stall the pipeline
		if(((rs1_address_id_i = rd_address_ex_i and rs1_in_use_i = '1') or
			 (rs2_address_id_i = rd_address_ex_i and rs2_in_use_i = '1')) and
			mem_to_reg_ex_i = "10") then
			en_s <= '0';
		else
		-- defualt, dont do anything
			en_s <= '1'; 
		end if;
   end process;

	-- if '0' stalls pc register
   pc_en_o        <= en_s;
	-- if '0' stalls if/id register and instruction memory
   if_id_en_o     <= en_s;
	-- when pipeline needs to stall this output if set to '0' 
	--    flushes control signals in ID/EX stage to stop them from changing anything
   control_pass_o <= en_s;

end architecture;
