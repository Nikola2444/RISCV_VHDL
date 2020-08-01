`ifndef STORE_IF_DRIVER_SV
 `define STORE_IF_DRIVER_SV
class store_if_driver extends uvm_driver#(store_if_seq_item);

    `uvm_component_utils(store_if_driver)
   
   virtual interface v_core_if vif;

   typedef enum {store_fifo_empty, store_fifo_not_empty} driving_stages;
   driving_stages store_if_dr_stages = store_fifo_empty;

   
   const logic [6 : 0] arith_opcode = 7'b1010111;
   const logic [6 : 0] store_opcode = 7'b0100111;

   const logic [5 : 0] v_add_funct6 = 6'b000000;
   const logic [5 : 0] v_sub_funct6 = 6'b000010;
   const logic [5 : 0] v_and_funct6 = 6'b001001;
   const logic [5 : 0] v_or_funct6 = 6'b001010;
   const logic [5 : 0] v_xor_funct6 = 6'b001011;
   

   const logic [1 : 0] vrf_read_write = 2'b00;
   const logic [1 : 0] vrf_no_access = 2'b11;
   
   
   function new(string name = "store_if_driver", uvm_component parent = null);
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
       vif.vrf_type_of_access_i = vrf_no_access;      
       forever begin
           @(posedge(vif.clk));
	   #1ns;		       			   
	   if (vif.reset) begin
	       if (!vif.store_fifo_empty_o) begin
		   vif.store_fifo_re_i = 1'b1;		   
	       end
	       else vif.store_fifo_re_i = 1'b0;		   
	   end // if (vif.reset)
       end
   endtask : main_phase


   /*This function generates vector lane control signals. It has two argumets:
    
    vif - inside it is the virtual interface of vector lane
    vector_instruction_i - is the instruction the lane needs to receive
    
    */
   task generate_control_signals(virtual v_core_if vif, logic[31 : 0] vector_instruction_i);
      logic [6 : 0] opcode = req.vector_instruction_i [6 : 0];
      logic [5 : 0] funct6 = req.vector_instruction_i[31 : 26];
       
       
       case (opcode)
	   arith_opcode: begin
	       vif.vrf_type_of_access_i = vrf_read_write;
	       vif.vs1_addr_src_i = 0;	       
	       case (funct6)
		   v_add_funct6: begin
		       $display("sending add_op");		       
		       vif.alu_op_i = add_op;
		   end
		   v_sub_funct6: begin
		       vif.alu_op_i = sub_op;
		   end
		   v_and_funct6: begin
		       vif.alu_op_i = and_op;
		   end
		   v_or_funct6: begin
		       vif.alu_op_i = or_op;
		   end
		   v_xor_funct6: begin
		       vif.alu_op_i = xor_op;
		   end		   
	       endcase; // case funct6	       
	   end // case: arith_opcode
	   store_opcode: begin
	       vif.vs1_addr_src_i = 1;
	       vif.vrf_type_of_access_i = 2'b10; // read from VRD
	       vif.alu_op_i = add_op;
	       `uvm_info(get_type_name(),
			 $sformatf("Seting fifo_we_to 1"),
			 UVM_LOW)
	       vif.store_fifo_we_i <= #100 1'b1; // this way store fifo will be high after one clock cycle
	   end
       endcase; // case req.vector_instruction_i[31              	          
   endtask: generate_control_signals

endclass : store_if_driver

`endif

