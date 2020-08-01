`ifndef STORE_IF_MONITOR_SV
`define STORE_IF_MONITOR_SV
class store_if_monitor extends uvm_monitor;

    // control fileds
   bit checks_enable = 1;
   bit coverage_enable = 1;

    uvm_analysis_port #(store_if_seq_item) item_collected_port;

    `uvm_component_utils_begin(store_if_monitor)
	`uvm_field_int(checks_enable, UVM_DEFAULT)
	`uvm_field_int(coverage_enable, UVM_DEFAULT)
    `uvm_component_utils_end

    // The virtual interface used to drive and view HDL signals.
   virtual interface v_core_if vif;

   // current transaction
   store_if_seq_item curr_it;

   // coverage can go here
   // ...

   function new(string name = "store_if_monitor", uvm_component parent = null);
       super.new(name,parent);      
       item_collected_port = new("item_collected_port", this);
   endfunction

   function void connect_phase(uvm_phase phase);
       super.connect_phase(phase);
       if (!uvm_config_db#(virtual v_core_if)::get(this, "", "v_core_if", vif))
         `uvm_fatal("NOVIF",{"virtual interface must be set:",get_full_name(),".vif"})
   endfunction : connect_phase

   task main_phase(uvm_phase phase);
       // forever begin
       // curr_it = store_if_seq_item::type_id::create("curr_it", this);
       // ...
       // collect transactions
       // ...
       // item_collected_port.write(curr_it);
       // end
   endtask : main_phase

endclass : store_if_monitor

`endif
