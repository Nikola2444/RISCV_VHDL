`ifndef CALC_SEQ_ITEM_SV
 `define CALC_SEQ_ITEM_SV


class control_if_seq_item extends uvm_sequence_item;
    
    rand logic [31 : 0] vector_instruction_i;  
    rand logic [1 : 0]  vmul_i;   
    rand logic [$clog2(VECTOR_LENGTH) : 0] vector_length_i;
    rand logic [DATA_WIDTH - 1 : 0] rs1_data_i;
    rand logic [4 : 0] alu_op_i;   
    `uvm_object_utils_begin(control_if_seq_item)
	`uvm_field_int(vmul_i, UVM_DEFAULT)
	`uvm_field_int(vector_length_i, UVM_DEFAULT)
	`uvm_field_int(vector_instruction_i, UVM_DEFAULT)
	`uvm_field_int(alu_op_i, UVM_DEFAULT)
	`uvm_field_int(rs1_data_i, UVM_DEFAULT)
    `uvm_object_utils_end


    //constraint rs1_data_i_constr {rs1_data_i < 5;}
    constraint vector_length_contr {vector_length_i == 9;}
    function new (string name = "control_if_seq_item");
	super.new(name);
    endfunction // new

endclass : control_if_seq_item

`endif
