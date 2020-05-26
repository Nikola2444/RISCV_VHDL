-- THIS IP realises 32 bit multiplier by using 7 DPS slices. When this
-- multiplier receives inputs it will give the result after 4 clock cycles.

-- Basic idea is to
-- to use the next equivalence:

--                     X*Y = 2^(2k)*X1*Y1 + 2^(2k)(X1Y0 + X0Y1) + X0Y0

-- Here X and Y are 32 bit values.X1, Y1, X0, Y0 should be 16 bit values where
-- X1 containts upper 16 bits of X, Y1 containts upper 16 bits of Y, X0
-- contains lower 16 bits of X nad Y0 contains lower 16 bits of Y.
-- K has value 16

-- To calculate this equation 7 DSP slices were used. Each DSP was used to calculate
-- one part of previous equation:

-- DSP1 calculated: X1*Y1.

-- DSP2 calculated: X0*Y0

-- DSP3 calculated: X0*Y0  + X1*Y1* 2^2k  

-- DSP4 calculated: X1*Y0

-- DSP5 calculated: X0*Y1

-- DSP6 calculated: X1*Y0 * 2^k + X0*Y1 * 2^k

-- DSP7 sums the results of DSP6 and DSP3



library ieee;
use ieee.std_logic_1164.all;
use work.custom_functions_pkg.all;

library UNISIM;
use UNISIM.vcomponents.all;

entity multiplier32_bit is
   generic (DATA_WIDTH : natural := 32);
   port (
      clk   : in  std_logic;
      reset : in  std_logic;
      a     : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
      b     : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
      c     : out std_logic_vector(DATA_WIDTH - 1 downto 0));
end entity;

-- <-----Cut code below this line and paste into the architecture body---->

-- DSP48E1: 48-bit Multi-Functional Arithmetic Block
--          Artix-7
-- Xilinx HDL Language Template, version 2019.2
architecture beh of multiplier32_bit is

   --FSM state signal

   type FSM_state_t is (clk0, clk1, clk2, clk3, clk4);
   signal FSM_state_reg, FSM_state_next : FSM_state_t;

   constant zero_13bit_c : std_logic_vector(12 downto 0) := "0000"&"0000"&"0000"&'0';
   constant zero_34bit_c : std_logic_vector(33 downto 0) := x"00000000"&"00";
   constant zero_17bit_c : std_logic_vector(16 downto 0) := x"0000"&"0";

   signal reset_s : std_logic;

   signal X1_s : std_logic_vector(29 downto 0);
   signal Y1_s : std_logic_vector(17 downto 0);

   signal X0_s : std_logic_vector(29 downto 0);
   signal Y0_s : std_logic_vector(17 downto 0);

   signal X1Y1_shifted_s : std_logic_vector(47 downto 0);

   signal X1Y0_shifted_s : std_logic_vector(47 downto 0);
   signal X0Y1_shifted_s : std_logic_vector(47 downto 0);

   signal X0Y1_plus_X1Y0_shifted_s : std_logic_vector(47 downto 0);

   signal dsp1_over_flow_s  : std_logic;
   signal dsp1_under_flow_s : std_logic;
   signal dsp1_a_input_s    : std_logic_vector(29 downto 0);
   signal dsp1_p_out        : std_logic_vector (47 downto 0);


   signal dsp2_over_flow_s  : std_logic;
   signal dsp2_under_flow_s : std_logic;
   signal dsp2_p_out        : std_logic_vector (47 downto 0);

   signal dsp3_over_flow_s  : std_logic;
   signal dsp3_under_flow_s : std_logic;
   signal dsp3_pcin_input_s : std_logic_vector(47 downto 0);
   signal dsp3_a_input_s    : std_logic_vector(29 downto 0);
   signal dsp3_b_input_s    : std_logic_vector(17 downto 0);
   signal dsp3_p_out        : std_logic_vector (47 downto 0);

   signal dsp4_over_flow_s  : std_logic;
   signal dsp4_under_flow_s : std_logic;
   signal dsp4_p_out        : std_logic_vector (47 downto 0);

   signal dsp5_over_flow_s  : std_logic;
   signal dsp5_under_flow_s : std_logic;
   signal dsp5_p_out        : std_logic_vector (47 downto 0);

   signal dsp6_over_flow_s  : std_logic;
   signal dsp6_under_flow_s : std_logic;
   signal dsp6_pcin_input_s : std_logic_vector(47 downto 0);
   signal dsp6_a_input_s    : std_logic_vector(29 downto 0);
   signal dsp6_b_input_s    : std_logic_vector(17 downto 0);
   signal dsp6_p_out        : std_logic_vector (47 downto 0);

   signal dsp7_over_flow_s  : std_logic;
   signal dsp7_under_flow_s : std_logic;
   signal dsp7_p_out        : std_logic_vector (47 downto 0);
   signal dsp7_a_input_s    : std_logic_vector(29 downto 0);
   signal dsp7_b_input_s    : std_logic_vector(17 downto 0);


