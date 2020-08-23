library ieee;
use ieee.std_logic_1164.all;
use work.custom_functions_pkg.all;
use work.vector_alu_ops_pkg.all;
library UNIMACRO;
use UNIMACRO.vcomponents.all;
use ieee.numeric_std.all;

entity vector_lane is
    generic (DATA_WIDTH    : natural := 32;
             VECTOR_LENGTH : natural := 32;
             NUM_OF_LANES  : natural := 1
             );
    port(clk                        : in  std_logic;
         reset                      : in  std_logic;
         -- **************Input data**************************************
         vector_instruction_i       : in  std_logic_vector(31 downto 0);
         data_from_mem_i            : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
         vmul_i                     : in  std_logic_vector (1 downto 0);
         vector_length_i            : in  std_logic_vector(clogb2(VECTOR_LENGTH * 8) downto 0);
         rs1_data_i                 : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
         reduction_value_i          : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
         --*************control signals***********************************
         -- from memory control unit        
         load_fifo_we_i             : in  std_logic;
         store_fifo_re_i            : in  std_logic;
         -- from vector control unit
         -- if immediate_sign_i = 1 immediate is treated as unsigned else, it
         -- is treated as signed
         immediate_sign_i           : in  std_logic;
         --alu_op_i                : in  std_logic_vector(4 downto 0);
         alu_op_i                   : in  vector_alu_ops_t;
         mem_to_vrf_i               : in  std_logic_vector(1 downto 0);
         store_fifo_we_i            : in  std_logic;
         vrf_type_of_access_i       : in  std_logic_vector(1 downto 0);  --there are r/w, r, w, no_access
         alu_src_a_i                : in  std_logic_vector(1 downto 0);
         -- 1: all elements in VRF are updated (merge and move instructions)
         -- 0: only masked elements in VRF are updated 
         type_of_masking_i          : in  std_logic;
         alu_exe_time_i             : in  std_logic_vector(2 downto 0);
         load_fifo_re_i             : in  std_logic;
         vs1_addr_src_i             : in  std_logic;
         --reduction inputs
         en_reduction_i             : in  std_logic;
         combine_lane_redu_values_i : in  std_logic;
         --oputput data
         data_to_mem_o              : out std_logic_vector (DATA_WIDTH - 1 downto 0);
         -- status signals
         ready_o                    : out std_logic;
         load_fifo_almostempty_o    : out std_logic;
         load_fifo_almostfull_o     : out std_logic;
         load_fifo_empty_o          : out std_logic;
         load_fifo_full_o           : out std_logic;
         load_fifo_rdcount_o        : out std_logic_vector(8 downto 0);
         load_fifo_rderr_o          : out std_logic;
         load_fifo_wrcount_o        : out std_logic_vector(8 downto 0);
         load_fifo_wrerr_o          : out std_logic;

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

--****************************INTERCONNECTIONS*******************************



--VRF output signals
    signal vs1_data_s, vs2_data_s, vd_data_s : std_logic_vector (DATA_WIDTH - 1 downto 0);
    signal mask_s                            : std_logic;
    signal ready_s                           : std_logic;

-- VRF input signals
    signal sign_extension                            : std_logic_vector(DATA_WIDTH - 1 - 4 downto 0);
    signal immediate_sign_ext_next                   : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal masked_we_s                               : std_logic;
    alias vm_s                                       : std_logic is vector_instruction_i(25);
    signal merge_data_s                              : std_logic_vector (DATA_WIDTH - 1 downto 0);
    signal vm_or_update_el_next, vm_or_update_el_reg : std_logic;
    signal vd_address_s                              : std_logic_vector(4 downto 0);
    signal mem_to_vrf_reg                            : std_logic_vector(1 downto 0);
-- ALU I/O interconnections
    --signal alu_op_s: std_logic_vector(4 downto 0);
    signal alu_op_s                                  : vector_alu_ops_t;
    signal alu_result_s                              : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal alu_res_or_redu_reg                       : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal alu_a_input_s                             : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal alu_b_input_s                             : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal alu_src_a_reg                             : std_logic_vector(1 downto 0);
    --Reduction signals
    signal reduction_reg_s                           : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal en_reduction_reg                          : std_logic;
    signal vs1_or_reduction_reg                      : std_logic;
    signal vs1_or_reduction_data_s                   : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal vd_el0_we_s                               : std_logic;
    signal reset_red_reg                             : std_logic;
-- LOAD FIFO I/O signals
    constant load_fifo_empty_threshhold              : std_logic_vector(15 downto 0) := std_logic_vector(to_unsigned(VECTOR_LENGTH - 1, 16));
    signal fifo_data_output_s                        : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal alu_exe_time_s                            : std_logic_vector(2 downto 0);
    signal fifo_reset_s                              : std_logic;
    signal load_fifo_re_s                            : std_logic;
    -- STORE FIFO I/O signals
    signal store_fifo_we_s                           : std_logic;
    signal ready_reg                                 : std_logic;

    signal vs1_address_s : std_logic_vector(4 downto 0);

    signal immediate_sign_ext_reg : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal rs1_data_reg           : std_logic_vector(DATA_WIDTH - 1 downto 0);
begin

--**************************COMBINATIORIAL LOGIC*****************************
    -- "ID_PHASE"
    sign_extension <= (others => vector_instruction_i(19)) when immediate_sign_i = '0'else
                      (others => '0');
    immediate_sign_ext_next <= sign_extension & vector_instruction_i(18 downto 15);

    --chosing what to write into VRF vs1 or vs2
    merge_data_s <= alu_a_input_s when mask_s = '1' else
                    vs2_data_s;
    --mem to vector register file mux
    alu_res_or_redu_reg <= alu_result_s when combine_lane_redu_values_i = '0' else
                           reduction_reg_s;

    vd_data_s <=
        fifo_data_output_s when mem_to_vrf_reg = "01" else
        merge_data_s       when mem_to_vrf_reg = "10" else
        alu_a_input_s      when mem_to_vrf_reg = "11" else
        alu_res_or_redu_reg;


    -- Depending on which instructions is being executed exe time of alu can differ.
    -- For example multiplication takes 4 clk but addition 0 (for now).
    alu_exe_time_s <= alu_exe_time_i;

    -- If Store is being executed instruction (11 : 7) holds the address of
    -- vector register that needs to be stored.
    vs1_address_s <= vector_instruction_i(19 downto 15) when vs1_addr_src_i = '0' else
                     vector_instruction_i(11 downto 7);

    --Only if value of both vm_s and type_of_masking_i is '0' then
    --masking should be applied, otherwise all elements are updated
    vm_or_update_el_next <= vm_s or type_of_masking_i;

    masked_we_s <= mask_s when vm_or_update_el_reg = '0' else
                   '1';


    -- EX PHASE
    -- this here models all signals that need to active one clock cycle after instruction
    -- is received
    process (clk)is
    begin
        if(rising_edge(clk)) then
            if (reset = '0') then
                vm_or_update_el_reg    <= '0';
                immediate_sign_ext_reg <= (others => '0');
                vd_address_s           <= (others => '0');
                rs1_data_reg           <= (others => '0');
                alu_op_s               <= and_op;
                --ready reg
                ready_reg              <= '0';
                alu_src_a_reg          <= (others => '0');
                mem_to_vrf_reg         <= (others => '0');
                en_reduction_reg       <= '0';
                vs1_or_reduction_reg   <= '0';
                vd_el0_we_s <= '0';
            else
                alu_src_a_reg          <= alu_src_a_i;
                vm_or_update_el_reg    <= vm_or_update_el_next;
                alu_op_s               <= alu_op_i;
                vd_address_s           <= vector_instruction_i(11 downto 7);
                ready_reg              <= ready_s;
                immediate_sign_ext_reg <= immediate_sign_ext_next;
                rs1_data_reg           <= rs1_data_i;
                mem_to_vrf_reg         <= mem_to_vrf_i;
                en_reduction_reg       <= en_reduction_i;
                vs1_or_reduction_reg   <= en_reduction_reg;
                vd_el0_we_s <= combine_lane_redu_values_i;
            end if;
        end if;
    end process;

    vs1_or_reduction_data_s <= vs1_data_s when vs1_or_reduction_reg = '0' else
                               reduction_reg_s;
    alu_a_input_s <= vs1_or_reduction_data_s when alu_src_a_reg = "00" else
                     rs1_data_reg when alu_src_a_reg = "01" else
                     immediate_sign_ext_reg;
    alu_b_input_s <= vs2_data_s when combine_lane_redu_values_i = '0' else
                     reduction_value_i;

    -- Generate a pulse on reset_red_reg  signal
    process (clk) is
    begin
        if (rising_edge(clk)) then
            if (reset = '0') then
                reset_red_reg <= '0';
            else
                if (reset_red_reg = '0' and en_reduction_i = '1') then
                    reset_red_reg <= '1';
                else
                    reset_red_reg <= '0';
                end if;
            end if;
        end if;
    end process;

    process (clk)is
    begin
        if (rising_edge(clk))then
            if (reset_red_reg = '1') then
                reduction_reg_s <= (others => '0');
            else
                if (en_reduction_reg = '1') then
                    reduction_reg_s <= alu_result_s;
                end if;
            end if;
        end if;
    end process;
--****************************INSTANTIATIONS*********************************

    -- With this we fix the adress in Vector register file to vd, and only
    -- enable writing to element 0 of a selected vector.    
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
            masked_we_i          => masked_we_s,
            vd_el0_we            => vd_el0_we_s,
            vector_length_i      => vector_length_i,
            vs1_address_i        => vs1_address_s,
            vs2_address_i        => vector_instruction_i(24 downto 20),
            vd_address_i         => vd_address_s,
            vd_data_i            => vd_data_s,
            vs1_data_o           => vs1_data_s,
            vs2_data_o           => vs2_data_s,
            mask_o               => mask_s,
            ready_o              => ready_s);

    ready_o <= ready_s;
    ALU_1 : entity work.V_ALU
        generic map (
            WIDTH => DATA_WIDTH)
        port map (
            clk   => clk,
            reset => reset,
            a_i   => alu_a_input_s,
            b_i   => alu_b_input_s,
            op_i  => alu_op_s,
            res_o => alu_result_s);


    fifo_reset_s   <= not(reset);
    load_fifo_re_s <= (load_fifo_re_i and not(ready_s));
    LOAD_FIFO_SYN_inst : FIFO_SYNC_MACRO
        generic map (
            DEVICE              => "7SERIES",  -- Target Device: "VIRTEX5, "VIRTEX6", "7SERIES" 
            ALMOST_FULL_OFFSET  => X"0080",  -- Sets almost full threshold
            ALMOST_EMPTY_OFFSET => to_bitvector(load_fifo_empty_threshhold),  -- Sets the almost empty threshold
            DATA_WIDTH          => DATA_WIDTH,  -- Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
            FIFO_SIZE           => "18Kb")   -- Target BRAM, "18Kb" or "36Kb" 
        port map (
            ALMOSTEMPTY => load_fifo_almostempty_o,  -- 1-bit output almost empty
            ALMOSTFULL  => load_fifo_almostfull_o,  -- 1-bit output almost full
            DO          => fifo_data_output_s,  -- Output data, width defined by DATA_WIDTH parameter
            EMPTY       => load_fifo_empty_o,  -- 1-bit output empty
            FULL        => load_fifo_full_o,   -- 1-bit output full
            RDCOUNT     => load_fifo_rdcount_o,  -- Output read count, width determined by FIFO depth
            RDERR       => load_fifo_rderr_o,  -- 1-bit output read error
            WRCOUNT     => load_fifo_wrcount_o,  -- Output write count, width determined by FIFO depth
            WRERR       => load_fifo_wrerr_o,  -- 1-bit output write error
            CLK         => clk,         -- 1-bit input clock
            DI          => data_from_mem_i,  -- Input data, width defined by DATA_WIDTH parameter
            RDEN        => load_fifo_re_s,   -- 1-bit input read enable
            RST         => fifo_reset_s,     -- 1-bit input reset
            WREN        => load_fifo_we_i    -- 1-bit input write enable
            );



    --- this logic is used to generate we for store fifo.
    process (clk) is
    begin
        if (rising_edge(clk)) then
            if (reset = '0') then
                store_fifo_we_s <= '0';
            else
                store_fifo_we_s <= store_fifo_we_i;
                if (ready_s = '1' and ready_reg = '1' and store_fifo_we_i = '1' and vector_length_i > std_logic_vector(to_unsigned(1, clogb2(VECTOR_LENGTH * 8) + 1))) then
                    store_fifo_we_s <= '0';
                end if;
            end if;
        end if;
    end process;
    STORE_FIFO_SYNC_inst : FIFO_SYNC_MACRO
        generic map (
            DEVICE              => "7SERIES",  -- Target Device: "VIRTEX5, "VIRTEX6", "7SERIES" 
            ALMOST_FULL_OFFSET  => X"0080",  -- Sets almost full threshold
            ALMOST_EMPTY_OFFSET => X"000F",  -- Sets the almost empty threshold
            DATA_WIDTH          => DATA_WIDTH,  -- Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
            FIFO_SIZE           => "18Kb")   -- Target BRAM, "18Kb" or "36Kb" 
        port map (
            ALMOSTEMPTY => store_fifo_almostempty_o,  -- 1-bit output almost empty
            ALMOSTFULL  => store_fifo_almostfull_o,  -- 1-bit output almost full
            DO          => data_to_mem_o,  -- Output data, width defined by DATA_WIDTH parameter
            EMPTY       => store_fifo_empty_o,  -- 1-bit output empty
            FULL        => store_fifo_full_o,  -- 1-bit output full
            RDCOUNT     => store_fifo_rdcount_o,  -- Output read count, width determined by FIFO depth
            RDERR       => store_fifo_rderr_o,  -- 1-bit output read error
            WRCOUNT     => store_fifo_wrcount_o,  -- Output write count, width determined by FIFO depth
            WRERR       => store_fifo_wrerr_o,  -- 1-bit output write error
            CLK         => CLK,         -- 1-bit input clock
            DI          => vs1_data_s,  -- Input data, width defined by DATA_WIDTH parameter
            RDEN        => store_fifo_re_i,  -- 1-bit input read enable
            RST         => fifo_reset_s,   -- 1-bit input reset
            WREN        => store_fifo_we_s   -- 1-bit input write enable
            );


end structural;





