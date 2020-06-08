create_clock -period 10.0 -name system_clk -waveform {0.00 5.0} [get_ports clk]
#set_property IOSTANDARD LVCMOS18 [get_ports -of_objects [get_iobanks -filter { BANK_TYPE !~  "BT_MGT" }]]
