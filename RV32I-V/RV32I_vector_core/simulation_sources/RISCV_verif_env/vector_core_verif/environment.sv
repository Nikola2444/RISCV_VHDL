`ifndef CALC_ENV_SV
 `define CALC_ENV_SV

class vector_core_env extends uvm_env;

    vector_core_agent control_agent;
    vector_core_scoreboard scoreboard;    
    vector_core_config cfg;
   virtual interface v_core_if vif;
   `uvm_component_utils (vector_core_env)

   function new(string name = "vector_core_env", uvm_component parent = null);
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
       uvm_config_db#(vector_core_config)::set(this, "*if_agent", "vector_core_config", cfg);
       uvm_config_db#(virtual v_core_if)::set(this, "*if_agent", "v_core_if", vif);
       /*****************************************************************/
       control_agent = vector_core_agent::type_id::create("vector_core_agent", this);
       scoreboard = vector_core_scoreboard::type_id::create("scoreboard", this);
              
   endfunction : build_phase

   function void connect_phase(uvm_phase phase);
       super.connect_phase(phase);
       control_agent.mon.instr_item_collected_port.connect(scoreboard.collected_imp_instr_item);
       control_agent.mon.store_data_collected_port.connect(scoreboard.collected_imp_store_data_item);
       control_agent.mon.load_data_collected_port.connect(scoreboard.collected_imp_load_data_item);
   endfunction : connect_phase
endclass : vector_core_env

`endif
