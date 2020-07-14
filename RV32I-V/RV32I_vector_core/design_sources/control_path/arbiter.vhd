
library ieee;
use ieee.std_logic_1164.all;
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
      scalar_core_stall_i     : in std_logic;
      load_fifo_empty_i :    std_logic;
      store_fifo_empty_i      :    std_logic;

      --M_CU interface
      rdy_for_load_i : in std_logic;
      rdy_for_store_i  : in std_logic;

      M_CU_rs1_o             : out std_logic_vector(31 downto 0);
      M_CU_rs2_o             : out std_logic_vector(31 downto 0);
      M_CU_vl_o              : out std_logic_vector(clogb2(VECTOR_LENGTH * 8) downto 0);  -- vector length
      M_CU_vmul_o            : out std_logic_vector(1 downto 0);
      M_CU_load_valid_o      : out std_logic;
      -- outputs
      vector_id_ex_en_o      : out std_logic;
      vector_stall_o         : out std_logic;
      vector_instr_to_V_CU_o : out std_logic_vector(31 downto 0);
      vector_instr_to_M_CU_o : out std_logic_vector(31 downto 0));
end entity;


architecture beh of arbiter is


   constant vector_store_c : std_logic_vector(6 downto 0) := "0100111";
   constant vector_load_c  : std_logic_vector(6 downto 0) := "0000111";
   constant vector_arith_c : std_logic_vector(6 downto 0) := "1010111";

   alias vector_instr_opcode_a : std_logic_vector (6 downto 0) is vector_instruction_i(6 downto 0);
   signal opcode_s             : std_logic_vector (6 downto 0);
   signal vector_instr_check_s : std_logic_vector(1 downto 0);

   signal inverted_ld_re_s: std_logic;
   ----------------------------------------------------------------------------------------------------------------------
   --rs1_rs2 and vmul_vl fifo interconnections

   -- rs1_rs2 and vmul_vl fifo enable signals
   signal ld_instr_fifo_re_s : std_logic;
   signal ld_instr_fifo_we_s : std_logic;
   signal fifo_reset_s       : std_logic;

   --rs1_rs2_ld_fifo interconnections
   signal rs1_rs2_ld_fifo_empty_s : std_logic;
   signal rs1_rs2_ld_fifo_full_s  : std_logic;
   signal rs1_rs2_ld_fifo_i_s     : std_logic_vector(2*DATA_WIDTH - 1 downto 0);
   signal rs1_rs2_ld_fifo_o_s     : std_logic_vector(2*DATA_WIDTH - 1 downto 0);

   --vmul_vl_ld_fifo interconnectionsa   
   signal vl_vmul_ld_fifo_i_s : std_logic_vector(clogb2(VECTOR_LENGTH * 8) + 2 downto 0);
   signal vl_vmul_ld_fifo_o_s : std_logic_vector(clogb2(VECTOR_LENGTH * 8) + 2 downto 0);
   ----------------------------------------------------------------------------------------------------------------------
   -- Configuration registers
   constant vl_reg_s            : std_logic_vector(clogb2(VECTOR_LENGTH * 8) downto 0) := (others => '1');
   constant vmul_reg_s          : std_logic_vector(1 downto 0):= "00";


   -- Signals neccessary for load valid signal generation
   signal current_ld_is_valid_s : std_logic;
   signal ld_from_fifo_is_valid : std_logic;
