library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use std.textio.all;
use work.txt_util.all;

entity TOP_RISCV_tb is
-- port ();
end entity;


architecture Behavioral of TOP_RISCV_tb is
   -- Operandi za rad sa fajlovima   
   file RISCV_instructions: text open read_mode is "../../../../../RISCV_tb/assembly_code.txt";   
   -- **************************************************
   signal clk: std_logic:='0';
   signal reset: std_logic;       
   --************Signali memorije sa instrukcijima****************
   signal wea_instr_s,web_instr_s: std_logic;
   signal addra_instr_s,addrb_instr_s: std_logic_vector(9 downto 0);
   signal dia_instr_s,dib_instr_s:std_logic_vector(31 downto 0);
   signal doa_instr_s,dob_instr_s:std_logic_vector(31 downto 0);
   --************Signali memorije sa podatcima***********************
   signal wea_data_s,web_data_s:std_logic;
   signal addra_data_s,addrb_data_s: std_logic_vector(9 downto 0);
   signal dia_data_s,dib_data_s:std_logic_vector(31 downto 0);
   signal doa_data_s,dob_data_s:std_logic_vector(31 downto 0);

   -- Signal pomocu koga se iz procesora prosledjuje ka memoriji sa instrukcijama
   -- adresa naredna instrukcije koju je potrebno proslediti procesoru.
   signal addrb_instr_extended_s:std_logic_vector(31 downto 0);

   -- Signal pomocu koga se iz procesora prosledjuje ka memoriji sa podatcima
   -- adresa na koju se upisuje naredni podatak.
   signal addra_data_extended_s:std_logic_vector(31 downto 0);

begin

   addrb_instr_s <= addrb_instr_extended_s(9 downto 0); --Suzenje addrb_instr_s signala
   addra_data_s  <= addra_data_extended_s(9 downto 0); --Suzenje addra_data_extended_s signala
   web_instr_s <= '0';
   dib_instr_s <= (others => '0');

   --********************INSTR_MEMORY****************************
   -- Interface A : Koristi se prilikom inicijalizacije memorije sa instrukcijama.
   -- Interface B : Koristi se za citanje instrukcija od strane procesora.
   instruction_mem: entity work.BRAM(behavioral)
      generic map(WADDR => 10)
      port map (clk=> clk,
                en_a_i => '1',    -- memory always enabled
                en_b_i => '1',
                we_a_i => wea_instr_s,
                we_b_i => web_instr_s,
                addr_a_i => addra_instr_s,
                addr_b_i => addrb_instr_s,
                data_a_i => dia_instr_s,
                data_b_i => dib_instr_s,
                data_a_o => doa_instr_s,
                data_b_o => dob_instr_s);

   --********************DATA_MEMORY*****************************
   -- Interface A : Koristi se od strane procesora kako bi citao ili pisao podatke.
   -- Interface B : Ne koristi se.
   data_mem: entity work.BRAM(behavioral)
      generic map(WADDR => 10)
      port map (clk=> clk,
                en_a_i => '1',    -- memorija uvek aktivna
                en_b_i => '1',
                we_a_i => wea_data_s,
                we_b_i => web_data_s,
                addr_a_i => addra_data_s,
                addr_b_i => addrb_data_s,
                data_a_i => dia_data_s,
                data_b_i => dib_data_s,
                data_a_o => doa_data_s,
                data_b_o => dob_data_s);

   --********************TOP_RISCV*******************************
   TOP_RISCV_1: entity work.TOP_RISCV
      generic map (
         DATA_WIDTH => 32)
      port map (
         clk                => clk,
         reset              => reset,
         -- ********* Interfejs za prihvat instrukcije *********
         instr_mem_read_i   => dob_instr_s,
         instr_mem_addr_o   => addrb_instr_extended_s,
         -- ********* Interfejs za prihvat i upis podataka *****
         data_mem_we_o    => wea_data_s,
         data_mem_addr_o => addra_data_extended_s,
         data_mem_read_i    => doa_data_s,
         data_mem_write_o   => dia_data_s);
   
   --******Logika za upis instrukcije iz fajla u Memoriju*********
   read_file_proc:process
      variable row: line;
      variable i: integer:= 0;
   begin
      reset <= '0';
      wea_instr_s <= '1';      
      while (not endfile(RISCV_instructions))loop         
         readline(RISCV_instructions, row);
         addra_instr_s <= std_logic_vector(to_unsigned(i, 10));
         dia_instr_s <= to_std_logic_vector(string(row));         
         i := i + 4;
         wait until rising_edge(clk);
      end loop;
      
      wea_instr_s <= '0';
      reset <= '1' after 20 ns;
      wait;
   end process;
   
   --***********************************************************   
   clk_proc: process
   begin
      clk <= '1', '0' after 100 ns;
      wait for 200 ns;
   end process;

   
   
   
end architecture;
