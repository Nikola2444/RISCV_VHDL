library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity forwarding_unit is
   port (
      -- mem inputs
      rd_we_mem_i        : in  std_logic;
      rd_address_mem_i   : in  std_logic_vector(4 downto 0);
      -- wb inputs
      rd_we_wb_i         : in  std_logic;
      rd_address_wb_i    : in  std_logic_vector(4 downto 0);
      -- ex inputs
      rs1_address_ex_i   : in  std_logic_vector(4 downto 0);
      rs2_address_ex_i   : in  std_logic_vector(4 downto 0);
      -- id inputs
      rs1_address_id_i   : in  std_logic_vector(4 downto 0);
      rs2_address_id_i   : in  std_logic_vector(4 downto 0);
      -- forward control outputs
      alu_forward_a_o    : out std_logic_vector (1 downto 0);
      alu_forward_b_o    : out std_logic_vector(1 downto 0));
end entity;

architecture Behavioral of forwarding_unit is
   constant zero_c : std_logic_vector (4 downto 0) := std_logic_vector(to_unsigned(0, 5));
begin

   --process that checks whether forwarding for instructions in EX stage is needed or not.
   -- forwarding from MEM stage has advantage over forwading information from WB
   -- stage, because information contained there is more recent than in WB.
   forward_proc : process(rd_we_mem_i, rd_address_mem_i, rd_we_wb_i, rd_address_wb_i,
                          rs1_address_ex_i, rs2_address_ex_i)is
   begin
      alu_forward_a_o <= "00";
      alu_forward_b_o <= "00";
      -- forwarding from WB stage
      if (rd_we_wb_i = '1' and rd_address_wb_i /= zero_c)then
         if (rd_address_wb_i = rs1_address_ex_i)then
            alu_forward_a_o <= "01";
         end if;
         if(rd_address_wb_i = rs2_address_ex_i)then
            alu_forward_b_o <= "01";
         end if;
      end if;
      -- forwarding from MEM stage
      if (rd_we_mem_i = '1' and rd_address_mem_i /= zero_c)then
         if (rd_address_mem_i = rs1_address_ex_i)then
            alu_forward_a_o <= "10";
         end if;
         if (rd_address_mem_i = rs2_address_ex_i)then
            alu_forward_b_o <= "10";
         end if;
      end if;
   end process;


end architecture;
