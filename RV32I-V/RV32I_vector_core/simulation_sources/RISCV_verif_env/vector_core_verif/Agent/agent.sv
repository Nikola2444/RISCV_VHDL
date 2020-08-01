class vector_core_agent extends uvm_agent;

    // components
    vector_core_driver drv;
    vector_core_sequencer seqr;
    vector_core_monitor mon;
   virtual interface v_core_if vif;
   // configuration
   vector_core_config cfg;
   int 	   value;   
   `uvm_component_utils_begin (vector_core_agent)
       `uvm_field_object(cfg, UVM_DEFAULT)
   `uvm_component_utils_end

   function new(string name = "vector_core_agent", uvm_component parent = null);
       super.new(name,parent);
   endfunction

   function void build_phase(uvm_phase phase);
       super.build_phase(phase);
       /************Geting from configuration database*******************/
       if (!uvm_config_db#(virtual v_core_if)::get(this, "", "v_core_if", vif))
         `uvm_fatal("NOVIF",{"virtual interface must be set:",get_full_name(),".vif"})
       
       if(!uvm_config_db#(vector_core_config)::get(this, "", "vector_core_config", cfg))
         `uvm_fatal("NOCONFIG",{"Config object must be set for: ",get_full_name(),".cfg"})
       /*****************************************************************/
       
       /************Setting to configuration database********************/
       uvm_config_db#(virtual v_core_if)::set(this, "*", "v_core_if", vif);
       /*****************************************************************/
       
       mon = vector_core_monitor::type_id::create("mon", this);
       if(cfg.is_active == UVM_ACTIVE) begin
           drv = vector_core_driver::type_id::create("drv", this);
           seqr = vector_core_sequencer::type_id::create("seqr", this);
       end
   endfunction : build_phase

   function void connect_phase(uvm_phase phase);
       super.connect_phase(phase);
       if(cfg.is_active == UVM_ACTIVE) begin
           drv.seq_item_port.connect(seqr.seq_item_export);
       end
   endfunction : connect_phase

endclass : vector_core_agent
