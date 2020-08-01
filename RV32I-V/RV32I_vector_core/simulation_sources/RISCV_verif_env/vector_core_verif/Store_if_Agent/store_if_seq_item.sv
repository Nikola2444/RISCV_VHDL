`ifndef STORE_IF_SEQ_ITEM_SV
 `define STORE_IF_SEQ_ITEM_SV


class store_if_seq_item extends uvm_sequence_item;

    rand logic [31 : 0] vector_instruction_i;  
    rand logic [1 : 0]  vmul_i;   
    rand logic [$clog2(VECTOR_LENGTH/DATA_WIDTH) : 0] vector_length_i ; 
    
   `uvm_object_utils_begin(store_if_seq_item)
       `uvm_field_int(vmul_i, UVM_DEFAULT)
       `uvm_field_int(vector_length_i, UVM_DEFAULT)
      `uvm_field_int(vector_instruction_i, UVM_DEFAULT)
   `uvm_object_utils_end

   function new (string name = "store_if_seq_item");
      super.new(name);
   endfunction // new

endclass : store_if_seq_item

`endif
