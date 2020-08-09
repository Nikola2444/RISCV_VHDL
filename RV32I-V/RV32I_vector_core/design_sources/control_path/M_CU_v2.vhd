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
        store_fifos_empty_i: in std_logic;
        --scalar core interface
        scalar_load_req_i  : in std_logic;
        scalar_store_req_i : in std_logic;
        scalar_address_i   : in std_logic_vector(31 downto 0);        
        --Memory interface        
        data_mem_addr_o  : out std_logic_vector(31 downto 0);
        mem_we_o        : out std_logic;
        mem_re_o        : out std_logic;

        --Vector lane Load/store fifo interface
        store_fifos_en_o :out std_logic_vector(NUM_OF_LANES - 1 downto 0);
        load_fifos_en_o  :out std_logic_vector(NUM_OF_LANES - 1 downto 0)

        );


    
end entity;

architecture behavioral of M_CU is
    --signals and types needed for LOAD instructions
    type load_fsm_states is (waiting_for_ld_or_st, store_vector_state, load_vector_state, load_vector_state_2);
    signal ld_st_fsm_states_reg, ld_st_fsm_states_next   : load_fsm_states;
    signal data_mem_addr_next, data_mem_addr_reg         : std_logic_vector(31 downto 0);
    signal ld_st_counter_next, ld_st_counter_reg         : std_logic_vector(clogb2(8 * VECTOR_LENGTH) downto 0);
    signal ld_st_vl_reg, ld_st_vl_next                   : std_logic_vector(clogb2(8 * VECTOR_LENGTH) downto 0);
    signal vector_ld_st_rs2_next, vector_ld_st_rs2_reg       : std_logic_vector(31 downto 0);
    signal load_start_s                                : std_logic;
    signal load_fifos_en_reg, load_fifos_en_next       : std_logic_vector(NUM_OF_LANES - 1 downto 0);
    --signals and types needed for STORE instructions                
    signal store_start_s                               : std_logic;
    signal store_fifos_en_reg, store_fifos_en_next     : std_logic_vector(NUM_OF_LANES -1 downto 0);
    signal mem_we_next, mem_we_reg: std_logic;

