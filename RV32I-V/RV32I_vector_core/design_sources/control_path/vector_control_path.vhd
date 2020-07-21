library ieee;
use ieee.std_logic_1164.all;
use work.custom_functions_pkg.all;
use work.vector_alu_ops_pkg.all;
use work.instruction_fields_constants_pkg.all;


entity vector_control_path is
    port (clk                  : in std_logic;
          reset                : in std_logic;
          --Input data
          vector_instruction_i : in std_logic_vector(31 downto 0);

          --output control signals 0
          vrf_type_of_access_o : out std_logic_vector(1 downto 0);  --there are r/w, r, w, no_access
          immediate_sign_o : out std_logic;
          alu_op_o             : out std_logic_vector(4 downto 0);
          mem_to_vrf_o         : out std_logic_vector(1 downto 0);
          store_fifo_we_o      : out std_logic;
          alu_src_a_o: out std_logic_vector(1 downto 0);
          type_of_masking_o   :out std_logic;
          vs1_addr_src_o       : out std_logic;
          load_fifo_re_o       : out std_logic

     --input status signals from VRF         
     --Input status signals from memory control unit                  
     -- Output status signals         
          );
end entity;

architecture behavioral of vector_control_path is
    
    signal OPMVV_instr_check_s:std_logic;
    signal store_fifo_we_s: std_logic;

    alias opcode_i: std_logic_vector(5 downto 0) is vector_instruction_i(6 downto 0);
    alias funct6_i: std_logic_vector(5 downto 0) is vector_instruction_i(31 downto 26);
    alias funct3_i: std_logic_vector(5 downto 0) is vector_instruction_i(14 downto 12);
    alias vm_i: std_logic is vector_instruction_i(25);
    --signals between alu_decoder and ctrl_decoder    

    
    constant vector_store_c : std_logic_vector(6 downto 0) := "0100111";
    constant vector_load_c  : std_logic_vector(6 downto 0) := "0000111";
    constant vector_arith_c : std_logic_vector(6 downto 0) := "1010111";
begin

    -- Sequential logig
    process (clk) is
    begin
        if (rising_edge(clk))then
            if (reset = '0') then
                store_fifo_we_o <= '0';
            else
                store_fifo_we_o <= store_fifo_we_s;
            end if;
        end if;
    end process;
    
    -- Combinational logic
    control_dec : process (opcode_i, funct6_i, OPMVV_instr_check_s, vm_i) is
    begin        
        mem_to_vrf_o         <= "00";        
        load_fifo_re_o       <= '0';
        vrf_type_of_access_o <= (others => '0');
        vs1_addr_src_o <= '0';
        immediate_sign_o <= '0';
        store_fifo_we_s <= '0';
        type_of_masking_o <= '0';
        alu_op_o <= (others => '0');
        case opcode_i is
            when vector_store_c =>
                vrf_type_of_access_o <= "10";
                vs1_addr_src_o <= '1';
                store_fifo_we_s      <= '1';
            when vector_load_c =>
                vrf_type_of_access_o <= "01";
                mem_to_vrf_o         <= "01";
                load_fifo_re_o       <= '1';
            when vector_arith_c =>
                vrf_type_of_access_o <= "00";
                case funct6_i is
                    when v_add_funct6 =>
                        alu_op_o <= add_op;
                    when v_sub_funct6 =>
                        alu_op_o <= sub_op;
                    when v_and_funct6 =>
                        alu_op_o <= and_op;
                    when v_or_funct6 =>
                        alu_op_o <= or_op;
                    when v_xor_funct6 =>
                        alu_op_o <= xor_op;
                    when v_shll_vmul_funct6 =>
                        if (OPMVV_instr_check_s = '0') then
                            immediate_sign_o <= '1';
                            alu_op_o <= sll_op;
                        else
                            alu_op_o <= muls_op;
                        end if;
                    when v_shrl_funct6 =>
                        immediate_sign_o <= '1';
                        alu_op_o <= srl_op;
                    when v_shra_funct6 =>
                        immediate_sign_o <= '1';
                        alu_op_o <= sra_op;
                    when v_vmseq_funct6 =>
                        alu_op_o <= eq_op;
                    when v_vmsne_funct6 =>
                        alu_op_o <= neq_op;
                    when v_vmslt_funct6 =>
                        alu_op_o <= slt_op;
                    when v_vmsltu_funct6 =>
                        alu_op_o <= sltu_op;
                    when v_vmsleu_funct6 =>
                        alu_op_o <= sleu_op;
                    when v_vmsle_funct6 =>
                        alu_op_o <= sle_op;
                    when v_vmsgtu_funct6 =>
                        alu_op_o <= sgtu_op;
                    when v_vmsgt_funct6 =>
                        alu_op_o <= sgt_op;
                    when v_vminu_funct6 =>
                        alu_op_o <= minu_op;
                    when v_vmin_funct6 =>
                        alu_op_o <= min_op;
                    when v_merge_funct6 =>
                        alu_op_o <= add_op;
                        type_of_masking_o <= '1';
                        if (vm_i = '1') then
                            mem_to_vrf_o <= "11";
                        else
                            mem_to_vrf_o <= "10";
                        end if;
                    when v_mulhsu_funct6 =>
                        alu_op_o <= mulhsu_op;
                    when v_mulhs_funct6 =>
                        alu_op_o <= mulhs_op;
                    when v_mulhu_funct6 =>
                        alu_op_o <= mulhu_op;
                    when others =>                        
                end case;                        
            when others =>                
        end case;
    end process;

    process (funct3_i)is
    begin
        OPMVV_instr_check_s <= '0';
        alu_src_a_o <= (others =>'0');
        case funct3_i is
            when  OPIVV_funct3 =>
                alu_src_a_o <= "00";
            when  OPIVX_funct3 =>
                alu_src_a_o <= "01";
            when  OPIVI_funct3 =>
                alu_src_a_o <= "10";
            when  OPMVV_funct3 =>
                alu_src_a_o <= "00";
                OPMVV_instr_check_s <= '1';
            when  OPMVX_funct3 =>
                alu_src_a_o <= "01";
                OPMVV_instr_check_s <= '1';
            when others =>
        end case;
    end process;

end behavioral;
