
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library UNIMACRO;
use UNIMACRO.vcomponents.all;
use work.custom_functions_pkg.all;


entity arbiter is
    generic (
        VECTOR_LENGTH : natural := 32;
        DATA_WIDTH    : natural := 32);
    port (
        clk                     : in std_logic;
        reset                   : in std_logic;
        ready_i                 : in std_logic;
        --input data
        vector_instruction_i    : in std_logic_vector(31 downto 0);
        rs1_i                   : in std_logic_vector(31 downto 0);
        rs2_i                   : in std_logic_vector(31 downto 0);
        --Status signals
        --scalar_core_stall_i     : in std_logic;
        load_fifo_empty_i : in    std_logic;
        store_fifo_empty_i      : in    std_logic;

        --M_CU interface
        rdy_for_load_i : in std_logic;
        rdy_for_store_i  : in std_logic;
        -- M_CU data necessary for load exe
        M_CU_ld_rs1_o             : out std_logic_vector(31 downto 0);
        M_CU_ld_rs2_o             : out std_logic_vector(31 downto 0);
        M_CU_ld_vl_o              : out std_logic_vector(clogb2(VECTOR_LENGTH * 8) downto 0);  -- vector length
        M_CU_load_valid_o      : out std_logic;
        -- M_CU data necessary for store exe
        M_CU_st_rs1_o             : out std_logic_vector(31 downto 0);
        M_CU_st_rs2_o             : out std_logic_vector(31 downto 0);
        M_CU_st_vl_o              : out std_logic_vector(clogb2(VECTOR_LENGTH * 8) downto 0);  -- vector       
        M_CU_store_valid_o      : out std_logic;
        -- outputs      
        vector_stall_o         : out std_logic;
        all_v_stores_executed_o:out std_logic;
        all_v_loads_executed_o:out std_logic;
        -- V_CU interface
        rs1_to_V_CU_i                   : out std_logic_vector(31 downto 0);
        vmul_to_V_CU_o: out std_logic_vector(1 downto 0);
        vl_to_V_CU_o: out std_logic_vector(clogb2(VECTOR_LENGTH * 8) downto 0);
        vector_instr_to_V_CU_o : out std_logic_vector(31 downto 0));
    


end entity;


