LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY c_l_adder_top IS
	GENERIC(
		CELL_WIDTH : NATURAL := 8;
		CELL_NUM : NATURAL := 8);
	PORT(
		x_in  :  IN   STD_LOGIC_VECTOR(((CELL_NUM*CELL_WIDTH)-1) DOWNTO 0);
		y_in  :  IN   STD_LOGIC_VECTOR(((CELL_NUM*CELL_WIDTH)-1) DOWNTO 0);
		c_in  :  IN   STD_LOGIC;
		sum   :  OUT  STD_LOGIC_VECTOR(((CELL_NUM*CELL_WIDTH)-1) DOWNTO 0);
		c_out :  OUT  STD_LOGIC);
END c_l_adder_top;

ARCHITECTURE behavioral OF c_l_adder_top IS

	SIGNAL    g,gg     :    STD_LOGIC_VECTOR(((CELL_NUM)-1) DOWNTO 0);
	SIGNAL    p,pp     :    STD_LOGIC_VECTOR(((CELL_NUM)-1) DOWNTO 0);
	SIGNAL    cc 		 :    STD_LOGIC_VECTOR(((CELL_NUM)-1) DOWNTO 0);

BEGIN

	
	cells: for i in 0 to (CELL_NUM -1) generate
	begin
		cell: entity work.c_l_adder_8mod(Behavioral)
		generic map (WIDTH => CELL_WIDTH)
		port map(
			x_in=>x_in(((i+1)*CELL_WIDTH)-1 downto i*CELL_WIDTH),
			y_in=>y_in(((i+1)*CELL_WIDTH)-1 downto i*CELL_WIDTH),
			c_in=>cc(i),
			sum=>sum(((i+1)*CELL_WIDTH)-1 downto i*CELL_WIDTH),
			g_out=>g(i),
			p_out=>p(i));
	end generate;


	PROCESS (c_in,cc,gg,g,pp,p)
	BEGIN
	    cc <= (others=>'0');
	    pp <= (others=>'0');
  	    gg <= (others=>'0');


		cc(0) <= c_in;
		gg(0) <= g(0);
		pp(0) <= p(0);

		inst: FOR i IN 1 TO (CELL_NUM-1) LOOP

			gg(i) <= g(i) or (p(i) and gg(i-1));
			pp(i) <= p(i) and pp(i-1);
			cc(i) <= gg(i-1) or (pp(i-1) and c_in);

		END LOOP;
	END PROCESS;

	c_out <= cc(CELL_NUM-1);

END behavioral;
