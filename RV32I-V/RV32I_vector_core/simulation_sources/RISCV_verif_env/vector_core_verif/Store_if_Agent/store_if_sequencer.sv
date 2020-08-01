`ifndef STORE_IF_SEQUENCER_SV
 `define STORE_IF_SEQUENCER_SV

class store_if_sequencer extends uvm_sequencer#(store_if_seq_item);

   `uvm_component_utils(store_if_sequencer)

   function new(string name = "store_if_sequencer", uvm_component parent = null);
      super.new(name,parent);
   endfunction

endclass : store_if_sequencer

`endif

