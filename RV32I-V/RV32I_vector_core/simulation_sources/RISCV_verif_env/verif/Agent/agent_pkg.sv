`ifndef AGENT_PKG
`define AGENT_PKG

package agent_pkg;
 
   import uvm_pkg::*;
   `include "uvm_macros.svh"

   //////////////////////////////////////////////////////////
   // include Agent components : driver,monitor,sequencer
   /////////////////////////////////////////////////////////
   import configurations_pkg::*;
   import v_alu_ops_pkg::*;
   
   //`include "v_alu_ops_pkg.sv"
   `include "seq_item.sv"
   `include "sequencer.sv"
   `include "driver.sv"
   `include "monitor.sv"
   `include "agent.sv"

endpackage
`include "../module_if.sv"
`endif



