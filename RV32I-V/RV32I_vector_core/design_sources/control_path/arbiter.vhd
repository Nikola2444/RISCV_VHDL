
library ieee;
use ieee.std_logic_1164.all;
use work.custom_functions_pkg.all;


entity arbiter is
   generic (
      VECTOR_LENGTH: natural := 32;
      DATA_WIDTH: natural := 32);
   port (
      clk: in std_logic;
      reset: in std_logic;
      ready_i                    : in  std_logic;
      --input data
      vector_instruction_i       : in  std_logic_vector(31 downto 0);
      rs1_i: in std_logic_vector(31 downto 0);
      rs2_i: in std_logic_vector(31 downto 0);
      --Status signals
      scalar_core_stall_i: in std_logic;
      rs1_rs2_ld_fifo_empty_s: std_logic;
      store_fifo_empty: std_logic;

      --M_CU interface
      rdy_for_load_i: in std_logic;
      rdy_for_store: in std_logic;

      M_CU_rs1_o: out std_logic_vector(31 downto 0);
      M_CU_rs2: out std_logic_vector(31 downto 0);
      M_CU_vl_o: out std_logic_vector(31 downto 0); -- vector length
      M_CU_vmul_o: out std_logic_vector(31 downto 0);
      M_CU_load_valid_o: out std_logic;
      -- outputs
      vector_id_ex_en_o          : out std_logic;
      vector_stall_o             : out std_logic;
      vector_instr_to_V_CU_o       : out std_logic_vector(31 downto 0);
      vector_instr_to_M_CU_o       : out std_logic_vector(31 downto 0));
end entity;


architecture beh of arbiter is

   
   constant vector_store_c : std_logic_vector(6 downto 0) := "0100111";
   constant vector_load_c  : std_logic_vector(6 downto 0) := "0000111";
   constant vector_arith_c : std_logic_vector(6 downto 0) := "1010111";

   alias vector_instr_opcode_a : std_logic_vector (6 downto 0) is vector_instruction_i(6 downto 0);
   alias M_CU_load_opcode_a    : std_logic_vector (6 downto 0) is M_CU_load_instruction_i (6 downto 0);
   signal opcode_s             : std_logic_vector (6 downto 0);
   signal vector_instr_check_s : std_logic_vector(1 downto 0);

   --rs1_rs2_ld_fifo interconnections

   signal ld_instr_fifo_re_s: std_logic;
   signal ld_instr_fifo_we_s: std_logic;
   signal rs1_rs2_ld_fifo_i_s: std_logic_vector(2*DATA_WIDTH - 1 downto 0);
   signal rs1_rs2_ld_fifo_o_s: std_logic_vector(2*DATA_WIDTH - 1 downto 0);
   signal rs1_rs2_ld_fifo_empty_s: std_logic;
   signal rs1_rs2_ld_fifo_full_s: std_logic;

   -- Configuration registers
   signal vl_reg_s: std_logic_vector(clogb2(VECTOR_LENGTH * 8) downto 0);
   signal vmul_reg_s: std_logic_vector(1 downto 0);


   -- Signals neccessary for load valid signal generation
   signal current_ld_is_valid_s: std_logic;
   signal ld_from_fifo_is_valid: std_logic;