architecture beh of arbiter is

    ----------------------------------------------------------------------------------------------------------------------
    -- signals necessary for sinchronization  logic 
    ----------------------------------------------------------------------------------------------------------------------    
    signal fifo_reset_s       : std_logic;
    
    ----------------------------------------------------------------------------------------------------------------------
    -- Constants and signals necessary for instruction DECODE logic
    ----------------------------------------------------------------------------------------------------------------------
    constant vector_store_c : std_logic_vector(6 downto 0) := "0100111";
    constant vector_load_c  : std_logic_vector(6 downto 0) := "0000111";
    constant vector_arith_c : std_logic_vector(6 downto 0) := "1010111";    
    alias vector_instr_opcode_a : std_logic_vector (6 downto 0) is vector_instruction_i(6 downto 0);    
    alias mop_i: std_logic_vector (1 downto 0) is vector_instruction_i(27 downto 26);
    
    signal vector_instr_check_s : std_logic_vector(1 downto 0);
    signal vector_stall_s: std_logic;
    signal vector_instr_to_V_CU_s:std_logic_vector(31 downto 0);
    
    
    ----------------------------------------------------------------------------------------------------------------------
    -- Interconnections necessary for fifos that store rs1, rs2, vl, vmul when
    -- vector LOAD instructions arives
    ----------------------------------------------------------------------------------------------------------------------
    signal all_stores_executed_s: std_logic;
    -- rs1_rs2 and vmul_vl fifo enable signals
    signal ld_instr_fifo_re_s : std_logic;
    signal ld_instr_fifo_we_s : std_logic;
    --rs1_rs2_ld_fifo interconnections
    signal rs1_rs2_ld_fifo_empty_s : std_logic;
    signal rs1_rs2_ld_fifo_full_s  : std_logic;
    signal rs1_rs2_ld_fifo_i_s     : std_logic_vector(2*DATA_WIDTH - 1 downto 0);
    signal rs1_rs2_ld_fifo_o_s     : std_logic_vector(2*DATA_WIDTH - 1 downto 0);
    --vl_ld_fifo interconnections      
    signal vl_ld_fifo_o_s : std_logic_vector(clogb2(VECTOR_LENGTH * 8) downto 0);

    -- Signals neccessary for load valid signal generation when M_CU tries to
    -- get information necessary for load execution
    signal current_ld_is_valid_s : std_logic;
    signal ld_from_fifo_is_valid_s : std_logic;
    ----------------------------------------------------------------------------------------------------------------------
    
    ----------------------------------------------------------------------------------------------------------------------
    -- Interconnections necessary for fifos that store rs1, rs2, vl, vmul when
    -- STORE instructions arive
    ----------------------------------------------------------------------------------------------------------------------   
    signal dependency_check_reg: std_logic;
    -- rs1_rs2 and vmul_vl fifo enable signals
    signal st_instr_fifo_re_s : std_logic;
    signal st_instr_fifo_we_s : std_logic;
    --rs1_rs2_st_fifo interconnections
    signal rs1_rs2_st_fifo_empty_s : std_logic;
    signal rs1_rs2_st_fifo_full_s  : std_logic;
    signal rs1_rs2_st_fifo_i_s     : std_logic_vector(2*DATA_WIDTH - 1 downto 0);
    signal rs1_rs2_st_fifo_o_s     : std_logic_vector(2*DATA_WIDTH - 1 downto 0);

    --vmul_vl_st_fifo interconnectionsa   
    
    signal vl_st_fifo_o_s : std_logic_vector(clogb2(VECTOR_LENGTH * 8) downto 0);

    signal M_CU_store_valid_s: std_logic;
    ----------------------------------------------------------------------------------------------------------------------
    -- Configuration registers
    ----------------------------------------------------------------------------------------------------------------------
    signal vl_reg_s            : std_logic_vector(clogb2(VECTOR_LENGTH * 8) downto 0) := (others => '1');
    signal vmul_reg_s          : std_logic_vector(1 downto 0):= "00";
    
    ----------------------------------------------------------------------------------------------------------------------
    -- Signals necessary for resolving dependecies with vector load
    ----------------------------------------------------------------------------------------------------------------------    
    alias vs1_i: std_logic_vector(4 downto 0) is vector_instruction_i(24 downto 20);
    alias vs2_i: std_logic_vector(4 downto 0) is vector_instruction_i(19 downto 15);
    alias vs3_i: std_logic_vector(4 downto 0) is vector_instruction_i(11 downto 7);
    signal V_CU_rdy_for_load_s: std_logic;
    --18 bits are necessary because that's how much vector loads can be
    --stored inside load fifo in vector lanes
    signal reg_write_enables_s: std_logic_vector(17 downto 0);

    --Each bit of this signal is an enable bit of one of comparators necessary
    --for resolving vector load dependecies
    signal comparator_enables_reg: std_logic_vector(17 downto 0);

    -- register in which load instruction that are not yet executed are stored
    type dependency_regs is array (0 to 17) of std_logic_vector(14 + clogb2(VECTOR_LENGTH * 8) + 1  downto 0);   
    signal load_dependency_regs:dependency_regs;
    
    
    signal load_comparators: std_logic_vector (17 downto 0);

    signal dependency_check_s: std_logic;
