`ifndef VECTOR_CORE_SIMPLE_SEQ_SV
 `define VECTOR_CORE_SIMPLE_SEQ_SV

class vector_core_simple_seq extends vector_core_base_seq;

    `uvm_object_utils (vector_core_simple_seq)

   typedef  logic [31 : 0] instr_queue[$];
    
    instr_queue instr_queue_1;
    
   string 	file_path = "../RV32I_vector_core/simulation_sources/assembly_test_files/assembly_code.txt";


    
   function new(string name = "vector_core_simple_seq");
      super.new(name);
   endfunction
    
   virtual task body();
       // simple example - just send one item
       instr_queue_1 = read_instr_from_file (file_path);
       foreach (instr_queue_1[i])          
	  $display("instruction[%d]: %b", i, instr_queue_1[i]);
       foreach (instr_queue_1[i]) begin
	   //req.vector_instruction_i = instr_queue_1[i];
	   `uvm_do_with(req, {req.vector_instruction_i == instr_queue_1[i];});
       end
       `uvm_do_with(req, {req.vector_instruction_i == 0;});
       
       
   endtask : body

    
    function instr_queue read_instr_from_file (string file_path);       
       logic [31:0] instr;
       int 	    fd = $fopen (file_path, "r");
	instr_queue instr_queue_1;
	while (!$feof(fd)) begin
	    $fscanf(fd,"%b\n",instr);
	    instr_queue_1.push_back(instr);
	end
	
	//foreach (instr_queue_1[i])          
	  //$display("instruction[%d]: %b", i, instr_queue_1[i]);
	return instr_queue_1;
    endfunction
endclass : vector_core_simple_seq

`endif
