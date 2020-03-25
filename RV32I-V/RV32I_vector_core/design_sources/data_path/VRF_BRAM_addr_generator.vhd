--*******************************************
-- This module is a simple FSM that generates
-- read and write addresses for BRAM inside
-- Vector Register File (VRF).

--*******************************************

library ieee;
use ieee.std_logic_1164.all;
use work.clogb2_pkg.all;
use ieee.numeric_std.all;

entity VRF_BRAM_addr_generator is
   generic(BRAM_DEPTH   : natural := 2048;
           NUM_OF_LANES : natural := 1);
   port (
      clk   : in std_logic;
      reset : in std_logic;
      -- control signals

      vrf_access_i  : in std_logic_vector(1 downto 0);  --there are r/w, r, w,and /
      -- input signals
      rv1_address_i : in std_logic_vector(4 downto 0);
      rv2_address_i : in std_logic_vector(4 downto 0);
      rd_address_i  : in std_logic_vector(4 downto 0);

      vector_length_i   : in  std_logic_vector(7 downto 0);
      -- output signals
      BRAM1_r_address_o : out std_logic_vector(clogb2(BRAM_DEPTH) - 1 downto 0);
      BRAM1_w_address_o : out std_logic_vector(clogb2(BRAM_DEPTH) - 1 downto 0);
      BRAM1_we_o        : out std_logic;
      BRAM1_re_o        : out std_logic;

      BRAM2_r_address_o : out std_logic_vector(clogb2(BRAM_DEPTH) - 1 downto 0);
      BRAM2_w_address_o : out std_logic_vector(clogb2(BRAM_DEPTH) - 1 downto 0);
      BRAM2_we_o        : out std_logic;
      BRAM2_re_o        : out std_logic;

      ready : std_logic
      );
end entity;

architecture behavioral of VRF_BRAM_addr_generator is
   --**************************ENUMERATIONS*************************************   
   type access_type is (read_and_write, only_write, only_read, no_access);
   --***************************************************************************
   --**************************CONSTANTS****************************************
   -- Each lane has 32 vector register, and this constant describes the amount of
   -- elements per vector register.
   constant vector_reg_num_of_elements_c : integer := BRAM_DEPTH/32/NUM_OF_LANES;

   constant one_c : std_logic_vector(clogb2(vector_reg_num_of_elements_c) - 1 downto 0) := std_logic_vector(to_unsigned(1, clogb2(vector_reg_num_of_elements_c)));
   --***************************************************************************

   --********************SIGNALS NEEDED FOR SEQUENTIAL LOGIC********************
   -- Number of elements per vector register in a single lane is the maximum value
   -- counter_s can reach.
   signal read_counter_reg, read_counter_next         : std_logic_vector(clogb2(vector_reg_num_of_elements_c) - 1 downto 0);
   signal BRAM12_w_address_reg, BRAM12_w_address_next : std_logic_vector(clogb2(BRAM_DEPTH) - 1 downto 0);
   signal BRAM12_we_next, BRAM12_we_reg: std_logic;
   --***************************************************************************

   --********************SIGNALS NEEDED FOR COMBINATIONAL LOGIC*****************   
   signal access_type_s : access_type_s;
begin
   access_type_s <= vrf_access_i;

   --*********************************SEQUENTIAL LOGIC************************************
   process (clk) is
   begin
      if (rising_edge(clk)) then
         if (reset = '1') then
            read_counter_reg     <= (others => '0');
            BRAM12_w_address_reg <= (others => '0');
            BRAM12_we_reg <= '0';
         else
            read_counter_reg     <= read_counter_next;
            BRAM12_w_address_reg <= BRAM12_w_address_next;
            BRAM12_we_reg <= BRAM12_we_next;
         end if;
      end if;
   end process;

   --********************************COMBINATION LOGIC*************************************      
   read_counter : process (clk, read_counter_next, read_counter_reg)
   begin      
      read_counter_next <= read_counter_reg + one_c;
      if (read_counter_next = vector_length_i or access_type_s = no_access) then
         read_counter_next <= (others => '0');
      end if;
   end process;

   BRAM12_w_address_next <= vector_reg_num_of_elements_c * rd_address_i + read_counter_reg;
   BRAM12_we_next <= '1' when access_type_s = read_write or access_type_s = only_write else
                    '0';
   
   --**************************************OUTPUTS******************************************
   --BRAM read enable outputs
   BRAM1_re_o            <= '1' when access_type_s = read_write or access_type_s = only_read else
                            '0';
   BRAM2_re_o            <= '1' when access_type_s = read_write or access_type_s = only_read else
                            '0';
   BRAM1_we_o            <= BRAM12_we_reg when access_type_s = read_write else
                            BRAM12_we_next;
   BRAM2_we_o            <= BRAM12_we_reg when access_type_s = read_write else
                            BRAM12_we_next;

   --BRAM adress outputs
   BRAM1_r_address_o  <= vector_reg_num_of_elements_c * rv1_address_i + read_counter_reg;
   BRAM2_r_address_o  <= vector_reg_num_of_elements_c * rv2_address_i + read_counter_reg;
   BRAM12_w_address_o <= BRAM12_w_address_next when access_type_s = only_write else
                         BRAM12_w_address_reg;

   --control signals ouptus
   ready <= '1' when read_counter_reg /= (others => '0') else
            '0';
end behavioral;
