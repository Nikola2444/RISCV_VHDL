LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
use ieee.math_real.all;
use work.vector_alu_ops_pkg.all;



ENTITY V_ALU IS
   GENERIC(
      WIDTH : NATURAL := 32);
   PORT(
      clk: in std_logic;
      reset: in std_logic;
      a_i    : in STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0); --first input
      b_i    : in STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0); --second input
      --op_i   : in STD_LOGIC_VECTOR(4 DOWNTO 0); --operation select
      op_i   : in vector_alu_ops_t; --operation select
      res_o  : out STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0)); --result
      --zero_o : out STD_LOGIC; --zero flag
      --of_o   : out STD_LOGIC; --overflow flag
END V_ALU;

ARCHITECTURE behavioral OF V_ALU IS

   constant  l2WIDTH : natural := integer(ceil(log2(real(WIDTH))));
   signal    slt_res,sltu_res,add_res,sub_res,or_res,and_res,res_s,xor_res  :  STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);

   signal    eq_res,sll_res,srl_res,sra_res : STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
   signal    neq_res, sle_res, sleu_res, sgtu_res, sgt_res: STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
   signal min_res, minu_res:STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
   signal custom_mul32_res_s:std_logic_vector(WIDTH - 1 downto 0);
   --signal    divu_res,divs_res,rems_res,remu_res : STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
   signal    muls_res,mulhu_res : STD_LOGIC_VECTOR(2*WIDTH - 1  DOWNTO 0);	
   signal    mulhsu_res, mulhs_res : STD_LOGIC_VECTOR(2*WIDTH - 1 DOWNTO 0);
   signal c_s: std_logic_vector (63 downto 0);
   
   
