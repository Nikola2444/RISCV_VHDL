module assumptions
   (input logic clk,
    input logic 	reset,
    input logic 	stall,
    input logic 	flush,
    input logic [31 : 0] instruction);
   
   default clocking @(posedge clk); endclocking
   default disable iff !reset;

/* -----\/----- EXCLUDED -----\/-----
   opcode_constraint: assume property (opcode == 7'b0000011 || opcode == 7'b1100011 || opcode == 7'b0110011 ||
				       opcode == 7'b0010011 || opcode == 7'b0010111 || opcode == 7'b1100111 ||
				       opcode == 7'b1101111 || opcode == 7'b0100011 || opcode == 7'b0110111);
 -----/\----- EXCLUDED -----/\----- */

   stall_constraint: assume property (!stall |=> instruction == $past(instruction));
   flush_constraint: assume property (flush |=> instruction == 0);
   
   
  endmodule
