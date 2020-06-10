`ifndef CALC_IF_SV
 `define CALC_IF_SV

interface v_lane_if (input clk, logic reset);

   parameter DATA_WIDTH = 32;
   parameter VECTOR_LENGTH = 1024;
   parameter RESP_WIDTH = 2;
   parameter CMD_WIDTH = 4;

   logic [31 : 0] vector_instruction_i;   
   logic [DATA_WIDTH - 1 : 0] data_from_mem_i;   
   logic [1 : 0] 	      vmul_i;   
   logic [$clog2(VECTOR_LENGTH/DATA_WIDTH) : 0] vector_length_i ;
   
   /*************control signals***********************************/
   // from memory control unit        
   logic 					    load_fifo_we_i = 0;
   logic 					    store_fifo_re_i = 0;
   

   // from vector control unit
   logic [4 : 0] 				    alu_op_i;   
   logic [1 : 0] 				    mem_to_vrf_i;   
   logic 					    store_fifo_we_i = 0;   
   logic [1:0] 				    vrf_type_of_access_i;   
   logic 					    load_fifo_re_i = 0;
   

   //oputput data
   logic [DATA_WIDTH - 1 : 0] 	    data_to_mem_o;   
   // status signals
   logic 					    ready_o;   
   
   logic 					    load_fifo_almostempty_o;   
   logic 					    load_fifo_almostfull_o;   
   logic 					    load_fifo_empty_o;   
   logic 					    load_fifo_full_o;   
   logic [8 : 0] 				    load_fifo_rdcount_o;   
   logic 					    load_fifo_rderr_o;   
   logic [8 : 0] 				    load_fifo_wrcount_o;   
   logic 					    load_fifo_wrerr_o;
   
   logic 					    store_fifo_almostempty_o;   
   logic 					    store_fifo_almostfull_o;   
   logic 					    store_fifo_empty_o;   
   logic 					    store_fifo_full_o;   
   logic [8 : 0] 				    store_fifo_rdcount_o;   
   logic 					    store_fifo_rderr_o;   
   logic [8 : 0] 				    store_fifo_wrcount_o;   
   logic 					    store_fifo_wrerr_o;
   
endinterface : v_lane_if

`endif