begin

   multiplier32_bit_1: entity work.multiplier32_bit
      generic map (
         DATA_WIDTH => WIDTH)
      port map (
         clk   => clk,
         reset => reset,
         op => op_i,
         a     => a_i,
         b     => b_i,
         c     => c_s);
   
   -- addition
   add_res <= std_logic_vector(unsigned(a_i) + unsigned(b_i));
   -- subtraction
   sub_res <= std_logic_vector(unsigned(a_i) - unsigned(b_i));
   -- and gate
   and_res <= a_i and b_i;
   -- or gate
   or_res <= a_i or b_i;
   -- xor gate
   xor_res <= a_i xor b_i;
   -- equal
   eq_res <= std_logic_vector(to_unsigned(1,WIDTH)) when (signed(a_i) = signed(b_i)) else
             std_logic_vector(to_unsigned(0,WIDTH));
   neq_res <= std_logic_vector(to_unsigned(1,WIDTH)) when (signed(a_i) /= signed(b_i)) else
              std_logic_vector(to_unsigned(0,WIDTH));
   --min max
   min_res <= b_i when (signed(b_i) < signed(a_i)) else
              a_i;
   minu_res <= b_i when (unsigned(b_i) < unsigned(a_i)) else
              a_i;
   
   -- less then signed
   slt_res <= std_logic_vector(to_unsigned(1,WIDTH)) when (signed(b_i) < signed(a_i)) else
              std_logic_vector(to_unsigned(0,WIDTH));
   -- less then unsigned
   sltu_res <= std_logic_vector(to_unsigned(1,WIDTH)) when (unsigned(b_i) < unsigned(a_i)) else
              std_logic_vector(to_unsigned(0,WIDTH));
   -- less then or equal unsigned
   sleu_res <= std_logic_vector(to_unsigned(1,WIDTH)) when (unsigned(b_i) < unsigned(a_i) or unsigned(b_i) = unsigned(a_i)) else
               std_logic_vector(to_unsigned(0,WIDTH));
   -- less then or equal signed
   sle_res <= std_logic_vector(to_unsigned(1,WIDTH)) when (signed(b_i) < signed(a_i) or signed(a_i) = signed(b_i)) else
              std_logic_vector(to_unsigned(0,WIDTH));
   -- greater then 
      sgtu_res <= std_logic_vector(to_unsigned(1,WIDTH)) when (unsigned(b_i) > unsigned(a_i)) else std_logic_vector(to_unsigned(0,WIDTH));
   -- greater then 
   sgt_res <= std_logic_vector(to_unsigned(1,WIDTH)) when (signed(b_i) > signed(a_i)) else
              std_logic_vector(to_unsigned(0,WIDTH));
   --shift results
   sll_res <= std_logic_vector(shift_left(unsigned(b_i), to_integer(unsigned(a_i(l2WIDTH downto 0)))));
   srl_res <= std_logic_vector(shift_right(unsigned(b_i), to_integer(unsigned(a_i(l2WIDTH downto 0)))));
   sra_res <= std_logic_vector(shift_right(signed(b_i), to_integer(unsigned(a_i(l2WIDTH downto 0)))));
   --multiplication
   
   muls_res <= c_s;
   mulhs_res <= c_s;
   mulhsu_res <= c_s;
   mulhu_res <= c_s;
   --division
   --divs_res <= std_logic_vector(signed(a_i)/signed(b_i)) when b_i /= std_logic_vector(to_unsigned(0,WIDTH)) else
   --            (others => '1');
   --divu_res <= std_logic_vector(unsigned(a_i)/unsigned(b_i)) when b_i /= std_logic_vector(to_unsigned(0,WIDTH)) else
   --            (others => '1');
   --mode
   --rems_res <= std_logic_vector(signed(a_i) rem signed(b_i)) when b_i /= std_logic_vector(to_unsigned(0,WIDTH)) else
   --            (others => '1');
   --remu_res <= std_logic_vector(unsigned(a_i) rem unsigned(b_i)) when b_i /= std_logic_vector(to_unsigned(0,WIDTH)) else
   --           (others => '1');
   
   -- SELECT RESULT
   res_o <= res_s;
   with op_i select
      res_s <= and_res when and_op, --and
      or_res when or_op, --or
      xor_res when xor_op, --xor
      add_res when add_op, --add (changed opcode)
      sub_res when sub_op, --sub
      eq_res when eq_op, -- set equal
      neq_res when neq_op,
      min_res when min_op,
      minu_res when minu_op,
      slt_res when slt_op, -- set less than signed
      sltu_res when sltu_op, -- set less than unsigned
      sleu_res when sleu_op,
      sle_res when sle_op,
      sgtu_res when sgtu_op,
      sgt_res when sgt_op,
      sll_res when sll_op, -- shift left logic
      srl_res when srl_op, -- shift right logic
      sra_res when sra_op, -- shift right arithmetic
      muls_res(WIDTH-1 downto 0) when muls_op, -- multiply lower
      mulhs_res(2*WIDTH-1 downto WIDTH) when mulhs_op, -- multiply higher signed
      mulhsu_res(2*WIDTH-1 downto WIDTH) when mulhsu_op, -- multiply higher signed and unsigned
      mulhu_res(2*WIDTH -1 downto WIDTH) when mulhu_op, -- multiply higher unsigned
      --divu_res when divu_op, -- divide unsigned
      --divs_res when divs_op, -- divide signed
      --remu_res when remu_op, -- reminder signed
      --rems_res when rems_op, -- reminder signed
      (others => '1') when others; 


   -- flag outputs
   -- set zero output flag when result is zero
   --zero_o <= '1' when res_s = std_logic_vector(to_unsigned(0,WIDTH)) else
             --'0';
   -- overflow happens when inputs have same sign, and output has different
   --of_o <= '1' when ((op_i="00011" and (a_i(WIDTH-1)=b_i(WIDTH-1)) and ((a_i(WIDTH-1) xor res_s(WIDTH-1))='1')) or (op_i="10011" and (a_i(WIDTH-1)=res_s(WIDTH-1)) and ((a_i(WIDTH-1) xor b_i(WIDTH-1))='1'))) else '0';


END behavioral;