begin
    ----------------------------------------------------------------------------------------------------------------------
    --ARCHITECTURE BEGINS HERE
    ----------------------------------------------------------------------------------------------------------------------

    -- Instruction decode logic
    with vector_instr_opcode_a select vector_instr_check_s <=
        "10" when vector_store_c,
        "01" when vector_arith_c,
        "11" when vector_load_c,
        "00" when others;

    -- Seting vl and vmul logic
    process (clk)is
    begin
        if (rising_edge(clk))then
            if (reset = '0') then
                vl_reg_s <= std_logic_vector(to_unsigned(17, clogb2(VECTOR_LENGTH * 8) + 1));
                vmul_reg_s <= "00";
            else
                if (vector_instr_check_s = "01" and vector_instruction_i (14 downto  12) = "111") then
                    --this part of vector instruction represents vmul
                    vmul_reg_s <= vector_instruction_i(21 downto 20);
                    if (vector_instruction_i (19 downto 15) /= std_logic_vector(to_unsigned(0, 5))) then
                        vl_reg_s <= rs1_i(clogb2(VECTOR_LENGTH * 8) downto 0);
                    elsif(vector_instruction_i (11 downto 7) = std_logic_vector(to_unsigned(0,5 ))) then
                        vl_reg_s <= std_logic_vector(to_unsigned(32, clogb2(VECTOR_LENGTH * 8) + 1));
                    end if;
                end if;
            end if;
        end if;
    end process;

    
    --Vector instruction to V_CU
    -- Code segment below sends correct instructions to V_CU. First it checks if
    -- there are vector loads stored inside arbiter that need to be executed. If
    -- there are, send that instruction to V_CU (as can be seen from the code
    -- only vm, vd and opcode fields are sent).
    process (clk)is
    begin
        if (rising_edge(clk))then
            if (reset = '0')then
                vector_instr_to_V_CU_s <= (others => '0');
            else
                if (V_CU_rdy_for_load_s = '1') then
                    vl_to_V_CU_o <= load_dependency_regs(0)(clogb2(VECTOR_LENGTH*8) + 13 downto 13);
                    vmul_to_V_CU_o <= load_dependency_regs(0)(clogb2(VECTOR_LENGTH*8) + 13 +2 downto clogb2(VECTOR_LENGTH*8) + 14);
                    -- sending to V_CU  necessary fields from a vector load instruction
                    vector_instr_to_V_CU_s <= "000000"&load_dependency_regs(0)(12)&"0000000000000" & load_dependency_regs(0)(11 downto 0);
                elsif (ready_i = '1' and vector_instr_check_s /= "11" and dependency_check_s = '0') then
                    rs1_to_V_CU_i <= rs1_i;                
                    vl_to_V_CU_o <= vl_reg_s;
                    vmul_to_V_CU_o <= vmul_reg_s;
                    vector_instr_to_V_CU_s <= vector_instruction_i;
                elsif (ready_i = '1' and not(V_CU_rdy_for_load_s) = '1') then
                    vector_instr_to_V_CU_s <= (others => '0');
                end if;            
            end if;
        end if;
    end process;
    vector_instr_to_V_CU_o <= vector_instr_to_V_CU_s;

    
    --logic that handles generation of stall signal
    process (ready_i, dependency_check_s, vector_instr_check_s, reg_write_enables_s)is
    begin
        if (reg_write_enables_s(17) = '1' and vector_instr_check_s = "11")then
            vector_stall_s <= '1';
        elsif ((not(ready_i) = '1' or dependency_check_s = '1') and vector_instr_check_s /= "11") then
            vector_stall_s <= '1';
        else
            vector_stall_s <= '0';
        end if;
    end process;
    vector_stall_o <= vector_stall_s;
    

    ---------------------------------------------------------------------------------------------------------------------------------
    -- Code that handles sending LOAD instructions to the M_CU and V_CU
    ---------------------------------------------------------------------------------------------------------------------------------
    
    -- mux that choses what data is sent to M_CU. If load_fifo_empy = '1' that
    -- means there is no data in ld_fifos and currect instruction should be sent,
    -- else if fifo is not empty send stored load information.

    --vl_reg_s, vmul_reg_s add these when they are not constants
    process (rs1_rs2_ld_fifo_empty_s, rs1_i, rs2_i, rs1_rs2_ld_fifo_o_s, vl_ld_fifo_o_s, ld_from_fifo_is_valid_s, vl_reg_s) is                                                       
    begin
        if (ld_from_fifo_is_valid_s = '0') then
            M_CU_ld_rs1_o  <= rs1_i;
            M_CU_ld_rs2_o  <= rs2_i;
            M_CU_ld_vl_o   <= vl_reg_s;         
        else
            M_CU_ld_rs1_o  <= rs1_rs2_ld_fifo_o_s(2*DATA_WIDTH - 1 downto DATA_WIDTH);
            M_CU_ld_rs2_o  <= rs1_rs2_ld_fifo_o_s(DATA_WIDTH - 1 downto 0);
            M_CU_ld_vl_o   <= vl_ld_fifo_o_s(clogb2(VECTOR_LENGTH * 8) downto 0);
        end if;
    end process;

    --Logic that generates valid signal to indicate that the data sent to M_CU
    --is valid.
    M_CU_load_valid_o <= ld_from_fifo_is_valid_s;
    
    -- this here checks if all stores have executed and stored the data from VRF
    -- to memory. This is necessary to check because no load should execute
    -- until all storess have finished. In this manner data dependecy is avoided
    all_stores_executed_s <= not(M_CU_store_valid_s)  and store_fifo_empty_i;
    
    process (rs1_rs2_ld_fifo_empty_s, vector_instr_check_s, ld_instr_fifo_re_s, clk, rdy_for_load_i, rs1_rs2_ld_fifo_empty_s, all_stores_executed_s) is
    begin      
        -- if data is read from ld fifo generate a valid pulse
        if (rising_edge(clk)) then
            if (reset = '0') then
                ld_from_fifo_is_valid_s <= '0';
            else
                if (ld_instr_fifo_re_s = '1' and ld_from_fifo_is_valid_s = '0') then
                    ld_from_fifo_is_valid_s <= '1';
                elsif (ld_from_fifo_is_valid_s = '1' and rdy_for_load_i = '1') then
                    ld_from_fifo_is_valid_s <= '0';
                end if;
            end if;
        end if;      
    end process;


    --generating read enable and write enable for fifo block that are necessary
    --for storing load data that M_CU needs
    ld_instr_fifo_re_s <= all_stores_executed_s and not(ld_from_fifo_is_valid_s) and (not(rs1_rs2_ld_fifo_empty_s)) when reset = '1' else '0';
    
    --check if received instructions i load and check if load_dependency_regs is
    --full.
    ld_instr_fifo_we_s <= '1' when vector_instr_check_s = "11" and reg_write_enables_s(17) = '0' and reset = '1' else
                          '0';
    --reset needs to be inverted because fifo blocks expect a logic 1 when reset
    --is aplied and system expects logic 0
    fifo_reset_s <= not(reset);
    
    
    --concatanating rs1 and and offset. Depenending on received load
    --instruction (strided or non-strided) offset is rs2 or a constant equal to
    --4 (minimum distance beetween two 32 bit elements).
    rs1_rs2_ld_fifo_i_s <= rs1_i & rs2_i when mop_i(1) = '1' else
                           rs1_i & std_logic_vector(to_unsigned(4, 32));

    
    LOAD_RS1_RS2_FIFO : FIFO_SYNC_MACRO
        generic map (
            DEVICE              => "7SERIES",  -- Target Device: "VIRTEX5, "VIRTEX6", "7SERIES" 
            ALMOST_FULL_OFFSET  => X"0080",    -- Sets almost full threshold
            ALMOST_EMPTY_OFFSET => X"0080",    -- Sets the almost empty threshold
            DATA_WIDTH          => DATA_WIDTH * 2,  -- Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
            FIFO_SIZE           => "36Kb")     -- Target BRAM, "18Kb" or "36Kb" 
        port map (
            ALMOSTEMPTY => open,           -- 1-bit output almost empty
            ALMOSTFULL  => open,           -- 1-bit output almost full
            DO          => rs1_rs2_ld_fifo_o_s,  -- Output data, width defined by DATA_WIDTH parameter
            EMPTY       => rs1_rs2_ld_fifo_empty_s,  -- 1-bit output empty
            FULL        => rs1_rs2_ld_fifo_full_s,  -- 1-bit output full
            RDCOUNT     => open,  -- Output read count, width determined by FIFO depth
            RDERR       => open,           -- 1-bit output read error
            WRCOUNT     => open,  -- Output write count, width determined by FIFO depth
            WRERR       => open,           -- 1-bit output write error
            CLK         => clk,            -- 1-bit input clock
            DI          => rs1_rs2_ld_fifo_i_s,  -- Input data, width defined by DATA_WIDTH parameter
            RDEN        => ld_instr_fifo_re_s,   -- 1-bit input read enable
            RST         => fifo_reset_s,   -- 1-bit input reset
            WREN        => ld_instr_fifo_we_s  -- 1-bit input write enable
            );


    
    LOAD_VL_FIFO : FIFO_SYNC_MACRO
        generic map (
            DEVICE              => "7SERIES",  -- Target Device: "VIRTEX5, "VIRTEX6", "7SERIES" 
            ALMOST_FULL_OFFSET  => X"0080",    -- Sets almost full threshold
            ALMOST_EMPTY_OFFSET => X"0080",    -- Sets the almost empty threshold
            DATA_WIDTH          => clogb2(VECTOR_LENGTH * 8) + 1,  -- Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
            FIFO_SIZE           => "18Kb")     -- Target BRAM, "18Kb" or "36Kb" 
        port map (
            ALMOSTEMPTY => open,           -- 1-bit output almost empty
            ALMOSTFULL  => open,           -- 1-bit output almost full
            DO          => vl_ld_fifo_o_s,  -- Output data, width defined by DATA_WIDTH parameter
            EMPTY       => open,           -- 1-bit output empty
            FULL        => open,           -- 1-bit output full
            RDCOUNT     => open,  -- Output read count, width determined by FIFO depth
            RDERR       => open,           -- 1-bit output read error
            WRCOUNT     => open,  -- Output write count, width determined by FIFO depth
            WRERR       => open,           -- 1-bit output write error
            CLK         => clk,            -- 1-bit input clock
            DI          => vl_reg_s,  -- Input data, width defined by DATA_WIDTH parameter
            RDEN        => ld_instr_fifo_re_s,   -- 1-bit input read enable
            RST         => fifo_reset_s,   -- 1-bit input reset
            WREN        => ld_instr_fifo_we_s  -- 1-bit input write enable
            );

