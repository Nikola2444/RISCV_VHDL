library ieee;
use ieee.std_logic_1164.all;
use work.custom_functions_pkg.all;
use ieee.numeric_std.all;

entity VRF_BRAM_addr_generator is
   generic(VECTOR_LENGTH : natural := 1024;
           DATA_WIDTH: natural := 32
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

      vmul_i : in std_logic_vector (1 downto 0);
      --vector_length_i tells us how many elements there are per vector register
      vector_length_i   : in  std_logic_vector(clogb2(VECTOR_LENGTH/DATA_WIDTH) downto 0);
      -- output signals
      BRAM1_r_address_o : out std_logic_vector(clogb2(VECTOR_LENGTH) - 1 downto 0);
      BRAM2_r_address_o : out std_logic_vector(clogb2(VECTOR_LENGTH) - 1 downto 0);

      BRAM_w_address_o : out std_logic_vector(clogb2(VECTOR_LENGTH) - 1 downto 0);
      BRAM_we_o        : out std_logic;
      BRAM_re_o        : out std_logic;

      ready_o : out std_logic
      );
end entity;

architecture behavioral of VRF_BRAM_addr_generator is

   type lookup_table_of_vr_indexes is array (0 to 31) of std_logic_vector(clogb2(VECTOR_LENGTH) - 1 downto 0);


      -- ******************FUNCTION DEFINITIONS NEEDED FOR THIS MODULE*************
   -- Purpose of this function is initialization of a look_up_table_of_vr_indexes;
   -- Parameter: VECTOR_LENGTH - is the distance between two vector registers
   function init_lookup_table (VECTOR_LENGTH : in natural) return lookup_table_of_vr_indexes is
      variable lookup_table_v : lookup_table_of_vr_indexes;
   begin
      for i in lookup_table_of_vr_indexes'range loop
         lookup_table_v(i) := std_logic_vector(to_unsigned(i * VECTOR_LENGTH, clogb2(VECTOR_LENGTH)));
      end loop;
      return lookup_table_v;
   end function;
   --***************************************************************************************

   constant concat_bits: std_logic_vector(clogb2(VECTOR_LENGTH/DATA_WIDTH)  downto 0) := (others => '0');
   constant no_access_c      : std_logic_vector(1 downto 0) := "11";
   constant read_and_write_c : std_logic_vector(1 downto 0) := "00";
   constant only_read_c      : std_logic_vector(1 downto 0) := "10";
   constant only_write_c     : std_logic_vector(1 downto 0) := "01";
   constant one_c : unsigned(clogb2(VECTOR_LENGTH/DATA_WIDTH)  + 3 downto 0) := to_unsigned(1, clogb2(VECTOR_LENGTH/DATA_WIDTH) + 4);


   signal index_lookup_table_s : lookup_table_of_vr_indexes := init_lookup_table(VECTOR_LENGTH);
   signal vector_len_shifted_s: std_logic_vector (clogb2(VECTOR_LENGTH/DATA_WIDTH)  + 3 downto 0);
   signal bram_vs1_index_s: std_logic_vector(clogb2(VECTOR_LENGTH) - 1 downto 0);
   signal bram_vs2_index_s: std_logic_vector(clogb2(VECTOR_LENGTH) - 1 downto 0);
   signal bram_vd_index_s: std_logic_vector(clogb2(VECTOR_LENGTH) - 1 downto 0);
   signal bram_vs1_index_vmul_shifted_s: std_logic_vector(clogb2(VECTOR_LENGTH) - 1 downto 0);
   signal bram_vs2_index_vmul_shifted_s: std_logic_vector(clogb2(VECTOR_LENGTH) - 1 downto 0);
   signal bram_vd_index_vmul_shifted_s: std_logic_vector(clogb2(VECTOR_LENGTH) - 1 downto 0);
   --+3 takes into account the shift that happens when vmul > 1
   signal v_len_s: std_logic_vector(clogb2(VECTOR_LENGTH/DATA_WIDTH)  + 3 downto 0);

   signal finished_with_gen_s:std_logic;
      --+3 takes into account the shift that happens when vmul > 1
   signal counter1_reg_s, counter1_next_s : std_logic_vector(clogb2(VECTOR_LENGTH/DATA_WIDTH) + 3 downto 0);
      --+3 takes into account the shift that happens when vmul > 1
   signal counter2_reg_s, counter2_next_s : std_logic_vector(clogb2(VECTOR_LENGTH/DATA_WIDTH)  + 3 downto 0);

   
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

   
   --generate v_len_s taking vmul into account
   process (vector_length_i, vmul_i)is
   begin
      case vmul_i is
         when "00"=>
            vector_len_shifted_s <= "000"&vector_length_i;
         when "01" =>            
            vector_len_shifted_s <= "00"&vector_length_i&'0';
         when "10" =>
            vector_len_shifted_s <= "0"&vector_length_i&"00";
         when "11" =>
            vector_len_shifted_s <= vector_length_i&"000";
         when others =>
      end case;
   end process;
   
   v_len_s <= std_logic_vector(unsigned(vector_len_shifted_s) - one_c);
   
   counter_increment : process (counter1_reg_s, v_len_s, vrf_type_of_access_i, counter2_reg_s)
   begin
      counter1_next_s <= std_logic_vector(unsigned(counter1_reg_s) + one_c);
      if (vrf_type_of_access_i = no_access_c) then
         counter1_next_s <= counter1_reg_s;         
      end if;
      if (vrf_type_of_access_i = read_and_write_c) then
         if (counter2_reg_s = v_len_s) then
            counter1_next_s <= (others => '0');
         end if;
      else
         if (counter1_reg_s = v_len_s) then
            counter1_next_s <= (others => '0');
         end if;
      end if;
   end process;

   --counter 1 enables counting of counter 2
   rw_counter_increment : process (counter2_reg_s, v_len_s, counter1_reg_s, alu_exe_time_i, vrf_type_of_access_i)
   begin
      counter2_next_s <= counter2_reg_s;
      if (counter1_reg_s > (concat_bits&alu_exe_time_i) and vrf_type_of_access_i = read_and_write_c) then
         counter2_next_s <= std_logic_vector(unsigned(counter2_reg_s) + one_c);
      end if;
      if (counter2_reg_s = v_len_s) then
         counter2_next_s <= (others => '0');
      end if;
   end process;

   -- ready gen logic
   rdy_proc: process(vrf_type_of_access_i, counter2_reg_s, counter1_reg_s, v_len_s)is
   begin
      ready_o <= '0';
      if (vrf_type_of_access_i = no_access_c)then
         ready_o <= '1';
      elsif (vrf_type_of_access_i = read_and_write_c) then
         if (counter2_reg_s = v_len_s) then
            ready_o <='1';
         end if;
      else
         if (counter1_reg_s = v_len_s) then
            ready_o <='1';
         end if;
      end if;
   end process;

   --write_en logic
   we_proc: process (counter1_reg_s, vrf_type_of_access_i, alu_exe_time_i) is
   begin
      BRAM_we_o <= '0';
      if (vrf_type_of_access_i = read_and_write_c) then
         if (counter1_reg_s > concat_bits&alu_exe_time_i) then
            BRAM_we_o <= '1';
         else
            BRAM_we_o <= '0';
         end if;
      elsif (vrf_type_of_access_i = only_write_c) then
         BRAM_we_o <= '1';
      end if;      
   end process;
   


   BRAM_re_o <= '1';


   bram_vs1_index_s <= std_logic_vector(unsigned(index_lookup_table_s(to_integer(unsigned(vs1_address_i)))));
   bram_vs2_index_s <= std_logic_vector(unsigned(index_lookup_table_s(to_integer(unsigned(vs2_address_i)))));
   bram_vd_index_s <= std_logic_vector(unsigned(index_lookup_table_s(to_integer(unsigned(vd_address_i)))));
   process (vmul_i, vs1_address_i, vs2_address_i, vd_address_i, bram_vs1_index_s,
            bram_vs2_index_s, bram_vd_index_s)is
   begin
      case vmul_i is
         when "00"=>
            bram_vs1_index_vmul_shifted_s <= bram_vs1_index_s;
            bram_vs2_index_vmul_shifted_s <= bram_vs2_index_s;
            bram_vd_index_vmul_shifted_s <= bram_vd_index_s;
         when "01" =>            
            bram_vs1_index_vmul_shifted_s <= bram_vs1_index_s(clogb2(VECTOR_LENGTH) - 2 downto 0)&'0';
            bram_vs2_index_vmul_shifted_s <= bram_vs2_index_s(clogb2(VECTOR_LENGTH) - 2 downto 0)&'0';            
            bram_vd_index_vmul_shifted_s <= bram_vd_index_s(clogb2(VECTOR_LENGTH) - 2 downto 0)&'0';
         when "10" =>
            bram_vs1_index_vmul_shifted_s <= bram_vs1_index_s(clogb2(VECTOR_LENGTH) - 3 downto 0)&"00";
            bram_vs2_index_vmul_shifted_s <= bram_vs2_index_s(clogb2(VECTOR_LENGTH) - 3 downto 0)&"00";
            bram_vd_index_vmul_shifted_s <= bram_vd_index_s(clogb2(VECTOR_LENGTH) - 3 downto 0)&"00";
         when "11" =>            
            bram_vs1_index_vmul_shifted_s <= bram_vs1_index_s(clogb2(VECTOR_LENGTH) - 4 downto 0)&"000";            
            bram_vs2_index_vmul_shifted_s <= bram_vs2_index_s(clogb2(VECTOR_LENGTH) - 4 downto 0)&"000";            
            bram_vd_index_vmul_shifted_s <= bram_vd_index_s(clogb2(VECTOR_LENGTH) - 4 downto 0)&"000";
         when others =>
      end case;
   end process;

                       
   
   BRAM1_r_address_o <= std_logic_vector(unsigned(bram_vs1_index_vmul_shifted_s) + unsigned(counter1_reg_s));
   BRAM2_r_address_o <= std_logic_vector(unsigned(bram_vs2_index_vmul_shifted_s) + unsigned(counter1_reg_s));


   -- Sredi i ovo tako da uzimas u obzir vmul !!
   BRAM_w_address_o <= std_logic_vector(unsigned(bram_vd_index_vmul_shifted_s) + unsigned(counter2_reg_s))
                       when vrf_type_of_access_i= read_and_write_c else
                       std_logic_vector(unsigned(bram_vd_index_vmul_shifted_s) + unsigned(counter1_reg_s));
end behavioral;
