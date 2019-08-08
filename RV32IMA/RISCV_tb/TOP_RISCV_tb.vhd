library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use std.textio.all;
use work.txt_util.all;
use work.util_pkg.all;

entity TOP_RISCV_tb is
-- port ();
end entity;


architecture Behavioral of TOP_RISCV_tb is
   -- file operands
   constant NUM_COL: integer := 2;   -- number of column of file
   file RISCV_instructions: text open read_mode is "/home/nikola/Documents/git_repos/RISCV_VHDL/RV32IMA/RISCV_tb/assembly_code.txt";
   type t_integer_array       is array(integer range <> )  of integer;
   signal instruction_read: std_logic_vector(31 downto 0);
   -- **************************************************
   
   signal clk                : std_logic:= '0';
   signal reset              : std_logic;
   signal instruction_i      : std_logic_vector(31 downto 0);
   signal pc_o               : std_logic_vector(31 downto 0);
   signal mem_ext_write_o    : std_logic;
   signal ext_data_address_o : std_logic_vector(31 downto 0);
   signal read_ext_data_i    : std_logic_vector(31 downto 0);
   signal write_ext_data_o   : std_logic_vector(31 downto 0);

   --Instruction_mem_signals
   signal pi_clka_s,pi_clkb_s,pi_ena_s,pi_enb_s,pi_wea_s,pi_web_s:std_logic;
   signal pi_addra_s,pi_addrb_s: std_logic_vector(9 downto 0);
   signal pi_dia_s,pi_dib_s:std_logic_vector(31 downto 0);
   signal po_doa_s,po_dob_s:std_logic_vector(31 downto 0);
   -- pi_addra extension bacause 32 bit address for instruction mem isn't supported
   constant address_extend: std_logic_vector (21 downto 0):=(others => '0');
   signal pi_addrb_s_extended:std_logic_vector(31 downto 0);
   --Data_mem_signals
   signal pi_clka_s_d,pi_clkb_s_d,pi_ena_s_d,pi_enb_s_d,pi_wea_s_d,pi_web_s_d:std_logic;
   signal pi_addra_s_d,pi_addrb_s_d: std_logic_vector(9 downto 0);
   signal pi_dia_s_d,pi_dib_s_d:std_logic_vector(31 downto 0);
   signal po_doa_s_d,po_dob_s_d:std_logic_vector(31 downto 0);

   -- pi_addra extension bacause 32 bit address for data mem isn't supported
   signal pi_addra_s_d_extended:std_logic_vector(31 downto 0);
begin
   pi_addrb_s_extended <= address_extend & pi_addrb_s;
   pi_addra_s_d_extended <= address_extend & pi_addra_s_d;
   -- memories always enabled
   instruction_mem: entity work.BRAM
      generic map(WADDR => 10,
                  WDATA => 32)
      port map (pi_clka => clk,
                pi_clkb => clk,
                pi_ena => '1',    -- memorie always enabled
                pi_enb => '1',
                pi_wea => pi_wea_s,
                pi_web => pi_web_s,
                pi_addra => pi_addra_s,
                pi_addrb => pi_addrb_s,
                pi_dia => pi_dia_s,
                pi_dib => pi_dib_s,
                po_doa => po_doa_s,
                po_dob => po_dob_s);


   data_mem: entity work.BRAM
      generic map(WADDR => 10,
                  WDATA => 32)
      port map (pi_clka => clk,
                pi_clkb => clk,
                pi_ena => '1',    -- memorie always enabled
                pi_enb => '1',
                pi_wea => pi_wea_s_d,
                pi_web => pi_web_s_d,
                pi_addra => pi_addra_s_d,
                pi_addrb => pi_addrb_s_d,
                pi_dia => pi_dia_s_d,
                pi_dib => pi_dib_s_d,
                po_doa => po_doa_s_d,
                po_dob => po_dob_s_d);


   --******TOP_RISCV instance**********************
   TOP_RISCV_1: entity work.TOP_RISCV
      generic map (
         DATA_WIDTH => 32)
      port map (
         clk                => clk,
         reset              => reset,
         instruction_i      => po_dob_s,
         pc_o               => pi_addrb_s_extended,         
         mem_ext_write_o    => pi_wea_s_d,
         ext_data_address_o => pi_addra_s_d_extended,
         read_ext_data_i    => po_dob_s_d,
         write_ext_data_o   => po_dob_s_d);
   
   --******Filling instruction MEM*****************
   read_file_proc:process
      variable row: line;
      variable i: integer:= 0;
   begin
      pi_ena_s <= '1';
      pi_wea_s <= '1';      
      while (not endfile(RISCV_instructions))loop         
         readline(RISCV_instructions, row);
         pi_addra_s <= std_logic_vector(to_unsigned(i, 10));
         pi_dia_s <= to_std_logic_vector(string(row));
         instruction_read <= to_std_logic_vector(string(row));
         i := i + 1;
         wait until rising_edge(clk);
      end loop;
      pi_ena_s <= '0';
      pi_wea_s <= '0';
      wait;
   end process;
   --****************************************************

   
   clk_proc: process
   begin
      clk <= '1', '0' after 100 ns;
      wait for 200 ns;
   end process;

   
   
   
end architecture;
