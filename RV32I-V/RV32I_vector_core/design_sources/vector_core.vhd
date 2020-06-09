library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.custom_functions_pkg.all;


entity vector_core is
   generic (DATA_WIDTH        : natural := 32;
            VECTOR_LENGTH : natural := 1024;
            NUM_OF_LANES      : natural := 1
            );

   port(clk   : in std_logic;
        reset : in std_logic;

        --input data
        instruction_i : in std_logic_vector(31 downto 0);
        vmul_i : in std_logic_vector (1 downto 0);
        --output data        
        vector_stall_o : out std_logic;
        vector_length_i   : in  std_logic_vector(clogb2(VECTOR_LENGTH/DATA_WIDTH) downto 0)
        --TODO: memory interface to be added
        );

end entity;


architecture struct of vector_core is

   --Constants
   -- Signals needed for communication between of Vector lanes and V_CU
   signal vrf_type_of_access_s : std_logic_vector(1 downto 0);
   signal alu_op_s             : std_logic_vector(4 downto 0);
   signal mem_to_vrf_s         : std_logic_vector(1 downto 0);
   signal V_CU_store_fifo_we_s : std_logic;
   signal V_CU_load_fifo_re_s  : std_logic;
   signal combined_lanes_ready_s              : std_logic_vector(NUM_OF_LANES - 1 downto 0);
   signal ready_s: std_logic;


   -- Signals needed for communication between of Vector lanes and M_CU
   signal M_CU_store_fifo_re_s : std_logic;
   signal M_CU_load_fifo_we_s  : std_logic;

   --Signals needed for communication between M_CU and V_CU
   constant M_CU_load_instruction_s    : std_logic_vector(31 downto 0) := (others => '0');
   constant M_CU_instruction_is_load_s : std_logic                     := '0';

   -- Vector Lane I/O data interface
   signal data_from_mem_s : std_logic_vector (DATA_WIDTH - 1 downto 0);
   signal data_to_mem_s : std_logic_vector (DATA_WIDTH - 1 downto 0);

begin

   vector_control_path_1 : entity work.vector_control_path
      port map (
         clk                        => clk,
         reset                      => reset,
         vector_instruction_i       => instruction_i,
         vrf_type_of_access_o       => vrf_type_of_access_s,
         alu_op_o                   => alu_op_s,
         mem_to_vrf_o               => mem_to_vrf_s,
         store_fifo_we_o            => V_CU_store_fifo_we_s,
         load_fifo_re_o             => V_CU_load_fifo_re_s,
         ready_i                    => ready_s,
         M_CU_load_instruction_i    => M_CU_load_instruction_s,
         M_CU_instruction_is_load_i => M_CU_instruction_is_load_s,
         vector_stall_o             => vector_stall_o);


   ready_s <= '1' when combined_lanes_ready_s = std_logic_vector(to_unsigned(2**(NUM_OF_LANES + 1) - 1, NUM_OF_LANES))
 else
              '0';
   gen_vector_lanes : for i in 0 to NUM_OF_LANES - 1 generate
      vector_lane_1 : entity work.vector_lane
         generic map (
            DATA_WIDTH        => DATA_WIDTH,
            VECTOR_LENGTH => VECTOR_LENGTH/NUM_OF_LANES)
         port map (
            clk                     => clk,
            reset                   => reset,
            vector_instruction_i    => instruction_i,
            data_from_mem_i         => data_from_mem_s,
            vmul_i => vmul_i,
            vector_length_i => vector_length_i,
            --Control singnals from M_CU
            load_fifo_we_i          => M_CU_load_fifo_we_s,
            store_fifo_re_i         => M_CU_store_fifo_re_s,
            --Control singnals from V_CU
            alu_op_i                => alu_op_s,
            mem_to_vrf_i            => mem_to_vrf_s,
            store_fifo_we_i         => V_CU_store_fifo_we_s,
            vrf_type_of_access_i    => vrf_type_of_access_s,
            load_fifo_re_i          => V_CU_load_fifo_re_s,
            -- Output data
            data_to_mem_o           => data_to_mem_s,
            -- Status signals
            ready_o                 => combined_lanes_ready_s(i),
            load_fifo_almostmpty_o  => open,
            load_fifo_almostfull_o  => open,
            load_fifo_empty_o       => open,
            load_fifo_full_o        => open,
            load_fifo_rdcount_o     => open,
            load_fifo_rderr_o       => open,
            load_fifo_wrcount_o     => open,
            load_fifo_wrerr_o       => open,
            store_fifo_almostmpty_o => open,
            store_fifo_almostfull_o => open,
            store_fifo_empty_o      => open,
            store_fifo_full_o       => open,
            store_fifo_rdcount_o    => open,
            store_fifo_rderr_o      => open,
            store_fifo_wrcount_o    => open,
            store_fifo_wrerr_o      => open);
   end generate;

   --TODO: M_CU and memory subsystem need to be implemented
end struct;
