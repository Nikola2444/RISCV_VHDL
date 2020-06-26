`uvm_analysis_imp_decl(_instr_item)
`uvm_analysis_imp_decl(_store_data_item)

class vector_lane_scoreboard extends uvm_scoreboard;

    // control fileds
   bit checks_enable = 1;
   bit coverage_enable = 1;
   int i = 0;
   int VRF_num_of_el = VECTOR_LENGTH;
   int num_of_matches = 0;
   int num_of_mis_matches = 0;
   const int elements_per_vector = VECTOR_LENGTH;

    
   typedef struct 
		 {
		    logic [$clog2(VECTOR_LENGTH) : 0] vector_length_i; 
		    logic [1 : 0] 			 vmul_i;
		    logic [4 : 0] 			 vd_addr;
		 } store_info;

    store_info store_info_fifo[$];    
    // This TLM port is used to connect the scoreboard to the monitor
    uvm_analysis_imp_instr_item#(control_if_seq_item, vector_lane_scoreboard) collected_imp_instr_item;
    uvm_analysis_imp_store_data_item#(store_data_seq_item, vector_lane_scoreboard) collected_imp_store_data_item;
    
   int num_of_tr;

   logic [31 : 0] VRF_referent_model [VECTOR_LENGTH * 32];

    `uvm_component_utils_begin(vector_lane_scoreboard)
	`uvm_field_int(checks_enable, UVM_DEFAULT)
	`uvm_field_int(coverage_enable, UVM_DEFAULT)
    `uvm_component_utils_end

    function new(string name = "vector_lane_scoreboard", uvm_component parent = null);
	super.new(name,parent);
	collected_imp_instr_item = new("collected_imp_instr_item", this);
	collected_imp_store_data_item = new("collected_imp_store_data_item", this);
	// initializing VRF referent model the same way real VRF is initialized
	for (int i = 0; i < VECTOR_LENGTH * 32; i++) begin
	    VRF_referent_model[i] = i;
	    $display ("VRF[%d] = %d",i, VRF_referent_model[i]);	    
	end 
    endfunction : new


    function void report_phase(uvm_phase phase);
	`uvm_info(get_type_name(), $sformatf("vector lane scoreboard examined: %0d transactions", num_of_tr), UVM_LOW);
	`uvm_info(get_type_name(), $sformatf("vector lane scoreboard num of matches: %0d ", num_of_matches), UVM_LOW);
	`uvm_info(get_type_name(), $sformatf("vector lane scoreboard num of miss matches: %0d ", num_of_mis_matches), UVM_LOW);
    endfunction : report_phase


    
    function write_instr_item (control_if_seq_item tr);
	control_if_seq_item tr_clone;
	$cast(tr_clone, tr.clone());
	if(checks_enable) begin
            // do actual checking here
            // ...
             ++num_of_tr;
	    update_VRF_ref_model(tr_clone);
	end
    endfunction : write_instr_item


    function write_store_data_item (store_data_seq_item tr);
	store_info tmp_store_info;
	store_data_seq_item tr_clone;
	
	tmp_store_info = store_info_fifo[0];
	$cast(tr_clone, tr.clone());	
	if(checks_enable) begin
	   int vrf_addr = i++ + tmp_store_info.vd_addr * elements_per_vector; 
	    assert(tr_clone.data_to_mem_o == VRF_referent_model[vrf_addr]) begin
		`uvm_info(get_type_name(), $sformatf("Match on position VRF[%d]! expected value: %x, \t real_value: %x", 
						       vrf_addr, VRF_referent_model[vrf_addr ], tr_clone.data_to_mem_o), UVM_HIGH);
		num_of_matches++;		
	    end
	      else begin
		  `uvm_info(get_type_name(), $sformatf("Mismatch on position VRF[%d]! expected value: %x, \t real_value: %x", 
						       vrf_addr, VRF_referent_model[vrf_addr ], tr_clone.data_to_mem_o), UVM_LOW);
		  num_of_mis_matches++;
	      end
		
	    if(i == ( tmp_store_info.vector_length_i*2**tmp_store_info.vmul_i)) begin
		i = 0;
		store_info_fifo.pop_front();	
	    end	     
	end
    endfunction : write_store_data_item

    

    function void update_VRF_ref_model(control_if_seq_item tr);

	store_info tmp_store_info;	
       
       
       const logic [6 : 0] arith_opcode = 7'b1010111;
       const logic [6 : 0] store_opcode = 7'b0100111;


       const logic [2 : 0] OPIVV_funct3 = 3'b000;
       const logic [2 : 0] OPIVX_funct3 = 3'b100;
       const logic [2 : 0] OPIVI_funct3 = 3'b011;
       const logic [2 : 0] OPMVV_funct3 = 3'b010;
       const logic [2 : 0] OPMVX_funct3 = 3'b110;

       const logic [5 : 0] v_merge_funct6 = 6'b010111;

	
       logic [31 : 0] 	   a;
       logic [31 : 0] 	   b;

       /*Instruction fields*/
       logic 		   vm = tr.vector_instruction_i[25];	
       logic [6 : 0] 	   opcode = tr.vector_instruction_i [6 : 0];
       logic [5 : 0] 	   funct6 = tr.vector_instruction_i[31 : 26];
       logic [4 : 0] 	   vs1_addr = tr.vector_instruction_i[19 : 15];
       logic [4 : 0] 	   vs2_addr = tr.vector_instruction_i[24 : 20];
       logic [4 : 0] 	   vd_addr = tr.vector_instruction_i[11 : 7];
       logic [4 : 0] 	   imm = tr.vector_instruction_i[19 : 15];
	// Funct3 determines the type of operands (vector - vector or vector-scalar or 
	// vector - immediate) 
       logic [2 : 0] 	   funct3 = tr.vector_instruction_i[14:12];
	`uvm_info(get_type_name(), $sformatf("funct3 is: %d",  funct3), UVM_LOW)
	case (opcode)
	    arith_opcode: begin
		for (int i = 0; i < 2**tr.vmul_i*tr.vector_length_i; i++)begin
		    // Finding correct operand for arith operation
		    if (funct3 == OPIVV_funct3 || funct3 == OPMVV_funct3) begin
			    a = VRF_referent_model[i + vs1_addr*elements_per_vector];
			    b = VRF_referent_model[i + vs2_addr*elements_per_vector];			    
		    end
		    else if(funct3 == OPIVX_funct3 || funct3 == OPMVX_funct3) begin
			    a = tr.rs1_data_i;			    
			    b = VRF_referent_model[i + vs2_addr*elements_per_vector];
		    end
		    else if (funct3 == OPIVI_funct3) begin			
			    a = imm;
			    b = VRF_referent_model[i + vs2_addr*elements_per_vector];		
		    end
		    else
		      `uvm_error (get_type_name(), $sformatf("Non supported OPM funct3 generated with value: %x", funct3))

		    
		    /*Checking if arith instruction is merge or not. If it is calculate acordingly 
		     expected values. If vm = 1, that means that merge is a move instruction
		     and expected value is equal to vs1 (a), else depending on mask bits in V0
		     expected value can be a or b. If instruction is not merge that means it's a 
		     regular arith instruction, and calculcation is done only if VM and VRF_referent_model[i][0]
		     are not zero. When they are, that means masking is on (vm = 0), mask bit is zero, and
		     element on that index should not be updated.*/
		    case (funct6)
			v_merge_funct6: begin
			    if (vm) // when vm = 1 merge is a move instruction (vmv)
			      VRF_referent_model [i + vd_addr*elements_per_vector] = a;
			    else
			      if (VRF_referent_model[i][0]) 
				VRF_referent_model [i + vd_addr*elements_per_vector] = a;
			      else
				VRF_referent_model [i + vd_addr*elements_per_vector] = b;
			end
			default: begin
			    if (vm | VRF_referent_model[i][0])
			      VRF_referent_model [i + vd_addr*elements_per_vector] = arith_operation(a, b, tr.alu_op_i);
			end
		    endcase // case (funct6)
		    `uvm_info(get_type_name(), $sformatf("alu_result[%d]: %x \t a is: %x, b is :%x", i + vd_addr*elements_per_vector, VRF_referent_model [i + vd_addr*elements_per_vector], a, b), UVM_FULL);
		end // for (int i = 0; i < 2**tr.vmul_i*tr.vector_length_i; i++)
		
	    end // case: arith_opcode
	    store_opcode: begin
		tmp_store_info.vector_length_i = tr.vector_length_i;
		tmp_store_info.vmul_i = tr.vmul_i;
		tmp_store_info.vd_addr = vd_addr;
		store_info_fifo.push_back(tmp_store_info);		
	    end
	endcase; // case tr.vector_instruction_i[31              	          
    endfunction: update_VRF_ref_model


    function logic[31 : 0] arith_operation(logic [31 : 0] a, logic [31 : 0] b, logic [4 : 0] alu_op);
       logic [63 : 0] mul_temp;	
	case (alu_op)
	    add_op: return a + b;		       
	    sub_op: return a - b;	   
	    and_op: return a & b;		
	    or_op: return a | b;
	    xor_op: return a ^ b;
	    mulhu_op: begin 
		mul_temp = unsigned'(a) * unsigned'(b);
		return mul_temp[63 : 32];		
	    end
	    mulhs_op: begin 
		mul_temp = signed'(a) * signed'(b);
		return mul_temp[63 : 32];		
	    end
	    muls_op: begin 
		mul_temp = signed'(a) * signed'(b);
		return mul_temp[31 : 0];		
	    end
	    mulhsu_op: begin 
		mul_temp = unsigned'(a) * signed'(b);
		return mul_temp[31 : 0];		
	    end	    
	    sll_op: return b << a;	   
	    srl_op: return b >> a;		
	    sra_op: return b >>>a;
	    eq_op: return a == b;
	    neq_op: return a != b;
	    sle_op: return (signed'(a) != signed'(b) || signed'(b) < signed'(a));
	    sleu_op: return (unsigned'(a) != unsigned'(b) || unsigned'(b) < unsigned'(a));
	    sle_op: return (signed'(b) < signed'(a));
	    sleu_op: return (unsigned'(b) < unsigned'(a));
	    sgt_op: return (signed'(b) > signed'(a));
	    sgtu_op: return (unsigned'(b) > unsigned'(a));
	    min_op: begin 
		if (signed'(a) < signed'(b)) 
		  return a; 
		else 
		  return b;
	    end
	    minu_op: begin 
		if (unsigned'(a) < unsigned'(b)) 
		  return a; 
		else 
		  return b;
	    end
	    
	    
	endcase;
    endfunction: arith_operation
endclass : vector_lane_scoreboard


