`ifndef LOAD_DATA_SEQ_ITEM_SV
 `define LOAD_DATA_SEQ_ITEM_SV


class load_data_seq_item extends uvm_sequence_item;

    rand logic [31 : 0] data_from_mem_s;
    
    
    `uvm_object_utils_begin( load_data_seq_item)
	`uvm_field_int(data_from_mem_s, UVM_DEFAULT)
	`uvm_field_int(mem_re_s, UVM_DEFAULT)
	`uvm_field_int(load_address_s, UVM_DEFAULT)
    `uvm_object_utils_end

    function new (string name = " load_data_seq_item");
	super.new(name);
    endfunction // new

endclass :  load_data_seq_item

`endif
