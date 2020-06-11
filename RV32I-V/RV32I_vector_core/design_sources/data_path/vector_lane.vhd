library ieee;
use ieee.std_logic_1164.all;
use work.custom_functions_pkg.all;
library UNIMACRO;
use UNIMACRO.vcomponents.all;
use ieee.numeric_std.all;

entity vector_lane is
   generic (DATA_WIDTH    : natural := 32;
            VECTOR_LENGTH : natural := 1024
            );
   port(clk                  : in std_logic;
        reset                : in std_logic;
        -- **************Input data**************************************
        vector_instruction_i : in std_logic_vector(31 downto 0);
        data_from_mem_i      : in std_logic_vector(DATA_WIDTH - 1 downto 0);
        vmul_i               : in std_logic_vector (1 downto 0);
        vector_length_i      : in std_logic_vector(clogb2(VECTOR_LENGTH/DATA_WIDTH) downto 0);
        --*************control signals***********************************
        -- from memory control unit        
        load_fifo_we_i       : in std_logic;
        store_fifo_re_i      : in std_logic;

        -- from vector control unit
        alu_op_i                : in  std_logic_vector(4 downto 0);
        mem_to_vrf_i            : in  std_logic_vector(1 downto 0);
        store_fifo_we_i         : in  std_logic;
        vrf_type_of_access_i    : in  std_logic_vector(1 downto 0);  --there are r/w, r, w, no_access        
        load_fifo_re_i          : in  std_logic;
        vs1_addr_src_i          : in  std_logic;
        --oputput data
        data_to_mem_o           : out std_logic_vector (DATA_WIDTH - 1 downto 0);
        -- status signals
        ready_o                 : out std_logic;
        load_fifo_almostempty_o : out std_logic;
        load_fifo_almostfull_o  : out std_logic;
        load_fifo_empty_o       : out std_logic;
        load_fifo_full_o        : out std_logic;
        load_fifo_rdcount_o     : out std_logic_vector(8 downto 0);
        load_fifo_rderr_o       : out std_logic;
        load_fifo_wrcount_o     : out std_logic_vector(8 downto 0);
        load_fifo_wrerr_o       : out std_logic;

        store_fifo_almostempty_o : out std_logic;
        store_fifo_almostfull_o  : out std_logic;
        store_fifo_empty_o       : out std_logic;
        store_fifo_full_o        : out std_logic;
        store_fifo_rdcount_o     : out std_logic_vector(8 downto 0);
        store_fifo_rderr_o       : out std_logic;
        store_fifo_wrcount_o     : out std_logic_vector(8 downto 0);
        store_fifo_wrerr_o       : out std_logic
        );
end entity;

architecture structural of vector_lane is

   type ROM_OP_exe_time is array (0 to 31) of std_logic_vector(2 downto 0);
   -- Each location in this memory contans data that tells VRF how many
   -- clock cycles is needed for each operation to be executed. If zero clock
   -- cycles is needed, that means insutruction is not supported. This is hardcoded!
   signal ROM_OP_exe_time_s : ROM_OP_exe_time :=
      --and      or      add      xor
      ("000", "000", "000", "000",
       --no_op             sub      shr
       "000", "000", "000", "000",
       -- shra    mulu  mulhs  mulhsu
       "001", "100", "100", "100",
       --mulhu  divu    divs     remu
       "100", "000", "000", "000",
       --rems    setLts  setLtu  shl     
       "000", "000", "000", "001",
       --seteq
       "000", others => "000");

--****************************INTERCONNECTIONS*******************************
--VRF output signals
   signal vs1_data_s, vs2_data_s, vd_data_s : std_logic_vector (DATA_WIDTH - 1 downto 0);
-- ALU result
   signal alu_result_s                      : std_logic_vector(DATA_WIDTH - 1 downto 0);
-- LOAD FIFO I/O signals
   signal fifo_data_output_s                : std_logic_vector(DATA_WIDTH - 1 downto 0);
   signal alu_exe_time_s                    : std_logic_vector(2 downto 0);
   signal fifo_reset_s                      : std_logic;

   signal vs1_address_s: std_logic_vector(4 downto 0);
begin

--**************************COMBINATIORIAL LOGIC*****************************

   --mem to vector register file mux
   vd_data_s <= fifo_data_output_s when mem_to_vrf_i = "01" else
                alu_result_s;


