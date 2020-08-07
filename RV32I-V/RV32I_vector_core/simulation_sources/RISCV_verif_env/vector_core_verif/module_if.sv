`ifndef CALC_IF_SV
 `define CALC_IF_SV
import configurations_pkg::*;   
interface v_core_if (input clk, logic reset);
   
   logic [31 : 0] vector_instruction_i;
   logic [31 : 0] rs1_i;  
   logic [31 : 0] rs2_i;

   //Scalar core load and store interface
   logic 	  scalar_load_req_i = 0;
   logic 	  scalar_store_req_i = 0;
   logic [31 : 0] scalar_address_i = 0;

   logic 	  all_v_stores_executed_o;
   logic 	  all_v_loads_executed_o;
   
   
   
   //Vector core status signal
   logic 	  vector_stall_s;


   //Interconnections between data memory and vector core
   logic 	  mem_we_s;
   logic 	  mem_re_s;
   logic [31 : 0] data_mem_addr_s ;
   logic [31 : 0] data_from_mem_s;
   logic [31 : 0] data_to_mem_s;
   

   
endinterface : v_core_if

`endif
