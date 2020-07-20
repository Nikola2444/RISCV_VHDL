library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.custom_functions_pkg.all;


entity vector_core is
    generic (DATA_WIDTH    : natural := 32;
             VECTOR_LENGTH : natural := 32;  -- num of elements per vector register
             NUM_OF_LANES  : natural := 4
             );

    port(clk   : in std_logic;
         reset : in std_logic;

         --input data
         instruction_i : in std_logic_vector(31 downto 0);

         rs1_i : in std_logic_vector(31 downto 0);
         rs2_i : in std_logic_vector(31 downto 0);

         --Signals coming from scalar core
         scalar_core_stall_i : in std_logic;
         scalar_load_req_i   : in std_logic;
         scalar_store_req_i  : in std_logic;
         scalar_address_i    : in std_logic_vector(31 downto 0);

         -- Memory interface
         store_address_o : out std_logic_vector(31 downto 0);
         load_address_o  : out std_logic_vector(31 downto 0);
         mem_we_o        : out std_logic;
         mem_re_o        : out std_logic;
         data_from_mem_i : in  std_logic_vector (31 downto 0);
         data_to_mem_o   : out    std_logic_vector(31 downto 0);

         --output data        
         vector_stall_o  : out std_logic;
         -- Vector_length should not be among input ports of vector core !! It
         -- is for now here so synthesis is possible
         vector_length_i : in  std_logic_vector(clogb2(VECTOR_LENGTH/NUM_OF_LANES*8) downto 0)
     --TODO: memory interface to be added
         );

end entity;


architecture struct of vector_core is

    --Constants
    -- Signals needed for communication between of Vector lanes and V_CU
    signal vrf_type_of_access_s   : std_logic_vector(1 downto 0);
    signal alu_op_s               : std_logic_vector(4 downto 0);
    signal mem_to_vrf_s           : std_logic_vector(1 downto 0);
    signal V_CU_store_fifo_we_s   : std_logic;
    signal V_CU_load_fifo_re_s    : std_logic;
    signal immediate_sign_s       : std_logic;
    signal combined_lanes_ready_s : std_logic_vector(NUM_OF_LANES - 1 downto 0);
    signal alu_src_a_s            : std_logic_vector(1 downto 0);
    signal type_of_masking_s      : std_logic;
    signal vs1_addr_src_s         : std_logic;

    signal rs1_data_s : std_logic_vector (31 downto 0);


    -- Signals needed for communication between of Vector lanes and M_CU
    signal M_CU_store_fifo_re_s : std_logic;
    signal M_CU_load_fifo_we_s  : std_logic;

    --Signals needed for communication between M_CU and V_CU

    -- Vector Lane I/O data interface

    type data_to_mem_t is array (0 to NUM_OF_LANES - 1) of std_logic_vector(31 downto 0);
    signal data_to_mem_s : data_to_mem_t;

    type lane_vector_length_t is array (0 to NUM_OF_LANES - 1) of std_logic_vector(clogb2(VECTOR_LENGTH/NUM_OF_LANES * 8) downto 0);
    signal lane_vector_length_s : lane_vector_length_t;
    
    signal vector_length_shifted : std_logic_vector(clogb2(VECTOR_LENGTH/NUM_OF_LANES * 8) downto 0);
    signal vector_length_shifted_incr:  std_logic_vector(clogb2(VECTOR_LENGTH/NUM_OF_LANES * 8) downto 0);
    -- Interconnections for arbiter, M_CU, vector lanes and V_CU
    signal ready_s               : std_logic;
    signal vector_instruction_i  : std_logic_vector(31 downto 0);


    signal load_fifo_empty_s  : std_logic;
    signal store_fifo_empty_s : std_logic;
    signal rdy_for_load_s     : std_logic;
    signal rdy_for_store_s    : std_logic;
    signal M_CU_ld_rs1_s      : std_logic_vector(31 downto 0);
    signal M_CU_ld_rs2_s      : std_logic_vector(31 downto 0);
    signal M_CU_ld_vl_s       : std_logic_vector(clogb2(VECTOR_LENGTH * 8) downto 0);
    signal M_CU_load_valid_s  : std_logic;
    signal M_CU_st_rs1_s      : std_logic_vector(31 downto 0);
    signal M_CU_st_rs2_s      : std_logic_vector(31 downto 0);
    signal M_CU_st_vl_s       : std_logic_vector(clogb2(VECTOR_LENGTH * 8) downto 0);
    signal M_CU_store_valid_s : std_logic;
    signal comparison_s       : std_logic;
    signal vector_stall_s     : std_logic;
    signal rs1_to_V_CU_s      : std_logic_vector(31 downto 0);

    signal vmul_to_V_CU_s         : std_logic_vector(1 downto 0);
    signal vl_to_V_CU_s           : std_logic_vector(clogb2(VECTOR_LENGTH * 8) downto 0);
    signal vector_instr_to_V_CU_s : std_logic_vector(31 downto 0);
    signal load_fifos_en_s        : std_logic_vector(NUM_OF_LANES - 1 downto 0);
    signal store_fifos_en_s       : std_logic_vector(NUM_OF_LANES - 1 downto 0);
