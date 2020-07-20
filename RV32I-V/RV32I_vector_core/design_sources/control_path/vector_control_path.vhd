library ieee;
use ieee.std_logic_1164.all;
use work.custom_functions_pkg.all;



entity vector_control_path is
   port (clk                  : in std_logic;
         reset                : in std_logic;
         --Input data
         vector_instruction_i : in std_logic_vector(31 downto 0);

         --output control signals 0
         vrf_type_of_access_o : out std_logic_vector(1 downto 0);  --there are r/w, r, w, no_access
         immediate_sign_i : out std_logic;
         alu_op_o             : out std_logic_vector(4 downto 0);
         mem_to_vrf_o         : out std_logic_vector(1 downto 0);
         store_fifo_we_o      : out std_logic;
         alu_src_a_i: out std_logic;
         type_of_masking_i   :out std_logic;
         vs1_addr_src_i       : out std_logic;
         load_fifo_re_o       : out std_logic;

         --input status signals from VRF
         ready_i : in std_logic
         --Input status signals from memory control unit                  
         -- Output status signals         
         );
end entity;

architecture behavioral of vector_control_path is

   signal vector_instruction_id_reg_s, vector_instruction_ex_next_s : std_logic_vector (31 downto 0);
   signal vector_id_ex_en_s                                         : std_logic;

   --signals between alu_decoder and ctrl_decoder
   signal alu_2_bit_op_s : std_logic_vector(1 downto 0);
begin
   -- Sequential logic
   reg_modeling : process (clk) is
   begin
      if (rising_edge(clk)) then
         if (reset = '0') then
             vector_instruction_id_reg_s <= (others => '0');
         else
            if(vector_id_ex_en_s = '1') then
               vector_instruction_id_reg_s <= vector_instruction_ex_next_s;
            end if;
         end if;
      end if;
   end process;

   -- Combinational logic that checks if vector core is ready for another instruction.
   -- If its not it generates a stall signal      

   -- Here ALU_decoder and ctrl_decoder will be instantiated
   -- TODO: implement combinational logic inside EXE phase of vector processor
   vector_ctrl_decoder_1 : entity work.vector_ctrl_decoder
      port map (
         opcode_i             => vector_instruction_id_reg_s(6 downto 0),
         funct3_i             => vector_instruction_id_reg_s(14 downto 12),
         --funct6_i => vector_instruction_id_reg_s(31 downto 26),
         vrf_type_of_access_o => vrf_type_of_access_o,
         alu_2_bit_op_o        => alu_2_bit_op_s,
         mem_to_vrf_o         => mem_to_vrf_o,
         store_fifo_we_o      => store_fifo_we_o,
         load_fifo_re_o       => load_fifo_re_o);

   vector_alu_decoder_1 : entity work.vector_alu_decoder
      port map (
         alu_2_bit_op_i => alu_2_bit_op_s,
         funct6_i       => vector_instruction_id_reg_s(31 downto 26),
         alu_op_o       => alu_op_o);

end behavioral;
