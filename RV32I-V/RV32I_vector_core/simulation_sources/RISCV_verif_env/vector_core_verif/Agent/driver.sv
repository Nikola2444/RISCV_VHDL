`ifndef CALC_DRIVER_SV
 `define CALC_DRIVER_SV
class vector_core_driver extends uvm_driver#(vector_core_seq_item);
    
    `uvm_component_utils(vector_core_driver)
    
   virtual interface v_core_if vif;

   typedef enum {get_instruction, send_instruction} driving_stages;
   driving_stages v_core_dr_stages = get_instruction;
   
   const logic [1 : 0] vrf_read_write = 2'b00;
   const logic [1 : 0] vrf_no_access = 2'b11;
   int 		       clk_counter;
   
   
   function new(string name = "vector_core_driver", uvm_component parent = null);
       super.new(name,parent);       
   endfunction

   function void build_phase(uvm_phase phase);
       super.build_phase(phase);
       if (!uvm_config_db#(virtual v_core_if)::get(this, "", "v_core_if", vif))
         `uvm_fatal("NOVIF",{"virtual interface must be set:",get_full_name(),".vif"})
   endfunction: build_phase
   function void connect_phase(uvm_phase phase);
       super.connect_phase(phase);

   endfunction : connect_phase

   
   task main_phase(uvm_phase phase);       
       forever begin
	   if (vif.reset) begin	       	       
	       /*State machine that send instructions to vector core if there is no get_instruction*/
	       #1;	       
	       while(vif.vector_stall_s)begin		 
		 @(posedge(vif.clk));	    
		   #1; 
	       end
	       seq_item_port.get_next_item(req);
	       `uvm_info(get_type_name(),
			 $sformatf("Driver sending...\n%s", req.sprint()),
			 UVM_HIGH)		      		      
	       seq_item_port.item_done();
	       
	       @(posedge(vif.clk));
	       #1
	       vif.rs1_i = req.rs1_i;
	       vif.vector_instruction_i <= req.vector_instruction_i;
	       
	       vif.rs2_i = req.rs2_i;
	       
	       
	   end // if (vif.reset)
	   else
	     @(posedge(vif.clk));
       end // forever begin
       
   endtask : main_phase   
endclass : vector_core_driver



`endif

   
