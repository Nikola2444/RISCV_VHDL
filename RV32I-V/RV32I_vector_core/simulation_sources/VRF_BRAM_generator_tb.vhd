library ieee;
use ieee.std_logic_1164.all;
use work.clogb2_pkg.all;
use ieee.numeric_std.all;



entity VRF_BRAM_addr_generator_tb is
   generic(MAX_VECTOR_LENGTH: natural:= 64;
           NUM_OF_LANES: natural:= 1);
end entity;


architecture behavioral of VRF_BRAM_addr_generator_tb is
   signal clk                  : std_logic := '0';
   signal reset                : std_logic;
   signal vrf_type_of_access_i : std_logic_vector(1 downto 0) := "00";
   signal vs1_address_i        : std_logic_vector(4 downto 0) := (others => '0');
   signal vs2_address_i        : std_logic_vector(4 downto 0):= "00001";
   signal vd_address_i         : std_logic_vector(4 downto 0):= (others => '0');
   signal vector_length_i      : std_logic_vector(clogb2(MAX_VECTOR_LENGTH) - 1 downto 0):= "100000";
   signal BRAM1_r_address_o    : std_logic_vector(clogb2(MAX_VECTOR_LENGTH * 32) - 1 downto 0);
   signal BRAM1_w_address_o    : std_logic_vector(clogb2(MAX_VECTOR_LENGTH * 32) - 1 downto 0);
   signal BRAM1_we_o           : std_logic;
   signal BRAM1_re_o           : std_logic;
   signal BRAM2_r_address_o    : std_logic_vector(clogb2(MAX_VECTOR_LENGTH * 32) - 1 downto 0);
   signal BRAM2_w_address_o    : std_logic_vector(clogb2(MAX_VECTOR_LENGTH * 32) - 1 downto 0);
   signal BRAM2_we_o           : std_logic;
   signal BRAM2_re_o           : std_logic;
   signal ready_o              : std_logic;
begin
   VRF_BRAM_addr_generator_1: entity work.VRF_BRAM_addr_generator
      generic map (
         MAX_VECTOR_LENGTH   => MAX_VECTOR_LENGTH,
         NUM_OF_LANES => NUM_OF_LANES)
      port map (
         clk                  => clk,
         reset                => reset,
         vrf_type_of_access_i => vrf_type_of_access_i,
         vs1_address_i        => vs1_address_i,
         vs2_address_i        => vs2_address_i,
         vd_address_i         => vd_address_i,
         vector_length_i      => vector_length_i,
         BRAM1_r_address_o    => BRAM1_r_address_o,
         BRAM1_w_address_o    => BRAM1_w_address_o,
         BRAM1_we_o           => BRAM1_we_o,
         BRAM1_re_o           => BRAM1_re_o,
         BRAM2_r_address_o    => BRAM2_r_address_o,
         BRAM2_w_address_o    => BRAM2_w_address_o,
         BRAM2_we_o           => BRAM2_we_o,
         BRAM2_re_o           => BRAM2_re_o,
         ready_o              => ready_o);

   clk_gen:process
   begin
      clk <= '1', '0' after 10 ns;
      wait for 20 ns;
   end process;

   reset_gen:process
   begin
      reset <= '1', '0' after 20 ns;
      wait;
   end process;
end architecture;
