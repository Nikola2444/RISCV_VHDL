
module pc_checker
  (
   input logic 		clk,
   input logic 		reset,
   input logic [31 : 0] pc_reg,  
   input logic [6 : 0] 	opcode_id
  
   );

   
   logic [6 : 0] 	opcode_ex;
   logic [6 : 0] 	opcode_mem;
   logic 		no_jump_in_id;
   logic 		no_jump_in_ex;
   logic 		no_jump_in_mem;
   logic 		no_jump_in_id_ex_mem;
   logic [31 : 0] 	pc_reg_prev;
   
   default clocking @(posedge clk); endclocking   
   default disable iff !reset;

   always @(posedge clk)begin
      if (!reset) begin
	 opcode_ex <= 0;
	 opcode_mem <= 0;
	 pc_reg_prev <= 0;	 
      end
      else begin
	 opcode_ex <= opcode_id;
	 opcode_mem <= opcode_ex;
	 pc_reg_prev <= pc_reg;
      end 
   end 
   // Asserts that pc increments by 4 or stays the same if in ID, EXE, MEM there is a non jump instruction
   assign no_jump_in_id = opcode_id != 7'b1100011 && opcode_id != 7'b1101111 && opcode_id != 7'b1100111;
   assign no_jump_in_ex = opcode_ex != 7'b1100011 && opcode_ex != 7'b1101111 && opcode_ex != 7'b1100111;
   assign no_jump_in_mem = opcode_mem != 7'b1100111;       
   assign no_jump_in_id_ex_mem = no_jump_in_id  &&  no_jump_in_ex  && no_jump_in_mem;
 
   pc_assert: assert property (no_jump_in_id_ex_mem |-> (pc_reg_prev == pc_reg || pc_reg_prev == pc_reg - 4));
endmodule
