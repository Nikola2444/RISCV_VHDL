
--*******************************************
-- This module generates read and write addresses and enable signals for BRAM inside
-- Vector Register File (VRF). When there is a need for vector register
-- read or write, this module will start generating BRAM addreses each
-- cycle until all elements of a vector register are read or written to.
--*******************************************

library ieee;
use ieee.std_logic_1164.all;
use work.custom_functions_pkg.all;
use ieee.numeric_std.all;

entity VRF_BRAM_addr_generator_2 is
   generic(VECTOR_LENGTH : natural := 64
           );
   port (
      clk   : in std_logic;
      reset : in std_logic;
      -- control signals

      vrf_type_of_access_i : in std_logic_vector(1 downto 0);  --there are r/w, r, w,and /
      alu_exe_time_i       : in std_logic_vector(2 downto 0);
      -- input signals
      vs1_address_i        : in std_logic_vector(4 downto 0);
      vs2_address_i        : in std_logic_vector(4 downto 0);
      vd_address_i         : in std_logic_vector(4 downto 0);

      vector_length_i   : in  std_logic_vector(clogb2(VECTOR_LENGTH) downto 0);
      -- output signals
      BRAM1_r_address_o : out std_logic_vector(clogb2(VECTOR_LENGTH*32) - 1 downto 0);
      BRAM2_r_address_o : out std_logic_vector(clogb2(VECTOR_LENGTH*32) - 1 downto 0);

      BRAM_w_address_o : out std_logic_vector(clogb2(VECTOR_LENGTH*32) - 1 downto 0);
      BRAM_we_o        : out std_logic;
      BRAM_re_o        : out std_logic;

      ready_o : out std_logic
      );
end entity;

architecture behavioral of VRF_BRAM_addr_generator_2 is
   

   --  This table contains starting addresses of every vector register inside BRAM
   type lookup_table_of_vr_indexes is array (0 to 31) of std_logic_vector(clogb2(VECTOR_LENGTH*32) - 1 downto 0);
   type addr_gen_states is (idle, addr_gen_read_and_write, addr_gen_only_read, addr_gen_only_write);

   constant no_access_c      : std_logic_vector(1 downto 0) := "11";
   constant read_and_write_c : std_logic_vector(1 downto 0) := "00";
   constant only_read_c      : std_logic_vector(1 downto 0) := "10";
   constant only_write_c     : std_logic_vector(1 downto 0) := "01";
   --***************************************************************************

   -- ******************FUNCTION DEFINITIONS NEEDED FOR THIS MODULE*************
   -- Purpose of this function is initialization of a look_up_table_of_vr_indexes;
   -- Parameter: VECTOR_LENGTH - is the distance between two vector registers
   function init_lookup_table (VECTOR_LENGTH : in natural) return lookup_table_of_vr_indexes is
      variable lookup_table_v : lookup_table_of_vr_indexes;
   begin
      for i in lookup_table_of_vr_indexes'range loop
         lookup_table_v(i) := std_logic_vector(to_unsigned(i * VECTOR_LENGTH, clogb2(VECTOR_LENGTH*32)));
      end loop;
      return lookup_table_v;
   end function;

   --**************************CONSTANTS****************************************
   -- Each lane has 32 vector register, and this constant describes the amount of
   -- elements per vector register.
   constant vector_reg_num_of_elements_c : integer := VECTOR_LENGTH;

   constant one_c : unsigned(clogb2(vector_reg_num_of_elements_c) - 1 downto 0) := to_unsigned(1, clogb2(vector_reg_num_of_elements_c));
   --***************************************************************************

   --********************SIGNALS NEEDED FOR SEQUENTIAL LOGIC********************
   signal state_reg, state_next           : addr_gen_states;
   -- Conter_reg counts from 0 to num_of_elements inside a single vector
   -- register, and is needed for BRAM address generation
   signal counter1_reg_s, counter1_next_s : std_logic_vector(clogb2(vector_reg_num_of_elements_c) downto 0);
   signal counter2_reg_s, counter2_next_s : std_logic_vector(clogb2(vector_reg_num_of_elements_c) downto 0);
   --***************************************************************************

   --********************SIGNALS NEEDED FOR COMBINATIONAL LOGIC*****************
   signal index_lookup_table_s : lookup_table_of_vr_indexes := init_lookup_table(VECTOR_LENGTH);

   signal vl_reached : std_logic;


   --**************************Debug****************************

   --// **************************ARCHITECTURE BEGIN**************************************

