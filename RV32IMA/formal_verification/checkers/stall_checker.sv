module stall_checker
  (
   input logic 		clk,
   input logic 		reset,   
   input logic [4 : 0] 	rs1_id,
   input logic [4 : 0] 	rs2_id,
   input logic [6 : 0] 	opcode,   
   input logic 		stall,   
   input logic [4 : 0] 	rd_ex_s
   );
   
   logic 		branch_forward_check;

   

   default clocking @(posedge clk); endclocking   
   default disable iff !reset;
   
   
   
   assign branch_forward_check = (rd_ex_s == rs1_id) || (rd_ex_s == rs2_id);
   
   
   //check if 2 clk stall will only happen when beq is in id and load is in exe and rs1_id = rd_ex or rs2_id = rd_ex
   beq_after_load_stall: assert property(!(branch_forward_check && $past(opcode) == 7'b0000011 && opcode == 7'b1100011)  |-> not(stall[*2]));
   // maximum 2 clk stall
   max_2_clk_stall_check:assert property (not(stall[*3]));
   //Jal doesn't cause a stall
   jal_instr_stall:assert property (stall |-> opcode != 7'b1101111);
   
   //Conditional branches cause 0 or 1 or 2 clk stalls
   conditional_b_stall: assert property (opcode == 7'b1100011 |-> !stall or (stall ##1 !stall) or stall[*2]);

   // TODO: load before R, exactly one clk stall
;
   // Assert no stall when lui after lw
   //load_before_lui: assert property (opcode == 7'b0000011 ##1 (opcode == 7'b0110111 || opcode == 7'b0010111 || opcode == 7'b1101111) |-> !stall); // BUG

   //Assert only one stall when LOAD, R sequence appears
   assign load_R_stall = (rs1_id == rd_ex_s) && $past(opcode) == 7'b0000011 && opcode == 7'b1100111;//rs2 shouldn't stall for every instruction. I type for example
   
   //load_R_1_clk_stall: assert property (##1 load_R_stall |-> stall);// THIS found a bug

   load_before_jalr: assert property (##1 load_R_stall |-> stall);// THIS found a bug


   
endmodule
