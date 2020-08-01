`ifndef CALC_DRIVER_SV
 `define CALC_DRIVER_SV
class vector_core_driver extends uvm_driver#(vector_core_seq_item);
    
    `uvm_component_utils(vector_core_driver)
    
   virtual interface v_core_if vif;

   typedef enum {get_instr, send_instruction} driving_stages;
   driving_stages v_core_dr_stages = get_instr;


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
   const logic [5 : 0] v_mulhu_funct6 = 6'b100100; // unsigned higher mul //implemented
   
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
       vif.vrf_type_of_access_i = vrf_no_access;      
       forever begin
           @(posedge(vif.clk));
	   #1ns;		       			   
	   if (vif.reset) begin	       	       
	       /*State machine that send instructions to vector core if there is no get_instr*/
	       case (v_core_dr_stages)
		   get_instr: begin		       		       		       
		       seq_item_port.get_next_item(req);
		       `uvm_info(get_type_name(),
				 $sformatf("Driver sending...\n%s", req.sprint()),
				 UVM_HIGH)		      		      
		       seq_item_port.item_done();
		   end
		   send_instruction: begin
		       //receiving item
		       if (!vif.vector_stall_s)begin
			   vif.vector_instruction_i = req.vector_instruction_i;
			   vif.rs1_i = req.rs1_i;
			   vif.rs2_i = req.rs2_i;			   
			   v_core_dr_stages = get_instr;
		       end
		   end
	       endcase; // case (v_core_dr_stages)
	   end // if (vif.reset)
       end
   endtask : main_phase


   /*This function generates vector lane control signals. It has two argumets:
    
    vif - inside it, is the virtual interface of vector lane
    vector_instruction_i - is the instruction the lane needs to receive    
    */
   task generate_control_signals(virtual v_core_if vif, logic[31 : 0] vector_instruction_i);
       // Funct3 constants       
      logic [6 : 0] 	  opcode = req.vector_instruction_i [6 : 0];
      logic [5 : 0] 	  funct6 = req.vector_instruction_i[31 : 26];
      logic [2 : 0] 	  funct3 = req.vector_instruction_i[14 : 12];
      logic 		  vm = vector_instruction_i[25];	
       
       case (opcode)
	   arith_opcode: begin
	       generate_arith_control_signals(vif, vector_instruction_i);	       
	   end // case: arith_opcode	   
	   store_opcode: begin
	       vif.type_of_masking_i = 1'b0;
	       vif.immediate_sign_i = 1'b0;	       
	       vif.vs1_addr_src_i = 1;
	       vif.vrf_type_of_access_i = 2'b10; // read from VRD
	       vif.alu_op_i = add_op;	       
	       vif.store_fifo_we_i <= 1'b1;
	   end
	   default: begin
	       vif.vrf_type_of_access_i = vrf_no_access;
	       vif.immediate_sign_i = 1'b0;
	       vif.vs1_addr_src_i = 0;
	       vif.type_of_masking_i = 1'b0;
	       vif.mem_to_vrf_i = 2'b00;
	       // Next line need's to be handled better. Two	       
	       // Clock cycles delay is neccessary after receiveng new
	       // intruction before setting store_we_i to 0
	       vif.store_fifo_we_i <= 1'b0; 
	   end
	   
       endcase; // case req.vector_instruction_i[31              	          
   endtask: generate_control_signals

   task generate_arith_control_signals(virtual v_core_if vif, logic[31 : 0] vector_instruction_i);

      logic [6 : 0] 	  opcode = req.vector_instruction_i [6 : 0];
      logic [5 : 0] 	  funct6 = req.vector_instruction_i[31 : 26];
      logic [2 : 0] 	  funct3 = req.vector_instruction_i[14 : 12];
      logic 		  vm = vector_instruction_i[25];	

      const logic [2 : 0] OPIVV_funct3 = 3'b000;
      const logic [2 : 0] OPIVX_funct3 = 3'b100;
      const logic [2 : 0] OPIVI_funct3 = 3'b011;
      const logic [2 : 0] OPMVV_funct3 = 3'b010;
      const logic [2 : 0] OPMVX_funct3 = 3'b110;
       

       vif.vrf_type_of_access_i = vrf_read_write;
       vif.vs1_addr_src_i = 0;
       vif.type_of_masking_i = 1'b0;
       vif.mem_to_vrf_i = 2'b00;
       vif.immediate_sign_i = 1'b0;
       vif.store_fifo_we_i <= 1'b0;
       
       
       // Next line need's to be handled better. One
       // Clock cycles delay is neccessary after receiveng new
       // intruction before setting store_we_i to 0

       
       // Depending on funct3 some instructions may be in OPI group or OPM group, and instructions
       // from these two groups can have the same funct6.
       if (funct3 == OPIVV_funct3 || funct3 == OPIVX_funct3 || funct3 == OPIVI_funct3) begin
	   case (funct6)
	       v_add_funct6: vif.alu_op_i = add_op;
	       v_sub_funct6: vif.alu_op_i = sub_op;
	       v_and_funct6: vif.alu_op_i = and_op;
	       v_or_funct6: vif.alu_op_i = or_op;
	       v_xor_funct6: vif.alu_op_i = xor_op;		       
	       v_shll_funct6: begin
		   vif.immediate_sign_i = 1'b1;		   
		   vif.alu_op_i = sll_op;
	       end
	       v_shrl_funct6: begin
		   vif.immediate_sign_i = 1'b1;
		   vif.alu_op_i = srl_op;
	       end
	       v_shra_funct6: begin
		   vif.immediate_sign_i = 1'b1;
		   vif.alu_op_i = sra_op;
	       end
	       v_vmseq_funct6: vif.alu_op_i = eq_op;
	       v_vmsne_funct6: vif.alu_op_i = neq_op;		   
	       v_vmslt_funct6: vif.alu_op_i = slt_op;		   
	       v_vmsltu_funct6: vif.alu_op_i = sltu_op;
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
		   // vmv and v_merge share the same encodings except for vm and vs2
		   // if vm = 1 the instructions is vmv else instruction is merge
		   if(vm) begin 
		       vif.mem_to_vrf_i = 2'b11;
		   end
	       end
	       default:
		 `uvm_fatal (get_type_name(), $sformatf("Non supported OPM funct6 generated with value: %x", funct6))
	   endcase; // case funct6
       end // if (funct3 == OPIVI_funct3 || funct3 == OPIVX_funct3 || funct3 == OPIVI_funct3)
       else if (funct3 == OPMVV_funct3 || funct3 == OPMVX_funct3) begin
	   case (funct6)
	       v_mul_funct6: vif.alu_op_i = muls_op;		   
	       v_mulhsu_funct6: vif.alu_op_i = mulhsu_op;
	       v_mulhs_funct6: vif.alu_op_i = mulhs_op;
	       v_mulhu_funct6: vif.alu_op_i = mulhu_op;
	       default:
		 `uvm_fatal (get_type_name(), $sformatf("Non supported OPM funct6 generated with value: %x", funct6))
	   endcase		    
       end
       else 
	 `uvm_fatal (get_type_name(), $sformatf("Non supported OPM funct3 generated with value: %x", funct3))
       
       // depending on funct3 set alu_src_a_i
       case (funct3)
	   OPIVV_funct3:begin
	       vif.alu_src_a_i = 2'b00;
	   end
	   OPIVX_funct3: begin
	       vif.alu_src_a_i = 2'b01;
	   end
	   OPIVI_funct3: begin
	       vif.alu_src_a_i = 2'b11;
	   end
	   OPMVV_funct3: begin
	       vif.alu_src_a_i = 2'b00;		       
	   end
	   OPMVX_funct3: begin
	       vif.alu_src_a_i = 2'b01;		       
	   end
	   default:
	     `uvm_error (get_type_name(), $sformatf("Non supported funct3 generated when setting src_a with value: %x", funct3))
       endcase // case (funct3)	       
   endtask: generate_arith_control_signals;
   
   
endclass : vector_core_driver



`endif

   
