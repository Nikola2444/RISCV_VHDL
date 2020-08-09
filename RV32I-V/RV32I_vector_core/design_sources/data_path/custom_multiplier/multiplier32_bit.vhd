-- THIS IP realises 64 bit multiplier by using 6 DPS slices on artix fpga. When this
-- multiplier receives inputs it will give the result after 4 clock cycles.

-- Basic idea is to
-- to use the next equivalence:

--                     X*Y = 2^(2k)*X1*Y1 + 2^(2k)(X1Y0 + X0Y1) + X0Y0

-- Here X and Y are 32 bit values.X1, Y1, X0, Y0 should be 16 bit values where
-- X1 contains upper 16 bits of X, Y1 containts upper 16 bits of Y, X0
-- contains lower 16 bits of X nad Y0 contains lower 16 bits of Y.
-- K has value 16

-- To calculate this equation 6 DSP slices were used. Each DSP was used to calculate
-- one part of previous equation. Order in which calculation takes places is:

-- In clock 0:
          -- DSP1 is calculating: X1*Y1.
          -- DSP2 is calculating: X0*Y0
          -- DSP3 is calculating: X1*Y0
          -- DSP4 is calculating: X0*Y1

-- In clock 1:
          -- DSP5 is calculating: X1*Y0 + X0*Y1
          -- DSP1(31:0) was concataneted with result of DSP2(31:16) and put
          -- into C register of DSP7. This concatanation is equivalent to 2^16
          -- left shift of DSP1 result.
          -- DSP2(15:0) was put into dsp2_p_clk1_reg_s so it can be used for
          -- concatanation in clock 3.
-- In clock 2:
          -- DSP6 is calculating DSP1 + DSP5
-- In clock 3:
          -- Output of DSP6 is being concataneted with DSP6 output and sent to
          -- c output.




library ieee;
use ieee.std_logic_1164.all;
use work.custom_functions_pkg.all;
use ieee.numeric_std.all;
use work.vector_alu_ops_pkg.all;
library UNISIM;
use UNISIM.vcomponents.all;

entity multiplier32_bit is
   generic (DATA_WIDTH : natural := 32);
   port (
      clk   : in  std_logic;
      reset : in  std_logic;
      --op   : in STD_LOGIC_VECTOR(4 DOWNTO 0); --operation Selection
      op   : in vector_alu_ops_t; --operation select
      a     : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
      b     : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
      c     : out std_logic_vector(2*DATA_WIDTH - 1 downto 0));
end entity;

architecture beh of multiplier32_bit is

   constant zero_14bit_c : std_logic_vector(13 downto 0) := "0000"&"0000"&"0000"&"00";
     
   signal reset_s : std_logic;
   
   signal X1_s : std_logic_vector(29 downto 0);
   signal Y1_s : std_logic_vector(17 downto 0);

   signal X0_s : std_logic_vector(29 downto 0);
   signal Y0_s : std_logic_vector(17 downto 0);
     
   -- logic needed to check whether the input are signed or unsigned
   --output sign needs to be propagated trough all the multiply stages
   signal output_sign_clk0_s, output_sign_clk1_s, output_sign_clk2_s, output_sign_clk3_s, output_sign_clk4_s : std_logic;
   
   signal a_signed_s: std_logic_vector(DATA_WIDTH - 1 downto 0);
   signal b_signed_s: std_logic_vector(DATA_WIDTH - 1 downto 0);
   signal a_s: std_logic_vector(DATA_WIDTH - 1 downto 0);
   signal b_s: std_logic_vector(DATA_WIDTH - 1 downto 0);
   signal c_s: std_logic_vector(2 * DATA_WIDTH - 1 downto 0);
   signal c_complemented_s: std_logic_vector (2 * DATA_WIDTH -1 downto 0);

   
   signal X1Y1_shifted_s_16_bits_s: std_logic_vector (47 downto 0);   

   signal dsp1_over_flow_s  : std_logic;
   signal dsp1_under_flow_s : std_logic;
   signal dsp1_a_input_s    : std_logic_vector(29 downto 0);
   signal dsp1_p_out_s        : std_logic_vector (47 downto 0);


   signal dsp2_over_flow_s  : std_logic;
   signal dsp2_under_flow_s : std_logic;
   signal dsp2_p_out_s        : std_logic_vector (47 downto 0);
   signal dsp2_p_clk1_reg_s : std_logic_vector (15 downto 0);
   signal dsp2_p_clk2_reg_s : std_logic_vector (15 downto 0);
     

   signal dsp3_over_flow_s  : std_logic;
   signal dsp3_under_flow_s : std_logic;
   signal dsp3_p_out_s        : std_logic_vector (47 downto 0);

   signal dsp4_over_flow_s  : std_logic;
   signal dsp4_under_flow_s : std_logic;
   signal dsp4_p_out_s        : std_logic_vector (47 downto 0);

   signal dsp5_over_flow_s  : std_logic;
   signal dsp5_under_flow_s : std_logic;
   signal dsp5_pcin_input_s : std_logic_vector(47 downto 0);
   signal dsp5_a_input_s    : std_logic_vector(29 downto 0);
   signal dsp5_b_input_s    : std_logic_vector(17 downto 0);
   signal dsp5_p_out_s        : std_logic_vector (47 downto 0);

   signal dsp6_over_flow_s  : std_logic;
   signal dsp6_under_flow_s : std_logic;
   signal dsp6_p_out_s        : std_logic_vector (47 downto 0);
   signal dsp6_a_input_s    : std_logic_vector(29 downto 0);
   signal dsp6_b_input_s    : std_logic_vector(17 downto 0);

   


