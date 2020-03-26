library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity control_path is
   port (
      -- global synchronization signals
      clk                : in  std_logic;
      reset              : in  std_logic;
      -- instruction is read from memory
      instruction_i      : in  std_logic_vector (31 downto 0);
      -- from data_path comparator
      branch_condition_i : in  std_logic;
      -- control signals forwarded to datapath and memory
      set_a_zero_o       : out std_logic;
      mem_to_reg_o       : out std_logic_vector(1 downto 0);
      load_type_o        : out std_logic_vector(2 downto 0);
      alu_op_o           : out std_logic_vector(4 downto 0);
      alu_src_b_o        : out std_logic;
      alu_src_a_o        : out std_logic;
      rd_we_o            : out std_logic;
      pc_next_sel_o      : out std_logic_vector(1 downto 0);
      data_mem_we_o      : out std_logic_vector(3 downto 0);
      -- control singals for forwarding
      alu_forward_a_o    : out std_logic_vector (1 downto 0);
      alu_forward_b_o    : out std_logic_vector (1 downto 0);
      branch_forward_a_o : out std_logic_vector (1 downto 0);  -- mux a 
      branch_forward_b_o : out std_logic_vector(1 downto 0);   -- mux b
      -- control singals for flushing
      if_id_flush_o      : out std_logic;
      id_ex_flush_o      : out std_logic;
      -- control signals for stalling
      pc_en_o            : out std_logic;
      if_id_en_o         : out std_logic
      );
end entity;


architecture behavioral of control_path is

   --********** REGISTER CONTROL ***************
   signal if_id_en_s        : std_logic;   
   signal if_id_flush_s     : std_logic;   
   signal id_ex_flush_s     : std_logic;   
   
   --*********  INSTRUCTION DECODE **************
   signal branch_type_id_s  : std_logic_vector(1 downto 0);
   signal funct3_id_s       : std_logic_vector(2 downto 0);
   signal funct7_id_s       : std_logic_vector(6 downto 0);
   signal alu_2bit_op_id_s  : std_logic_vector(1 downto 0);
   signal set_a_zero_id_s   : std_logic;   
   
   signal control_pass_s    : std_logic;
   signal rs1_in_use_id_s   : std_logic;
   signal rs2_in_use_id_s   : std_logic;
   signal alu_src_a_id_s    : std_logic;
   signal alu_src_b_id_s    : std_logic;

   signal data_mem_we_id_s  : std_logic;
   signal rd_we_id_s        : std_logic;
   signal mem_to_reg_id_s   : std_logic_vector(1 downto 0);
   signal rs1_address_id_s  : std_logic_vector (4 downto 0);
   signal rs2_address_id_s  : std_logic_vector (4 downto 0);
   signal rd_address_id_s   : std_logic_vector (4 downto 0);
   signal bcc_id_s          : std_logic;
   --*********       EXECUTE       **************

   signal branch_type_ex_s  : std_logic_vector(1 downto 0);
   signal funct3_ex_s       : std_logic_vector(2 downto 0);
   signal funct7_ex_s       : std_logic_vector(6 downto 0);
   signal alu_2bit_op_ex_s  : std_logic_vector(1 downto 0);
   signal set_a_zero_ex_s   : std_logic;

   signal alu_src_a_ex_s    : std_logic;
   signal alu_src_b_ex_s    : std_logic;

   signal data_mem_we_ex_s  : std_logic;
   signal rd_we_ex_s        : std_logic;
   signal mem_to_reg_ex_s   : std_logic_vector(1 downto 0);


   signal rs1_address_ex_s  : std_logic_vector (4 downto 0);
   signal rs2_address_ex_s  : std_logic_vector (4 downto 0);
   signal rd_address_ex_s   : std_logic_vector (4 downto 0);

   --*********       MEMORY        **************

   signal funct3_mem_s      : std_logic_vector(2 downto 0);
   signal data_mem_we_mem_s : std_logic;
   signal rd_we_mem_s       : std_logic;
   signal mem_to_reg_mem_s  : std_logic_vector(1 downto 0);

   signal rd_address_mem_s  : std_logic_vector (4 downto 0);

   --*********      WRITEBACK      **************

   signal funct3_wb_s       : std_logic_vector(2 downto 0);
   signal rd_we_wb_s        : std_logic;
   signal mem_to_reg_wb_s   : std_logic_vector(1 downto 0);
   signal rd_address_wb_s   : std_logic_vector (4 downto 0);

