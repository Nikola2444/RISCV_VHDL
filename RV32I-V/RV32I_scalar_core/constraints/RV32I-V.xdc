create_clock -period 7.5 -name system_clk -waveform {0.00 5.00} [get_ports clk]
set_system_jitter 0.5
