`ifndef CALC_SEQ_ITEM_SV
 `define CALC_SEQ_ITEM_SV


class vector_core_seq_item extends uvm_sequence_item;
    
   rand logic [31 : 0] vector_instruction_i;
   rand logic [31 : 0] rs1_i;  
   rand logic [31 : 0] rs2_i;    
   
    `uvm_object_utils_begin(vector_core_seq_item)	
	`uvm_field_int(vector_instruction_i, UVM_DEFAULT)
	`uvm_field_int(rs2_i, UVM_DEFAULT)
	`uvm_field_int(rs1_i, UVM_DEFAULT)
    `uvm_object_utils_end


    //constraint rs1_data_i_constr {rs1_data_i < 5;}
    constraint rs1_rs2_constr {rs2_i < 50; rs1_i <  50}
    function new (string name = "vector_core_seq_item");
	super.new(name);
    endfunction // new

endclass : vector_core_seq_item

`endif