begin
    
    process (clk)is
    begin
        if (rising_edge(clk))then
            if (reset = '0')then
                --registers needed for load and store instructions
                ld_st_fsm_states_reg  <= waiting_for_ld_or_st;
                vector_ld_st_rs2_reg    <= (others => '0');
                data_mem_addr_reg     <= (others => '0');
                ld_st_vl_reg          <= (others => '0');
                ld_st_counter_reg     <= (others => '0');
                --registers needed for load instructions                
                load_fifos_en_reg    <= (others => '0');
                --registers needed for store instructions                
                store_fifos_en_reg   <= (others => '0');
                mem_we_reg <= '0';
            else
                --registers needed for load and store instructions
                ld_st_fsm_states_reg  <= ld_st_fsm_states_next;
                vector_ld_st_rs2_reg    <= vector_ld_st_rs2_next;
                data_mem_addr_reg     <= data_mem_addr_next;
                ld_st_vl_reg          <= ld_st_vl_next;
                ld_st_counter_reg     <= ld_st_counter_next;
                --registers needed for load instructions                                                                
                load_fifos_en_reg    <= load_fifos_en_next;
                --registers needed for store instructions                                                                
                store_fifos_en_reg   <= store_fifos_en_next;
                mem_we_reg <= mem_we_next;
            end if;
        end if;
    end process;


    ---------------------------------------------------------------------------------------------------------------------------------------------
    -- logic that handles LOADING and STORING data
    ---------------------------------------------------------------------------------------------------------------------------------------------

    process (ld_st_fsm_states_next, ld_st_fsm_states_reg, vector_ld_st_rs2_next, store_fifos_empty_i,
             vector_ld_st_rs2_reg, M_CU_load_valid_i, M_CU_store_valid_i, scalar_address_i,
             scalar_load_req_i, scalar_store_req_i, ld_st_vl_reg, ld_st_vl_next, data_mem_addr_next, data_mem_addr_reg,
             ld_st_counter_reg, ld_st_counter_next, M_CU_ld_vl_i, M_CU_st_vl_i, M_CU_ld_rs1_i, M_CU_ld_rs2_i,M_CU_st_rs1_i,
             M_CU_st_rs2_i, mem_we_reg) is
    begin
        --load default values        
        vector_ld_st_rs2_next <= vector_ld_st_rs2_reg;
        mem_re_o           <= '0';
        M_CU_load_done_i <= '0';
        rdy_for_load_o     <= '0';       
        load_start_s       <= '0';
        --store default values
        store_start_s       <= '0';        
        mem_we_next              <= '0';
        rdy_for_store_o <= '0';
        -- Load and store default values
        ld_st_counter_next  <= ld_st_counter_reg;
        data_mem_addr_next  <= data_mem_addr_reg;
        ld_st_vl_next       <= ld_st_vl_reg;
        -- FSM
        case ld_st_fsm_states_reg is
            when waiting_for_ld_or_st =>
                -- scalar loads and storeshave a higher priority because they only extract one
                -- element from memory, and vector loads extrac VECTOR_LENGTH
                -- elements from the memory.
                -- if there is a valid vector store start reading data from the memory.                    
                -- Raise rdy_for_store_o for one clock cycle (that is the
                -- handshake the arbiter expects). The same goes for vector
                -- loads, only rdy_for_load is being set   
                ld_st_fsm_states_next <= waiting_for_ld_or_st;                
                if (scalar_load_req_i = '1') then
                    data_mem_addr_next <= scalar_address_i;
                    mem_re_o          <= '1';
                elsif (scalar_store_req_i = '1') then
                        data_mem_addr_next <= scalar_address_i;                        
                elsif (M_CU_store_valid_i = '1' and
                       M_CU_st_vl_i /= std_logic_vector(to_unsigned(0, clogb2(VECTOR_LENGTH * 8) + 1)) and
                       store_fifos_empty_i = '0') then
                    ld_st_fsm_states_next <= store_vector_state;
                    rdy_for_store_o <= '1';
                    mem_we_next        <= '1';
                    store_start_s      <= '1';
                    -- register vl, rs1 and rs2
                    ld_st_vl_next      <= M_CU_st_vl_i;
                    vector_ld_st_rs2_next <= M_CU_st_rs2_i;
                    -- set write address and increment the counter
                    data_mem_addr_next <= M_CU_st_rs1_i;
                    ld_st_counter_next <= std_logic_vector(unsigned(ld_st_counter_reg) + to_unsigned(1, clogb2(VECTOR_LENGTH * 8) + 1));                    
                elsif (M_CU_load_valid_i = '1' and
                       M_CU_ld_vl_i /= std_logic_vector(to_unsigned(0, clogb2(VECTOR_LENGTH * 8) + 1))) then
                    -- if there is a valid vector load start reading data from the memory.
                    ld_st_fsm_states_next <= load_vector_state;
                    -- Raise rdy_for_load_o for one clock cycle (that is the
                    -- handshake the arbiter expects)
                    rdy_for_load_o <= '1';
                    mem_re_o       <= '1';
                    load_start_s      <= '1';                    
                    -- register vl, rs1 and rs2
                    ld_st_vl_next       <= M_CU_ld_vl_i;
                    vector_ld_st_rs2_next <= M_CU_ld_rs2_i;
                    -- set read address and increment the counter
                    data_mem_addr_next <= M_CU_ld_rs1_i;
                    ld_st_counter_next <= std_logic_vector(unsigned(ld_st_counter_reg) + to_unsigned(1, clogb2(VECTOR_LENGTH * 8) + 1));
                end if;
                
            when load_vector_state =>
                mem_re_o             <= '1';
                load_start_s         <= '1';
                ld_st_fsm_states_next <= load_vector_state;
                -- if there is a scalar load pending, stop with vector load
                -- execution for one clock cycle, extract the data necessary for
                -- scalar load, and then continue with vector load
                if (scalar_load_req_i = '0') then
                    data_mem_addr_next    <= std_logic_vector (unsigned(vector_ld_st_rs2_reg) + unsigned(data_mem_addr_reg));
                    ld_st_counter_next    <= std_logic_vector(unsigned(ld_st_counter_reg) + to_unsigned(1, clogb2(VECTOR_LENGTH * 8) + 1));
                    if (ld_st_counter_reg = ld_st_vl_reg) then
                        ld_st_fsm_states_next <= load_vector_state_2;
                        mem_re_o         <= '0';
                        M_CU_load_done_i <= '1';
                        ld_st_counter_next    <= (others => '0');
                    end if;
                else
                    load_start_s <= '0';
                end if;                
            when store_vector_state =>
                mem_we_next              <= '1';
                store_start_s         <= '1';
                ld_st_fsm_states_next <= store_vector_state;
                data_mem_addr_next    <= std_logic_vector (unsigned(vector_ld_st_rs2_reg) + unsigned(data_mem_addr_reg));
                ld_st_counter_next    <= std_logic_vector(unsigned(ld_st_counter_reg) + to_unsigned(1, clogb2(VECTOR_LENGTH * 8) + 1));
                if (ld_st_counter_reg = std_logic_vector(unsigned(ld_st_vl_reg) - to_unsigned(1, clogb2(VECTOR_LENGTH / NUM_OF_LANES *8) + 1))) then
                    ld_st_fsm_states_next <= waiting_for_ld_or_st;
                    ld_st_counter_next    <= (others => '0');
                end if;
            when others =>
                ld_st_fsm_states_next <= waiting_for_ld_or_st;                
        end case;
    end process;


        -- Logic that generates enables for load fifos
    process (ld_st_fsm_states_reg, load_fifos_en_next, load_fifos_en_reg, load_start_s, ld_st_counter_reg, ld_st_counter_reg)is
    begin
        load_fifos_en_next <= load_fifos_en_reg;
        case ld_st_fsm_states_reg is
            when waiting_for_ld_or_st =>
                load_fifos_en_next <= (others => '0');
                if (load_start_s = '1') then
                    load_fifos_en_next <= std_logic_vector(to_unsigned(1, NUM_OF_LANES));
                end if;
            when load_vector_state =>
                if (load_start_s = '1') then
                    load_fifos_en_next <= load_fifos_en_reg(NUM_OF_LANES - 2 downto 0) & '0';
                    if (ld_st_counter_reg = ld_st_vl_reg) then
                        load_fifos_en_next <= (others => '0');
                    elsif (load_fifos_en_reg (NUM_OF_LANES - 1) = '1') then
                        load_fifos_en_next <= std_logic_vector(to_unsigned(1, NUM_OF_LANES));
                    end if;
                end if;
            when others =>
        end case;
    end process;

    
    -- Logic that generates enables for store fifos
    process (ld_st_fsm_states_reg, store_fifos_en_next, store_fifos_en_reg, store_start_s)is
    begin
        store_fifos_en_next <= store_fifos_en_reg;
        case ld_st_fsm_states_reg is
            when waiting_for_ld_or_st =>
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


    -----------------------------------------------------------------------------
    -- OUTPUTS
    -----------------------------------------------------------------------------
    mem_we_o <= '1' when scalar_store_req_i = '1' else
                mem_we_reg;
    data_mem_addr_o <= data_mem_addr_reg when store_start_s = '1' else
                       data_mem_addr_next;
    -- Enable signal for store fifos inside vector lanes. If there are multiple
    -- lanes it decides from which vector lane fifo the data is taken. This is
    -- done in cyclical manner.
    store_fifos_en_o <= store_fifos_en_next;    
    -- Enable signal for load fifos inside vector lanes. If there are multiple
    -- lanes it decides into which vector lane fifo the data should be stored. This is
    -- done in cyclical manner.
    load_fifos_en_o <= load_fifos_en_reg when load_start_s = '1' else
                       (others => '0');

    

end behavioral;



