--*******************************************
-- This module generates read and write addresses and enable signals for BRAM inside
-- Vector Register File (VRF). When there is a need for vector register
-- read or write, this module will start generating BRAM addreses each
-- cycle until all elements of a vector register are read or written to.
--*******************************************

library ieee;
use ieee.std_logic_1164.all;
use work.clogb2_pkg.all;
use ieee.numeric_std.all;

entity VRF_BRAM_addr_generator is
   generic(MAX_VECTOR_LENGTH : natural := 64;
           NUM_OF_LANES      : natural := 1);
   port (
      clk   : in std_logic;
      reset : in std_logic;
      -- control signals

      vrf_type_of_access_i : in std_logic_vector(1 downto 0);  --there are r/w, r, w,and /
      -- input signals
      vs1_address_i        : in std_logic_vector(4 downto 0);
      vs2_address_i        : in std_logic_vector(4 downto 0);
      vd_address_i         : in std_logic_vector(4 downto 0);

      vector_length_i   : in  std_logic_vector(clogb2(MAX_VECTOR_LENGTH) -1 downto 0);
      -- output signals
      BRAM1_r_address_o : out std_logic_vector(clogb2(MAX_VECTOR_LENGTH*32) - 1 downto 0);
      BRAM1_w_address_o : out std_logic_vector(clogb2(MAX_VECTOR_LENGTH*32) - 1 downto 0);
      BRAM1_we_o        : out std_logic;
      BRAM1_re_o        : out std_logic;

      BRAM2_r_address_o : out std_logic_vector(clogb2(MAX_VECTOR_LENGTH*32) - 1 downto 0);
      BRAM2_w_address_o : out std_logic_vector(clogb2(MAX_VECTOR_LENGTH*32) - 1 downto 0);
      BRAM2_we_o        : out std_logic;
      BRAM2_re_o        : out std_logic;

      ready_o : out std_logic
      );
end entity;

architecture behavioral of VRF_BRAM_addr_generator is
   --**************************CUSTOM TYPES*************************************   
   type access_type is (read_and_write, only_write, only_read, no_access);

   --  This table contains starting addresses of every vector register inside BRAM
   type lookup_table_of_vr_indexes is array (0 to 31) of std_logic_vector(clogb2(MAX_VECTOR_LENGTH*32) - 1 downto 0);
   --***************************************************************************

   -- ******************FUNCTION DEFINITIONS NEEDED FOR THIS MODULE*************
   -- Purpose of this function is initialization of a look_up_table_of_vr_indexes;
   -- Parameter: MAX_VECTOR_LENGTH - is the distance between two vector registers
   function init_lookup_table (MAX_VECTOR_LENGTH : in natural) return lookup_table_of_vr_indexes is
      variable lookup_table_v : lookup_table_of_vr_indexes;
   begin
      for i in lookup_table_of_vr_indexes'range loop
         lookup_table_v(i) := std_logic_vector(to_unsigned(i * MAX_VECTOR_LENGTH, clogb2(MAX_VECTOR_LENGTH*32)));
      end loop;
      return lookup_table_v;
   end function;

   --**************************CONSTANTS****************************************
   -- Each lane has 32 vector register, and this constant describes the amount of
   -- elements per vector register.
   constant vector_reg_num_of_elements_c : integer := MAX_VECTOR_LENGTH/NUM_OF_LANES;

   constant one_c : unsigned(clogb2(vector_reg_num_of_elements_c) - 1 downto 0) := to_unsigned(1, clogb2(vector_reg_num_of_elements_c));
   --***************************************************************************

   --********************SIGNALS NEEDED FOR SEQUENTIAL LOGIC********************
   -- Conter_reg counts from 0 to num_of_elements inside a single vector
   -- register, and is needed for BRAM address generation
   signal counter_reg, counter_next                   : std_logic_vector(clogb2(vector_reg_num_of_elements_c) - 1 downto 0);
   signal BRAM12_w_address_reg, BRAM12_w_address_next : std_logic_vector(clogb2(MAX_VECTOR_LENGTH*32) - 1 downto 0);
   signal BRAM12_we_next, BRAM12_we_reg               : std_logic;
   --***************************************************************************

   --********************SIGNALS NEEDED FOR COMBINATIONAL LOGIC*****************
   signal index_lookup_table_s : lookup_table_of_vr_indexes := init_lookup_table(MAX_VECTOR_LENGTH);
   signal type_of_access_s     : access_type;


   --// **************************ARCHITECTURE BEGIN**************************************
   
begin
   type_of_access_s <= read_and_write when vrf_type_of_access_i = "00" else
                       only_write when vrf_type_of_access_i = "01" else
                       only_read  when vrf_type_of_access_i = "10" else
                       no_access;

   --*********************************SEQUENTIAL LOGIC************************************
   process (clk) is
   begin
      if (rising_edge(clk)) then
         if (reset = '1') then
            counter_reg          <= (others => '0');
            BRAM12_w_address_reg <= (others => '0');
            BRAM12_we_reg        <= '0';
         else
            counter_reg          <= counter_next;
            BRAM12_w_address_reg <= BRAM12_w_address_next;
            BRAM12_we_reg        <= BRAM12_we_next;
         end if;
      end if;
   end process;

   --********************************COMBINATION LOGIC*************************************      
   read_counter : process (counter_reg, vector_length_i, type_of_access_s)
   begin
      counter_next <= std_logic_vector(unsigned(counter_reg) + one_c);
      if (counter_reg = vector_length_i or type_of_access_s = no_access) then
         counter_next <= (others => '0');
      end if;
   end process;

   BRAM12_w_address_next <= std_logic_vector(unsigned(index_lookup_table_s(to_integer(unsigned(vd_address_i)))) + unsigned(counter_reg));
   -- BRAM12_w_address_next  <= "00000"&std_logic_vector(unsigned(counter_reg) + unsigned(vd_address_i));
   BRAM12_we_next        <= '1' when (type_of_access_s = read_and_write or type_of_access_s = only_write) else
                     '0';

   --**************************************OUTPUTS******************************************
   --BRAM read and write enable outputs
   BRAM1_re_o <= '1' when type_of_access_s = read_and_write or type_of_access_s = only_read else
                 '0';
   BRAM2_re_o <= '1' when type_of_access_s = read_and_write or type_of_access_s = only_read else
                 '0';
   BRAM1_we_o <= BRAM12_we_next when type_of_access_s = only_write else
                 BRAM12_we_reg when type_of_access_s = read_and_write else
                 '0';
   BRAM2_we_o <= BRAM12_we_next when type_of_access_s = only_write else
                 BRAM12_we_reg when type_of_access_s = read_and_write else
                 '0';

   --BRAM address outputs
   BRAM1_r_address_o <= std_logic_vector(unsigned(index_lookup_table_s(to_integer(unsigned(vs1_address_i)))) + unsigned(counter_reg));
   BRAM2_r_address_o <= std_logic_vector(unsigned(index_lookup_table_s(to_integer(unsigned(vs2_address_i)))) + unsigned(counter_reg));




   BRAM1_w_address_o <= BRAM12_w_address_next when type_of_access_s = only_write else
                        BRAM12_w_address_reg when type_of_access_s = read_and_write else
                        (others => '0');
   BRAM2_w_address_o <= BRAM12_w_address_next when type_of_access_s = only_write else
                        BRAM12_w_address_reg when type_of_access_s = read_and_write else
                        (others => '0');

   --control signals ouptus
   ready_o <= '1' when counter_reg = std_logic_vector(to_unsigned(0, clogb2(vector_reg_num_of_elements_c))) else
              '0';
end behavioral;