begin

   --*********************************SEQUENTIAL LOGIC************************************
   process (clk) is
   begin
      if (rising_edge(clk)) then
         if (reset = '0') then
            counter1_reg_s <= (others => '0');
            counter2_reg_s <= (others => '0');
            state_reg      <= idle;
         else
            counter1_reg_s <= counter1_next_s;
            counter2_reg_s <= counter2_next_s;
            state_reg      <= state_next;
         end if;
      end if;
   end process;

   --********************************COMBINATION LOGIC*************************************


   counter_increment : process (state_next, counter1_reg_s, vector_length_i, vrf_type_of_access_i, counter1_next_s)
   begin
      counter1_next_s <= std_logic_vector(unsigned(counter1_reg_s) + one_c);
      if (state_next = idle) then
         counter1_next_s <= (others => '0');
      else
         if (vrf_type_of_access_i = no_access_c) then
            counter1_next_s <= counter1_reg_s;
         end if;
      end if;
   end process;


   rw_counter_increment : process (counter2_reg_s, vector_length_i, counter2_next_s, counter1_reg_s, alu_exe_time_i, state_reg)
   begin
      counter2_next_s <= counter2_reg_s;
      if (counter1_reg_s > alu_exe_time_i) then
         counter2_next_s <= std_logic_vector(unsigned(counter2_reg_s) + one_c);
      end if;
      if (counter2_reg_s = vector_length_i or state_reg = idle) then
         counter2_next_s <= (others => '0');
      end if;
   end process;

   vl_reached <= '1' when counter1_reg_s = std_logic_vector(unsigned(vector_length_i) - one_c) else
                 '0';
   -- TODO: maybe set ready clk earlier
   read_write_en_gen_fsm : process (state_reg, vrf_type_of_access_i, counter1_reg_s, vector_length_i, counter1_next_s, counter2_reg_s, counter2_next_s, vl_reached)
   begin
      BRAM_re_o  <= '1';
      BRAM_we_o  <= '1';
      ready_o    <= '0';
      state_next <= idle;
      case state_reg is
         when idle =>
            if (vrf_type_of_access_i = read_and_write_c)then
               state_next <= addr_gen_read_and_write;
            elsif (vrf_type_of_access_i = only_write_c)then
               --BRAM_re_o  <= '0';               
               state_next <= addr_gen_only_write;
            elsif (vrf_type_of_access_i = only_read_c)then
               BRAM_we_o  <= '0';
               state_next <= addr_gen_only_read;
            else
               --BRAM_re_o  <= '0';
               BRAM_we_o  <= '0';
               ready_o    <= '1';
               state_next <= idle;
            end if;
         when addr_gen_read_and_write =>
            state_next <= addr_gen_read_and_write;
            if (counter2_next_s = vector_length_i)then
               --BRAM_re_o  <= '0';
               ready_o    <= '1';
               state_next <= idle;
            end if;
         when addr_gen_only_write =>
            state_next <= addr_gen_only_write;
            BRAM_we_o  <= '1';
            --BRAM_re_o  <= '0';
            if (vl_reached = '1') then
               ready_o    <= '1';
               state_next <= idle;
            end if;
         when addr_gen_only_read =>
            state_next <= addr_gen_only_read;
            if (vl_reached = '1') then
               ready_o    <= '1';
               state_next <= idle;
            end if;
      end case;
   end process;

   --**************************************OUTPUTS******************************************
   --BRAM read and write enable outputs
   --BRAM address outputs


   BRAM1_r_address_o <= std_logic_vector(unsigned(index_lookup_table_s(to_integer(unsigned(vs1_address_i)))) + unsigned(counter1_reg_s));
   BRAM2_r_address_o <= std_logic_vector(unsigned(index_lookup_table_s(to_integer(unsigned(vs2_address_i)))) + unsigned(counter1_reg_s));



   BRAM_w_address_o <= std_logic_vector(unsigned(index_lookup_table_s(to_integer(unsigned(vd_address_i)))) + unsigned(counter2_reg_s))
                       when state_reg = addr_gen_read_and_write else
                       std_logic_vector(unsigned(index_lookup_table_s(to_integer(unsigned(vd_address_i)))) + unsigned(counter1_reg_s));

--control signals ouptus   
end behavioral;