begin

   reset_s <= not reset;


   X1_s    <= zero_13bit_c & "00"&a(31 downto 17);  -- uper 15 bits of a_input
   Y1_s    <= "000"&b(31 downto 17);                -- upper 15 bits of b input

   X0_s <= zero_13bit_c & a(16 downto 0);  -- down 17 bits of a_input
   Y0_s <= "0"&b(16 downto 0);             -- down 17 bits of b input

   c <= dsp7_p_out(31 downto 0);




   --Shifting the output of dsp1 and sending it to inputs a and b of DSP3
   X1Y1_shifted_s    <= dsp1_p_out(13 downto 0) & zero_34bit_c;
   dsp3_a_input_s    <= X1Y1_shifted_s (47 downto 18);
   dsp3_b_input_s    <= X1Y1_shifted_s (17 downto 0);
   dsp3_pcin_input_s <= dsp2_p_out;


   -- Separeting dps4_p_out into two parts, one 30 bits large, the other 18,
   -- and sending them to a and b inputs respectively. In DSP6 these two inputs
   -- will be concataneted (a&b) and summed with PCIN.
   dsp6_a_input_s    <= dsp4_p_out (47 downto 18);
   dsp6_b_input_s    <= dsp4_p_out (17 downto 0);
   dsp6_pcin_input_s <= dsp5_p_out;

   --Shifting the output of dsp6   and sending it to inputs a and b
   --of DSP7
   X0Y1_plus_X1Y0_shifted_s <= dsp6_p_out(30 downto 0) & zero_17bit_c;
   dsp7_a_input_s           <= X0Y1_plus_X1Y0_shifted_s (47 downto 18);
   dsp7_b_input_s           <= X0Y1_plus_X1Y0_shifted_s (17 downto 0);

   --<-----DSP1 computes  X1*Y1 ------->
   DSP48E1_inst : DSP48E1
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
         P              => dsp1_p_out,  -- 48-bit output: Primary data output
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
         PCOUT          => dsp2_p_out,  -- 48-bit output: Cascade output
         -- Control: 1-bit (each) output: Control Inputs/Status Bits
         OVERFLOW       => dsp2_over_flow_s,  -- 1-bit output: Overflow in add/acc output
         PATTERNBDETECT => open,  -- 1-bit output: Pattern bar detect output
         PATTERNDETECT  => open,        -- 1-bit output: Pattern detect output
         UNDERFLOW      => dsp2_under_flow_s,  -- 1-bit output: Underflow in add/acc output
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



   -- End of DSP48E1_inst_2 instantiation


