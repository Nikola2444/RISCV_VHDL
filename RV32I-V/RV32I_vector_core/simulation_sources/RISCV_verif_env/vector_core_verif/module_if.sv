`ifndef CALC_IF_SV
 `define CALC_IF_SV
import configurations_pkg::*;   
interface v_core_if (input clk, logic reset);
   
   logic [31 : 0] vector_instruction_i;
   logic [31 : 0] rs1_i;  
   logic [31 : 0] rs2_i;

   //Scalar core load and store interface
   logic 	  scalar_load_req_i;
   logic 	  scalar_store_req_i;
   logic [31 : 0] scalar_address_i;

   //Vector core status signal
   logic 	  vector_stall_s;


   //Interconnections between data memory and vector core
   logic 	  mem_we_s;
   logic 	  mem_re_s;
   logic [31 : 0] store_address_s ;
   logic [31 : 0] load_address_s ;
   logic [31 : 0] data_from_mem_s;
   logic [31 : 0] data_to_mem_s;
   

   
endinterface : v_core_if

`endif
