module vector_core_verif_top;

   import uvm_pkg::*;     // import the UVM library
`include "uvm_macros.svh" // Include the UVM macros

   import test_pkg::*;

   logic clk;
   logic reset;
   parameter VECTOR_LENGTH = 32;
   
   parameter NUM_OF_LANES = 8;
   parameter DATA_WIDTH = 32;

   // interface
   v_core_if v_core_vif(clk, reset);
   

   // DUT
 vector_core #(
		 .VECTOR_LENGTH(VECTOR_LENGTH),
		 .NUM_OF_LANES(NUM_OF_LANES),
		 .DATA_WIDTH(DATA_WIDTH))
   DUT(
       .clk(clk),
       .reset(reset),
       .instruction_i(v_core_vif.vector_instruction_i),
       .vector_stall_o(v_core_vif.vector_stall_s),
       .rs1_i(v_core_vif.rs1_i),
       .rs2_i(v_core_vif.rs2_i),
       
       
       .scalar_load_req_i(v_core_vif.scalar_load_req_i),
       .scalar_store_req_i(v_core_vif.scalar_store_req_i),
       .scalar_address_i(v_core_vif.scalar_address_i),

       .all_v_stores_executed_o(v_core_vif.all_v_stores_executed_o),
       .all_v_loads_executed_o(v_core_vif.all_v_loads_executed_o),
       
       .store_address_o(v_core_vif.store_address_s),
       .load_address_o(v_core_vif.load_address_s),
       .mem_we_o(v_core_vif.mem_we_s),
       .mem_re_o(v_core_vif.mem_re_s),
       .data_from_mem_i(v_core_vif.data_from_mem_s),
       .data_to_mem_o(v_core_vif.data_to_mem_s));
       
       


       BRAM_18KB #
       (
	.RAM_WIDTH(DATA_WIDTH),
	.RAM_DEPTH (2**16),
	.RAM_PERFORMANCE("LOW_LATENCY"),
	.INIT_FILE(""))
       DATA_MEM(
		.clk(clk),
		.write_addr_i(v_core_vif.store_address_s[15 : 0]),
		.read_addr_i(v_core_vif.load_address_s[15 : 0]),
		.write_data_i(v_core_vif.data_to_mem_s),
		.we_i(v_core_vif.mem_we_s),
		.re_i(v_core_vif.mem_re_s),
		.rst_read_i(1'b0),
		.output_reg_en_i(1'b0),
		.read_data_o(v_core_vif.data_from_mem_s));

   //run test
   initial begin      
       uvm_config_db#(virtual v_core_if)::set(null, "uvm_test_top.env", "v_core_if", v_core_vif);
       run_test();   
end

   // clock and reset init.
   initial begin
       clk <= 0;       
       reset <= 0;
       for (int i = 0; i < 6; i++)
	 @(posedge(clk));
       reset <= 1;
       
   end

   // clock generation
   always #50 clk = ~clk;

endmodule : vector_core_verif_top
