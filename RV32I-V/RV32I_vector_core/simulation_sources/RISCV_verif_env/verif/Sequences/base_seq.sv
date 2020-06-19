`ifndef CALC_BASE_SEQ_SV
 `define CALC_BASE_SEQ_SV

class control_if_base_seq extends uvm_sequence#(control_if_seq_item);

   `uvm_object_utils(control_if_base_seq)
   `uvm_declare_p_sequencer(control_if_sequencer)

   function new(string name = "control_if_base_seq");
      super.new(name);
   endfunction

   // objections are raised in pre_body
   virtual task pre_body();
      uvm_phase phase = get_starting_phase();
      if (phase != null)
        phase.raise_objection(this, {"Running sequence '", get_full_name(), "'"});
   endtask : pre_body

   // objections are dropped in post_body
   virtual task post_body();
       uvm_phase phase = get_starting_phase();
      if (phase != null)
        phase.drop_objection(this, {"Completed sequence '", get_full_name(), "'"});
   endtask : post_body

endclass : control_if_base_seq

`endif
