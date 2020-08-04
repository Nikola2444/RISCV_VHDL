`uvm_analysis_imp_decl(_instr_item)
`uvm_analysis_imp_decl(_store_data_item)
`uvm_analysis_imp_decl(_load_data_item)

class vector_core_scoreboard extends uvm_scoreboard;

    // control fileds
   bit checks_enable = 1;
   bit coverage_enable = 1;
   int i = 0;
   int VRF_num_of_el = VECTOR_LENGTH;
   int num_of_matches = 0;
   int num_of_mis_matches = 0;
   const int elements_per_vector = VECTOR_LENGTH;

   // Registers whose value will change only if scoreboard receievs vsetvli instructions
   logic [1 : 0] vmul_reg = 0; 
   logic [$clog2(VECTOR_LENGTH) : 0] vl_reg = VECTOR_LENGTH;
    
   typedef struct 		     
		 {
		    logic [$clog2(VECTOR_LENGTH) : 0] vector_length; 
		    logic [1 : 0] 		      vmul;
		    logic [31 : 0] 		      rs1;
		    logic [31 : 0] 		      rs2;
		    logic [4 : 0] 		      vd_addr;
		     //Divided by 4 because maximum vmul is 8, and maximum number of elements in a vector is 256
		    logic [31 : 0] 		      store_vector [VECTOR_LENGTH * 32 / 4];
		 } load_store_info;

    
    load_store_info store_info_fifo[$];
    load_store_info load_info_fifo[$];     
    // This TLM port is used to connect the scoreboard to the monitor
    uvm_analysis_imp_instr_item#(vector_core_seq_item, vector_core_scoreboard) collected_imp_instr_item;
    uvm_analysis_imp_store_data_item#(store_data_seq_item, vector_core_scoreboard) collected_imp_store_data_item;
    uvm_analysis_imp_load_data_item#(load_data_seq_item, vector_core_scoreboard) collected_imp_load_data_item;
    
   int num_of_tr;

   logic [31 : 0] VRF_referent_model [VECTOR_LENGTH * 32];

    `uvm_component_utils_begin(vector_core_scoreboard)
	`uvm_field_int(checks_enable, UVM_DEFAULT)
	`uvm_field_int(coverage_enable, UVM_DEFAULT)
    `uvm_component_utils_end

    function new(string name = "vector_core_scoreboard", uvm_component parent = null);
	super.new(name,parent);
	collected_imp_instr_item = new("collected_imp_instr_item", this);
	collected_imp_store_data_item = new("collected_imp_store_data_item", this);
	collected_imp_load_data_item = new("collected_imp_load_data_item", this);
	// initializing VRF referent model the same way real VRF is initialized
	
	for (int j = 0; j < VECTOR_LENGTH * 32 / NUM_OF_LANES; j++) begin	    	    
	    for (int i = 0; i < NUM_OF_LANES; i++) begin
		VRF_referent_model[j * NUM_OF_LANES + i] = j;
		$display ("VRF[%d] = %d",j * NUM_OF_LANES + i, VRF_referent_model[j * NUM_OF_LANES + i]);	
	    end	    
	end 
    endfunction : new


    function void report_phase(uvm_phase phase);
	`uvm_info(get_type_name(), $sformatf("vector lane scoreboard examined: %0d transactions", num_of_tr), UVM_LOW);
	`uvm_info(get_type_name(), $sformatf("vector lane scoreboard num of matches: %0d ", num_of_matches), UVM_LOW);
	`uvm_info(get_type_name(), $sformatf("vector lane scoreboard num of miss matches: %0d ", num_of_mis_matches), UVM_LOW);
    endfunction : report_phase


    
    function write_instr_item (vector_core_seq_item tr);
	vector_core_seq_item tr_clone;
	$cast(tr_clone, tr.clone());

        // do actual checking here
        // ...
        ++num_of_tr;
	update_VRF_ref_model(tr_clone);

    endfunction : write_instr_item


   int load_iterator = 0;
   
    function write_load_data_item (load_data_seq_item tr);
	//variable declaration
	int vrf_load_addr;
	load_store_info tmp_load_info;
	load_data_seq_item tr_clone;

	//Function body
	tmp_load_info = load_info_fifo[0];
	$cast(tr_clone, tr.clone());	
        vrf_load_addr = load_iterator++ + tmp_load_info.vd_addr * elements_per_vector * 2**tmp_load_info.vmul;
	VRF_referent_model[vrf_load_addr] = tr_clone.data_from_mem_s;
	`uvm_info(get_type_name(), $sformatf("  load written on position [%d]: %x", 
							  vrf_load_addr, VRF_referent_model [vrf_load_addr]), UVM_HIGH);
	if(load_iterator == (tmp_load_info.vector_length)) begin
	    load_iterator = 0;
	    load_info_fifo.pop_front();
	end	     
    endfunction : write_load_data_item


    function write_store_data_item (store_data_seq_item tr);
	//variable declaration
       int vrf_addr;	
	load_store_info tmp_store_info;
	store_data_seq_item tr_clone;

	//Function body
	tmp_store_info = store_info_fifo[0];	
	$cast(tr_clone, tr.clone());	
	
	vrf_addr = i + tmp_store_info.vd_addr * elements_per_vector * 2**tmp_store_info.vmul; 
	assert(tr_clone.data_to_mem_s == tmp_store_info.store_vector[i]) begin
	    `uvm_info(get_type_name(), $sformatf("Match on position VRF[%d]! expected value: %x, \t real_value: %x", 
						 vrf_addr, tmp_store_info.store_vector[i], tr_clone.data_to_mem_s), UVM_MEDIUM);
	    num_of_matches++;		
	end
	else begin
	    `uvm_info(get_type_name(), $sformatf("Mismatch on position VRF[%d]! expected value: %x, \t real_value: %x", 
						 vrf_addr, tmp_store_info.store_vector[i], tr_clone.data_to_mem_s), UVM_LOW);
	    num_of_mis_matches++;
	end
	i++;	
	if(i == ( tmp_store_info.vector_length)) begin
	    i = 0;
	    store_info_fifo.pop_front();
	end	     
	
    endfunction : write_store_data_item

    

    function void update_VRF_ref_model(vector_core_seq_item tr);

	load_store_info tmp_store_info;
	load_store_info tmp_load_info;	
       
       // Vector instruction opcodes
       const logic [6 : 0] arith_opcode = 7'b1010111;
       const logic [6 : 0] store_opcode = 7'b0100111;
       const logic [6 : 0] load_opcode = 7'b0000111;
	
	// Funct 3 values that are of interest
       const logic [2 : 0] OPIVV_funct3 = 3'b000;
       const logic [2 : 0] OPIVX_funct3 = 3'b100;
       const logic [2 : 0] OPIVI_funct3 = 3'b011;
       const logic [2 : 0] OPMVV_funct3 = 3'b010;
       const logic [2 : 0] OPMVX_funct3 = 3'b110;
       const logic [2 : 0] OPCFG_funct3 = 3'b111;

       const logic [5 : 0] v_merge_funct6 = 6'b010111;


	// Operands
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
       logic [2 : 0] 	   funct3 = tr.vector_instruction_i[14:12];
       logic [10 : 0] 	   zimm = tr.vector_instruction_i[30:20];
	`uvm_info(get_type_name(), $sformatf("funct3 is: %d",  funct3), UVM_FULL)
	`uvm_info(get_type_name(), $sformatf("opcode is: %b",  opcode), UVM_FULL)
	case (opcode)
	    arith_opcode: begin
		//if received instruction is config
		if (funct3 == OPCFG_funct3)begin
		    vmul_reg = zimm[1 : 0];
		    if (vd_addr && !vs1_addr) begin
			//in this case vl is set to a maximum value
			vl_reg = VECTOR_LENGTH * 2**vmul_reg;			
		    end
		    else if (vs1_addr) begin
			// In this case vectorlength is taken from scalar register
			vl_reg = tr.rs1_i;			
		    end
		    return;		    
		end // if (funct3 == 3'b111)
		
		for (int i = 0; i < vl_reg; i++)begin
		    // Finding correct operand for arith operation
		    if (funct3 == OPIVV_funct3 || funct3 == OPMVV_funct3) begin
			a = VRF_referent_model[i + vs1_addr*elements_per_vector*2**vmul_reg];
			b = VRF_referent_model[i + vs2_addr*elements_per_vector*2**vmul_reg];
		    end
		    else if(funct3 == OPIVX_funct3 || funct3 == OPMVX_funct3) begin
			a = tr.rs1_i;			    
			b = VRF_referent_model[i + vs2_addr*elements_per_vector*2**vmul_reg];
		    end
		    else if (funct3 == OPIVI_funct3) begin			
			a = imm;
			b = VRF_referent_model[i + vs2_addr*elements_per_vector*2**vmul_reg];
		    end
		    else
		      `uvm_error (get_type_name(), $sformatf("Non supported OPM funct3 generated with valeu: %x", funct3))

		    
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
			      VRF_referent_model [i + vd_addr*elements_per_vector*2**vmul_reg] = a;
			    else
			      if (VRF_referent_model[i][0]) 
				VRF_referent_model [i + vd_addr*elements_per_vector*2**vmul_reg] = a;
			      else
				VRF_referent_model [i + vd_addr*elements_per_vector*2**vmul_reg] = b;
			end
			default: begin
			    if (vm | VRF_referent_model[i][0])
			      VRF_referent_model [i + vd_addr*elements_per_vector*2**vmul_reg] = arith_operation(a, b, generate_alu_op(tr.vector_instruction_i));
			end
		    endcase // case (funct6)
		    `uvm_info(get_type_name(), $sformatf("instruction: %x,  alu_result[%d]: %x \t a is: %x, b is :%x \t vs2 = %x", 
							 funct6,  i + vd_addr*elements_per_vector*2**vmul_reg, VRF_referent_model [i + vd_addr*elements_per_vector*2**vmul_reg], a, b, vs2_addr), UVM_MEDIUM);
		end // for (int i = 0; i < 2**tr.vmul*tr.vector_length; i++)
		
	    end // case: arith_opcode
	    store_opcode: begin
		tmp_store_info.vector_length = vl_reg;
		tmp_store_info.vmul = vmul_reg;
		tmp_store_info.vd_addr = vd_addr;
		tmp_store_info.rs1 = tr.rs1_i;
		tmp_store_info.rs2 = tr.rs2_i;
		for (int i = 0; i < vl_reg; i++)
		  tmp_store_info.store_vector[i] = VRF_referent_model[vd_addr * elements_per_vector * 2**vmul_reg + i];		
		store_info_fifo.push_back(tmp_store_info);
	    end
	    load_opcode:begin
		tmp_load_info.vector_length = vl_reg;
		tmp_load_info.vmul = vmul_reg;
		tmp_load_info.vd_addr = vd_addr;
		tmp_load_info.rs1 = tr.rs1_i;
		tmp_load_info.rs2 = tr.rs2_i;
		load_info_fifo.push_back(tmp_load_info);		
	    end
	endcase; // case tr.vector_instruction_i[31              	          
    endfunction: update_VRF_ref_model


    function logic [31 : 0] arith_operation(logic [31 : 0] a, logic [31 : 0] b, logic [4 : 0] alu_op);
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
		return mul_temp[63 : 32];		
	    end	    
	    sll_op: return b << a[5 : 0];	   
	    srl_op: return b >> a[5 : 0];		
	    sra_op: return int'(b) >>>a[5 : 0];
	    eq_op: return a == b;
	    neq_op: return a != b;
	    sle_op: return (signed'(a) == signed'(b) || signed'(b) < signed'(a));
	    sleu_op: return (unsigned'(a) == unsigned'(b) || unsigned'(b) < unsigned'(a));
	    slt_op: return (signed'(b) < signed'(a));
	    sltu_op: return (unsigned'(b) < unsigned'(a));
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

    function logic [4 : 0] generate_alu_op(logic[31 : 0] vector_instruction_i);
       logic [4 : 0]       alu_op;	
       logic [6 : 0] 	   opcode = vector_instruction_i [6 : 0];
       logic [5 : 0] 	  funct6 = vector_instruction_i[31 : 26];
       logic [2 : 0] 	  funct3 = vector_instruction_i[14 : 12];
       logic 		  vm = vector_instruction_i[25];	



	if (funct3 == OPIVV_funct3 || funct3 == OPIVX_funct3 || funct3 == OPIVI_funct3) begin
	    case (funct6)
		v_add_funct6: alu_op = add_op;
		v_sub_funct6: alu_op = sub_op;
		v_and_funct6: alu_op = and_op;
		v_or_funct6: alu_op = or_op;
		v_xor_funct6: alu_op = xor_op;
		v_shll_funct6: alu_op = sll_op;	      
		v_shrl_funct6: alu_op = srl_op;
		v_shra_funct6:alu_op = sra_op;
		v_vmseq_funct6: alu_op = eq_op;
		v_vmsne_funct6: alu_op = neq_op;		   
		v_vmslt_funct6: alu_op = slt_op;		   
		v_vmsltu_funct6: alu_op = sltu_op;
		v_vmsleu_funct6: alu_op = sleu_op;		   
		v_vmsle_funct6: alu_op = sle_op;		   
		v_vmsgtu_funct6: alu_op = sgtu_op;
		v_vmsgt_funct6: alu_op = sgt_op;
		v_vminu_funct6: alu_op = minu_op;
		v_vmin_funct6: alu_op = min_op;       
		v_merge_funct6: alu_op = add_op;		    
		default:
		  `uvm_fatal (get_type_name(), $sformatf("Non supported OPM funct6 generated with value: %x", funct6))
	    endcase; // case funct6
	end // if (funct3 == OPIVI_funct3 || funct3 == OPIVX_funct3 || funct3 == OPIVI_funct3)
	else if (funct3 == OPMVV_funct3 || funct3 == OPMVX_funct3) begin
	    case (funct6)
		v_mul_funct6: alu_op = muls_op;		   
		v_mulhsu_funct6: alu_op = mulhsu_op;
		v_mulhs_funct6: alu_op = mulhs_op;
		v_mulhu_funct6: alu_op = mulhu_op;
		default:
		  `uvm_fatal (get_type_name(), $sformatf("Non supported OPM funct6 generated with value: %x", funct6))
	    endcase		    
	end
	else 
	  `uvm_fatal (get_type_name(), $sformatf("Non supported OPM funct3 generated with value: %x", funct3))

	return alu_op;	
    endfunction: generate_alu_op
    
endclass : vector_core_scoreboard


