create_clock -period 15.00 -name system_clk -waveform {0.00 5.00} [get_ports clk]
set_system_jitter 0.5
