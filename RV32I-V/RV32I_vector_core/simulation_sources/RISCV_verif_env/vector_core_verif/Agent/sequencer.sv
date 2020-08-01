`ifndef CONTROL_SEQUENCER_SV
 `define CONTROL_SEQUENCER_SV

class vector_core_sequencer extends uvm_sequencer#(instruction_mem_seq_item);

   `uvm_component_utils(vector_core_sequencer)

   function new(string name = "vector_core_sequencer", uvm_component parent = null);
      super.new(name,parent);
   endfunction

endclass : vector_core_sequencer

`endif

