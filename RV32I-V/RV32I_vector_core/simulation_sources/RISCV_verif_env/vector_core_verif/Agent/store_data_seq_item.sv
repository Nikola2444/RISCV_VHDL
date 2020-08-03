`ifndef STORE_DATA_SEQ_ITEM_SV
 `define STORE_DATA_SEQ_ITEM_SV


class store_data_seq_item extends uvm_sequence_item;

    rand logic [31 : 0] data_to_mem_s;
    
    
    `uvm_object_utils_begin( store_data_seq_item)
	`uvm_field_int(data_to_mem_s, UVM_DEFAULT)	
    `uvm_object_utils_end

    function new (string name = " store_data_seq_item");
	super.new(name);
    endfunction // new

endclass :  store_data_seq_item

`endif