begin
    ready_s <= '1' when combined_lanes_ready_s = std_logic_vector(to_unsigned(2**(NUM_OF_LANES + 1) - 1, NUM_OF_LANES)) else '0';



    -----------------------------------------------------------------------------------------------------------------
    -- CONTROL PATH
    -----------------------------------------------------------------------------------------------------------------
    vector_control_path_1 : entity work.vector_control_path
        port map (
            clk                  => clk,
            reset                => reset,
            vector_instruction_i => instruction_i,
            vrf_type_of_access_o => vrf_type_of_access_s,
            alu_op_o             => alu_op_s,
            mem_to_vrf_o         => mem_to_vrf_s,
            store_fifo_we_o      => V_CU_store_fifo_we_s,
            load_fifo_re_o       => V_CU_load_fifo_re_s,
            ready_i              => ready_s);


    M_CU_1 : entity work.M_CU
        generic map (
            NUM_OF_LANES  => NUM_OF_LANES,
            VECTOR_LENGTH => VECTOR_LENGTH)
        port map (
            clk                => clk,
            reset              => reset,
            rdy_for_load_o     => rdy_for_load_s,
            rdy_for_store_o    => rdy_for_store_s,
            M_CU_ld_rs1_i      => M_CU_ld_rs1_s,
            M_CU_ld_rs2_i      => M_CU_ld_rs2_s,
            M_CU_ld_vl_i       => M_CU_ld_vl_s,
            M_CU_load_valid_i  => M_CU_load_valid_s,
            M_CU_st_rs1_i      => M_CU_st_rs1_s,
            M_CU_st_rs2_i      => M_CU_st_rs2_s,
            M_CU_st_vl_i       => M_CU_st_vl_s,
            M_CU_store_valid_i => M_CU_store_valid_s,
            scalar_load_req_i  => scalar_load_req_i,
            scalar_store_req_i => scalar_store_req_i,
            scalar_address_i   => scalar_address_i,
            store_address_o    => store_address_o,
            load_address_o     => load_address_o,
            mem_we_o           => mem_we_o,
            mem_re_o           => mem_re_o,
            store_fifos_en_o   => store_fifos_en_s,
            load_fifos_en_o    => load_fifos_en_s);


    arbiter_1 : entity work.arbiter
        generic map (
            VECTOR_LENGTH => VECTOR_LENGTH,
            DATA_WIDTH    => DATA_WIDTH)
        port map (
            clk                    => clk,
            reset                  => reset,
            ready_i                => ready_s,
            vector_instruction_i   => vector_instruction_i,
            rs1_i                  => rs1_i,
            rs2_i                  => rs2_i,
            scalar_core_stall_i    => scalar_core_stall_i,
            load_fifo_empty_i      => load_fifo_empty_s,
            store_fifo_empty_i     => store_fifo_empty_s,
            rdy_for_load_i         => rdy_for_load_s,
            rdy_for_store_i        => rdy_for_store_s,
            M_CU_ld_rs1_o          => M_CU_ld_rs1_s,
            M_CU_ld_rs2_o          => M_CU_ld_rs2_s,
            M_CU_ld_vl_o           => M_CU_ld_vl_s,
            M_CU_load_valid_o      => M_CU_load_valid_s,
            M_CU_st_rs1_o          => M_CU_st_rs1_s,
            M_CU_st_rs2_o          => M_CU_st_rs2_s,
            M_CU_st_vl_o           => M_CU_st_vl_s,
            M_CU_store_valid_o     => M_CU_store_valid_s,
            vector_stall_o         => vector_stall_s,
            rs1_to_V_CU_i          => rs1_to_V_CU_s,
            vmul_to_V_CU_o         => vmul_to_V_CU_s,
            vl_to_V_CU_o           => vl_to_V_CU_s,
            vector_instr_to_V_CU_o => vector_instr_to_V_CU_s);
    -----------------------------------------------------------------------------------------------------------------
    -- DATA PATH
    -----------------------------------------------------------------------------------------------------------------
    -- Code bellow calculates vector length for each lane. If vl_to_V_CU
    -- received from arbiter is diviseble by NUM_OF_LANES, then each lane
    -- receives the same vector length (i.e. all lanes need to update the same
    -- number of elements), but if on the other hand vl_to_V_CU is not
    -- divisible bu NUM_OF_LANES, then depending on remainder some lanes need
    -- to calculate one more element than the others
    
    --shifting vector lane num_of_lane bits and trying to realize rem
    vector_length_shifted <= vl_to_V_CU_s(clogb2(VECTOR_LENGTH*8) downto clogb2(NUM_OF_LANES));
    vector_length_shifted_incr <= std_logic_vector(unsigned(vector_length_shifted) + to_unsigned(1, clogb2(VECTOR_LENGTH/NUM_OF_LANES*8) + 1));
    --calculatng vector length for each lane
    process (vl_to_V_CU_s)is
    begin
        for i in 0 to NUM_OF_LANES - 1 loop
            if (i = NUM_OF_LANES - 1) then
                lane_vector_length_s(i) <= vector_length_shifted;
            else
                --this logic here checks how large the remainder is. We only
                --look at NUM_OF_LANES LSB bit.
                if(vl_to_V_CU_s(clogb2(NUM_OF_LANES) - 1 downto 0) > std_logic_vector(to_unsigned(i, clogb2(NUM_OF_LANES)))) then
                    lane_vector_length_s(i) <= vector_length_shifted_incr;
                else
                    lane_vector_length_s(i) <= vector_length_shifted;
                end if;
            end if;
        end loop;
    end process;

    gen_vector_lanes : for i in 0 to NUM_OF_LANES - 1 generate
        vector_lane_1 : entity work.vector_lane
            generic map (
                DATA_WIDTH    => DATA_WIDTH,
                VECTOR_LENGTH => VECTOR_LENGTH/NUM_OF_LANES)
            port map (
                clk                  => clk,
                reset                => reset,
                vector_instruction_i => vector_instr_to_V_CU_s,
                data_from_mem_i      => data_from_mem_i,
                vmul_i               => vmul_to_V_CU_s,
                vector_length_i      => lane_vector_length_s(i),
                rs1_data_i           => rs1_to_V_CU_s,
                --Control singnals from M_CU
                load_fifo_we_i       => load_fifos_en_s(i),
                store_fifo_re_i      => store_fifos_en_s(i),
                --Control singnals froom V_CU
                immediate_sign_i     => immediate_sign_s,
                alu_op_i             => alu_op_s,
                mem_to_vrf_i         => mem_to_vrf_s,
                store_fifo_we_i      => V_CU_store_fifo_we_s,
                vrf_type_of_access_i => vrf_type_of_access_s,
                alu_src_a_i          => alu_src_a_s,
                type_of_masking_i    => type_of_masking_s,
                vs1_addr_src_i       => vs1_addr_src_s,
                load_fifo_re_i       => V_CU_load_fifo_re_s,
                -- Output data
                data_to_mem_o        => data_to_mem_s(i),
                -- Status signals
                ready_o              => combined_lanes_ready_s(i),

                load_fifo_almostempty_o => open,
                load_fifo_almostfull_o  => open,
                load_fifo_empty_o       => open,
                load_fifo_full_o        => open,
                load_fifo_rdcount_o     => open,
                load_fifo_rderr_o       => open,
                load_fifo_wrcount_o     => open,
                load_fifo_wrerr_o       => open,

                store_fifo_almostempty_o => open,
                store_fifo_almostfull_o  => open,
                store_fifo_empty_o       => open,
                store_fifo_full_o        => open,
                store_fifo_rdcount_o     => open,
                store_fifo_rderr_o       => open,
                store_fifo_wrcount_o     => open,
                store_fifo_wrerr_o       => open);
    end generate;

    --data to mem logic
    process (store_fifos_en_s)is
    begin
        data_to_mem_o <= (others => '0');
        for i in 0 to NUM_OF_LANES - 1 loop
            if (store_fifos_en_s(i) = '1') then
                data_to_mem_o <= data_to_mem_s(i);
            end if;
        end loop;
    end process;
    
end struct;
