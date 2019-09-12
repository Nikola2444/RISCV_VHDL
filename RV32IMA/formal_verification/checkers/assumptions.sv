module assumptions
   (input logic clk,
    input logic 	reset,
    input logic 	stall,
    input logic 	flush,
    input logic [31 : 0] instruction);
   
   default clocking @(posedge clk); endclocking
   default disable iff !reset;

   assign opcode = instruction [6 : 0];
  
   opcode_constraint: assume property (instruction[6 : 0] == 7'b0000011 || instruction[6 : 0] == 7'b1100011 || instruction[6 : 0] == 7'b0110011 ||
				       instruction[6 : 0] == 7'b0010011 || instruction[6 : 0] == 7'b0010111 || instruction[6 : 0] == 7'b1100111 ||
				       instruction[6 : 0] == 7'b1101111 || instruction[6 : 0] == 7'b0100011 || instruction[6 : 0] == 7'b0110111 || instruction[6 : 0] == 7'b0000000);


   stall_constraint: assume property (!stall |=> instruction == $past(instruction));
   flush_constraint: assume property (flush |=> instruction == 0);
   
   
  endmodule
