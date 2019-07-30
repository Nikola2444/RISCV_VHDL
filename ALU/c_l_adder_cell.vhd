LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY c_l_adder_cell IS
	GENERIC(
		WIDTH : NATURAL :=8);
	PORT(
		x_in  :  IN   STD_LOGIC_VECTOR((WIDTH-1) DOWNTO 0);
		y_in  :  IN   STD_LOGIC_VECTOR((WIDTH-1) DOWNTO 0);
		c_in  :  IN   STD_LOGIC;
		sum   :  OUT  STD_LOGIC_VECTOR((WIDTH-1) DOWNTO 0);
		g_out :  OUT  STD_LOGIC;
		p_out :  OUT  STD_LOGIC);
END c_l_adder_cell;

ARCHITECTURE behavioral OF c_l_adder_cell IS

	SIGNAL    g,gg     :    STD_LOGIC_VECTOR((WIDTH-1) DOWNTO 0);
	SIGNAL    p,pp     :    STD_LOGIC_VECTOR((WIDTH-1) DOWNTO 0);
	SIGNAL    cc 		 :    STD_LOGIC_VECTOR((WIDTH-1) DOWNTO 0);

BEGIN
	g <= x_in AND y_in;
	p <= x_in OR y_in;

	PROCESS (c_in,cc,p,g,pp,gg)
	BEGIN
	    cc <= (others=>'0');
	    pp <= (others=>'0');
  	    gg <= (others=>'0');
		
		cc(0) <= c_in;
		gg(0) <= g(0);
		pp(0) <= p(0);

		inst: FOR i IN 1 TO (WIDTH-1) LOOP

			gg(i) <= g(i) or (p(i) and gg(i-1));
			pp(i) <= p(i) and pp(i-1);
			cc(i) <= gg(i-1) or (pp(i-1) and c_in);

		END LOOP;
	END PROCESS;

	g_out <= gg(WIDTH-1);
	p_out <= pp(WIDTH-1);
	sum <= x_in XOR y_in XOR cc;

END behavioral;
