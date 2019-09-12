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
   logic [6 : 0] 	prev_opcode;
   

   default clocking @(posedge clk); endclocking   
   default disable iff !reset;
   
   always @(posedge clk)begin
      if (reset == 0)begin
	 prev_opcode <= 0;
      end 
      else begin
	 prev_opcode <= opcode;	 
      end 
   end 
   
   
   assign branch_forward_check = (rd_ex_s == rs1_id) || (rd_ex_s == rs2_id);
   
   
   //check if 2 clk stall will only happen when beq is in id and load is in exe and rs1_id = rd_ex or rs2_id = rd_ex
   beq_after_load_stall: assert property(!(branch_forward_check && prev_opcode == 7'b0000011 && opcode == 7'b1100011)  |-> not(stall[*2]));
   // maximum 2 clk stall
   max_2_clk_stall_check:assert property (not(stall[*3]));
   //Jal and Jarl don't cause a stall
   jal_instr_stall:assert property (stall |-> opcode != 7'b1101111 and opcode != 7'b1100111);
   
   //Conditional branches cause 0 or 1 or 2 clk stalls
   conditional_b_stall: assert property (opcode == 7'b1100011 |-> !stall or (stall ##1 !stall) or stall[*2]);

   // TODO: load before R, exactly one clk stall
   
endmodule
