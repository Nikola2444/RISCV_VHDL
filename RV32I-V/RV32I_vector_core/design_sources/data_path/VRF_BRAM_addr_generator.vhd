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
   generic(MAX_VECTOR_LENGTH : natural := 64
           );
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
   type addr_gen_states is (idle, addr_gen_read_and_write, addr_gen_only_read, addr_gen_only_write);
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
   constant vector_reg_num_of_elements_c : integer := MAX_VECTOR_LENGTH;

   constant one_c : unsigned(clogb2(vector_reg_num_of_elements_c) - 1 downto 0) := to_unsigned(1, clogb2(vector_reg_num_of_elements_c));
   --***************************************************************************

   --********************SIGNALS NEEDED FOR SEQUENTIAL LOGIC********************
   signal state_reg, state_next     : addr_gen_states;
   -- Conter_reg counts from 0 to num_of_elements inside a single vector
   -- register, and is needed for BRAM address generation
   signal counter_reg, counter_next : std_logic_vector(clogb2(vector_reg_num_of_elements_c) - 1 downto 0);
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
         if (reset = '0') then
            counter_reg <= (others => '0');
            state_reg   <= idle;
         else
            counter_reg <= counter_next;
            state_reg   <= state_next;
         end if;
      end if;
   end process;

   --********************************COMBINATION LOGIC*************************************      
   counter_increment : process (state_reg, counter_reg, vector_length_i, type_of_access_s)
   begin
      case state_reg is
         when idle =>
            counter_next <= (others => '0');            
         when addr_gen_read_and_write =>
            counter_next <= std_logic_vector(unsigned(counter_reg) + one_c);            
         when others =>
            counter_next <= std_logic_vector(unsigned(counter_reg) + one_c);            
      end case;
   end process;


   -- TODO: maybe set ready clk earlier
   read_write_en_gen_fsm : process (state_reg, type_of_access_s, counter_reg, vector_length_i)
   begin
      BRAM1_re_o <= '1';
      BRAM2_re_o <= '1';
      BRAM1_we_o <= '1';
      BRAM2_we_o <= '1';
      ready_o    <= '0';
      state_next <= idle;
      case state_reg is
         when idle =>
            if (type_of_access_s = read_and_write)then
               BRAM1_we_o <= '0';
               BRAM2_we_o <= '0';
               state_next <= addr_gen_read_and_write;
            elsif (type_of_access_s = only_write)then
               state_next <= addr_gen_only_write;
            elsif (type_of_access_s = only_read)then
               state_next <= addr_gen_only_read;
            else
               BRAM1_we_o <= '0';
               BRAM2_we_o <= '0';
               ready_o <= '1';
               state_next <= idle;
            end if;
         when addr_gen_read_and_write =>
            state_next <= addr_gen_read_and_write;
            if (counter_reg = vector_length_i)then
               BRAM1_re_o <= '0';
               BRAM2_re_o <= '0';
               ready_o <= '1';
               state_next <= idle;
            end if;
         when addr_gen_only_write =>
            state_next <= addr_gen_only_write;
            BRAM1_re_o <= '0';
            BRAM2_re_o <= '0';
            if (counter_reg = std_logic_vector(unsigned(vector_length_i) - to_unsigned(1, clogb2(vector_reg_num_of_elements_c)))) then
               ready_o <= '1';
               state_next <= idle;
            end if;
         when addr_gen_only_read =>
            state_next <= addr_gen_only_read;
            BRAM1_we_o <= '0';
            BRAM2_we_o <= '0';
            if (counter_reg = std_logic_vector(unsigned(vector_length_i) - to_unsigned(1, clogb2(vector_reg_num_of_elements_c)))) then
               state_next <= idle;
            end if;
      end case;
   end process;

   --**************************************OUTPUTS******************************************
   --BRAM read and write enable outputs
   --BRAM address outputs


   BRAM1_r_address_o <= std_logic_vector(unsigned(index_lookup_table_s(to_integer(unsigned(vs1_address_i)))) + unsigned(counter_next));
   BRAM2_r_address_o <= std_logic_vector(unsigned(index_lookup_table_s(to_integer(unsigned(vs2_address_i)))) + unsigned(counter_next));



   BRAM1_w_address_o <= std_logic_vector(unsigned(index_lookup_table_s(to_integer(unsigned(vd_address_i)))) + unsigned(counter_reg))
                        when state_reg =  addr_gen_read_and_write else
                        std_logic_vector(unsigned(index_lookup_table_s(to_integer(unsigned(vd_address_i)))) + unsigned(counter_next));
   BRAM2_w_address_o <= std_logic_vector(unsigned(index_lookup_table_s(to_integer(unsigned(vd_address_i)))) + unsigned(counter_reg))
                        when state_reg =  addr_gen_read_and_write else
                        std_logic_vector(unsigned(index_lookup_table_s(to_integer(unsigned(vd_address_i)))) + unsigned(counter_next));

--control signals ouptus   
end behavioral;
