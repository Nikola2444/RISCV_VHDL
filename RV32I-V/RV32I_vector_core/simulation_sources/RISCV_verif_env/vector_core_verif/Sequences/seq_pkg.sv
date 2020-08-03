`ifndef CALC_SEQ_PKG_SV
 `define CALC_SEQ_PKG_SV
package seq_pkg;
   import uvm_pkg::*;      // import the UVM library
 `include "uvm_macros.svh" // Include the UVM macros
   import vector_core_agent_pkg::vector_core_seq_item;
   import vector_core_agent_pkg::vector_core_sequencer;
 `include "base_seq.sv"
 `include "simple_seq.sv"
endpackage 
`endif
