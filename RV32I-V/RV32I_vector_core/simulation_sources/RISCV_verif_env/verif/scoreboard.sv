`uvm_analysis_imp_decl(_instr_item)
`uvm_analysis_imp_decl(_store_data_item)

class vector_lane_scoreboard extends uvm_scoreboard;

    // control fileds
   bit checks_enable = 1;
   bit coverage_enable = 1;
   int i = 0;
   int VRF_num_of_el = VECTOR_LENGTH*32;
   int num_of_matches = 0;
   int num_of_mis_matches = 0;
   const int elements_per_vector = VECTOR_LENGTH/32;

    
   typedef struct 
		 {
		    logic [$clog2(VECTOR_LENGTH/DATA_WIDTH) : 0] vector_length_i; 
		    logic [1 : 0] 			 vmul_i;
		    logic [4 : 0] 			 vd_addr;
		 } store_info;

    store_info store_info_fifo[$];    
    // This TLM port is used to connect the scoreboard to the monitor
    uvm_analysis_imp_instr_item#(control_if_seq_item, vector_lane_scoreboard) collected_imp_instr_item;
    uvm_analysis_imp_store_data_item#(store_data_seq_item, vector_lane_scoreboard) collected_imp_store_data_item;
    
   int num_of_tr;

   logic [31 : 0] VRF_referent_model [VECTOR_LENGTH];

    `uvm_component_utils_begin(vector_lane_scoreboard)
	`uvm_field_int(checks_enable, UVM_DEFAULT)
	`uvm_field_int(coverage_enable, UVM_DEFAULT)
    `uvm_component_utils_end

    function new(string name = "vector_lane_scoreboard", uvm_component parent = null);
	super.new(name,parent);
	collected_imp_instr_item = new("collected_imp_instr_item", this);
	collected_imp_store_data_item = new("collected_imp_store_data_item", this);
	// initializing VRF referent model the same way real VRF is initialized
	for (int i = 0; i < VECTOR_LENGTH; i++) begin
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
		num_of_matches++;		
	    end
	      else begin
		  `uvm_info(get_type_name(), $sformatf("Mismatch on position VRF[%d]! expected value: %x, \t real_value: %x", 
						       vrf_addr, VRF_referent_model[vrf_addr ], tr_clone.data_to_mem_o), UVM_LOW);
		  num_of_mis_matches++;
	      end
		
	    if(i == ( tmp_store_info.vector_length_i*2**tmp_store_info.vmul_i - 1)) begin

		i = 0;
		store_info_fifo.pop_front();	
	    end	     
	end
    endfunction : write_store_data_item

    

    function void update_VRF_ref_model(control_if_seq_item tr);

	store_info tmp_store_info;	
       
       
       const logic [6 : 0] arith_opcode = 7'b1010111;
       const logic [6 : 0] store_opcode = 7'b0100111;

       const logic 	   vv_funct3 = 3'b000;
       const logic 	   vs_funct3 = 3'b100;
       const logic 	   vi_funct3 = 3'b011;

       logic [31 : 0] 	   a;
       logic [31 : 0] b;
       logic [6 : 0]  opcode = tr.vector_instruction_i [6 : 0];
       logic [5 : 0]  funct6 = tr.vector_instruction_i[31 : 26];
       logic [4 : 0]  vs1_addr = tr.vector_instruction_i[19 : 15];
       logic [4 : 0]  vs2_addr = tr.vector_instruction_i[24 : 20];
       logic [4 : 0]  vd_addr = tr.vector_instruction_i[11 : 7];
       logic [4 : 0]  imm = tr.vector_instruction_i[19 : 15];
	// Funct3 determines the type of operands (vector - vector or vector-scalar or 
	// vector - immediate) 
       logic [2 : 0]  funct3 = tr.vector_instruction_i[14:12];       	
	case (opcode)
	    arith_opcode: begin
		for (int i = 0; i < 2**tr.vmul_i*tr.vector_length_i; i++)begin		    
		    case (funct3)			
			vv_funct3:begin
			    a = VRF_referent_model[i + vs1_addr*elements_per_vector];
			    b = VRF_referent_model[i + vs2_addr*elements_per_vector];
			    VRF_referent_model [i + vd_addr*elements_per_vector] = arith_operation(a, b, tr.alu_op_i);			    			    
			end
			vs_funct3: begin
			    a = tr.rs1_data_i;			    
			    b = VRF_referent_model[i + vs2_addr*elements_per_vector];
			    VRF_referent_model [i + vd_addr*elements_per_vector] = arith_operation(a, b, tr.alu_op_i);			    
			end
			vi_funct3: begin
			    a = imm;
			    b = VRF_referent_model[i + vs2_addr*elements_per_vector];
			    VRF_referent_model [i + vd_addr*elements_per_vector] = arith_operation(a, b, tr.alu_op_i);			    
			end
		    endcase // case (funct3)
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
	case (alu_op)
	    add_op: return a + b;		       
	    sub_op: return a - b;	   
	    and_op: return a & b;		
	    or_op: return a | b;
	    xor_op: return a ^ b;	    
	endcase; // case funct6	       
    endfunction: arith_operation
endclass : vector_lane_scoreboard
