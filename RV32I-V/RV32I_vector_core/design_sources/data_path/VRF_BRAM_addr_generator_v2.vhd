library ieee;
use ieee.std_logic_1164.all;
use work.custom_functions_pkg.all;
use ieee.numeric_std.all;

entity VRF_BRAM_addr_generator is
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

architecture behavioral of VRF_BRAM_addr_generator is
   type lookup_table_of_vr_indexes is array (0 to 31) of std_logic_vector(clogb2(VECTOR_LENGTH*32) - 1 downto 0);

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
   --***************************************************************************************

   constant concat_bits: std_logic_vector(clogb2(VECTOR_LENGTH) - 3 downto 0) := (others => '0');
   constant no_access_c      : std_logic_vector(1 downto 0) := "11";
   constant read_and_write_c : std_logic_vector(1 downto 0) := "00";
   constant only_read_c      : std_logic_vector(1 downto 0) := "10";
   constant only_write_c     : std_logic_vector(1 downto 0) := "01";
   constant one_c : unsigned(clogb2(VECTOR_LENGTH) - 1 downto 0) := to_unsigned(1, clogb2(VECTOR_LENGTH));


   signal index_lookup_table_s : lookup_table_of_vr_indexes := init_lookup_table(VECTOR_LENGTH);
   signal v_len: std_logic_vector(clogb2(VECTOR_LENGTH) downto 0);
   signal finished_with_gen_s:std_logic;
   signal counter1_reg_s, counter1_next_s : std_logic_vector(clogb2(VECTOR_LENGTH) downto 0);
   
   signal counter2_reg_s, counter2_next_s : std_logic_vector(clogb2(VECTOR_LENGTH) downto 0);

   
begin
   --*********************************SEQUENTIAL LOGIC************************************
   process (clk) is
   begin
      if (rising_edge(clk)) then
         if (reset = '0') then
            counter1_reg_s <= (others => '0');
            counter2_reg_s <= (others => '0');
         else
            counter1_reg_s <= counter1_next_s;
            counter2_reg_s <= counter2_next_s;
         end if;
      end if;
   end process;

--********************************COMBINATION LOGIC*************************************

   v_len <= std_logic_vector(unsigned(vector_length_i) - one_c);
   
   counter_increment : process (counter1_reg_s, v_len, vrf_type_of_access_i, counter2_reg_s)
   begin
      counter1_next_s <= std_logic_vector(unsigned(counter1_reg_s) + one_c);
      if (vrf_type_of_access_i = no_access_c) then
         counter1_next_s <= counter1_reg_s;         
      end if;
      if (vrf_type_of_access_i = read_and_write_c) then
         if (counter2_reg_s = v_len) then
            counter1_next_s <= (others => '0');
         end if;
      else
         if (counter1_reg_s = v_len) then
            counter1_next_s <= (others => '0');
         end if;
      end if;
   end process;

   --counter 1 enables counting of counter 2
   rw_counter_increment : process (counter2_reg_s, v_len, counter1_reg_s, alu_exe_time_i, vrf_type_of_access_i)
   begin
      counter2_next_s <= counter2_reg_s;
      if (counter1_reg_s > (concat_bits&alu_exe_time_i) and vrf_type_of_access_i = read_and_write_c) then
         counter2_next_s <= std_logic_vector(unsigned(counter2_reg_s) + one_c);
      end if;
      if (counter2_reg_s = v_len) then
         counter2_next_s <= (others => '0');
      end if;
   end process;

   -- ready gen logic
   rdy_proc: process(vrf_type_of_access_i, counter2_reg_s, counter1_reg_s, v_len)is
   begin
      ready_o <= '0';
      if (vrf_type_of_access_i = no_access_c)then
         ready_o <= '1';
      elsif (vrf_type_of_access_i = read_and_write_c) then
         if (counter2_reg_s = v_len) then
            ready_o <='1';
         end if;
      else
         if (counter1_reg_s = v_len) then
            ready_o <='1';
         end if;
      end if;
   end process;

   --write_en logic
   we_proc: process (counter1_reg_s, vrf_type_of_access_i, alu_exe_time_i) is
   begin
      BRAM_we_o <= '1';
      if (vrf_type_of_access_i = read_and_write_c) then
         if (counter1_reg_s > alu_exe_time_i) then
            BRAM_we_o <= '1';
         else
            BRAM_we_o <= '0';
         end if;
      elsif (vrf_type_of_access_i = no_access_c) then
         BRAM_we_o <= '0';
      end if;      
   end process;
   


   BRAM_re_o <= '1';
   
   BRAM1_r_address_o <= std_logic_vector(unsigned(index_lookup_table_s(to_integer(unsigned(vs1_address_i)))) + unsigned(counter1_reg_s));
   BRAM2_r_address_o <= std_logic_vector(unsigned(index_lookup_table_s(to_integer(unsigned(vs2_address_i)))) + unsigned(counter1_reg_s));



   BRAM_w_address_o <= std_logic_vector(unsigned(index_lookup_table_s(to_integer(unsigned(vd_address_i)))) + unsigned(counter2_reg_s))
                       when vrf_type_of_access_i= read_and_write_c else
                       std_logic_vector(unsigned(index_lookup_table_s(to_integer(unsigned(vd_address_i)))) + unsigned(counter1_reg_s));
end behavioral;
   