--****************************INSTANTIATIONS*********************************

   
   alu_exe_time_s <= ROM_OP_exe_time_s (to_integer(unsigned(alu_op_i)));

   vs1_address_s <= vector_instruction_i(19 downto 15) when vs1_addr_src_i = '0' else
                     vector_instruction_i(11 downto 7);
   
   vector_register_file_1 : entity work.vector_register_file
      generic map (
         DATA_WIDTH    => DATA_WIDTH,
         VECTOR_LENGTH => VECTOR_LENGTH)
      port map (
         clk                  => clk,
         reset                => reset,
         vrf_type_of_access_i => vrf_type_of_access_i,
         alu_exe_time_i       => alu_exe_time_s,
         vmul_i               => vmul_i,
         vm_i                 => vector_instruction_i(25),
         vector_length_i      => vector_length_i,
         vs1_address_i        => vs1_address_s,
         vs2_address_i        => vector_instruction_i(24 downto 20),
         vd_address_i         => vector_instruction_i(11 downto 7),
         vd_data_i            => vd_data_s,
         vs1_data_o           => vs1_data_s,
         vs2_data_o           => vs2_data_s,
         ready_o              => ready_o);
   ALU_1 : entity work.ALU
      generic map (
         WIDTH => DATA_WIDTH)
      port map (
         a_i   => vs1_data_s,
         b_i   => vs2_data_s,
         op_i  => alu_op_i,
         res_o => alu_result_s);


   fifo_reset_s <= not(reset);
   LOAD_FIFO_SYN_inst : FIFO_SYNC_MACRO
      generic map (
         DEVICE              => "7SERIES",  -- Target Device: "VIRTEX5, "VIRTEX6", "7SERIES" 
         ALMOST_FULL_OFFSET  => X"0080",  -- Sets almost full threshold
         ALMOST_EMPTY_OFFSET => X"0080",  -- Sets the almost empty threshold
         DATA_WIDTH          => DATA_WIDTH,  -- Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
         FIFO_SIZE           => "18Kb")   -- Target BRAM, "18Kb" or "36Kb" 
      port map (
         ALMOSTEMPTY => load_fifo_almostempty_o,  -- 1-bit output almost empty
         ALMOSTFULL  => load_fifo_almostfull_o,   -- 1-bit output almost full
         DO          => fifo_data_output_s,  -- Output data, width defined by DATA_WIDTH parameter
         EMPTY       => load_fifo_empty_o,  -- 1-bit output empty
         FULL        => load_fifo_full_o,   -- 1-bit output full
         RDCOUNT     => load_fifo_rdcount_o,  -- Output read count, width determined by FIFO depth
         RDERR       => load_fifo_rderr_o,  -- 1-bit output read error
         WRCOUNT     => load_fifo_wrcount_o,  -- Output write count, width determined by FIFO depth
         WRERR       => load_fifo_wrerr_o,  -- 1-bit output write error
         CLK         => clk,            -- 1-bit input clock
         DI          => data_from_mem_i,  -- Input data, width defined by DATA_WIDTH parameter
         RDEN        => load_fifo_re_i,   -- 1-bit input read enable
         RST         => fifo_reset_s,   -- 1-bit input reset
         WREN        => load_fifo_we_i  -- 1-bit input write enable
         );

   STORE_FIFO_SYNC_inst : FIFO_SYNC_MACRO
      generic map (
         DEVICE              => "7SERIES",  -- Target Device: "VIRTEX5, "VIRTEX6", "7SERIES" 
         ALMOST_FULL_OFFSET  => X"0080",    -- Sets almost full threshold
         ALMOST_EMPTY_OFFSET => X"0080",    -- Sets the almost empty threshold
         DATA_WIDTH          => DATA_WIDTH,  -- Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
         FIFO_SIZE           => "18Kb")     -- Target BRAM, "18Kb" or "36Kb" 
      port map (
         ALMOSTEMPTY => store_fifo_almostempty_o,  -- 1-bit output almost empty
         ALMOSTFULL  => store_fifo_almostfull_o,   -- 1-bit output almost full
         DO          => data_to_mem_o,  -- Output data, width defined by DATA_WIDTH parameter
         EMPTY       => store_fifo_empty_o,  -- 1-bit output empty
         FULL        => store_fifo_full_o,  -- 1-bit output full
         RDCOUNT     => store_fifo_rdcount_o,  -- Output read count, width determined by FIFO depth
         RDERR       => store_fifo_rderr_o,  -- 1-bit output read error
         WRCOUNT     => store_fifo_wrcount_o,  -- Output write count, width determined by FIFO depth
         WRERR       => store_fifo_wrerr_o,  -- 1-bit output write error
         CLK         => CLK,            -- 1-bit input clock
         DI          => vs1_data_s,  -- Input data, width defined by DATA_WIDTH parameter
         RDEN        => store_fifo_re_i,    -- 1-bit input read enable
         RST         => fifo_reset_s,   -- 1-bit input reset
         WREN        => store_fifo_we_i     -- 1-bit input write enable
         );


end structural;
