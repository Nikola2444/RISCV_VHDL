#----------------------------------------
# JasperGold Version Info
# tool      : JasperGold 2018.06
# platform  : Linux 3.10.0-693.el7.x86_64
# version   : 2018.06p002 64 bits
# build date: 2018.08.27 18:04:53 PDT
#----------------------------------------
# started Tue Sep 10 16:12:01 CEST 2019
# hostname  : ws0.lab317.kel.net
# pid       : 4320
# arguments : '-label' 'session_0' '-console' 'ws0.lab317.kel.net:36221' '-style' 'windows' '-data' 'AQAAADx/////AAAAAAAAA3oBAAAAEABMAE0AUgBFAE0ATwBWAEU=' '-proj' '/nethome/nikola.kovacevic/Desktop/RISCV_VHDL/RV32IMA/formal_verification/jgproject/sessionLogs/session_0' '-init' '-hidden' '/nethome/nikola.kovacevic/Desktop/RISCV_VHDL/RV32IMA/formal_verification/jgproject/.tmp/.initCmds.tcl' 'do.tcl'
clear -all
set_elaborate_single_run_mode off



# Checkers
analyze -sv09 {checkers/branch_checker.sv}
analyze -sv09 {checkers/pc_checker.sv}
analyze -sv09 {checkers/forwarding_unit_checker.sv}
analyze -sv09 {checkers/stall_checker.sv}
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
analyze -vhdl2k -lib ieee {ieee_math_lib_folder/math_real.vhd}
analyze -vhdl2k -lib ieee {ieee_math_lib_folder/math_real_b.vhd}

analyze -vhdl2k {../data_path/ALU/ALU_simple.vhd}
analyze -vhdl2k {../data_path/immediate.vhd}
analyze -vhdl2k {../data_path/register_bank.vhd}
analyze -vhdl2k {../data_path/data_path.vhd}
include {do.tcl}
include {do.tcl}
include {do.tcl}
include {do.tcl}
include {do.tcl}
include {do.tcl}
include {do.tcl}
visualize -violation -property <embedded>::formal_top_RISCV.TOP_RISCV_1.data_path_1.forward_check_inst.alu_forward_assert -new_window
include {do.tcl}
visualize -violation -property <embedded>::formal_top_RISCV.TOP_RISCV_1.data_path_1.forward_check_inst.alu_forward_assert -new_window
include {do.tcl}
include {do.tcl}
include {do.tcl}
include {do.tcl}
visualize -violation -property <embedded>::formal_top_RISCV.TOP_RISCV_1.data_path_1.forward_check_inst.alu_forward_assert -new_window
include {do.tcl}
include {do.tcl}
visualize -violation -property <embedded>::formal_top_RISCV.TOP_RISCV_1.data_path_1.forward_check_inst.alu_forward_assert -new_window
include {do.tcl}
visualize -violation -property <embedded>::formal_top_RISCV.TOP_RISCV_1.data_path_1.forward_check_inst.alu_forward_assert -new_window
include {do.tcl}
visualize -violation -property <embedded>::formal_top_RISCV.TOP_RISCV_1.data_path_1.forward_check_inst.alu_forward_assert -new_window
include {do.tcl}
visualize -violation -property <embedded>::formal_top_RISCV.TOP_RISCV_1.data_path_1.forward_check_inst.alu_forward_assert -new_window
include {do.tcl}
include {do.tcl}
include {do.tcl}
include {do.tcl}
visualize -violation -property <embedded>::formal_top_RISCV.TOP_RISCV_1.data_path_1.forward_check_inst.alu_forward_assert -new_window
include {do.tcl}
visualize -violation -property <embedded>::formal_top_RISCV.TOP_RISCV_1.data_path_1.forward_check_inst.alu_forward_assert -new_window
include {do.tcl}
include {do.tcl}
include {do.tcl}
