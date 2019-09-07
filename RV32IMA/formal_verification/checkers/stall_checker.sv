module stall_checker
  (
   input logic 	       clk,
   input logic [4 : 0] rs1,
   input logic [4 : 0] rs2,
   input logic [6 : 0] opcode,
   input logic 	       reset,
   input logic 	       stall,
   input logic 	       flush_id,
   input logic 	       flush_ex,
   input logic [1 : 0] branch_id_s
   );
   
   logic [6 : 0]       opcode_prev;


   default clocking @(posedge clk); endclocking   
   default disable iff reset;
   
   
   
   // stall lasts not more than two cycles
   //flush_check: assert property (always @(posedge clk)  flush && (opcode_prev != 7'b1100111) |=> !flush);

   stall_2_clk_check: assert property( @(posedge clk) branch_id_s == 2'b01 |=> !stall);
   
   
endmodule