begin

   vector_instr_to_V_CU_o <= vector_instruction_i when M_CU_instruction_is_load_i = '0' else
                           M_CU_load_instruction_i;

   opcode_s <= vector_instr_opcode_a when M_CU_instruction_is_load_i = '0' else
               M_CU_load_opcode_a;
   -- combinational logic that checks whether an instruction is vector one or not.
   with opcode_s select vector_instr_check_s <=
      "10" when vector_store_c,
      "01" when vector_arith_c,
      "11" when vector_load_c,
      '0' when others;

   process (ready_i, vector_instr_check_s) is
   begin
      vector_id_ex_en_o <= '1';
      vector_stall_o    <= '1';
      if (ready_i = '0' and vector_instr_check_s = '1') then
         vector_id_ex_en_o <= '0';
         vector_stall_o    <= '0';
      elsif(vector_instr_check_s = '0') then
         vector_id_ex_en_o <= '0';
      end if;
   end process;

   ---------------------------------------------------------------------------------------------------------------------------------
   -- Code that handles sending load instructions to the M_CU
   -- mux that choses what data is sent to M_CU. If load_fifo_empy = '1' that
   -- means there is no data in ld_fifos and currect instruction should be sent,
   -- else if fifo is not empty send stored load information.
   process (rs1_rs2_ld_fifo_empty_s, rs1_i, rs2_i, vl_reg_s, vmul_reg_s) is
   begin
      if (rs1_rs2_ld_fifo_empty_s = '1') then
         M_CU_rs1_o <= rs1_i;
         M_CU_rs2_o <= rs2_i;
         M_CU_vl_o <= vl_reg_s;
         M_CU_vmul_o <= vmul_reg_s;
      else
         M_CU_rs1_o <= rs1_rs2_ld_fifo_o_s(2*DATA_WIDTH - 1 downto DATA_WIDTH);
         M_CU_rs2_o <= rs1_rs2_ld_fifo_o_s(DATA_WIDTH - 1 downto 0);
         M_CU_vl_o <= vl_reg_s;
         M_CU_vmul_o <= vmul_reg_s;         
      end if;
   end process;

   --Logic that generates valid signal to indicate that the data sent to M_CU
   --is valid.
   M_CU_load_valid_o <= ld_from_fifo_is_valid or current_ld_is_valid_s;
   
   process (rs1_rs2_ld_fifo_empty_s, vector_instr_check_s, ld_instr_fifo_re_s, clk) is
   begin
      if (rs1_rs2_ld_fifo_empty_s and vector_instr_check_s = "11") then
         current_ld_is_valid_s <= '1';
      else
         current_ld_is_valid_s <= '0';         
      end if;
      if (rising_edge(clk)) then
         if (ld_instr_fifo_re_s = '1') then
            ld_from_fifo_is_valid <= '1';
         else
            ld_from_fifo_is_valid <= '0';
         end if;
      end if;
   end process;
   
   

   ld_instr_fifo_re_s <= rdy_for_load_i and rs1_rs2_ld_fifo_empty_s;
   ld_instr_fifo_we_s <= '1' when rdy_for_load_i = '1' and (vector_instr_check_s = "10");
   LOAD_RS1_RS2_FIFO : FIFO_SYNC_MACRO
      generic map (
         DEVICE              => "7SERIES",  -- Target Device: "VIRTEX5, "VIRTEX6", "7SERIES" 
         ALMOST_FULL_OFFSET  => X"0080",    -- Sets almost full threshold
         ALMOST_EMPTY_OFFSET => X"0080",    -- Sets the almost empty threshold
         DATA_WIDTH          => DATA_WIDTH * 2,  -- Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
         FIFO_SIZE           => "36Kb")     -- Target BRAM, "18Kb" or "36Kb" 
      port map (
         ALMOSTEMPTY => open,  -- 1-bit output almost empty
         ALMOSTFULL  => open,   -- 1-bit output almost full
         DO          => rs1_rs2_ld_fifo_o_s,  -- Output data, width defined by DATA_WIDTH parameter
         EMPTY       => rs1_rs2_ld_fifo_empty_s,  -- 1-bit output empty
         FULL        => rs1_rs2_ld_fifo_full_s,  -- 1-bit output full
         RDCOUNT     => open,  -- Output read count, width determined by FIFO depth
         RDERR       => open,  -- 1-bit output read error
         WRCOUNT     => open,  -- Output write count, width determined by FIFO depth
         WRERR       => open,  -- 1-bit output write error
         CLK         => clk,            -- 1-bit input clock
         DI          => rs1_rs2_ld_fifo_i_s,  -- Input data, width defined by DATA_WIDTH parameter
         RDEN        => ld_instr_fifo_re_s,    -- 1-bit input read enable
         RST         => not(reset),   -- 1-bit input reset
         WREN        => ld_instr_fifo_we_s     -- 1-bit input write enable
         );

   LOAD_VL_VMUL_FIFO : FIFO_SYNC_MACRO
      generic map (
         DEVICE              => "7SERIES",  -- Target Device: "VIRTEX5, "VIRTEX6", "7SERIES" 
         ALMOST_FULL_OFFSET  => X"0080",    -- Sets almost full threshold
         ALMOST_EMPTY_OFFSET => X"0080",    -- Sets the almost empty threshold
         DATA_WIDTH          => DATA_WIDTH * 2,  -- Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
         FIFO_SIZE           => "36Kb")     -- Target BRAM, "18Kb" or "36Kb" 
      port map (
         ALMOSTEMPTY => open,  -- 1-bit output almost empty
         ALMOSTFULL  => open,   -- 1-bit output almost full
         DO          => vl_vmul_ld_fifo_o_s,  -- Output data, width defined by DATA_WIDTH parameter
         EMPTY       => open,  -- 1-bit output empty
         FULL        => vl_vmul_ld_fifo_full_s,  -- 1-bit output full
         RDCOUNT     => open,  -- Output read count, width determined by FIFO depth
         RDERR       => open,  -- 1-bit output read error
         WRCOUNT     => open,  -- Output write count, width determined by FIFO depth
         WRERR       => open,  -- 1-bit output write error
         CLK         => clk,            -- 1-bit input clock
         DI          => vl_vmul_ld_fifo_i_s,  -- Input data, width defined by DATA_WIDTH parameter
         RDEN        => ld_instr_fifo_re_s,    -- 1-bit input read enable
         RST         => not(reset),   -- 1-bit input reset
         WREN        => ld_instr_fifo_we_s     -- 1-bit input write enable
         );

---------------------------------------------------------------------------------------------------------------------------------
end architecture;

