library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library UNIMACRO;
use UNIMACRO.vcomponents.all;
use work.custom_functions_pkg.all;


entity M_CU is
    generic (
        NUM_OF_LANES  : natural := 4;
        VECTOR_LENGTH : natural := 32);
    port (
        clk             :     std_logic;
        reset           :     std_logic;
        rdy_for_load_o  : out std_logic;
        rdy_for_store_o : out std_logic;
        -- M_CU data necessary for load exe
        M_CU_ld_rs1_i   : in  std_logic_vector(31 downto 0);
        M_CU_ld_rs2_i   : in  std_logic_vector(31 downto 0);
        M_CU_ld_vl_i    : in  std_logic_vector(clogb2(VECTOR_LENGTH * 8) downto 0);  -- vector length      
        M_CU_load_done_i: out std_logic;
        M_CU_load_valid_i  : in std_logic;
        -- M_CU data necessary for store exe
        M_CU_st_rs1_i      : in std_logic_vector(31 downto 0);
        M_CU_st_rs2_i      : in std_logic_vector(31 downto 0);
        M_CU_st_vl_i       : in std_logic_vector(clogb2(VECTOR_LENGTH * 8) downto 0);  -- vector length
        M_CU_store_valid_i : in std_logic;
        --scalar core interface
        scalar_load_req_i  : in std_logic;
        scalar_store_req_i : in std_logic;
        scalar_address_i   : in std_logic_vector(31 downto 0);
        -- Memory subsystem interface        

        --Memory interface
        store_address_o : out std_logic_vector(31 downto 0);
        load_address_o  : out std_logic_vector(31 downto 0);
        mem_we_o        : out std_logic;
        mem_re_o        : out std_logic;

        --Vector lane Load/store fifo interface
        store_fifos_en_o :out std_logic_vector(NUM_OF_LANES - 1 downto 0);
        load_fifos_en_o  :out std_logic_vector(NUM_OF_LANES - 1 downto 0)

        );
end entity;

architecture behavioral of M_CU is
    --signals and types needed for LOAD instructions
    type load_fsm_states is (waiting_for_loads, load_scalar, load_vector_state);
    signal load_fsm_states_reg, load_fsm_states_next   : load_fsm_states;
    signal load_address_next, load_address_reg         : std_logic_vector(31 downto 0);
    signal load_counter_next, load_counter_reg         : std_logic_vector(clogb2(8 * VECTOR_LENGTH) downto 0);
    signal load_vl_reg, load_vl_next                   : std_logic_vector(clogb2(8 * VECTOR_LENGTH) downto 0);
    signal vector_ld_rs2_next, vector_ld_rs2_reg       : std_logic_vector(31 downto 0);
    signal load_start_s                                : std_logic;
    signal load_fifos_en_reg, load_fifos_en_next       : std_logic_vector(NUM_OF_LANES - 1 downto 0);
    --signals and types needed for STORE instructions
    type store_fsm_states is (waiting_for_stores, store_scalar, store_vector_state);
    signal store_fsm_states_reg, store_fsm_states_next : store_fsm_states;
    signal store_address_next, store_address_reg       : std_logic_vector(31 downto 0);
    signal store_counter_next, store_counter_reg       : std_logic_vector(clogb2(8 * VECTOR_LENGTH) downto 0);
    signal store_vl_reg, store_vl_next                 : std_logic_vector(clogb2(8 * VECTOR_LENGTH) downto 0);
    signal vector_st_rs2_next, vector_st_rs2_reg       : std_logic_vector(31 downto 0);
    signal store_start_s                               : std_logic;
    signal store_fifos_en_reg, store_fifos_en_next     : std_logic_vector(NUM_OF_LANES -1 downto 0);
    signal mem_we_s: std_logic;