begin


   --*********** Combinational logic ******************
   -- branch condition complement
   -- when branch instruction is executing:
   --    '0' -> beq blt bltu
   --    '1' -> bne bge geu  (opposite,complement of adequate comparison)
   bcc_id_s <= instruction_i(12);

   -- extract operation and operand data from instruction
   rs1_address_id_s <= instruction_i(19 downto 15);
   rs2_address_id_s <= instruction_i(24 downto 20);
   rd_address_id_s  <= instruction_i(11 downto 7);

   funct7_id_s <= instruction_i(31 downto 25);
   funct3_id_s <= instruction_i(14 downto 12);

   -- this is decoder that decides which bytes are written to memory
   data_mem_write_decoder :
      data_mem_we_o <= "0001" when data_mem_we_mem_s = '1' and funct3_mem_s = "000" else
                       "0011" when data_mem_we_mem_s = '1' and funct3_mem_s = "001" else
                       "1111" when data_mem_we_mem_s = '1' and funct3_mem_s = "010" else
                       "0000";

   -- this process covers conditional and unconditional branches
   -- base on which branch is executing: 
   --    control pc_next mux
   --    flush appropriate registers in pipeline
   pc_next_if_s : process(branch_type_id_s, branch_type_ex_s, branch_condition_i, bcc_id_s)
   begin
      if_id_flush_s <= '0';
      id_ex_flush_s <= '0';
      pc_next_sel_o <= "00";
      if (branch_type_id_s = "01" and ((branch_condition_i xor bcc_id_s) = '1'))then
         pc_next_sel_o <= "01";
         if_id_flush_s <= '1';
      end if;
      if(branch_type_id_s = "10")then
         pc_next_sel_o <= "10";
         if_id_flush_s <= '1';
      end if;
      if(branch_type_ex_s = "11") then
         pc_next_sel_o <= "11";
         if_id_flush_s <= '1';
         id_ex_flush_s <= '1';
      end if;
   end process;



   --*********** Sequential logic ******************
   --ID/EX register
   id_ex : process (clk) is
   begin
      if (rising_edge(clk)) then
         if (reset = '0' or control_pass_s = '0' or id_ex_flush_s = '1')then
            branch_type_ex_s <= (others => '0');
            funct3_ex_s      <= (others => '0');
            funct7_ex_s      <= (others => '0');
            set_a_zero_ex_s  <= '0';
            alu_src_a_ex_s   <= '0';
            alu_src_b_ex_s   <= '0';
            mem_to_reg_ex_s  <= (others => '0');
            alu_2bit_op_ex_s <= (others => '0');
            rs1_address_ex_s <= (others => '0');
            rs2_address_ex_s <= (others => '0');
            rd_address_ex_s  <= (others => '0');
            rd_we_ex_s       <= '0';
            data_mem_we_ex_s <= '0';
         else
            branch_type_ex_s <= branch_type_id_s;
            funct7_ex_s      <= funct7_id_s;
            funct3_ex_s      <= funct3_id_s;
            set_a_zero_ex_s  <= set_a_zero_id_s;
            alu_src_a_ex_s   <= alu_src_a_id_s;
            alu_src_b_ex_s   <= alu_src_b_id_s;
            mem_to_reg_ex_s  <= mem_to_reg_id_s;
            alu_2bit_op_ex_s <= alu_2bit_op_id_s;
            rs1_address_ex_s <= rs1_address_id_s; rs2_address_ex_s <= rs2_address_id_s;
            rd_address_ex_s  <= rd_address_id_s;
            rd_we_ex_s       <= rd_we_id_s;
            data_mem_we_ex_s <= data_mem_we_id_s;
         end if;
      end if;
   end process;

   --EX/MEM register
   ex_mem : process (clk) is
   begin
      if (rising_edge(clk)) then
         if (reset = '0')then
            funct3_mem_s      <= (others => '0');
            data_mem_we_mem_s <= '0';
            rd_we_mem_s       <= '0';
            mem_to_reg_mem_s  <= (others => '0');
            rd_address_mem_s  <= (others => '0');
         else
            funct3_mem_s      <= funct3_ex_s;
            data_mem_we_mem_s <= data_mem_we_ex_s;
            rd_we_mem_s       <= rd_we_ex_s;
            mem_to_reg_mem_s  <= mem_to_reg_ex_s;
            rd_address_mem_s  <= rd_address_ex_s;
         end if;
      end if;
   end process;

   --MEM/WB register
   mem_wb : process (clk) is
   begin
      if (rising_edge(clk)) then
         if (reset = '0')then
            funct3_wb_s     <= (others => '0');
            rd_we_wb_s      <= '0';
            mem_to_reg_wb_s <= (others => '0');
            rd_address_wb_s <= (others => '0');
         else
            funct3_wb_s     <= funct3_mem_s;
            rd_we_wb_s      <= rd_we_mem_s;
            mem_to_reg_wb_s <= mem_to_reg_mem_s;
            rd_address_wb_s <= rd_address_mem_s;
         end if;
      end if;
   end process;



   --*********** Instantiation ******************

   -- Control decoder
   ctrl_dec : entity work.ctrl_decoder(behavioral)
      port map(
         opcode_i      => instruction_i(6 downto 0),
         branch_type_o => branch_type_id_s,
         mem_to_reg_o  => mem_to_reg_id_s,
         data_mem_we_o => data_mem_we_id_s,
         alu_src_b_o   => alu_src_b_id_s,
         alu_src_a_o   => alu_src_a_id_s,
         set_a_zero_o  => set_a_zero_id_s,
         rd_we_o       => rd_we_id_s,
         rs1_in_use_o  => rs1_in_use_id_s,
         rs2_in_use_o  => rs2_in_use_id_s,
         alu_2bit_op_o => alu_2bit_op_id_s);

   -- ALU decoder
   alu_dec : entity work.alu_decoder(behavioral)
      port map(
         alu_2bit_op_i => alu_2bit_op_ex_s,
         funct3_i      => funct3_ex_s,
         funct7_i      => funct7_ex_s,
         alu_op_o      => alu_op_o);

   -- Forwarding_unit
   forwarding_u : entity work.forwarding_unit(behavioral)
      port map (
         rd_we_mem_i        => rd_we_mem_s,
         rd_address_mem_i   => rd_address_mem_s,
         rd_we_wb_i         => rd_we_wb_s,
         rd_address_wb_i    => rd_address_wb_s,
         rs1_address_ex_i   => rs1_address_ex_s,
         rs2_address_ex_i   => rs2_address_ex_s,
         rs1_address_id_i   => rs1_address_id_s,
         rs2_address_id_i   => rs2_address_id_s,
         alu_forward_a_o    => alu_forward_a_o,
         alu_forward_b_o    => alu_forward_b_o,
         branch_forward_a_o => branch_forward_a_o,
         branch_forward_b_o => branch_forward_b_o);

   -- Hazard unit
   hazard_u : entity work.hazard_unit(behavioral)
      port map (
         rs1_address_id_i => rs1_address_id_s,
         rs2_address_id_i => rs2_address_id_s,
         rs1_in_use_i     => rs1_in_use_id_s,
         rs2_in_use_i     => rs2_in_use_id_s,
         branch_type_id_i => branch_type_id_s,

         rd_address_ex_i => rd_address_ex_s,
         mem_to_reg_ex_i => mem_to_reg_ex_s,
         rd_we_ex_i      => rd_we_ex_s,

         rd_address_mem_i => rd_address_mem_s,
         mem_to_reg_mem_i => mem_to_reg_mem_s,

         pc_en_o        => pc_en_o,
         if_id_en_o     => if_id_en_s,
         control_pass_o => control_pass_s);



   --********** Outputs **************

   -- forward control signals to datapath
   if_id_en_o    <= if_id_en_s;
   mem_to_reg_o  <= mem_to_reg_wb_s;
   alu_src_b_o   <= alu_src_b_ex_s;
   alu_src_a_o   <= alu_src_a_ex_s;
   set_a_zero_o  <= set_a_zero_ex_s;
   rd_we_o       <= rd_we_wb_s;
   if_id_flush_o <= if_id_flush_s;
   id_ex_flush_o <= id_ex_flush_s;

   -- load_type controls which bytes are taken from memory in wb stage
   load_type_o <= funct3_wb_s;


end architecture;
