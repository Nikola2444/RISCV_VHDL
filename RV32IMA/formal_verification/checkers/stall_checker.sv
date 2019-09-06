module stall_checker
  (
   input logic 	       clk,
   input logic [4 : 0] rs1,
   input logic [4 : 0] rs2,
   input logic [6 : 0] opcode,
   input logic 	       reset,
   input logic 	       stall,
   input logic 	       flush
   );
   
   
   default clocking @(posedge clk); endclocking   
   default disable iff reset;

   // stall lasts not more than two cycles
   flush_check: assert property (always @(posedge clk)  (opcode != 7'b1100011 && opcode != 7'b1101111 && opcode != 7'b1100111) |-> !flush);
   
   //stall_2_clk_check: assert property(always @(posedge clk) !stall ##1 stall |=> stall[*1:2]);
   
endmodule