---------------------------------------------------------------------------------------------------------------------------------
    -- Code that handles sending STORE instructions to the M_CU and V_CU.
---------------------------------------------------------------------------------------------------------------------------------
    --logic that checks if in previous clock cycle stall wass 1;
    process (clk) is
    begin
        if (rising_edge(clk))then
            if (reset = '0')then
                dependency_check_reg <= '0';
            else
                dependency_check_reg <= dependency_check_s;
            end if;
        end if;
    end process;
    --logic for generating write enable signals for store fifos

    
    st_instr_fifo_we_s <= '1' when vector_instr_check_s = "10" and dependency_check_s = '0' and vector_stall_s = '0' else
                          '1' when vector_instr_check_s = "10" and dependency_check_s = '0' and dependency_check_reg = '1' else
                          '0';
    
    --logic for generating read enable signals for store fifos
    --st_instr_fifo_re_s <= not(store_fifo_empty_i) and not(rs1_rs2_st_fifo_empty_s) and not(M_CU_store_valid_s);
    st_instr_fifo_re_s <= not(rs1_rs2_st_fifo_empty_s) and not(M_CU_store_valid_s);

    --logic for generating valid signal to signalaze that valid data has been
    --read from fifo.
    
    M_CU_store_valid_o <= M_CU_store_valid_s;
    process (clk)is
    begin
        if (rising_edge(clk))then
            if (reset = '0') then
                M_CU_store_valid_s <= '0';
            else
                if (not(M_CU_store_valid_s) = '1' and st_instr_fifo_re_s = '1')then
                    M_CU_store_valid_s <= '1';
                elsif (M_CU_store_valid_s = '1' and rdy_for_store_i = '1') then
                    M_CU_store_valid_s <= '0';
                end if;
            end if;
        end if;        
    end process;


    process (rs1_i, rs2_i, rs1_rs2_st_fifo_o_s, vl_st_fifo_o_s, M_CU_store_valid_s) is                                                       
    begin
        if (M_CU_store_valid_s = '0') then
            M_CU_st_rs1_o  <= (others => '0') ;
            M_CU_st_rs2_o  <= (others => '0');
            M_CU_st_vl_o   <= (others => '0');         
        else
            M_CU_st_rs1_o  <= rs1_rs2_st_fifo_o_s(2*DATA_WIDTH - 1 downto DATA_WIDTH);
            M_CU_st_rs2_o  <= rs1_rs2_st_fifo_o_s(DATA_WIDTH - 1 downto 0);
            M_CU_st_vl_o   <= vl_st_fifo_o_s(clogb2(VECTOR_LENGTH * 8) downto 0);        
        end if;
    end process;

    --concatanating rs1 and and offset. Depenending on received store
    --instruction (strided or non-strided) offset is rs2 or a constant equal to
    --4 (minimum distance beetween two 32 bit elements).
    rs1_rs2_st_fifo_i_s <= rs1_i & rs2_i when mop_i(1) = '1' else
                           rs1_i & std_logic_vector(to_unsigned(4, 32));
    
    STORE_RS1_RS2_FIFO : FIFO_SYNC_MACRO
        generic map (
            DEVICE              => "7SERIES",  -- Target Device: "VIRTEX5, "VIRTEX6", "7SERIES" 
            ALMOST_FULL_OFFSET  => X"0080",    -- Sets almost full threshold
            ALMOST_EMPTY_OFFSET => X"0080",    -- Sets the almost empty threshold
            DATA_WIDTH          => DATA_WIDTH * 2,  -- Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
            FIFO_SIZE           => "36Kb")     -- Target BRAM, "18Kb" or "36Kb" 
        port map (
            ALMOSTEMPTY => open,           -- 1-bit output almost empty
            ALMOSTFULL  => open,           -- 1-bit output almost full
            DO          => rs1_rs2_st_fifo_o_s,  -- Output data, width defined by DATA_WIDTH parameter
            EMPTY       => rs1_rs2_st_fifo_empty_s,  -- 1-bit output empty
            FULL        => rs1_rs2_st_fifo_full_s,  -- 1-bit output full
            RDCOUNT     => open,  -- Output read count, width determined by FIFO depth
            RDERR       => open,           -- 1-bit output read error
            WRCOUNT     => open,  -- Output write count, width determined by FIFO depth
            WRERR       => open,           -- 1-bit output write error
            CLK         => clk,            -- 1-bit input clock
            DI          => rs1_rs2_st_fifo_i_s,  -- Input data, width defined by DATA_WIDTH parameter
            RDEN        => st_instr_fifo_re_s,   -- 1-bit input read enable
            RST         => fifo_reset_s,   -- 1-bit input reset
            WREN        => st_instr_fifo_we_s  -- 1-bit input write enable
            );


    
    STORE_VL_VMUL_FIFO : FIFO_SYNC_MACRO
        generic map (
            DEVICE              => "7SERIES",  -- Target Device: "VIRTEX5, "VIRTEX6", "7SERIES" 
            ALMOST_FULL_OFFSET  => X"0080",    -- Sets almost full threshold
            ALMOST_EMPTY_OFFSET => X"0080",    -- Sets the almost empty threshold
            DATA_WIDTH          => clogb2(VECTOR_LENGTH * 8) + 1,  -- Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
            FIFO_SIZE           => "18Kb")     -- Target BRAM, "18Kb" or "36Kb" 
        port map (
            ALMOSTEMPTY => open,           -- 1-bit output almost empty
            ALMOSTFULL  => open,           -- 1-bit output almost full
            DO          => vl_st_fifo_o_s,  -- Output data, width defined by DATA_WIDTH parameter
            EMPTY       => open,           -- 1-bit output empty
            FULL        => open,           -- 1-bit output full
            RDCOUNT     => open,  -- Output read count, width determined by FIFO depth
            RDERR       => open,           -- 1-bit output read error
            WRCOUNT     => open,  -- Output write count, width determined by FIFO depth
            WRERR       => open,           -- 1-bit output write error
            CLK         => clk,            -- 1-bit input clock
            DI          => vl_reg_s,  -- Input data, width defined by DATA_WIDTH parameter
            RDEN        => st_instr_fifo_re_s,   -- 1-bit input read enable
            RST         => fifo_reset_s,   -- 1-bit input reset
            WREN        => st_instr_fifo_we_s  -- 1-bit input write enable
            );

