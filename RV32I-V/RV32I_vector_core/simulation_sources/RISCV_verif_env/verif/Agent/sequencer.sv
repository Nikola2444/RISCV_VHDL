`ifndef CONTROL_SEQUENCER_SV
 `define CONTROL_SEQUENCER_SV

class control_if_sequencer extends uvm_sequencer#(control_if_seq_item);

   `uvm_component_utils(control_if_sequencer)

   function new(string name = "control_if_sequencer", uvm_component parent = null);
      super.new(name,parent);
   endfunction

endclass : control_if_sequencer

`endif

