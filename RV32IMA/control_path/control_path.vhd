library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity control_path is
  port (clk: in std_logic;
        reset: in std_logic;
        -- from top
        instruction_i: in std_logic_vector (31 downto 0);
        -- to datapath
		  branch_o: out std_logic;
		  mem_read_o: out std_logic;
		  mem_to_reg_o: out std_logic;
        mem_write_o: out std_logic;
        alu_src_o: out std_logic;
        reg_write_o: out std_logic
        );  
end entity;


architecture behavioral of control_path is
   signal alu_op_s: std_logic_vector(4 downto 0);
begin


end architecture;

