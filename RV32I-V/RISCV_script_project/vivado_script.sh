

#packages
xvhdl  ../RV32I_vector_core/design_sources/data_path/packages/BRAM_package.vhd
xvhdl  ../RV32I_scalar_core/design_sources/packages/alu_ops_pkg.vhd
#HDL files
xvhdl  ../RV32I_vector_core/design_sources/data_path/custom_multiplier/multiplier32_bit.vhd
xvhdl  ../RV32I_vector_core/design_sources/data_path/ALU.vhd
xvhdl  ../RV32I_vector_core/design_sources/data_path/BRAM_18KB.vhd
xvhdl  ../RV32I_vector_core/design_sources/data_path/VRF_BRAM_addr_generator_v2.vhd
xvhdl  ../RV32I_vector_core/design_sources/data_path/vector_register_file.vhd
xvhdl  ../RV32I_vector_core/design_sources/data_path/vector_lane.vhd




#Verification files


xvlog -sv  ../RV32I_vector_core/simulation_sources/RISCV_verif_env/verif/Configurations/configurations_pkg.sv -L uvm
xvlog -sv  ../RV32I_vector_core/simulation_sources/RISCV_verif_env/verif/Agent/v_alu_ops_pkg.sv -L uvm
xvlog -sv  ../RV32I_vector_core/simulation_sources/RISCV_verif_env/verif/module_if.sv -L uvm
xvlog -sv  ../RV32I_vector_core/simulation_sources/RISCV_verif_env/verif/Agent/agent_pkg.sv -L uvm
xvlog -sv  ../RV32I_vector_core/simulation_sources/RISCV_verif_env/verif/Store_if_Agent/store_if_agent_pkg.sv -L uvm
xvlog -sv  ../RV32I_vector_core/simulation_sources/RISCV_verif_env/verif/Sequences/seq_pkg.sv -L uvm
xvlog -sv  ../RV32I_vector_core/simulation_sources/RISCV_verif_env/verif/test_pkg.sv -L uvm
xvlog -sv  ../RV32I_vector_core/simulation_sources/RISCV_verif_env/verif/top.sv -L uvm

xelab -L uvm -debug typical vector_lane_verif_top -s top_sim
xsim top_sim -testplusarg UVM_TESTNAME=test_simple -testplusarg UVM_VERBOSITY=UVM_LOW -gui
