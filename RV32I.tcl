#process for getting script file directory
variable dispScriptFile [file normalize [info script]]
proc getScriptDirectory {} {
    variable dispScriptFile
    set scriptFolder [file dirname $dispScriptFile]
    return $scriptFolder
}

#change working directory to script file directory
cd [getScriptDirectory]
#set project directory
set projectDir .\/RV32I/RISCV_project

file mkdir $projectDir

# MAKE A PROJECT
create_project RISCV_project $projectDir -part xc7z020clg484-1
set_property board_part digilentinc.com:zedboard:part0:1.0 [current_project]


# Import sources

add_files -norecurse ./RV32I/design_sources/TOP_RISCV.vhd

add_files -norecurse ./RV32I/design_sources/data_path/ALU.vhd
add_files -norecurse ./RV32I/design_sources/data_path/immediate.vhd
add_files -norecurse ./RV32I/design_sources/data_path/register_bank.vhd
add_files -norecurse ./RV32I/design_sources/data_path/data_path.vhd

add_files -norecurse ./RV32I/design_sources/packages/alu_ops_pkg.vhd 

add_files -norecurse ./RV32I/design_sources/control_path/hazard_unit.vhd 
add_files -norecurse ./RV32I/design_sources/control_path/forwarding_unit.vhd 
add_files -norecurse ./RV32I/design_sources/control_path/control_path.vhd
add_files -norecurse ./RV32I/design_sources/control_path/ctrl_decoder.vhd
add_files -norecurse ./RV32I/design_sources/control_path/alu_decoder.vhd

update_compile_order -fileset sources_1


# Import design constraints

add_files -fileset constrs_1 -norecurse ./RV32I/constraints/RV32I.xdc

# Import simulation sources

add_files -fileset sim_1 -norecurse ./RV32I/simulation_sources/BRAM.vhd
add_files -fileset sim_1 -norecurse ./RV32I/simulation_sources/TOP_RISCV_tb.vhd 
add_files -fileset sim_1 -norecurse ./RV32I/simulation_sources/packages/txt_util.vhd

update_compile_order -fileset sim_1
