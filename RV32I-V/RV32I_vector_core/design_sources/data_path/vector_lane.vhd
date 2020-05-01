library ieee;
use ieee.std_logic_1164.all;
use work.custom_functions_pkg.all;
library UNIMACRO;
use UNIMACRO.vcomponents.all;


entity vector_lane is
   generic (DATA_WIDTH        : natural := 32;
            VECTOR_LENGTH : natural := 64            
            );
   port(clk                  : in std_logic;
        reset                : in std_logic;
        -- **************Input data**************************************
        vector_instruction_i : in std_logic_vector(31 downto 0);
        data_from_mem_i      : in std_logic_vector(DATA_WIDTH - 1 downto 0);
        --*************control signals***********************************
        -- from memory control unit        
        load_fifo_we_i       : in std_logic;
        store_fifo_re_i      : in std_logic;

        -- from vector control unit
        alu_op_i             : in std_logic_vector(4 downto 0);
        mem_to_vrf_i         : in std_logic_vector(1 downto 0);
        store_fifo_we_i      : in std_logic;
        vrf_type_of_access_i : in std_logic_vector(1 downto 0);  --there are r/w, r, w, no_access        
        load_fifo_re_i       : in std_logic;

        --oputput data
        data_to_mem_o          : out std_logic_vector (DATA_WIDTH - 1 downto 0);
        -- status signals
        ready_o                : out std_logic;
        load_fifo_almostmpty_o : out std_logic;
        load_fifo_almostfull_o : out std_logic;
        load_fifo_empty_o      : out std_logic;
        load_fifo_full_o       : out std_logic;
        load_fifo_rdcount_o    : out std_logic_vector(8 downto 0);
        load_fifo_rderr_o      : out std_logic;
        load_fifo_wrcount_o    : out std_logic_vector(8 downto 0);
        load_fifo_wrerr_o      : out std_logic;

        store_fifo_almostmpty_o : out std_logic;
        store_fifo_almostfull_o : out std_logic;
        store_fifo_empty_o      : out std_logic;
        store_fifo_full_o       : out std_logic;
        store_fifo_rdcount_o    : out std_logic_vector(8 downto 0);
        store_fifo_rderr_o      : out std_logic;
        store_fifo_wrcount_o    : out std_logic_vector(8 downto 0);
        store_fifo_wrerr_o      : out std_logic
        );
end entity;

architecture structural of vector_lane is
--****************************INTERCONNECTIONS*******************************
--VRF output signals
   signal vs1_data_s, vs2_data_s, vd_data_s : std_logic_vector (DATA_WIDTH - 1 downto 0);
-- ALU result
   signal alu_result_s                      : std_logic_vector(DATA_WIDTH - 1 downto 0);
-- LOAD FIFO I/O signals
   signal fifo_data_output_s                : std_logic_vector(DATA_WIDTH - 1 downto 0);


-- Constants used until CSR registers are implemented
   constant vector_length_c : std_logic_vector(clogb2(VECTOR_LENGTH) - 1 downto 0) := (others => '1');
begin

--**************************COMBINATIORIAL LOGIC*****************************

   --mem to vector register file mux
   vd_data_s <= fifo_data_output_s when mem_to_vrf_i = "01" else
                alu_result_s;


--****************************INSTANTIATIONS*********************************

   vector_register_file_1 : entity work.vector_register_file
      generic map (
         DATA_WIDTH        => DATA_WIDTH,
         VECTOR_LENGTH => VECTOR_LENGTH)
      port map (
         clk                  => clk,
         reset                => reset,
         vrf_type_of_access_i => vrf_type_of_access_i,
         vector_length_i      => vector_length_c,
         vs1_address_i        => vector_instruction_i(19 downto 15),
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
   LOAD_FIFO_SYN_inst : FIFO_SYNC_MACRO
      generic map (
         DEVICE              => "7SERIES",  -- Target Device: "VIRTEX5, "VIRTEX6", "7SERIES" 
         ALMOST_FULL_OFFSET  => X"0080",  -- Sets almost full threshold
         ALMOST_EMPTY_OFFSET => X"0080",  -- Sets the almost empty threshold
         DATA_WIDTH          => DATA_WIDTH,  -- Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
         FIFO_SIZE           => "18Kb")   -- Target BRAM, "18Kb" or "36Kb" 
      port map (
         ALMOSTEMPTY => load_fifo_almostmpty_o,  -- 1-bit output almost empty
         ALMOSTFULL  => load_fifo_almostfull_o,  -- 1-bit output almost full
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
         RST         => reset,          -- 1-bit input reset
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
         ALMOSTEMPTY => store_fifo_almostmpty_o,  -- 1-bit output almost empty
         ALMOSTFULL  => store_fifo_almostfull_o,  -- 1-bit output almost full
         DO          => data_to_mem_o,  -- Output data, width defined by DATA_WIDTH parameter
         EMPTY       => store_fifo_empty_o,  -- 1-bit output empty
         FULL        => store_fifo_full_o,  -- 1-bit output full
         RDCOUNT     => store_fifo_rdcount_o,  -- Output read count, width determined by FIFO depth
         RDERR       => store_fifo_rderr_o,  -- 1-bit output read error
         WRCOUNT     => store_fifo_wrcount_o,  -- Output write count, width determined by FIFO depth
         WRERR       => store_fifo_wrerr_o,  -- 1-bit output write error
         CLK         => CLK,            -- 1-bit input clock
         DI          => vs2_data_s,  -- Input data, width defined by DATA_WIDTH parameter
         RDEN        => store_fifo_re_i,    -- 1-bit input read enable
         RST         => reset,          -- 1-bit input reset
         WREN        => store_fifo_we_i     -- 1-bit input write enable
         );


end structural;
