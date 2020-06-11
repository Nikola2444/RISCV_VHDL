`ifndef STORE_IF_AGENT_PKG
`define STORE_IF_AGENT_PKG

package store_if_agent_pkg;
 
   import uvm_pkg::*;
   `include "uvm_macros.svh"

   //////////////////////////////////////////////////////////
   // include Agent components : driver,monitor,sequencer
   /////////////////////////////////////////////////////////
   import configurations_pkg::*;
   import v_alu_ops_pkg::*;
   
   //`include "v_alu_ops_pkg.sv"
   `include "store_if_seq_item.sv"
   `include "store_if_sequencer.sv"
   `include "store_if_driver.sv"
   `include "store_if_monitor.sv"
   `include "store_if_agent.sv"

endpackage
`include "../module_if.sv"
`endif



