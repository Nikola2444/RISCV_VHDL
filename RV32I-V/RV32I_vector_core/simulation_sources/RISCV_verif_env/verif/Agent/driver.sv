`ifndef CALC_DRIVER_SV
 `define CALC_DRIVER_SV
class control_if_driver extends uvm_driver#(control_if_seq_item);

    `uvm_component_utils(control_if_driver)
    
   virtual interface v_lane_if vif;

   typedef enum {wait_for_ready, send_control_signals} driving_stages;
   driving_stages v_lane_dr_stages = wait_for_ready;


   const logic [6 : 0] arith_opcode = 7'b1010111;
   const logic [6 : 0] store_opcode = 7'b0100111;
   
   const logic [5 : 0] v_add_funct6 = 6'b000000; //implemented
   const logic [5 : 0] v_sub_funct6 = 6'b000010;    //implemented
   
   const logic [5 : 0] v_and_funct6 = 6'b001001; //implemented
   const logic [5 : 0] v_or_funct6 = 6'b001010; //implemented
   const logic [5 : 0] v_xor_funct6 = 6'b001011; //implementeda
   
   const logic [5 : 0] v_merge_funct6 = 6'b010111; //implemented
   
   const logic [5 : 0] v_mul_funct6 = 6'b100101; // signed mul //implemented
   const logic [5 : 0] v_mulhsu_funct6 = 6'b100110;// signed (VS2) unsigned mul //implemented
   const logic [5 : 0] v_mulhs_funct6 = 6'b100111; //signed higher mul   //implemented
   const logic [5 : 0] v_mulhu_funct6 = 6'b100111; // unsigned higher mul //implemented
   
   const logic [5 : 0] v_shll_funct6 = 6'b100101; // shift left logic //implemented
   const logic [5 : 0] v_shrl_funct6 = 6'b101000; // shift right logic //implemented
   const logic [5 : 0] v_shra_funct6 = 6'b101001; // shift right arith //implemented

   const logic [5 : 0] v_vmseq_funct6 = 6'b011000 ; // set if equal //implemented
   const logic [5 : 0] v_vmsne_funct6 = 6'b011001 ; // set if not equal //implemented
   const logic [5 : 0] v_vmsltu_funct6 = 6'b011010 ; // set if less than unsigned  //implemented
   const logic [5 : 0] v_vmslt_funct6 = 6'b011011 ; // set if less than signed //implemented
   const logic [5 : 0] v_vmsleu_funct6 = 6'b011100 ; // set if less than or equal unsigned //implemented
   const logic [5 : 0] v_vmsle_funct6 = 6'b011101 ; // set if less than or equal signed //implemented
   const logic [5 : 0] v_vmsgtu_funct6 = 6'b011110 ; // set if greater than or equal unsigned //implemented
   const logic [5 : 0] v_vmsgt_funct6 = 6'b011111 ; // set if greater than or equal signed //implemented

   const logic [5 : 0] v_vminu_funct6 = 6'b000100 ; // unsigned min //implemented
   const logic [5 : 0] v_vmin_funct6 = 6'b000101 ; // signed min   //implemented
   
   const logic [1 : 0] vrf_read_write = 2'b00;
   const logic [1 : 0] vrf_no_access = 2'b11;
   int 		       clk_counter;
   
   
   function new(string name = "control_if_driver", uvm_component parent = null);
       super.new(name,parent);       
   endfunction

   function void build_phase(uvm_phase phase);
       super.build_phase(phase);
       if (!uvm_config_db#(virtual v_lane_if)::get(this, "", "v_lane_if", vif))
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
	       /*Generate read enable for store fifo if it is not empty*/
	       if (!vif.store_fifo_empty_o)
		 vif.store_fifo_re_i = 1'b1;
	       else
		 vif.store_fifo_re_i = 1'b0;
	       
	       /*State machine that genereates certain control signals depending
		on received instruction.*/
	       case (v_lane_dr_stages)
		   wait_for_ready: begin		       		       		       
		       if (vif.ready_o) begin			   			   			   
			   v_lane_dr_stages = send_control_signals ;
		       end			 
		   end
		   send_control_signals: begin
		       //receiving item
		       seq_item_port.get_next_item(req);
		       `uvm_info(get_type_name(),
				 $sformatf("Driver sending...\n%s", req.sprint()),
				 UVM_HIGH)		      
		       
		       vif.vector_instruction_i = req.vector_instruction_i;
		       vif.vector_length_i = req.vector_length_i;
		       vif.vmul_i = req.vmul_i;
		       vif.rs1_data_i = req.rs1_data_i;
		       generate_control_signals (vif, req.vector_instruction_i);

		       // Sending item
		       seq_item_port.item_done();
		       v_lane_dr_stages = wait_for_ready;		       
		   end
	       endcase; // case (v_lane_dr_stages)
	   end // if (vif.reset)
       end
   endtask : main_phase


   /*This function generates vector lane control signals. It has two argumets:
    
    vif - inside it, is the virtual interface of vector lane
    vector_instruction_i - is the instruction the lane needs to receive    
    */
   task generate_control_signals(virtual v_lane_if vif, logic[31 : 0] vector_instruction_i);
       // Funct3 constants
      const logic [2 : 0] vv_funct3 = 3'b000;
      const logic [2 : 0] vs_funct3 = 3'b100;
      const logic [2 : 0] vi_funct3 = 3'b011;
       
      logic [6 : 0] 	  opcode = req.vector_instruction_i [6 : 0];
      logic [5 : 0] 	  funct6 = req.vector_instruction_i[31 : 26];
      logic [2 : 0] 	  funct3 = req.vector_instruction_i[14 : 12];
      logic 		  vm = vector_instruction_i[25];	


       
       case (opcode)
	   arith_opcode: begin
	       vif.vrf_type_of_access_i = vrf_read_write;
	       vif.vs1_addr_src_i = 0;
	       vif.type_of_masking_i = 1'b0;
	       vif.mem_to_vrf_i = 2'b00;
	       vif.alu_src_a_i = funct3[1:0];
	       
	       // Next line need's to be handled better. One
	       // Clock cycles delay is neccessary after receiveng new
	       // intruction before setting store_we_i to 0
	       vif.store_fifo_we_i <= #99 1'b0; 
	       case (funct6)
		   v_add_funct6: vif.alu_op_i = add_op;
		   v_sub_funct6: vif.alu_op_i = sub_op;
		   v_and_funct6: vif.alu_op_i = and_op;
		   v_or_funct6: vif.alu_op_i = or_op;
		   v_xor_funct6: vif.alu_op_i = xor_op;
		   //v_mul_funct6: vif.alu_op_i = muls_op;		   
		   v_mulhsu_funct6: vif.alu_op_i = mulhsu_op;
		   v_mulhs_funct6: vif.alu_op_i = mulhs_op;
		   v_mulhu_funct6: vif.alu_op_i = mulhu_op;
		   v_shll_funct6: vif.alu_op_i = sll_op;
		   v_shrl_funct6: vif.alu_op_i = srl_op;
		   v_shra_funct6: vif.alu_op_i = sra_op;
		   v_vmseq_funct6: vif.alu_op_i = eq_op;
		   v_vmsne_funct6: vif.alu_op_i = neq_op;		   
		   v_vmsltu_funct6: vif.alu_op_i = slt_op;		   
		   v_vmslt_funct6: vif.alu_op_i = sltu_op;
		   v_vmsleu_funct6: vif.alu_op_i = sleu_op;		   
		   v_vmsle_funct6: vif.alu_op_i = sle_op;		   
		   v_vmsgtu_funct6: vif.alu_op_i = sgtu_op;
		   v_vmsgt_funct6: vif.alu_op_i = sgt_op;
		   v_vminu_funct6: vif.alu_op_i = minu_op;
		   v_vmin_funct6: vif.alu_op_i = min_op;       
		   v_merge_funct6: begin
		       vif.type_of_masking_i = 1'b1;
		       vif.mem_to_vrf_i = 2'b10;		       
		       vif.alu_op_i = add_op;
		       if(vm) begin // vmv and v_merge share the same encodings except for vm and vs2
			   vif.mem_to_vrf_i = 2'b11;
		       end
		   end
	       endcase; // case funct6
	       // depending on instruction set alu_src_a_i
	       case (funct3)			
		   vv_funct3:begin
		       vif.alu_src_a_i = 2'b00;		       
		   end
		   vs_funct3: begin
		       vif.alu_src_a_i = 2'b01;
		   end
		   vi_funct3: begin
		       vif.alu_src_a_i = 2'b11;
		   end
	       endcase // case (funct3)	       
	   end // case: arith_opcode	   
	   store_opcode: begin
	       vif.type_of_masking_i = 1'b0;
	       vif.vs1_addr_src_i = 1;
	       vif.vrf_type_of_access_i = 2'b10; // read from VRD
	       vif.alu_op_i = add_op;	       
	       vif.store_fifo_we_i <= #99 1'b1; // this way store fifo will be high after one clock cycle
	   end
	   default: begin
	       vif.vrf_type_of_access_i = vrf_no_access;
	       vif.vs1_addr_src_i = 0;
	       vif.type_of_masking_i = 1'b0;
	       vif.mem_to_vrf_i = 2'b00;
	       // Next line need's to be handled better. Two	       
	       // Clock cycles delay is neccessary after receiveng new
	       // intruction before setting store_we_i to 0
	       vif.store_fifo_we_i <= #99 1'b0; 
	   end
	   
       endcase; // case req.vector_instruction_i[31              	          
   endtask: generate_control_signals

endclass : control_if_driver

`endif

   