begin

    -- LOAD FSM
    process (clk)is
    begin
        if (rising_edge(clk))then
            if (reset = '0')then
                --registers needed for load instructions
                load_fsm_states_reg  <= waiting_for_loads;
                vector_ld_rs2_reg    <= (others => '0');
                load_address_reg     <= (others => '0');
                load_vl_reg          <= (others => '0');
                load_counter_reg     <= (others => '0');
                load_fifos_en_reg    <= (others => '0');
                --registers needed for store instructions
                store_fsm_states_reg <= waiting_for_stores;
                vector_st_rs2_reg    <= (others => '0');
                store_address_reg    <= (others => '0');
                store_vl_reg         <= (others => '0');
                store_counter_reg    <= (others => '0');
                store_fifos_en_reg   <= (others => '0');
            else
                --registers needed for load instructions
                load_fsm_states_reg  <= load_fsm_states_next;
                vector_ld_rs2_reg    <= vector_ld_rs2_next;
                load_address_reg     <= load_address_next;
                load_vl_reg          <= load_vl_next;
                load_counter_reg     <= load_counter_next;
                load_fifos_en_reg    <= load_fifos_en_next;
                --registers needed for store instructions
                store_fsm_states_reg <= store_fsm_states_next;
                vector_st_rs2_reg    <= vector_st_rs2_next;
                store_address_reg    <= store_address_next;
                store_vl_reg         <= store_vl_next;
                store_counter_reg    <= store_counter_next;
                store_fifos_en_reg   <= store_fifos_en_next;
            end if;
        end if;
    end process;

    -- Calculating number of elements that need to be extracted from memory

    ---------------------------------------------------------------------------------------------------------------------------------------------
    -- logic that handles LOAD instructions
    ---------------------------------------------------------------------------------------------------------------------------------------------

    process (load_fsm_states_next, load_fsm_states_reg, vector_ld_rs2_next,
             vector_ld_rs2_reg, M_CU_load_valid_i, scalar_address_i,
             scalar_load_req_i, load_vl_reg, load_vl_next, load_address_next, load_address_reg,
             load_counter_reg, load_counter_next, M_CU_ld_vl_i, M_CU_ld_rs1_i, M_CU_ld_rs2_i) is
    begin
        vector_ld_rs2_next <= vector_ld_rs2_reg;
        mem_re_o           <= '0';        
        rdy_for_load_o     <= '0';
        load_start_s       <= '0';
        load_counter_next  <= load_counter_reg;
        load_address_next  <= load_address_reg;
        load_vl_next       <= load_vl_reg;
        M_CU_load_done_i <= '0';
        case load_fsm_states_reg is
            when waiting_for_loads =>

                load_fsm_states_next <= waiting_for_loads;
                -- scalar load have a higher priority because they only extract one
                -- element from memory, and vector loads extrac VECTOR_LENGTH
                -- elements from the memory.
                if (scalar_load_req_i = '1') then
                    load_address_next <= scalar_address_i;
                    mem_re_o          <= '1';
                elsif (M_CU_load_valid_i = '1' and M_CU_ld_vl_i /= std_logic_vector(to_unsigned(0, clogb2(VECTOR_LENGTH * 8) + 1))) then
                    -- if there is a valid vector load start reading data from the memory.
                    load_fsm_states_next <= load_vector_state;
                    -- Raise rdy_for_load_o for one clock cycle (that is the
                    -- handshake the arbiter expects)

                    rdy_for_load_o <= '1';
                    mem_re_o       <= '1';

                    load_vl_next       <= M_CU_ld_vl_i;
                    vector_ld_rs2_next <= M_CU_ld_rs2_i;

                    load_address_next <= M_CU_ld_rs1_i;
                    load_counter_next <= std_logic_vector(unsigned(load_counter_reg) + to_unsigned(1, clogb2(VECTOR_LENGTH * 8) + 1));
                    load_start_s      <= '1';
                end if;
            when load_vector_state =>
                mem_re_o             <= '1';
                load_start_s         <= '1';
                load_fsm_states_next <= load_vector_state;
                -- if there is a scalar load pending, stop with vector load
                -- execution for one clock cycle, extract the data necessary for
                -- scalar load, and then continue with vector load
                if (scalar_load_req_i = '0') then
                    load_fsm_states_next <= load_vector_state;
                    load_address_next    <= std_logic_vector (unsigned(vector_ld_rs2_reg) + unsigned(load_address_reg));
                    load_counter_next    <= std_logic_vector(unsigned(load_counter_reg) + to_unsigned(1, clogb2(VECTOR_LENGTH * 8) + 1));
                    if (load_counter_reg = std_logic_vector(unsigned(load_vl_reg) - to_unsigned(1, clogb2(VECTOR_LENGTH / NUM_OF_LANES *8) + 1))) then
                        load_fsm_states_next <= waiting_for_loads;
                        M_CU_load_done_i <= '1';
                        load_counter_next    <= (others => '0');
                    end if;
                else
                    load_start_s <= '0';
                end if;
            when others =>
                load_fsm_states_next <= waiting_for_loads;
        end case;
    end process;


    -- Logic that generates enables for load fifos
    process (load_fsm_states_reg, load_fifos_en_next, load_fifos_en_reg, load_start_s)is
    begin
        load_fifos_en_next <= load_fifos_en_reg;
        case load_fsm_states_reg is
            when waiting_for_loads =>
                load_fifos_en_next <= (others => '0');
                if (load_start_s = '1') then
                    load_fifos_en_next <= std_logic_vector(to_unsigned(1, NUM_OF_LANES));
                end if;
            when load_vector_state =>
                if (load_start_s = '1') then
                    load_fifos_en_next <= load_fifos_en_reg(NUM_OF_LANES - 2 downto 0) & '0';
                    if (load_fifos_en_reg (NUM_OF_LANES - 1) = '1') then
                        load_fifos_en_next <= std_logic_vector(to_unsigned(1, NUM_OF_LANES));
                    end if;
                end if;
            when others =>
        end case;
    end process;
    ---------------------------------------------------------------------------------------------------------------------------------------------
    -- logic that handles STORE instructions
    ---------------------------------------------------------------------------------------------------------------------------------------------
    process (store_fsm_states_next, store_fsm_states_reg, vector_st_rs2_next,
             vector_st_rs2_reg, M_CU_store_valid_i, scalar_address_i,
             scalar_store_req_i, store_vl_reg, store_vl_next, store_address_next, store_address_reg,
             store_counter_reg, store_counter_next, M_CU_st_vl_i, M_CU_st_rs1_i, M_CU_st_rs2_i) is
    begin
        vector_st_rs2_next <= vector_st_rs2_reg;        
        mem_we_s           <= '0';
        rdy_for_store_o    <= '0';
        store_start_s      <= '0';
        store_counter_next <= store_counter_reg;
        store_address_next <= store_address_reg;
        store_vl_next      <= store_vl_reg;
        case store_fsm_states_reg is
            when waiting_for_stores =>
                store_fsm_states_next <= waiting_for_stores;
                -- scalar store have a higher priority because they only extract one
                -- element from memory, and vector stores extrac VECTOR_LENGTH
                -- elements from the memory.
                if (scalar_store_req_i = '1') then
                    store_address_next <= scalar_address_i;
                    mem_we_s        <= '1';
                elsif (M_CU_store_valid_i = '1' and M_CU_st_vl_i /= std_logic_vector(to_unsigned(0, clogb2(VECTOR_LENGTH * 8) + 1))) then
                    -- if there is a valid vector store start reading data from the memory.
                    store_fsm_states_next <= store_vector_state;
                    -- Raise rdy_for_store_o for one clock cycle (that is the
                    -- handshake the arbiter expects)

                    rdy_for_store_o <= '1';
                    mem_we_s        <= '1';

                    store_vl_next      <= M_CU_st_vl_i;
                    vector_st_rs2_next <= M_CU_st_rs2_i;

                    store_address_next <= M_CU_st_rs1_i;
                    store_counter_next <= std_logic_vector(unsigned(store_counter_reg) + to_unsigned(1, clogb2(VECTOR_LENGTH * 8) + 1));
                    store_start_s      <= '1';
                end if;
            when store_vector_state =>
                mem_we_s              <= '1';
                store_start_s         <= '1';
                store_fsm_states_next <= store_vector_state;
                -- if there is a scalar store pending, stop with vector store
                -- execution for one clock cycle, extract the data necessary for
                -- scalar store, and then continue with vector store
                if (scalar_store_req_i = '0') then
                    store_fsm_states_next <= store_vector_state;
                    store_address_next    <= std_logic_vector (unsigned(vector_st_rs2_reg) + unsigned(store_address_reg));
                    store_counter_next    <= std_logic_vector(unsigned(store_counter_reg) + to_unsigned(1, clogb2(VECTOR_LENGTH * 8) + 1));
                    if (store_counter_reg = std_logic_vector(unsigned(store_vl_reg) - to_unsigned(1, clogb2(VECTOR_LENGTH / NUM_OF_LANES *8) + 1))) then
                        store_fsm_states_next <= waiting_for_stores;
                        store_counter_next    <= (others => '0');
                    end if;
                else
                    store_start_s <= '0';
                end if;
            when others =>
                store_fsm_states_next <= waiting_for_stores;
        end case;
    end process;

    -- Logic that generates enables for store fifos
    process (store_fsm_states_reg, store_fifos_en_next, store_fifos_en_reg, store_start_s)is
    begin
        store_fifos_en_next <= store_fifos_en_reg;
        case store_fsm_states_reg is
            when waiting_for_stores =>
                store_fifos_en_next <= (others => '0');
                if (store_start_s = '1') then
                    store_fifos_en_next <= std_logic_vector(to_unsigned(1, NUM_OF_LANES));
                end if;
            when store_vector_state =>
                if (store_start_s = '1') then
                    store_fifos_en_next <= store_fifos_en_reg(NUM_OF_LANES - 2 downto 0) & '0';
                    if (store_fifos_en_reg (NUM_OF_LANES - 1) = '1') then
                        store_fifos_en_next <= std_logic_vector(to_unsigned(1, NUM_OF_LANES));
                    end if;
                end if;
            when others =>
        end case;
    end process;
    ---------------------------------------------------------------------------------------------------------------------------------------------
    -- OUTPUTS
    ---------------------------------------------------------------------------------------------------------------------------------------------
    
    load_address_o <= load_address_next when scalar_load_req_i = '0' else
                      scalar_address_i;
    store_address_o <= store_address_reg when scalar_store_req_i = '0' else
                       scalar_address_i;

    store_fifos_en_o <= store_fifos_en_next;
    load_fifos_en_o <= load_fifos_en_reg;

    process (clk) is
    begin
        if (rising_edge(clk))then
            if (reset = '0')then
                mem_we_o <= '0';
            else
                mem_we_o <= mem_we_s;
            end if;
        end if;
    end process;
    --generating enables for load and store fifos inside vector lanes

    



    
end behavioral;