begin

   -- Instruction decode logic
   with vector_instr_opcode_a select vector_instr_check_s <=
      "10" when vector_store_c,
      "01" when vector_arith_c,
      "11" when vector_load_c,
      "00" when others;

   ---------------------------------------------------------------------------------------------------------------------------------
   -- Code that handles sending load instructions to the M_CU
   -- mux that choses what data is sent to M_CU. If load_fifo_empy = '1' that
   -- means there is no data in ld_fifos and currect instruction should be sent,
   -- else if fifo is not empty send stored load information.

   --vl_reg_s, vmul_reg_s add these when they are not constants
   process (rs1_rs2_ld_fifo_empty_s, rs1_i, rs2_i, rs1_rs2_ld_fifo_o_s, vl_vmul_ld_fifo_o_s) is                                                       
   begin
      if (ld_from_fifo_is_valid = '0') then
         M_CU_rs1_o  <= rs1_i;
         M_CU_rs2_o  <= rs2_i;
         M_CU_vl_o   <= vl_reg_s;
         M_CU_vmul_o <= vmul_reg_s;
      else
         M_CU_rs1_o  <= rs1_rs2_ld_fifo_o_s(2*DATA_WIDTH - 1 downto DATA_WIDTH);
         M_CU_rs2_o  <= rs1_rs2_ld_fifo_o_s(DATA_WIDTH - 1 downto 0);
         M_CU_vl_o   <= vl_vmul_ld_fifo_o_s(clogb2(VECTOR_LENGTH * 8) + 2 downto 2);
         M_CU_vmul_o <= vl_vmul_ld_fifo_o_s(1 downto 0);
      end if;
   end process;

   --Logic that generates valid signal to indicate that the data sent to M_CU
   --is valid.
   M_CU_load_valid_o <= ld_from_fifo_is_valid or current_ld_is_valid_s;
   
   process (rs1_rs2_ld_fifo_empty_s, vector_instr_check_s, ld_instr_fifo_re_s, clk, rdy_for_load_i) is
   begin
      if (rs1_rs2_ld_fifo_empty_s = '1' and vector_instr_check_s = "11" and rdy_for_load_i = '1') then
         current_ld_is_valid_s <= '1';
      else
         current_ld_is_valid_s <= '0';
      end if;
      if (rising_edge(clk)) then
         if (ld_instr_fifo_re_s = '1' ) then
            ld_from_fifo_is_valid <= '1';
         else
            ld_from_fifo_is_valid <= '0';
         end if;
      end if;
      
      if (rising_edge(clk))then
         if (reset = '0')then
            inverted_ld_re_s <= '0';
         else
            inverted_ld_re_s <= not rdy_for_load_i;
         end if;
      end if;
      
   end process;


   --genereting read enable and write enable for fifo block that are necessary
   --for storing load data that M_CU needs
   ld_instr_fifo_re_s <= (rdy_for_load_i and inverted_ld_re_s and (not(rs1_rs2_ld_fifo_empty_s))) when reset = '1' else '0';
   -- ld_instr_fifo_we_s <= '1' when (rs1_rs2_ld_fifo_empty_s = '0' and vector_instr_check_s = "11") and reset = '1' else
   --                       '1' when ld_from_fifo_is_valid = '1' and vector_instr_check_s = "11" and reset = '1' else
   --                       '1' when rdy_for_load_i = '0' and vector_instr_check_s = "11" and reset = '1'else
   --                       '0';

   
   ld_instr_fifo_we_s <= '1' when (not(rs1_rs2_ld_fifo_empty_s) = '1' or (not(rs1_rs2_ld_fifo_empty_s)) = '1' or not(rdy_for_load_i) = '1') and vector_instr_check_s = "11" and reset = '1' else
                         '0';
   --reset needs to be inverted because fifo blocks expect a logic 1 when reset
   --is aplied and system expects logic 0
   fifo_reset_s <= not(reset);

   --concatanating vl and vmul
   vl_vmul_ld_fifo_i_s <= vl_reg_s & vmul_reg_s;

   --concatanating rs1 and rs2
   rs1_rs2_ld_fifo_i_s <= rs1_i & rs2_i;

   
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


   
   LOAD_VL_VMUL_FIFO : FIFO_SYNC_MACRO
      generic map (
         DEVICE              => "7SERIES",  -- Target Device: "VIRTEX5, "VIRTEX6", "7SERIES" 
         ALMOST_FULL_OFFSET  => X"0080",    -- Sets almost full threshold
         ALMOST_EMPTY_OFFSET => X"0080",    -- Sets the almost empty threshold
         DATA_WIDTH          => clogb2(VECTOR_LENGTH * 8) + 1 + 2,  -- Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
         FIFO_SIZE           => "18Kb")     -- Target BRAM, "18Kb" or "36Kb" 
      port map (
         ALMOSTEMPTY => open,           -- 1-bit output almost empty
         ALMOSTFULL  => open,           -- 1-bit output almost full
         DO          => vl_vmul_ld_fifo_o_s,  -- Output data, width defined by DATA_WIDTH parameter
         EMPTY       => open,           -- 1-bit output empty
         FULL        => open,           -- 1-bit output full
         RDCOUNT     => open,  -- Output read count, width determined by FIFO depth
         RDERR       => open,           -- 1-bit output read error
         WRCOUNT     => open,  -- Output write count, width determined by FIFO depth
         WRERR       => open,           -- 1-bit output write error
         CLK         => clk,            -- 1-bit input clock
         DI          => vl_vmul_ld_fifo_i_s,  -- Input data, width defined by DATA_WIDTH parameter
         RDEN        => ld_instr_fifo_re_s,   -- 1-bit input read enable
         RST         => fifo_reset_s,   -- 1-bit input reset
         WREN        => ld_instr_fifo_we_s  -- 1-bit input write enable
         );

---------------------------------------------------------------------------------------------------------------------------------
end architecture;

