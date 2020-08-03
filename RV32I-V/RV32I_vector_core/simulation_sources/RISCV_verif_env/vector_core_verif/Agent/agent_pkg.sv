`ifndef CONTRO_IF_AGENT_PKG
`define CONTRO_IF_AGENT_PKG

package vector_core_agent_pkg;
 
   import uvm_pkg::*;
   `include "uvm_macros.svh"

   //////////////////////////////////////////////////////////
   // include Agent components : driver,monitor,sequencer
   /////////////////////////////////////////////////////////
   import configurations_pkg::*;
   import v_alu_ops_pkg::*;
   import instruction_constants_pkg::*;
   
   //`include "v_alu_ops_pkg.sv"
   `include "store_data_seq_item.sv"
   `include "load_data_seq_item.sv"
   `include "seq_item.sv"
   `include "sequencer.sv"
   `include "driver.sv"
   `include "monitor.sv"
   `include "agent.sv"

endpackage
`include "../module_if.sv"
`endif



