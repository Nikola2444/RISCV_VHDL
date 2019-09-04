library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.ft_pkg.all;

ENTITY ALU_ft IS
   GENERIC(
      NUM_MODULES: NATURAL := 3);
   PORT(
      clk  :  IN   STD_LOGIC;
      reset  :  IN   STD_LOGIC;
      a_i  :  IN   STD_LOGIC_VECTOR(31 DOWNTO 0); 
      b_i  :  IN   STD_LOGIC_VECTOR(31 DOWNTO 0);
      op_i  :  IN   STD_LOGIC_VECTOR(4 DOWNTO 0); 
      res_o   :  OUT  STD_LOGIC_VECTOR(31 DOWNTO 0); 
      zero_o   :  OUT  STD_LOGIC;
      of_o   :  OUT  STD_LOGIC);
END ALU_ft;




ARCHITECTURE behavioral OF ALU_ft IS
   
   
   signal alu_res_array_s : array32_t (0 to NUM_MODULES-1);
   signal alu_sw_array_s : array32_t (0 to NUM_MODULES-1);
   signal alu_valid_reg,alu_valid_next,alu_valid_s: std_logic_vector(31 downto 0);
   signal zero_s: std_logic_vector(NUM_MODULES downto 0);
   signal of_s: std_logic_vector(NUM_MODULES downto 0);


BEGIN


   instantiate_alus:
   for i in 0 to NUM_MODULES generate
      alu_inst: entity work.ALU(behavioral)
      generic map (WIDTH => WIDTH)
      port map (a_i => a_i,
                b_i => b_i,
                res_s => alu_res_array_s(i),
                zero_o => zero_s(i),
                of_o => of_s(i));

      alu_sw_array(i) <= alu_res_array(i) when alu_valid_reg(i) = '0' else
                      (others => '0');

      alu_valid_s(i) <= '1' when (IZLAZ_VOTERA xor REZULTAT_OVOG_ALUA) = (others => '0') else -- TODO nadji prave signale
                        '0';

   switch_logic:
   process is
   begin
      
   end process;

   end generate instantiate_alus;

   entity work.treshold_voter(behavioral) -- TODO instanciraj voter

   reg: process (clk) is
   begin
      if(rising_edge(clk))then
         if(reset='0')then
            alu_valid_reg <= (others=>'1');
         else
            alu_valid_reg <= alu_valid_next and alu_valid_s;
         end if;
      end if;
   end process;
   alu_valid_next <= alu_valid_reg;



END behavioral;
