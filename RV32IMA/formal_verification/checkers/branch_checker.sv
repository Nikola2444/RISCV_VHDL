module branch_checker
  (
   input logic 		clk,
   input logic 		reset,
   input logic [6 : 0] 	opcode,
   input logic [1 : 0] 	pc_next_sel_i,
   input logic [31 : 0] pc_reg_ex_s,
   input logic [31 : 0] pc_reg_if_s,
   input logic [31 : 0] immediate_extended_ex_s
   );
   

   logic [6 : 0] 	prev_opcode;   
   
   default clocking @(posedge clk); endclocking   
   default disable iff !reset;

   //design for ferificaion
   always @(posedge clk)begin
      if (!reset)begin
	 prev_opcode <= 0;
      end
      else begin
	 prev_opcode <= opcode;
      end 
   end 
   //Asserts that pc_next takes ALU output when JAL is in ID and JALR is in EX phase.
   jall_id_jalr_ex: assert property ((prev_opcode == 7'b1100111) && (opcode == 7'b1101111) |-> pc_next_sel_i == 2'b11);
   //Asserts that pc_next takes ALU output when B-type instruction is in ID and JALR is in EX phase.
   branch_id_jalr_ex: assert property ((prev_opcode == 7'b1100111) && (opcode == 7'b1100011) |-> pc_next_sel_i == 2'b11);

   //Checks if JAL jumps to appropriate loacation... 
   pc_next_position_check: assert property (opcode == 7'b1101111 && $past(opcode) != 7'b1100111 |=> pc_reg_if_s == pc_reg_ex_s  + immediate_extended_ex_s);
   
   //TODO: Checks if Conditional jumps and JARL jump to appropriate loacation 
   
endmodule
