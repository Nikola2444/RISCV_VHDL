`uvm_analysis_imp_decl(_instr_item)
`uvm_analysis_imp_decl(_store_data_item)

class vector_core_scoreboard extends uvm_scoreboard;

    // control fileds
   bit checks_enable = 1;
   bit coverage_enable = 1;

    // This TLM port is used to connect the scoreboard to the monitor
    uvm_analysis_imp_instr_item#(vector_core_seq_item, vector_lane_scoreboard) instr_item_collected_imp;
    uvm_analysis_imp_store_data_item#(vector_core_seq_item, vector_lane_scoreboard) store_data_collected_imp;
    
   int num_of_tr;

    `uvm_component_utils_begin(vector_core_scoreboard)
	`uvm_field_int(checks_enable, UVM_DEFAULT)
	`uvm_field_int(coverage_enable, UVM_DEFAULT)
    `uvm_component_utils_end

    function new(string name = "vector_core_scoreboard", uvm_component parent = null);
	super.new(name,parent);
	instr_item_collected_imp = new("instr_item_collected_imp", this);
	store_data_collected_imp = new("store_data_collected_imp", this);
    endfunction : new

    function write_instr_item (vector_core_seq_item tr);
	vector_core_seq_item tr_clone;
	$cast(tr_clone, tr.clone());
	if(checks_enable) begin
            // do actual checking here
            // ...
            // ++num_of_tr;
	end
    endfunction : write_instr_item


    function write_store_data_item (store_data_seq_item tr);
	store_data_seq_item tr_clone;
	$cast(tr_clone, tr.clone());
	if(checks_enable) begin
            // do actual checking here
            // ...
            // ++num_of_tr;
	end
    endfunction : write_store_data_item

    function void report_phase(uvm_phase phase);
	`uvm_info(get_type_name(), $sformatf("Calc scoreboard examined: %0d transactions", num_of_tr), UVM_LOW);
    endfunction : report_phase

endclass : vector_core_scoreboard
