library ieee;
use ieee.std_logic_1164.all;
use work.clogb2_pkg.all;

entity vector_register_file is
   generic (DATA_WIDTH : natural := 32;
            BRAM_DEPTH : natural := 2048;
            NUM_OF_LANES: natural := 1
            );
   port (clk   : in std_logic;
         reset : in std_logic;
         
         -- Control_signals
         vrf_we_i : in std_logic; -- write enable
         vrf_re_i : in std_logic; --read enable

         -- input data
         rv1_address_i : in std_logic_vector(4 downto 0);  --number of vector registers is 32
         rv2_address_i : in std_logic_vector(4 downto 0);
         rd_address_i  : in std_logic_vector(4 downto 0);

         rd_data_i : in std_logic_vector(DATA_WIDTH - 1 downto 0);

         -- output data        
         rv1_data_o : out std_logic_vector(DATA_WIDTH - 1 downto 0);
         rv2_data_o : out std_logic_vector(DATA_WIDTH - 1 downto 0)
         );
end entity;

architecture structural of vector_register_file is
   component VRF_BRAM_addr_generator is
      generic(BRAM_DEPTH : natural := 2048;
              NUM_OF_LANES: natural := 1);
      port (
         clk               : in  std_logic;
         reset             : in  std_logic;
         -- control signals
         vrf_we_i           : in  std_logic;
         vrf_re_i           : in  std_logic; 
         -- input signals
         rv1_address_i     : in  std_logic_vector(4 downto 0);
         rv2_address_i     : in  std_logic_vector(4 downto 0);
         rd_address_i      : in  std_logic_vector(4 downto 0);

         vector_length_i : in std_logic_vector(7 downto 0);
         -- output signals
         bram1_r_address_o : out std_logic_vector(clogb2(BRAM_DEPTH) - 1 downto 0);
         bram1_w_address_o : out std_logic_vector(clogb2(BRAM_DEPTH) - 1 downto 0);
         bram1_we_o        : out std_logic;
         bram1_re_o        : out std_logic;

         bram2_r_address_o : out std_logic_vector(clogb2(BRAM_DEPTH) - 1 downto 0);
         bram2_w_address_o : out std_logic_vector(clogb2(BRAM_DEPTH) - 1 downto 0);
         bram2_we_o        : out std_logic;
         bram2_re_o        : out std_logic
         );


   end component;
   --***************VRF_BRAM_addr_generator signals ***************************
   -- input signals 

   -- output signals
   signal bram1_r_address_s : std_logic_vector(clogb2(BRAM_DEPTH) - 1 downto 0);
   signal bram1_w_address_s : std_logic_vector(clogb2(BRAM_DEPTH) - 1 downto 0);
   signal bram1_we_s        : std_logic;
   signal bram1_re_s        : std_logic;

   signal bram2_r_address_s : std_logic_vector(clogb2(BRAM_DEPTH) - 1 downto 0);
   signal bram2_w_address_s : std_logic_vector(clogb2(BRAM_DEPTH) - 1 downto 0);
   signal bram2_we_s        : std_logic;
   signal bram2_re_s        : std_logic;
   --*************************************************************************


begin

   VRF_BRAM_addr_generator_1 : VRF_BRAM_addr_generator
      generic map (BRAM_DEPTH => BRAM_DEPTH,
                   NUM_OF_LANES => NUM_OF_LANES)
      port map (
         clk               => clk,
         reset             => reset,
         vrf_we_i           => vrf_we_i,
         vrf_re_i           => vrf_re_i,
         rv1_address_i     => rv1_address_i,
         rv2_address_i     => rv2_address_i,
         rd_address_i      => rd_address_i,
         vector_length_i => x"20",1
         bram1_r_address_o => bram1_r_address_s,
         bram1_w_address_o => bram1_w_address_s,
         bram1_we_o        => bram1_we_s,
         bram1_re_o        => bram1_re_s,
         bram2_r_address_o => bram2_r_address_s,
         bram2_w_address_o => bram2_w_address_s,
         bram2_we_o        => bram2_we_s,
         bram2_re_o        => bram2_re_s);


   BRAM_18KB_1 : entity work.BRAM_18KB
      generic map (
         RAM_WIDTH       => DATA_WIDTH,
         RAM_DEPTH       => BRAM_DEPTH,
         RAM_PERFORMANCE => "LOW_LATENCY",
         INIT_FILE       => "")
      port map (
         clk             => clk,
         write_addr_i    => bram1_w_address_s,
         read_addr_i     => bram1_r_address_s,
         write_data_i    => rd_data_i,
         we_i            => bram1_we_s,
         re_i            => bram1_re_s,
         rst_read_i      => '0',
         output_reg_en_i => '0',
         read_data_o     => rv1_data_o);

   BRAM_18KB_2 : entity work.BRAM_18KB
      generic map (
         RAM_WIDTH       => DATA_WIDTH,
         RAM_DEPTH       => BRAM_DEPTH,
         RAM_PERFORMANCE => "LOW_LATENCY",
         INIT_FILE       => "")
      port map (
         clk             => clk,
         write_addr_i    => bram2_w_address_s,
         read_addr_i     => bram2_r_address_s,
         write_data_i    => rd_data_i,
         we_i            => bram2_we_s,
         re_i            => bram2_re_s,
         rst_read_i      => '0',
         output_reg_en_i => '0',
         read_data_o     => rv2_data_o);

end structural;