begin
   
   --************************Multiplier output**************************************
   --Concatanating dsp6_p_out_s(47:0) with dsp2_p_reg(15 : 0) to get a 64 bit result
   c_complemented_s <= std_logic_vector( unsigned(not c_s) + to_unsigned(1, DATA_WIDTH));
   c_s <= dsp6_p_out_s(47 downto 0) & dsp2_p_clk2_reg_s;
   c <= c_complemented_s when output_sign_clk4_s = '1' else
        c_s;
   --******************************************************************************

   --*************************SIGN CHECK LOGIC**************************************
   
   a_signed_s <= std_logic_vector(unsigned(not a) + to_unsigned(1, DATA_WIDTH));
   
   process (a, op, a_signed_s) is
   begin
      if (a(DATA_WIDTH - 1) /= '1') then
         a_s <= a;
      else
          case op is
            when muls_op =>
               a_s <= a_signed_s;
            when mulhs_op =>
               a_s <= a_signed_s;
            when others =>
               a_s <= a;
         end case;      
      end if;      
   end process;
   
   b_signed_s <= std_logic_vector(unsigned(not b) + to_unsigned(1, DATA_WIDTH));
   
   process (b, op, b_signed_s) is
   begin
      if (b(DATA_WIDTH - 1) /= '1') then
         b_s <= b;
      else
         case op is
            when muls_op =>
               b_s <= b_signed_s;
            when mulhs_op =>
               b_s <= b_signed_s;
            when mulhsu_op =>
               b_s <= b_signed_s;
            when others =>
               b_s <= b;
         end case;      
      end if;      
   end process;

   
   output_sign_clk0_s <= a(DATA_WIDTH - 1) xor b(DATA_WIDTH - 1) when op /= mulhu_op else
                         '0';
   process (clk) is
   begin
      if (rising_edge(clk))then
         if (reset_s = '1') then
            output_sign_clk1_s <= '0';
            output_sign_clk2_s <= '0';
            output_sign_clk3_s <= '0';
            output_sign_clk4_s <= '0';
         else
            
            output_sign_clk1_s <= output_sign_clk0_s;
            output_sign_clk2_s <= output_sign_clk1_s;
            output_sign_clk3_s <= output_sign_clk2_s;
            output_sign_clk4_s <= output_sign_clk3_s;            
         end if;
      end if;
   end process;

   --**************************************************************************************

   
   -- This was neccesseray because system reset is on '0' but dsp reset is on '1'
   reset_s <= not reset;
   
   -- Because DSP input A a expects a 30 bit input X1 is 30 bits wide
   X1_s    <= zero_14bit_c & a_s(31 downto 16);

   -- Because DSP input B a expects a 18 bit input Y1 is 18 bits wide
   Y1_s    <= "00"&b_s(31 downto 16);                -- upper 15 bits of b input

   -- Because DSP input A a expects a 30 bit input X0 is 30 bits wide
   X0_s <= zero_14bit_c & a_s(15 downto 0);  -- down 17 bits of a_input

   -- Because DSP input B a expects a 18 bit input Y0 is 18 bits wide
   Y0_s <= "00"&b_s(15 downto 0);             -- down 17 bits of b input

   
   
   --***********Using outputs of DSP1 and DSP2*********************
   --Concatanating dsp1_p_out_s(31:0) with dsp2(31:15). This is equivalent to
   --2^16 left shift
   X1Y1_shifted_s_16_bits_s    <= dsp1_p_out_s(31 downto 0) & dsp2_p_out_s(31 downto 16);   

   --Puting dsp2_p_out_s (15 downto 0) into register 
   process (clk) is
   begin
      if (rising_edge(clk)) then
         if (reset_s = '1') then
            dsp2_p_clk1_reg_s <= (others => '0');
            dsp2_p_clk2_reg_s <= (others => '0');
         else
            dsp2_p_clk1_reg_s <= dsp2_p_out_s (15 downto 0);
            dsp2_p_clk2_reg_s <= dsp2_p_clk1_reg_s;
         end if;
      end if;
   end process;
   --***********Using outputs of DSP4 and DSP5*********************
   
   -- Separating dsp3_p_out_s into two parts, one 30 bits large, the other 18,
   -- and sending them to A and B inputs of DSP6 inputs respectively. In DSP6 these two inputs
   -- will be concataneted (A&B) and summed with PCIN which is the output of DSP4. 
   dsp5_a_input_s    <= dsp3_p_out_s (47 downto 18);
   dsp5_b_input_s    <= dsp3_p_out_s (17 downto 0);
   dsp5_pcin_input_s <= dsp4_p_out_s;


   --***********Using outputs of DSP6*********************
   -- In dsp6 output of DSP6 and X1Y1_shifted_s_16_bits_s are being summed.
   -- X1Y1_shifted_s_16_bits_s was is calculating in clk1 but used in clk3. This
   -- was possible because it was registered inside DSP7 for 1 clk.
   
   dsp6_a_input_s           <= dsp5_p_out_s(47 downto 18);
   dsp6_b_input_s           <= dsp5_p_out_s (17 downto 0);

   --<-----DSP1 computes  X1*Y1 ------->
   DSP48E1_inst_1 : DSP48E1
      generic map (
         -- Feature Control Attributes: Data Path Selection
         A_INPUT            => "DIRECT",  -- Selects A input source, "DIRECT" (A port) or "CASCADE" (ACIN port)
         B_INPUT            => "DIRECT",  -- Selects B input source, "DIRECT" (B port) or "CASCADE" (BCIN port)
         USE_DPORT          => false,   -- Select D port usage (TRUE or FALSE)
         USE_MULT           => "MULTIPLY",  -- Select multiplier usage ("MULTIPLY", "DYNAMIC", or "NONE")
         USE_SIMD           => "ONE48",  -- SIMD selection ("ONE48", "TWO24", "FOUR12")
         -- Pattern Detector Attributes: Pattern Detection Configuration
         AUTORESET_PATDET   => "NO_RESET",  -- "NO_RESET", "RESET_MATCH", "RESET_NOT_MATCH" 
         MASK               => X"3fffffffffff",  -- 48-bit mask value for pattern detect (1=ignore)
         PATTERN            => X"000000000000",  -- 48-bit pattern match for pattern detect
         SEL_MASK           => "MASK",  -- "C", "MASK", "ROUNDING_MODE1", "ROUNDING_MODE2" 
         SEL_PATTERN        => "PATTERN",  -- Select pattern value ("PATTERN" or "C")
         USE_PATTERN_DETECT => "NO_PATDET",  -- Enable pattern detect ("PATDET" or "NO_PATDET")
         -- Register Control Attributes: Pipeline Register Configuration
         ACASCREG           => 0,  -- Number of pipeline stages between A/ACIN and ACOUT (0, 1 or 2)
         ADREG              => 1,  -- Number of pipeline stages for pre-adder (0 or 1)
         ALUMODEREG         => 1,  -- Number of pipeline stages for ALUMODE (0 or 1)
         AREG               => 0,  -- Number of pipeline stages for A (0, 1 or 2)
         BCASCREG           => 0,  -- Number of pipeline stages between B/BCIN and BCOUT (0, 1 or 2)
         BREG               => 0,  -- Number of pipeline stages for B (0, 1 or 2)
         CARRYINREG         => 1,  -- Number of pipeline stages for CARRYIN (0 or 1)
         CARRYINSELREG      => 1,  -- Number of pipeline stages for CARRYINSEL (0 or 1)
         CREG               => 1,  -- Number of pipeline stages for C (0 or 1)
         DREG               => 1,  -- Number of pipeline stages for D (0 or 1)
         INMODEREG          => 1,  -- Number of pipeline stages for INMODE (0 or 1)
         MREG               => 1,  -- Number of multiplier pipeline stages (0 or 1)
         OPMODEREG          => 1,  -- Number of pipeline stages for OPMODE (0 or 1)
         PREG               => 1  -- Number of pipeline stages for P (0 or 1)
         )
      port map (
         -- Cascade: 30-bit (each) output: Cascade Ports
         ACOUT          => open,        -- 30-bit output: A port cascade output
         BCOUT          => open,        -- 18-bit output: B port cascade output
         CARRYCASCOUT   => open,        -- 1-bit output: Cascade carry output
         MULTSIGNOUT    => open,  -- 1-bit output: Multiplier sign cascade output
         PCOUT          => open,        -- 48-bit output: Cascade output
         -- Control: 1-bit (each) output: Control Inputs/Status Bits
         OVERFLOW       => dsp1_over_flow_s,  -- 1-bit output: Overflow in add/acc output
         PATTERNBDETECT => open,  -- 1-bit output: Pattern bar detect output
         PATTERNDETECT  => open,        -- 1-bit output: Pattern detect output
         UNDERFLOW      => dsp1_under_flow_s,  -- 1-bit output: Underflow in add/acc output
         -- Data: 4-bit (each) output: Data Ports
         CARRYOUT       => open,        -- 4-bit output: Carry output
         P              => dsp1_p_out_s,  -- 48-bit output: Primary data output
         -- Cascade: 30-bit (each) input: Cascade Ports
         ACIN           => (others => '0'),  -- 30-bit input: A cascade data input
         BCIN           => (others => '0'),  -- 18-bit input: B cascade input
         CARRYCASCIN    => '0',         -- 1-bit input: Cascade carry input
         MULTSIGNIN     => '0',         -- 1-bit input: Multiplier sign input
         PCIN           => (others => '0'),  -- 48-bit input: P cascade input
         -- Control: 4-bit (each) input: Control Inputs/Status Bits
         ALUMODE        => "0000",      -- 4-bit input: ALU control input
         CARRYINSEL     => (others => '0'),  -- 3-bit input: Carry select input
         CLK            => CLK,         -- 1-bit input: Clock input
         INMODE         => (others => '0'),  -- 5-bit input: INMODE control input
         OPMODE         => "000"&"01"&"01",  -- 7-bit input: Operation mode input(z&y&x)
         -- Data: 30-bit (each) input: Data Ports
         A              => X1_s,        -- 30-bit input: A data input
         B              => Y1_s,        -- 18-bit input: B data input
         C              => (others => '0'),  -- 48-bit input: C data input
         CARRYIN        => '0',         -- 1-bit input: Carry input signal
         D              => (others => '0'),  -- 25-bit input: D data input
         -- Reset/Clock Enable: 1-bit (each) input: Reset/Clock Enable Inputs
         CEA1           => '0',  -- 1-bit input: Clock enable input for 1st stage AREG
         CEA2           => '0',  -- 1-bit input: Clock enable input for 2nd stage AREG
         CEAD           => '0',  -- 1-bit input: Clock enable input for ADREG
         CEALUMODE      => '0',  -- 1-bit input: Clock enable input for ALUMODE
         CEB1           => '0',  -- 1-bit input: Clock enable input for 1st stage BREG
         CEB2           => '0',  -- 1-bit input: Clock enable input for 2nd stage BREG
         CEC            => '0',  -- 1-bit input: Clock enable input for CREG
         CECARRYIN      => '0',  -- 1-bit input: Clock enable input for CARRYINREG
         CECTRL         => '1',  -- 1-bit input: Clock enable input for OPMODEREG and CARRYINSELREG
         CED            => '0',  -- 1-bit input: Clock enable input for DREG
         CEINMODE       => '1',  -- 1-bit input: Clock enable input for INMODEREG
         CEM            => '1',  -- 1-bit input: Clock enable input for MREG
         CEP            => '1',  -- 1-bit input: Clock enable input for PREG
         RSTA           => reset_s,     -- 1-bit input: Reset input for AREG
         RSTALLCARRYIN  => reset_s,  -- 1-bit input: Reset input for CARRYINREG
         RSTALUMODE     => reset_s,  -- 1-bit input: Reset input for ALUMODEREG
         RSTB           => '0',         -- 1-bit input: Reset input for BREG
         RSTC           => '0',         -- 1-bit input: Reset input for CREG
         RSTCTRL        => reset_s,  -- 1-bit input: Reset input for OPMODEREG and CARRYINSELREG
         RSTD           => '0',  -- 1-bit input: Reset input for DREG and ADREG
         RSTINMODE      => reset_s,  -- 1-bit input: Reset input for INMODEREG
         RSTM           => reset_s,     -- 1-bit input: Reset input for MREG
         RSTP           => reset_s      -- 1-bit input: Reset input for PREG
         );



   -- End of DSP48E1_inst1 instantiation



   --<-----DSP2 computes  X0*Y0 ------->
   DSP48E1_inst_2 : DSP48E1
      generic map (
         -- Feature Control Attributes: Data Path Selection
         A_INPUT            => "DIRECT",  -- Selects A input source, "DIRECT" (A port) or "CASCADE" (ACIN port)
         B_INPUT            => "DIRECT",  -- Selects B input source, "DIRECT" (B port) or "CASCADE" (BCIN port)
         USE_DPORT          => false,   -- Select D port usage (TRUE or FALSE)
         USE_MULT           => "MULTIPLY",  -- Select multiplier usage ("MULTIPLY", "DYNAMIC", or "NONE")
         USE_SIMD           => "ONE48",  -- SIMD selection ("ONE48", "TWO24", "FOUR12")
         -- Pattern Detector Attributes: Pattern Detection Configuration
         AUTORESET_PATDET   => "NO_RESET",  -- "NO_RESET", "RESET_MATCH", "RESET_NOT_MATCH" 
         MASK               => X"3fffffffffff",  -- 48-bit mask value for pattern detect (1=ignore)
         PATTERN            => X"000000000000",  -- 48-bit pattern match for pattern detect
         SEL_MASK           => "MASK",  -- "C", "MASK", "ROUNDING_MODE1", "ROUNDING_MODE2" 
         SEL_PATTERN        => "PATTERN",  -- Select pattern value ("PATTERN" or "C")
         USE_PATTERN_DETECT => "NO_PATDET",  -- Enable pattern detect ("PATDET" or "NO_PATDET")
         -- Register Control Attributes: Pipeline Register Configuration
         ACASCREG           => 0,  -- Number of pipeline stages between A/ACIN and ACOUT (0, 1 or 2)
         ADREG              => 1,  -- Number of pipeline stages for pre-adder (0 or 1)
         ALUMODEREG         => 1,  -- Number of pipeline stages for ALUMODE (0 or 1)
         AREG               => 0,  -- Number of pipeline stages for A (0, 1 or 2)
         BCASCREG           => 0,  -- Number of pipeline stages between B/BCIN and BCOUT (0, 1 or 2)
         BREG               => 0,  -- Number of pipeline stages for B (0, 1 or 2)
         CARRYINREG         => 1,  -- Number of pipeline stages for CARRYIN (0 or 1)
         CARRYINSELREG      => 1,  -- Number of pipeline stages for CARRYINSEL (0 or 1)
         CREG               => 1,  -- Number of pipeline stages for C (0 or 1)
         DREG               => 1,  -- Number of pipeline stages for D (0 or 1)
         INMODEREG          => 1,  -- Number of pipeline stages for INMODE (0 or 1)
         MREG               => 1,  -- Number of multiplier pipeline stages (0 or 1)
         OPMODEREG          => 1,  -- Number of pipeline stages for OPMODE (0 or 1)
         PREG               => 1  -- Number of pipeline stages for P (0 or 1)
         )
      port map (
         -- Cascade: 30-bit (each) output: Cascade Ports
         ACOUT          => open,        -- 30-bit output: A port cascade output
         BCOUT          => open,        -- 18-bit output: B port cascade output
         CARRYCASCOUT   => open,        -- 1-bit output: Cascade carry output
         MULTSIGNOUT    => open,  -- 1-bit output: Multiplier sign cascade output
         PCOUT          => open,  -- 48-bit output: Cascade output
         -- Control: 1-bit (each) output: Control Inputs/Status Bits
         OVERFLOW       => dsp2_over_flow_s,  -- 1-bit output: Overflow in add/acc output
         PATTERNBDETECT => open,  -- 1-bit output: Pattern bar detect output
         PATTERNDETECT  => open,        -- 1-bit output: Pattern detect output
         UNDERFLOW      => dsp2_under_flow_s,  -- 1-bit output: Underflow in add/acc output
         -- Data: 4-bit (each) output: Data Ports
         CARRYOUT       => open,        -- 4-bit output: Carry output
         P              => dsp2_p_out_s,        -- 48-bit output: Primary data output
         -- Cascade: 30-bit (each) input: Cascade Ports
         ACIN           => (others => '0'),  -- 30-bit input: A cascade data input
         BCIN           => (others => '0'),  -- 18-bit input: B cascade input
         CARRYCASCIN    => '0',         -- 1-bit input: Cascade carry input
         MULTSIGNIN     => '0',         -- 1-bit input: Multiplier sign input
         PCIN           => (others => '0'),  -- 48-bit input: P cascade input
         -- Control: 4-bit (each) input: Control Inputs/Status Bits
         ALUMODE        => "0000",      -- 4-bit input: ALU control input
         CARRYINSEL     => (others => '0'),  -- 3-bit input: Carry select input
         CLK            => CLK,         -- 1-bit input: Clock input
         INMODE         => (others => '0'),  -- 5-bit input: INMODE control input
         OPMODE         => "000"&"01"&"01",  -- 7-bit input: Operation mode input(z&y&x)
         -- Data: 30-bit (each) input: Data Ports
         A              => X0_s,        -- 30-bit input: A data input
         B              => Y0_s,        -- 18-bit input: B data input
         C              => (others => '0'),  -- 48-bit input: C data input
         CARRYIN        => '0',         -- 1-bit input: Carry input signal
         D              => (others => '0'),  -- 25-bit input: D data input
         -- Reset/Clock Enable: 1-bit (each) input: Reset/Clock Enable Inputs
         CEA1           => '0',  -- 1-bit input: Clock enable input for 1st stage AREG
         CEA2           => '0',  -- 1-bit input: Clock enable input for 2nd stage AREG
         CEAD           => '0',  -- 1-bit input: Clock enable input for ADREG
         CEALUMODE      => '0',  -- 1-bit input: Clock enable input for ALUMODE
         CEB1           => '0',  -- 1-bit input: Clock enable input for 1st stage BREG
         CEB2           => '0',  -- 1-bit input: Clock enable input for 2nd stage BREG
         CEC            => '0',  -- 1-bit input: Clock enable input for CREG
         CECARRYIN      => '0',  -- 1-bit input: Clock enable input for CARRYINREG
         CECTRL         => '1',  -- 1-bit input: Clock enable input for OPMODEREG and CARRYINSELREG
         CED            => '0',  -- 1-bit input: Clock enable input for DREG
         CEINMODE       => '1',  -- 1-bit input: Clock enable input for INMODEREG
         CEM            => '1',  -- 1-bit input: Clock enable input for MREG
         CEP            => '1',  -- 1-bit input: Clock enable input for PREG
         RSTA           => reset_s,     -- 1-bit input: Reset input for AREG
         RSTALLCARRYIN  => reset_s,  -- 1-bit input: Reset input for CARRYINREG
         RSTALUMODE     => reset_s,  -- 1-bit input: Reset input for ALUMODEREG
         RSTB           => '0',         -- 1-bit input: Reset input for BREG
         RSTC           => '0',         -- 1-bit input: Reset input for CREG
         RSTCTRL        => reset_s,  -- 1-bit input: Reset input for OPMODEREG and CARRYINSELREG
         RSTD           => '0',  -- 1-bit input: Reset input for DREG and ADREG
         RSTINMODE      => reset_s,  -- 1-bit input: Reset input for INMODEREG
         RSTM           => reset_s,     -- 1-bit input: Reset input for MREG
         RSTP           => reset_s      -- 1-bit input: Reset input for PREG
         );



   DSP48E1_inst_3 : DSP48E1
      generic map (
         -- Feature Control Attributes: Data Path Selection
         A_INPUT            => "DIRECT",  -- Selects A input source, "DIRECT" (A port) or "CASCADE" (ACIN port)
         B_INPUT            => "DIRECT",  -- Selects B input source, "DIRECT" (B port) or "CASCADE" (BCIN port)
         USE_DPORT          => false,   -- Select D port usage (TRUE or FALSE)
         USE_MULT           => "MULTIPLY",  -- Select multiplier usage ("MULTIPLY", "DYNAMIC", or "NONE")
         USE_SIMD           => "ONE48",  -- SIMD selection ("ONE48", "TWO24", "FOUR12")
         -- Pattern Detector Attributes: Pattern Detection Configuration
         AUTORESET_PATDET   => "NO_RESET",  -- "NO_RESET", "RESET_MATCH", "RESET_NOT_MATCH" 
         MASK               => X"3fffffffffff",  -- 48-bit mask value for pattern detect (1=ignore)
         PATTERN            => X"000000000000",  -- 48-bit pattern match for pattern detect
         SEL_MASK           => "MASK",  -- "C", "MASK", "ROUNDING_MODE1", "ROUNDING_MODE2" 
         SEL_PATTERN        => "PATTERN",  -- Select pattern value ("PATTERN" or "C")
         USE_PATTERN_DETECT => "NO_PATDET",  -- Enable pattern detect ("PATDET" or "NO_PATDET")
         -- Register Control Attributes: Pipeline Register Configuration
         ACASCREG           => 0,  -- Number of pipeline stages between A/ACIN and ACOUT (0, 1 or 2)
         ADREG              => 1,  -- Number of pipeline stages for pre-adder (0 or 1)
         ALUMODEREG         => 1,  -- Number of pipeline stages for ALUMODE (0 or 1)
         AREG               => 0,  -- Number of pipeline stages for A (0, 1 or 2)
         BCASCREG           => 0,  -- Number of pipeline stages between B/BCIN and BCOUT (0, 1 or 2)
         BREG               => 0,  -- Number of pipeline stages for B (0, 1 or 2)
         CARRYINREG         => 1,  -- Number of pipeline stages for CARRYIN (0 or 1)
         CARRYINSELREG      => 1,  -- Number of pipeline stages for CARRYINSEL (0 or 1)
         CREG               => 1,  -- Number of pipeline stages for C (0 or 1)
         DREG               => 1,  -- Number of pipeline stages for D (0 or 1)
         INMODEREG          => 1,  -- Number of pipeline stages for INMODE (0 or 1)
         MREG               => 1,  -- Number of multiplier pipeline stages (0 or 1)
         OPMODEREG          => 1,  -- Number of pipeline stages for OPMODE (0 or 1)
         PREG               => 1  -- Number of pipeline stages for P (0 or 1)
         )
      port map (
         -- Cascade: 30-bit (each) output: Cascade Ports
         ACOUT          => open,        -- 30-bit output: A port cascade output
         BCOUT          => open,        -- 18-bit output: B port cascade output
         CARRYCASCOUT   => open,        -- 1-bit output: Cascade carry output
         MULTSIGNOUT    => open,  -- 1-bit output: Multiplier sign cascade output
         PCOUT          => open,        -- 48-bit output: Cascade output
         -- Control: 1-bit (each) output: Control Inputs/Status Bits
         OVERFLOW       => dsp3_over_flow_s,  -- 1-bit output: Overflow in add/acc output
         PATTERNBDETECT => open,  -- 1-bit output: Pattern bar detect output
         PATTERNDETECT  => open,        -- 1-bit output: Pattern detect output
         UNDERFLOW      => dsp3_under_flow_s,  -- 1-bit output: Underflow in add/acc output
         -- Data: 4-bit (each) output: Data Ports
         CARRYOUT       => open,        -- 4-bit output: Carry output
         P              => dsp3_p_out_s,  -- 48-bit output: Primary data output
         -- Cascade: 30-bit (each) input: Cascade Ports
         ACIN           => (others => '0'),  -- 30-bit input: A cascade data input
         BCIN           => (others => '0'),  -- 18-bit input: B cascade input
         CARRYCASCIN    => '0',         -- 1-bit input: Cascade carry input
         MULTSIGNIN     => '0',         -- 1-bit input: Multiplier sign input
         PCIN           => (others => '0'),  -- 48-bit input: P cascade input
         -- Control: 4-bit (each) input: Control Inputs/Status Bits
         ALUMODE        => "0000",      -- 4-bit input: ALU control input
         CARRYINSEL     => (others => '0'),  -- 3-bit input: Carry select input
         CLK            => CLK,         -- 1-bit input: Clock input
         INMODE         => (others => '0'),  -- 5-bit input: INMODE control input
         OPMODE         => "000"&"01"&"01",  -- 7-bit input: Operation mode input(z&y&x)
         -- Data: 30-bit (each) input: Data Ports
         A              => X1_s,        -- 30-bit input: A data input
         B              => Y0_s,        -- 18-bit input: B data input
         C              => (others => '0'),  -- 48-bit input: C data input
         CARRYIN        => '0',         -- 1-bit input: Carry input signal
         D              => (others => '0'),  -- 25-bit input: D data input
         -- Reset/Clock Enable: 1-bit (each) input: Reset/Clock Enable Inputs
         CEA1           => '0',  -- 1-bit input: Clock enable input for 1st stage AREG
         CEA2           => '0',  -- 1-bit input: Clock enable input for 2nd stage AREG
         CEAD           => '0',  -- 1-bit input: Clock enable input for ADREG
         CEALUMODE      => '0',  -- 1-bit input: Clock enable input for ALUMODE
         CEB1           => '0',  -- 1-bit input: Clock enable input for 1st stage BREG
         CEB2           => '0',  -- 1-bit input: Clock enable input for 2nd stage BREG
         CEC            => '0',  -- 1-bit input: Clock enable input for CREG
         CECARRYIN      => '0',  -- 1-bit input: Clock enable input for CARRYINREG
         CECTRL         => '1',  -- 1-bit input: Clock enable input for OPMODEREG and CARRYINSELREG
         CED            => '0',  -- 1-bit input: Clock enable input for DREG
         CEINMODE       => '1',  -- 1-bit input: Clock enable input for INMODEREG
         CEM            => '1',  -- 1-bit input: Clock enable input for MREG
         CEP            => '1',  -- 1-bit input: Clock enable input for PREG
         RSTA           => reset_s,     -- 1-bit input: Reset input for AREG
         RSTALLCARRYIN  => reset_s,  -- 1-bit input: Reset input for CARRYINREG
         RSTALUMODE     => reset_s,  -- 1-bit input: Reset input for ALUMODEREG
         RSTB           => '0',         -- 1-bit input: Reset input for BREG
         RSTC           => '0',         -- 1-bit input: Reset input for CREG
         RSTCTRL        => reset_s,  -- 1-bit input: Reset input for OPMODEREG and CARRYINSELREG
         RSTD           => '0',  -- 1-bit input: Reset input for DREG and ADREG
         RSTINMODE      => reset_s,  -- 1-bit input: Reset input for INMODEREG
         RSTM           => reset_s,     -- 1-bit input: Reset input for MREG
         RSTP           => reset_s      -- 1-bit input: Reset input for PREG
         );


   --END of DSP_inst_3 instantiation

   --<-----DSP5 computes  X0*Y1 ------->
   DSP48E1_inst_4 : DSP48E1
      generic map (
         -- Feature Control Attributes: Data Path Selection
         A_INPUT            => "DIRECT",  -- Selects A input source, "DIRECT" (A port) or "CASCADE" (ACIN port)
         B_INPUT            => "DIRECT",  -- Selects B input source, "DIRECT" (B port) or "CASCADE" (BCIN port)
         USE_DPORT          => false,   -- Select D port usage (TRUE or FALSE)
         USE_MULT           => "MULTIPLY",  -- Select multiplier usage ("MULTIPLY", "DYNAMIC", or "NONE")
         USE_SIMD           => "ONE48",  -- SIMD selection ("ONE48", "TWO24", "FOUR12")
         -- Pattern Detector Attributes: Pattern Detection Configuration
         AUTORESET_PATDET   => "NO_RESET",  -- "NO_RESET", "RESET_MATCH", "RESET_NOT_MATCH" 
         MASK               => X"3fffffffffff",  -- 48-bit mask value for pattern detect (1=ignore)
         PATTERN            => X"000000000000",  -- 48-bit pattern match for pattern detect
         SEL_MASK           => "MASK",  -- "C", "MASK", "ROUNDING_MODE1", "ROUNDING_MODE2" 
         SEL_PATTERN        => "PATTERN",  -- Select pattern value ("PATTERN" or "C")
         USE_PATTERN_DETECT => "NO_PATDET",  -- Enable pattern detect ("PATDET" or "NO_PATDET")
         -- Register Control Attributes: Pipeline Register Configuration
         ACASCREG           => 0,  -- Number of pipeline stages between A/ACIN and ACOUT (0, 1 or 2)
         ADREG              => 1,  -- Number of pipeline stages for pre-adder (0 or 1)
         ALUMODEREG         => 1,  -- Number of pipeline stages for ALUMODE (0 or 1)
         AREG               => 0,  -- Number of pipeline stages for A (0, 1 or 2)
         BCASCREG           => 0,  -- Number of pipeline stages between B/BCIN and BCOUT (0, 1 or 2)
         BREG               => 0,  -- Number of pipeline stages for B (0, 1 or 2)
         CARRYINREG         => 1,  -- Number of pipeline stages for CARRYIN (0 or 1)
         CARRYINSELREG      => 1,  -- Number of pipeline stages for CARRYINSEL (0 or 1)
         CREG               => 1,  -- Number of pipeline stages for C (0 or 1)
         DREG               => 1,  -- Number of pipeline stages for D (0 or 1)
         INMODEREG          => 1,  -- Number of pipeline stages for INMODE (0 or 1)
         MREG               => 1,  -- Number of multiplier pipeline stages (0 or 1)
         OPMODEREG          => 1,  -- Number of pipeline stages for OPMODE (0 or 1)
         PREG               => 1  -- Number of pipeline stages for P (0 or 1)
         )
      port map (
         -- Cascade: 30-bit (each) output: Cascade Ports
         ACOUT          => open,        -- 30-bit output: A port cascade output
         BCOUT          => open,        -- 18-bit output: B port cascade output
         CARRYCASCOUT   => open,        -- 1-bit output: Cascade carry output
         MULTSIGNOUT    => open,  -- 1-bit output: Multiplier sign cascade output
         PCOUT          => dsp4_p_out_s,  -- 48-bit output: Cascade output
         -- Control: 1-bit (each) output: Control Inputs/Status Bits
         OVERFLOW       => dsp4_over_flow_s,  -- 1-bit output: Overflow in add/acc output
         PATTERNBDETECT => open,  -- 1-bit output: Pattern bar detect output
         PATTERNDETECT  => open,        -- 1-bit output: Pattern detect output
         UNDERFLOW      => dsp4_under_flow_s,  -- 1-bit output: Underflow in add/acc output
         -- Data: 4-bit (each) output: Data Ports
         CARRYOUT       => open,        -- 4-bit output: Carry output
         P              => open,        -- 48-bit output: Primary data output
         -- Cascade: 30-bit (each) input: Cascade Ports
         ACIN           => (others => '0'),  -- 30-bit input: A cascade data input
         BCIN           => (others => '0'),  -- 18-bit input: B cascade input
         CARRYCASCIN    => '0',         -- 1-bit input: Cascade carry input
         MULTSIGNIN     => '0',         -- 1-bit input: Multiplier sign input
         PCIN           => (others => '0'),  -- 48-bit input: P cascade input
         -- Control: 4-bit (each) input: Control Inputs/Status Bits
         ALUMODE        => "0000",      -- 4-bit input: ALU control input
         CARRYINSEL     => (others => '0'),  -- 3-bit input: Carry select input
         CLK            => CLK,         -- 1-bit input: Clock input
         INMODE         => (others => '0'),  -- 5-bit input: INMODE control input
         OPMODE         => "000"&"01"&"01",  -- 7-bit input: Operation mode input(z&y&x)
         -- Data: 30-bit (each) input: Data Ports
         A              => X0_s,        -- 30-bit input: A data input
         B              => Y1_s,        -- 18-bit input: B data input
         C              => (others => '0'),  -- 48-bit input: C data input
         CARRYIN        => '0',         -- 1-bit input: Carry input signal
         D              => (others => '0'),  -- 25-bit input: D data input
         -- Reset/Clock Enable: 1-bit (each) input: Reset/Clock Enable Inputs
         CEA1           => '0',  -- 1-bit input: Clock enable input for 1st stage AREG
         CEA2           => '0',  -- 1-bit input: Clock enable input for 2nd stage AREG
         CEAD           => '0',  -- 1-bit input: Clock enable input for ADREG
         CEALUMODE      => '0',  -- 1-bit input: Clock enable input for ALUMODE
         CEB1           => '0',  -- 1-bit input: Clock enable input for 1st stage BREG
         CEB2           => '0',  -- 1-bit input: Clock enable input for 2nd stage BREG
         CEC            => '0',  -- 1-bit input: Clock enable input for CREG
         CECARRYIN      => '0',  -- 1-bit input: Clock enable input for CARRYINREG
         CECTRL         => '1',  -- 1-bit input: Clock enable input for OPMODEREG and CARRYINSELREG
         CED            => '0',  -- 1-bit input: Clock enable input for DREG
         CEINMODE       => '1',  -- 1-bit input: Clock enable input for INMODEREG
         CEM            => '1',  -- 1-bit input: Clock enable input for MREG
         CEP            => '1',  -- 1-bit input: Clock enable input for PREG
         RSTA           => reset_s,     -- 1-bit input: Reset input for AREG
         RSTALLCARRYIN  => reset_s,  -- 1-bit input: Reset input for CARRYINREG
         RSTALUMODE     => reset_s,  -- 1-bit input: Reset input for ALUMODEREG
         RSTB           => '0',         -- 1-bit input: Reset input for BREG
         RSTC           => '0',         -- 1-bit input: Reset input for CREG
         RSTCTRL        => reset_s,  -- 1-bit input: Reset input for OPMODEREG and CARRYINSELREG
         RSTD           => '0',  -- 1-bit input: Reset input for DREG and ADREG
         RSTINMODE      => reset_s,  -- 1-bit input: Reset input for INMODEREG
         RSTM           => reset_s,     -- 1-bit input: Reset input for MREG
         RSTP           => reset_s      -- 1-bit input: Reset input for PREG
         );

   --END of DSP_inst_4 instantiation

   --<-----DSP3 computes  X1*Y1 >> 34 + X0Y0---->


   DSP48E1_inst_5 : DSP48E1
      generic map (
         -- Feature Control Attributes: Data Path Selection
         A_INPUT            => "DIRECT",  -- Selects A input source, "DIRECT" (A port) or "CASCADE" (ACIN port)
         B_INPUT            => "DIRECT",  -- Selects B input source, "DIRECT" (B port) or "CASCADE" (BCIN port)
         USE_DPORT          => false,   -- Select D port usage (TRUE or FALSE)
         USE_MULT           => "MULTIPLY",  -- Select multiplier usage ("MULTIPLY", "DYNAMIC", or "NONE")
         USE_SIMD           => "ONE48",  -- SIMD selection ("ONE48", "TWO24", "FOUR12")
         -- Pattern Detector Attributes: Pattern Detection Configuration
         AUTORESET_PATDET   => "NO_RESET",  -- "NO_RESET", "RESET_MATCH", "RESET_NOT_MATCH" 
         MASK               => X"3fffffffffff",  -- 48-bit mask value for pattern detect (1=ignore)
         PATTERN            => X"000000000000",  -- 48-bit pattern match for pattern detect
         SEL_MASK           => "MASK",  -- "C", "MASK", "ROUNDING_MODE1", "ROUNDING_MODE2" 
         SEL_PATTERN        => "PATTERN",  -- Select pattern value ("PATTERN" or "C")
         USE_PATTERN_DETECT => "NO_PATDET",  -- Enable pattern detect ("PATDET" or "NO_PATDET")
         -- Register Control Attributes: Pipeline Register Configuration
         ACASCREG           => 0,  -- Number of pipeline stages between A/ACIN and ACOUT (0, 1 or 2)
         ADREG              => 1,  -- Number of pipeline stages for pre-adder (0 or 1)
         ALUMODEREG         => 1,  -- Number of pipeline stages for ALUMODE (0 or 1)
         AREG               => 0,  -- Number of pipeline stages for A (0, 1 or 2)
         BCASCREG           => 0,  -- Number of pipeline stages between B/BCIN and BCOUT (0, 1 or 2)
         BREG               => 0,  -- Number of pipeline stages for B (0, 1 or 2)
         CARRYINREG         => 1,  -- Number of pipeline stages for CARRYIN (0 or 1)
         CARRYINSELREG      => 1,  -- Number of pipeline stages for CARRYINSEL (0 or 1)
         CREG               => 1,  -- Number of pipeline stages for C (0 or 1)
         DREG               => 1,  -- Number of pipeline stages for D (0 or 1)
         INMODEREG          => 1,  -- Number of pipeline stages for INMODE (0 or 1)
         MREG               => 1,  -- Number of multiplier pipeline stages (0 or 1)
         OPMODEREG          => 1,  -- Number of pipeline stages for OPMODE (0 or 1)
         PREG               => 1  -- Number of pipeline stages for P (0 or 1)
         )
      port map (
         -- Cascade: 30-bit (each) output: Cascade Ports
         ACOUT          => open,        -- 30-bit output: A port cascade output
         BCOUT          => open,        -- 18-bit output: B port cascade output
         CARRYCASCOUT   => open,        -- 1-bit output: Cascade carry output
         MULTSIGNOUT    => open,  -- 1-bit output: Multiplier sign cascade output
         PCOUT          => open,        -- 48-bit output: Cascade output
         -- Control: 1-bit (each) output: Control Inputs/Status Bits
         OVERFLOW       => dsp5_over_flow_s,  -- 1-bit output: Overflow in add/acc output
         PATTERNBDETECT => open,  -- 1-bit output: Pattern bar detect output
         PATTERNDETECT  => open,        -- 1-bit output: Pattern detect output
         UNDERFLOW      => dsp5_under_flow_s,  -- 1-bit output: Underflow in add/acc output
         -- Data: 4-bit (each) output: Data Ports
         CARRYOUT       => open,        -- 4-bit output: Carry output
         P              => dsp5_p_out_s,  -- 48-bit output: Primary data output
         -- Cascade: 30-bit (each) input: Cascade Ports
         ACIN           => (others => '0'),  -- 30-bit input: A cascade data input
         BCIN           => (others => '0'),  -- 18-bit input: B cascade input
         CARRYCASCIN    => '0',         -- 1-bit input: Cascade carry input
         MULTSIGNIN     => '0',         -- 1-bit input: Multiplier sign input
         PCIN           => dsp5_pcin_input_s,  -- 48-bit input: P cascade input
         -- Control: 4-bit (each) input: Control Inputs/Status Bits
         ALUMODE        => "0000",      -- 4-bit input: ALU control input
         CARRYINSEL     => (others => '0'),  -- 3-bit input: Carry select input
         CLK            => CLK,         -- 1-bit input: Clock input
         INMODE         => (others => '0'),  -- 5-bit input: INMODE control input
         OPMODE         => "001"&"00"&"11",  -- 7-bit input: Operation mode input(z&y&x)
         -- Data: 30-bit (each) input: Data Ports
         A              => dsp5_a_input_s,  -- 30-bit input: A data input
         B              => dsp5_b_input_s,  -- 18-bit input: B data input
         C              => (others => '0'),  -- 48-bit input: C data input
         CARRYIN        => '0',         -- 1-bit input: Carry input signal
         D              => (others => '0'),  -- 25-bit input: D data input
         -- Reset/Clock Enable: 1-bit (each) input: Reset/Clock Enable Inputs
         CEA1           => '0',  -- 1-bit input: Clock enable input for 1st stage AREG
         CEA2           => '0',  -- 1-bit input: Clock enable input for 2nd stage AREG
         CEAD           => '0',  -- 1-bit input: Clock enable input for ADREG
         CEALUMODE      => '0',  -- 1-bit input: Clock enable input for ALUMODE
         CEB1           => '0',  -- 1-bit input: Clock enable input for 1st stage BREG
         CEB2           => '0',  -- 1-bit input: Clock enable input for 2nd stage BREG
         CEC            => '0',  -- 1-bit input: Clock enable input for CREG
         CECARRYIN      => '0',  -- 1-bit input: Clock enable input for CARRYINREG
         CECTRL         => '1',  -- 1-bit input: Clock enable input for OPMODEREG and CARRYINSELREG
         CED            => '0',  -- 1-bit input: Clock enable input for DREG
         CEINMODE       => '1',  -- 1-bit input: Clock enable input for INMODEREG
         CEM            => '1',  -- 1-bit input: Clock enable input for MREG
         CEP            => '1',  -- 1-bit input: Clock enable input for PREG
         RSTA           => reset_s,     -- 1-bit input: Reset input for AREG
         RSTALLCARRYIN  => reset_s,  -- 1-bit input: Reset input for CARRYINREG
         RSTALUMODE     => reset_s,  -- 1-bit input: Reset input for ALUMODEREG
         RSTB           => '0',         -- 1-bit input: Reset input for BREG
         RSTC           => '0',         -- 1-bit input: Reset input for CREG
         RSTCTRL        => reset_s,  -- 1-bit input: Reset input for OPMODEREG and CARRYINSELREG
         RSTD           => '0',  -- 1-bit input: Reset input for DREG and ADREG
         RSTINMODE      => reset_s,  -- 1-bit input: Reset input for INMODEREG
         RSTM           => reset_s,     -- 1-bit input: Reset input for MREG
         RSTP           => reset_s      -- 1-bit input: Reset input for PREG
         );

   -- END of dsp_inst_5 instantiation



   DSP48E1_inst_6 : DSP48E1
      generic map (
         -- Feature Control Attributes: Data Path Selection
         A_INPUT            => "DIRECT",  -- Selects A input source, "DIRECT" (A port) or "CASCADE" (ACIN port)
         B_INPUT            => "DIRECT",  -- Selects B input source, "DIRECT" (B port) or "CASCADE" (BCIN port)
         USE_DPORT          => false,   -- Select D port usage (TRUE or FALSE)
         USE_MULT           => "MULTIPLY",  -- Select multiplier usage ("MULTIPLY", "DYNAMIC", or "NONE")
         USE_SIMD           => "ONE48",  -- SIMD selection ("ONE48", "TWO24", "FOUR12")
         -- Pattern Detector Attributes: Pattern Detection Configuration
         AUTORESET_PATDET   => "NO_RESET",  -- "NO_RESET", "RESET_MATCH", "RESET_NOT_MATCH" 
         MASK               => X"3fffffffffff",  -- 48-bit mask value for pattern detect (1=ignore)
         PATTERN            => X"000000000000",  -- 48-bit pattern match for pattern detect
         SEL_MASK           => "C",  -- "C", "MASK", "ROUNDING_MODE1", "ROUNDING_MODE2" 
         SEL_PATTERN        => "PATTERN",  -- Select pattern value ("PATTERN" or "C")
         USE_PATTERN_DETECT => "NO_PATDET",  -- Enable pattern detect ("PATDET" or "NO_PATDET")
         -- Register Control Attributes: Pipeline Register Configuration
         ACASCREG           => 0,  -- Number of pipeline stages between A/ACIN and ACOUT (0, 1 or 2)
         ADREG              => 1,  -- Number of pipeline stages for pre-adder (0 or 1)
         ALUMODEREG         => 1,  -- Number of pipeline stages for ALUMODE (0 or 1)
         AREG               => 0,  -- Number of pipeline stages for A (0, 1 or 2)
         BCASCREG           => 0,  -- Number of pipeline stages between B/BCIN and BCOUT (0, 1 or 2)
         BREG               => 0,  -- Number of pipeline stages for B (0, 1 or 2)
         CARRYINREG         => 1,  -- Number of pipeline stages for CARRYIN (0 or 1)
         CARRYINSELREG      => 1,  -- Number of pipeline stages for CARRYINSEL (0 or 1)
         CREG               => 1,  -- Number of pipeline stages for C (0 or 1)
         DREG               => 1,  -- Number of pipeline stages for D (0 or 1)
         INMODEREG          => 1,  -- Number of pipeline stages for INMODE (0 or 1)
         MREG               => 1,  -- Number of multiplier pipeline stages (0 or 1)
         OPMODEREG          => 1,  -- Number of pipeline stages for OPMODE (0 or 1)
         PREG               => 1  -- Number of pipeline stages for P (0 or 1)
         )
      port map (
         -- Cascade: 30-bit (each) output: Cascade Ports
         ACOUT          => open,        -- 30-bit output: A port cascade output
         BCOUT          => open,        -- 18-bit output: B port cascade output
         CARRYCASCOUT   => open,        -- 1-bit output: Cascade carry output
         MULTSIGNOUT    => open,  -- 1-bit output: Multiplier sign cascade output
         PCOUT          => open,        -- 48-bit output: Cascade output
         -- Control: 1-bit (each) output: Control Inputs/Status Bits
         OVERFLOW       => dsp6_over_flow_s,  -- 1-bit output: Overflow in add/acc output
         PATTERNBDETECT => open,  -- 1-bit output: Pattern bar detect output
         PATTERNDETECT  => open,        -- 1-bit output: Pattern detect output
         UNDERFLOW      => dsp6_under_flow_s,  -- 1-bit output: Underflow in add/acc output
         -- Data: 4-bit (each) output: Data Ports
         CARRYOUT       => open,        -- 4-bit output: Carry output
         P              => dsp6_p_out_s,  -- 48-bit output: Primary data output
         -- Cascade: 30-bit (each) input: Cascade Ports
         ACIN           => (others => '0'),  -- 30-bit input: A cascade data input
         BCIN           => (others => '0'),  -- 18-bit input: B cascade input
         CARRYCASCIN    => '0',         -- 1-bit input: Cascade carry input
         MULTSIGNIN     => '0',         -- 1-bit input: Multiplier sign input
         PCIN           => (others => '0'),  -- 48-bit input: P cascade input
         -- Control: 4-bit (each) input: Control Inputs/Status Bits
         ALUMODE        => "0000",      -- 4-bit input: ALU control input
         CARRYINSEL     => (others => '0'),  -- 3-bit input: Carry select input
         CLK            => CLK,         -- 1-bit input: Clock input
         INMODE         => (others => '0'),  -- 5-bit input: INMODE control input
         OPMODE         => "000"&"11"&"11",  -- 7-bit input: Operation mode input(z&y&x)
         -- Data: 30-bit (each) input: Data Ports
         A              => dsp6_a_input_s,  -- 30-bit input: A data input
         B              => dsp6_b_input_s,  -- 18-bit input: B data input
         C              => X1Y1_shifted_s_16_bits_s,  -- 48-bit input: C data input
         CARRYIN        => '0',         -- 1-bit input: Carry input signal
         D              => (others => '0'),  -- 25-bit input: D data input
         -- Reset/Clock Enable: 1-bit (each) input: Reset/Clock Enable Inputs
         CEA1           => '0',  -- 1-bit input: Clock enable input for 1st stage AREG
         CEA2           => '0',  -- 1-bit input: Clock enable input for 2nd stage AREG
         CEAD           => '0',  -- 1-bit input: Clock enable input for ADREG
         CEALUMODE      => '0',  -- 1-bit input: Clock enable input for ALUMODE
         CEB1           => '0',  -- 1-bit input: Clock enable input for 1st stage BREG
         CEB2           => '0',  -- 1-bit input: Clock enable input for 2nd stage BREG
         CEC            => '1',  -- 1-bit input: Clock enable input for CREG
         CECARRYIN      => '0',  -- 1-bit input: Clock enable input for CARRYINREG
         CECTRL         => '1',  -- 1-bit input: Clock enable input for OPMODEREG and CARRYINSELREG
         CED            => '0',  -- 1-bit input: Clock enable input for DREG
         CEINMODE       => '1',  -- 1-bit input: Clock enable input for INMODEREG
         CEM            => '1',  -- 1-bit input: Clock enable input for MREG
         CEP            => '1',  -- 1-bit input: Clock enable input for PREG
         RSTA           => reset_s,     -- 1-bit input: Reset input for AREG
         RSTALLCARRYIN  => reset_s,  -- 1-bit input: Reset input for CARRYINREG
         RSTALUMODE     => reset_s,  -- 1-bit input: Reset input for ALUMODEREG
         RSTB           => '0',         -- 1-bit input: Reset input for BREG
         RSTC           => reset_s,         -- 1-bit input: Reset input for CREG
         RSTCTRL        => reset_s,  -- 1-bit input: Reset input for OPMODEREG and CARRYINSELREG
         RSTD           => '0',  -- 1-bit input: Reset input for DREG and ADREG
         RSTINMODE      => reset_s,  -- 1-bit input: Reset input for INMODEREG
         RSTM           => reset_s,     -- 1-bit input: Reset input for MREG
         RSTP           => reset_s      -- 1-bit input: Reset input for PREG
         );
-- END of dsp_inst_7 instantiation
end beh;
