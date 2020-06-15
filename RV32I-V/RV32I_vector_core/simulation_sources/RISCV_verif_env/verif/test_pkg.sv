`ifndef CALC_TEST_PKG_SV
 `define CALC_TEST_PKG_SV

package test_pkg;

   import uvm_pkg::*;      // import the UVM library   
 `include "uvm_macros.svh" // Include the UVM macros

   import configurations_pkg::*;
   import control_if_agent_pkg::*;
   import store_if_agent_pkg::*;
   import seq_pkg::*;
   
`include "environment.sv"   
`include "test_base.sv"
`include "test_simple.sv"
`include "test_simple_2.sv"


endpackage : test_pkg

`include "module_if.sv"

`endif

