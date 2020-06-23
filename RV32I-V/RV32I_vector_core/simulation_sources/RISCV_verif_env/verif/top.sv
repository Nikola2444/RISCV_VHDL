module vector_lane_verif_top;

   import uvm_pkg::*;     // import the UVM library
`include "uvm_macros.svh" // Include the UVM macros

   import test_pkg::*;

   logic clk;
   logic reset;

   // interface
   v_lane_if v_lane_vif(clk, reset);

   // DUT
   vector_lane#(
		.VECTOR_LENGTH (32),
		.DATA_WIDTH(32)) 
   vector_lane_DUT(
		   .clk(clk),
		   .reset(reset),

		   .vector_instruction_i(v_lane_vif.vector_instruction_i),
		   .data_from_mem_i (v_lane_vif.data_from_mem_i),
		   .vmul_i(v_lane_vif.vmul_i),
		   .vector_length_i(v_lane_vif.vector_length_i),

		   .load_fifo_we_i(v_lane_vif.load_fifo_we_i),
		   .store_fifo_re_i(v_lane_vif.store_fifo_re_i),

		   .alu_op_i(v_lane_vif.alu_op_i),
		   .mem_to_vrf_i(v_lane_vif.mem_to_vrf_i),
		   .store_fifo_we_i(v_lane_vif.store_fifo_we_i),
		   .vrf_type_of_access_i(v_lane_vif.vrf_type_of_access_i),
		   .type_of_masking_i(v_lane_vif.type_of_masking_i),
		   .load_fifo_re_i(v_lane_vif.load_fifo_re_i),
		   .vs1_addr_src_i(v_lane_vif.vs1_addr_src_i),
		   .data_to_mem_o(v_lane_vif.data_to_mem_o),

		   .ready_o(v_lane_vif.ready_o),

		   .load_fifo_almostempty_o(v_lane_vif.load_fifo_almostempty_o), //not used
		   .load_fifo_almostfull_o(v_lane_vif.load_fifo_almostfull_o),//not used
		   .load_fifo_empty_o(v_lane_vif.load_fifo_empty_o),
		   .load_fifo_full_o(v_lane_vif.load_fifo_full_o),
		   .load_fifo_rdcount_o(v_lane_vif.load_fifo_rdcount_o),//not used
		   .load_fifo_rderr_o(v_lane_vif.load_fifo_rderr_o),//not used
		   .load_fifo_wrcount_o(v_lane_vif.load_fifo_wrcount_o),//not used
		   .load_fifo_wrerr_o(v_lane_vif.load_fifo_wrerr_o),//not used

		   .store_fifo_almostempty_o(v_lane_vif.store_fifo_almostempty_o),//not used
		   .store_fifo_almostfull_o(v_lane_vif.store_fifo_almostfull_o),//not used
		   .store_fifo_empty_o(v_lane_vif.store_fifo_empty_o),
		   .store_fifo_full_o(v_lane_vif.store_fifo_full_o),
		   .store_fifo_rdcount_o(v_lane_vif.store_fifo_rdcount_o),//not used
		   .store_fifo_rderr_o(v_lane_vif.store_fifo_rderr_o),//not used
		   .store_fifo_wrcount_o(v_lane_vif.store_fifo_wrcount_o),//not used
		   .store_fifo_wrerr_o(v_lane_vif.store_fifo_wrerr_o)//not used
       
		   );

   // run test
   initial begin      
       uvm_config_db#(virtual v_lane_if)::set(null, "uvm_test_top.env", "v_lane_if", v_lane_vif);
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

endmodule : vector_lane_verif_top