---------------------------------------------------------------------------------------------------------------------------------
    -- Code that handles vector instruction dependecies
---------------------------------------------------------------------------------------------------------------------------------
    
    --logic that checks if V_CU is ready to execute load instruction
    V_CU_rdy_for_load_s <= dependency_check_s and ready_i and not(load_fifo_empty_i) and all_stores_executed_s;
    -- comparison_o register write en
    process (clk)is
    begin
        if (rising_edge(clk)) then
            if (reset = '0') then
                reg_write_enables_s <= std_logic_vector(to_unsigned(1, 18));
            else   
                if (vector_instr_check_s = "11") then
                    reg_write_enables_s <= reg_write_enables_s(16 downto 0) & '0';               
                elsif(V_CU_rdy_for_load_s = '1') then
                    reg_write_enables_s <= '0' & reg_write_enables_s(17 downto 1);
                end if;
            end if;
        end if;
    end process;

    --enable for comparators
    process (clk)is
    begin
        if (rising_edge(clk)) then
            if (reset = '0') then
                comparator_enables_reg <= (others => '0');
            else   
                if (vector_instr_check_s = "11") then
                    comparator_enables_reg<= comparator_enables_reg(16 downto 0) & '1';               
                elsif(V_CU_rdy_for_load_s = '1') then
                    comparator_enables_reg<= '0' & comparator_enables_reg(17 downto 1);
                end if;
            end if;
        end if;
    end process;

    --registers used for storing load instruction so they can be compared to
    --incoming instruction and checked if there is dependecy between them.
    -- In this code segment 18 registers are created and depending on vector
    -- instruction are connected in PIPO format or PISO. Something like a
    -- fifo buffer, but whose elements can all be read in parallel but only
    -- first written element can be read out.
    process (clk)is
    begin
        if (rising_edge(clk))then
            if (reset = '0') then
                load_dependency_regs <= (others => (others =>'0'));
            else 
                for i in 0 to 17 loop
                    if(vector_instr_check_s = "11") then
                        if (reg_write_enables_s(i) = '1') then
                            load_dependency_regs(i) <= vmul_reg_s & vl_reg_s & vector_instruction_i(25) & vector_instruction_i(11 downto 0);                   
                        end if;
                    elsif (V_CU_rdy_for_load_s = '1') then
                        if (i = 0) then 
                            load_dependency_regs(0) <= load_dependency_regs(i + 1);
                        elsif (i = 17) then
                            load_dependency_regs(17) <= (others =>'0');
                        else
                            load_dependency_regs(i) <= load_dependency_regs(i + 1);
                        end if;
                    end if;
                end loop;
            end if;
        end if;
    end process;


    --Code segment bellow generates 18 comparators that check whether or not
    --there are dependecies between load instructions that haven't been executed
    --and incoming instructions
    process (comparator_enables_reg, vs1_i, vs2_i, vs3_i, load_dependency_regs, vector_instr_check_s) is
    begin
        for i in 0 to 17 loop
            if (vector_instr_check_s /= "11" and comparator_enables_reg(i) = '1' and (vs1_i = load_dependency_regs(i)(11 downto 7) or
                                                                                      vs2_i = load_dependency_regs(i)(11 downto 7) or
                                                                                      vs3_i = load_dependency_regs(i)(11 downto 7)))  then
                load_comparators(i) <= '1';
            else
                load_comparators(i) <= '0';
            end if;         
        end loop;
    end process;
    
    process (load_comparators)is
    begin
        if (load_comparators = std_logic_vector(to_unsigned(0, 18))) then
            dependency_check_s <= '0';
        else
            dependency_check_s <= '1';
        end if ;
    end process;   
---------------------------------------------------------------------------------------------------------------------------------
    -- Code that handles that checks if all vector stores and loads have been executed    
---------------------------------------------------------------------------------------------------------------------------------
    -- all stores have been executed if M_CU is rdy for another ifstore
    -- fifos inside vector lanes are empty, rs1_rs2 store fifos are empty
    -- (there are no pending stores) and current instructions is not a vectore
    -- store
    all_v_stores_executed_o <= store_fifo_empty_i and rs1_rs2_st_fifo_empty_s and not(vector_instr_check_s(1)) and vector_instr_check_s(0);

    -- all loads have been executed if M_CU is rdy for another load, there is
    -- no valid data inside rs1_rs2 load fifo and current instruction is not a
    -- vector load (vector_instr_check_s != "11")
    all_v_loads_executed_o <= rdy_for_load_i and not(ld_from_fifo_is_valid_s) and not(vector_instr_check_s(1)) and not(vector_instr_check_s(0));
end architecture;


