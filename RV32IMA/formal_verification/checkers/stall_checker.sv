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
   
   //Assert that load in EX causes a stall when rs1_id = rd_ex for all instructions except JAL, LUI, AUIPC and nop
   assign opcode_check = (opcode != 7'b0110111 && opcode != 7'b0010111 && opcode != 7'b1101111 && opcode != 0) && $past(opcode) == 7'b0000011;   
   load_in_ex: assert property (nexttime always( opcode_check && !$past(stall) && (rs1_id == rd_ex_s) |-> stall)); // BUG_found
  
   //Assert rs2_id == rd_ex shouldn't cause a stall when I-type, AUIPC, LUI, JAL, NOP  instruction are in ID and load in EX phase
   assign opcode_check_for_I = (opcode == 7'b0110111 || opcode == 7'b0010111 || opcode == 7'b1101111 || opcode == 0 || opcode == 7'b0010011) && $past(opcode) == 7'b0000011;	// 
   load_in_ex_I_in_id: assert property (rs2_id == rd_ex_s && rs1_id != rd_ex_s && opcode_check_for_I |-> !stall);
   
endmodule
