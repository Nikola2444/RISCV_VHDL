library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.ft_pkg.all;

ENTITY ALU_ft IS
   GENERIC(
      NUM_MODULES: NATURAL := 8);
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
   signal voter_res_s: std_logic_vector(31 downto 0);
   signal alu_valid_reg,alu_valid_s: std_logic_vector(0 to NUM_MODULES-1);
   signal zero_s: std_logic_vector(NUM_MODULES downto 0);
   signal of_s: std_logic_vector(NUM_MODULES downto 0);


BEGIN


   -- GENERATES ARRAY OF ALUS
   instantiate_alus:
   for i in 0 to NUM_MODULES-1 generate
      alu_inst: entity work.ALU(behavioral)
      generic map (WIDTH => 32)
      port map (a_i => a_i,
                b_i => b_i,
                op_i => op_i,
                res_o => alu_res_array_s(i),
                zero_o => zero_s(i),
                of_o => of_s(i));
   end generate instantiate_alus;


   -- SWITCHING LOGIC
   -- First statement implements mux that forwards ALU result or all zeros to voter 
   --    based on register that keeps track of working units
   -- Second statement implements logic to change balue of mentioned register 
   switch_logic: 
   process (alu_res_array_s,alu_valid_reg,voter_res_s)is
   begin
      for i in 0 to NUM_MODULES-1 loop

         if (alu_valid_reg(i) = '0')then
            alu_sw_array_s(i) <= alu_res_array_s(i);
         else
            alu_sw_array_s(i) <= (others => '0');
         end if;

         if((alu_res_array_s(i) xor voter_res_s) = std_logic_vector(to_unsigned(0,32))) then
            alu_valid_s(i) <= '1';
         else
            alu_valid_s(i) <= '0';
         end if;

      end loop;

      
   end process;


   -- REGISTER THAT KEEPS TRACK OF WORKING UNITS
   -- Every bit represents one ALU
   -- When bit is set to 0, it means that corresponding ALU has a hardware error
   --    and that it no longer will be used to vote. It cannot change back to 1 without reset
   unit_valid_register: 
   process (clk) is
   begin
      if(rising_edge(clk))then
         if(reset='0')then
            alu_valid_reg <= (others=>'1');
         else
            alu_valid_reg <= alu_valid_reg and alu_valid_s;
         end if;
      end if;
   end process;

   -- TRESHOLD VOTER
   -- Based on multiple inputs, finds optimal as the one that is most common
   voter: entity work.treshold_voter(Behavioral)
   generic map(NUM_MODULES => NUM_MODULES)
   port map(
      voter_res_i => alu_sw_array_s,
      valid_reg_i => alu_valid_reg,
      voter_res_o => voter_res_s);


END behavioral;