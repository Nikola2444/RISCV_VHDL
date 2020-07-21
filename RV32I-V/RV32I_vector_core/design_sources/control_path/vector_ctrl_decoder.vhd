library ieee;
use ieee.std_logic_1164.all;
use work.custom_functions_pkg.all;


entity vector_ctrl_decoder is
    port (opcode_i             : in  std_logic_vector (6 downto 0);
          -- funct3 to be used (for arith instructions it determines wheter
          -- there is an operation beetwen vv, vs, ...)
          funct3_i             : in  std_logic_vector(2 downto 0);                            
          funct6_i: in std_logic_vector(5 downto 0);
          alu_op_o: out std_logic_vector(4 downto 0);
          --control signals
          vrf_type_of_access_o : out std_logic_vector(1 downto 0);  --there are r/w, r, w, no_access
          alu_2_bit_op_o        : out std_logic_vector(1 downto 0);
          mem_to_vrf_o         : out std_logic_vector(1 downto 0);
          store_fifo_we_o      : out std_logic;
          load_fifo_re_o       : out std_logic);
end entity;


architecture beh of vector_ctrl_decoder is

    constant v_add_c: std_logic_vector(5 downto 0):= "000000";
    constant v_sub_c: std_logic_vector(5 downto 0):= "000010";
    constant v_and_c: std_logic_vector(5 downto 0):= "001001";
    constant v_or_c: std_logic_vector(5 downto 0) := "001010";
    constant v_xor_c: std_logic_vector(5 downto 0):= "001011";

    
    constant vector_store_c : std_logic_vector(6 downto 0) := "0100111";
    constant vector_load_c  : std_logic_vector(6 downto 0) := "0000111";
    constant vector_arith_c : std_logic_vector(6 downto 0) := "1010111";
begin

    control_dec : process (opcode_i) is
    begin
        alu_2_bit_op_o        <= "00";
        mem_to_vrf_o         <= "00";
        store_fifo_we_o      <= '0';
        load_fifo_re_o       <= '0';
        vrf_type_of_access_o <= (others => '0');
        case opcode_i is
            when vector_store_c =>
                vrf_type_of_access_o <= "10";
                alu_2_bit_op_o        <= "00";
                store_fifo_we_o      <= '1';
            when vector_load_c =>
                vrf_type_of_access_o <= "01";
                mem_to_vrf_o         <= "01";
                alu_2_bit_op_o        <= "00";
                load_fifo_re_o       <= '1';
            when vector_arith_c =>
                vrf_type_of_access_o <= "00";
                alu_2_bit_op_o        <= "11";
            when others =>
                
        end case;
    end process;
end architecture;