--<-----DSP3 computes  X1*Y1 >> 34 + X0Y0---->


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
         PCOUT          => dsp3_p_out,  -- 48-bit output: Cascade output
         -- Control: 1-bit (each) output: Control Inputs/Status Bits
         OVERFLOW       => dsp3_over_flow_s,  -- 1-bit output: Overflow in add/acc output
         PATTERNBDETECT => open,  -- 1-bit output: Pattern bar detect output
         PATTERNDETECT  => open,        -- 1-bit output: Pattern detect output
         UNDERFLOW      => dsp3_under_flow_s,  -- 1-bit output: Underflow in add/acc output
         -- Data: 4-bit (each) output: Data Ports
         CARRYOUT       => open,        -- 4-bit output: Carry output
         P              => open,
         -- 48-bit output: Primary data output
         -- Cascade: 30-bit (each) input: Cascade Ports
         ACIN           => (others => '0'),  -- 30-bit input: A cascade data input
         BCIN           => (others => '0'),  -- 18-bit input: B cascade input
         CARRYCASCIN    => '0',         -- 1-bit input: Cascade carry input
         MULTSIGNIN     => '0',         -- 1-bit input: Multiplier sign input
         PCIN           => dsp2_p_out,  -- 48-bit input: P cascade input
         -- Control: 4-bit (each) input: Control Inputs/Status Bits
         ALUMODE        => "0000",      -- 4-bit input: ALU control input
         CARRYINSEL     => (others => '0'),  -- 3-bit input: Carry select input
         CLK            => CLK,         -- 1-bit input: Clock input
         INMODE         => (others => '0'),  -- 5-bit input: INMODE control input
         OPMODE         => "001"&"00"&"11",  -- 7-bit input: Operation mode input(z&y&x)
         -- Data: 30-bit (each) input: Data Ports
         A              => dsp3_a_input_s,  -- 30-bit input: A data input
         B              => dsp3_b_input_s,  -- 18-bit input: B data input
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



   -- End of DSP48E1_inst_3 instantiation


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
         PCOUT          => open,        -- 48-bit output: Cascade output
         -- Control: 1-bit (each) output: Control Inputs/Status Bits
         OVERFLOW       => dsp4_over_flow_s,  -- 1-bit output: Overflow in add/acc output
         PATTERNBDETECT => open,  -- 1-bit output: Pattern bar detect output
         PATTERNDETECT  => open,        -- 1-bit output: Pattern detect output
         UNDERFLOW      => dsp4_under_flow_s,  -- 1-bit output: Underflow in add/acc output
         -- Data: 4-bit (each) output: Data Ports
         CARRYOUT       => open,        -- 4-bit output: Carry output
         P              => dsp4_p_out,  -- 48-bit output: Primary data output
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


   --END of DSP_inst_4 instantiation

   --<-----DSP5 computes  X0*Y1 ------->
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
         PCOUT          => dsp5_p_out,  -- 48-bit output: Cascade output
         -- Control: 1-bit (each) output: Control Inputs/Status Bits
         OVERFLOW       => dsp5_over_flow_s,  -- 1-bit output: Overflow in add/acc output
         PATTERNBDETECT => open,  -- 1-bit output: Pattern bar detect output
         PATTERNDETECT  => open,        -- 1-bit output: Pattern detect output
         UNDERFLOW      => dsp5_under_flow_s,  -- 1-bit output: Underflow in add/acc output
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
         OVERFLOW       => dsp6_over_flow_s,  -- 1-bit output: Overflow in add/acc output
         PATTERNBDETECT => open,  -- 1-bit output: Pattern bar detect output
         PATTERNDETECT  => open,        -- 1-bit output: Pattern detect output
         UNDERFLOW      => dsp6_under_flow_s,  -- 1-bit output: Underflow in add/acc output
         -- Data: 4-bit (each) output: Data Ports
         CARRYOUT       => open,        -- 4-bit output: Carry output
         P              => dsp6_p_out,  -- 48-bit output: Primary data output
         -- Cascade: 30-bit (each) input: Cascade Ports
         ACIN           => (others => '0'),  -- 30-bit input: A cascade data input
         BCIN           => (others => '0'),  -- 18-bit input: B cascade input
         CARRYCASCIN    => '0',         -- 1-bit input: Cascade carry input
         MULTSIGNIN     => '0',         -- 1-bit input: Multiplier sign input
         PCIN           => dsp6_pcin_input_s,  -- 48-bit input: P cascade input
         -- Control: 4-bit (each) input: Control Inputs/Status Bits
         ALUMODE        => "0000",      -- 4-bit input: ALU control input
         CARRYINSEL     => (others => '0'),  -- 3-bit input: Carry select input
         CLK            => CLK,         -- 1-bit input: Clock input
         INMODE         => (others => '0'),  -- 5-bit input: INMODE control input
         OPMODE         => "001"&"00"&"11",  -- 7-bit input: Operation mode input(z&y&x)
         -- Data: 30-bit (each) input: Data Ports
         A              => dsp6_a_input_s,  -- 30-bit input: A data input
         B              => dsp6_b_input_s,  -- 18-bit input: B data input
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

   -- END of dsp_inst6 instantiation



   DSP48E1_inst_7 : DSP48E1
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
         OVERFLOW       => dsp7_over_flow_s,  -- 1-bit output: Overflow in add/acc output
         PATTERNBDETECT => open,  -- 1-bit output: Pattern bar detect output
         PATTERNDETECT  => open,        -- 1-bit output: Pattern detect output
         UNDERFLOW      => dsp7_under_flow_s,  -- 1-bit output: Underflow in add/acc output
         -- Data: 4-bit (each) output: Data Ports
         CARRYOUT       => open,        -- 4-bit output: Carry output
         P              => dsp7_p_out,  -- 48-bit output: Primary data output
         -- Cascade: 30-bit (each) input: Cascade Ports
         ACIN           => (others => '0'),  -- 30-bit input: A cascade data input
         BCIN           => (others => '0'),  -- 18-bit input: B cascade input
         CARRYCASCIN    => '0',         -- 1-bit input: Cascade carry input
         MULTSIGNIN     => '0',         -- 1-bit input: Multiplier sign input
         PCIN           => dsp3_p_out,  -- 48-bit input: P cascade input
         -- Control: 4-bit (each) input: Control Inputs/Status Bits
         ALUMODE        => "0000",      -- 4-bit input: ALU control input
         CARRYINSEL     => (others => '0'),  -- 3-bit input: Carry select input
         CLK            => CLK,         -- 1-bit input: Clock input
         INMODE         => (others => '0'),  -- 5-bit input: INMODE control input
         OPMODE         => "001"&"00"&"11",  -- 7-bit input: Operation mode input(z&y&x)
         -- Data: 30-bit (each) input: Data Ports
         A              => dsp7_a_input_s,  -- 30-bit input: A data input
         B              => dsp7_b_input_s,  -- 18-bit input: B data input
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

-- END of dsp_inst7 instantiation
end beh;
