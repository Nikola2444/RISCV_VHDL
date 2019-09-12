module branch_checker
  (
   input logic 		clk,
   input logic 		reset,
   input logic [31 : 0] instruction_id_i,
   input logic 		branch_condition_i,
   input logic [31 : 0] pc_next_if_i,
   input logic [31 : 0] pc_reg_id_i,
   input logic [31 : 0] alu_result_ex_i,
   input logic [31 : 0] branch_adder_id_i,
   input logic 		id_ex_flush_i
   );
   

   
   default clocking @(posedge clk); endclocking   
   default disable iff !reset;

   
   //Asserts that pc_next takes ALU output when JAL is in ID and JALR is in EX phase.   
   jall_id_jalr_ex: assert property ((instruction_id_i[6 : 0] == 7'b1100111) ##1 (instruction_id_i[6 : 0] == 7'b1101111) |-> pc_next_if_i == alu_result_ex_i);
   //Asserts that pc_next takes ALU output when B-type instruction is in ID and JALR is in EX phase.
   branch_id_jalr_ex: assert property ((instruction_id_i[6 : 0] == 7'b1100111) ##1 (instruction_id_i[6 : 0] == 7'b1100011) |-> pc_next_if_i == alu_result_ex_i);

   //Checks if JAL jumps to appropriate loacation... 
   jal_pc_next_position_check: assert property ((instruction_id_i[6 : 0] != 7'b1100111) ##1 (instruction_id_i[6 : 0] == 7'b1101111) |-> pc_next_if_i == branch_adder_id_i);
   
   //Asserts that conditional branch will jump to appropriate location when it is in ID and when JALR is not i EX phase
   assign conditional_branch_check = (instruction_id_i[12] ^ branch_condition_i);   
   cb_pc_next_position_check: assert property (instruction_id_i[6 : 0] != 7'b1100111 ##1 (instruction_id_i[6 : 0] == 7'b1100011 and conditional_branch_check) |-> pc_next_if_i == branch_adder_id_i);

   //Asserts that JALR will jump to appropriate location
   jalr_pc_next_position_check: assert property (nexttime always($past(instruction_id_i[6 : 0]) == 7'b1100111 && !$past(id_ex_flush_i) |-> pc_next_if_i == alu_result_ex_i));
   

   

   
   
endmodule
