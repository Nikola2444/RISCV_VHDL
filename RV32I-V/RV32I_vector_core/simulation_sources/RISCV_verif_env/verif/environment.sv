`ifndef CALC_ENV_SV
 `define CALC_ENV_SV

class control_if_env extends uvm_env;

    control_if_agent agent;
    vector_lane_config cfg;
   virtual interface v_lane_if vif;
   `uvm_component_utils (control_if_env)

   function new(string name = "control_if_env", uvm_component parent = null);
       super.new(name,parent);
   endfunction

   function void build_phase(uvm_phase phase);
       super.build_phase(phase);
       /************Geting from configuration database*******************/
       if (!uvm_config_db#(virtual v_lane_if)::get(this, "", "v_lane_if", vif))
         `uvm_fatal("NOVIF",{"virtual interface must be set:",get_full_name(),".vif"})
       
       if(!uvm_config_db#(vector_lane_config)::get(this, "", "vector_lane_config", cfg))
         `uvm_fatal("NOCONFIG",{"Config object must be set for: ",get_full_name(),".cfg"})
       /*****************************************************************/


       /************Setting to configuration database********************/
       uvm_config_db#(vector_lane_config)::set(this, "agent", "vector_lane_config", cfg);
       uvm_config_db#(virtual v_lane_if)::set(this, "agent", "v_lane_if", vif);
       /*****************************************************************/
       agent = control_if_agent::type_id::create("agent", this);
       
   endfunction : build_phase

endclass : control_if_env

`endif
