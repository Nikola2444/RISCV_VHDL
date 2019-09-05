clear -all
set_elaborate_single_run_mode off


# packages
analyze -vhdl2k {../packages/alu_ops_pkg.vhd}
analyze -vhdl2k {../packages/datapath_signals_pkg.vhd}
analyze -vhdl2k {../packages/controlpath_signals_pkg.vhd}
analyze -vhdl2k {../packages/txt_util.vhd}

#control path files
analyze -vhdl2k {../control_path/alu_decoder.vhd}
analyze -vhdl2k {../control_path/ctrl_decoder.vhd}
analyze -vhdl2k {../control_path/forwarding_unit.vhd}
analyze -vhdl2k {../control_path/hazard_unit.vhd}
analyze -vhdl2k {../control_path/control_path.vhd}

# data_path files
analyze -vhdl2k -lib ieee {math_real.vhd}
analyze -vhdl2k -lib ieee {math_real_b.vhd}

analyze -vhdl2k {../data_path/ALU/ALU_simple.vhd}
analyze -vhdl2k {../data_path/immediate.vhd}
analyze -vhdl2k {../data_path/register_bank.vhd}
analyze -vhdl2k {../data_path/data_path.vhd}

#TOP
analyze -vhdl2k {../TOP_RISCV.vhd}

elaborate -vhdl -top {TOP_RISCV}
clock clk -factor 1 -phase 1
#reset -none

reset -expression {reset}
prove -bg -all
