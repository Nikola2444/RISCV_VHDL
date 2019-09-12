module forwarding_checker
  (
    input logic 	 reset,
    input logic 	 clk,

    input logic 	 id_ex_flush_i,
    input logic 	 stall,
    
    input logic [31 : 0] alu_in_a_i,
    input logic [31 : 0] alu_in_b_i,
    input logic [31 : 0] branch_condition_a_id_s,
    input logic [31 : 0] branch_condition_b_id_s,

    input logic [4 : 0]  rs1_address_id_i,
    input logic [4 : 0]  rs2_address_id_i,
    input logic [4 : 0]  rd_address_mem_i,
    input logic [4 : 0]  rd_address_wb_i,
    input logic 	 reg_write_i,
   
    input logic [6 : 0]  opcode_id_i,

    input logic [31 : 0] alu_result_mem_i,
    input logic [31 : 0] rd_data_wb_i
    
);   

   
   logic [4 : 0] 	 rs1_address_ex_r;
   logic [4 : 0] 	 rs2_address_ex_r;
   
   
   default clocking @(posedge clk); endclocking
   default disable iff !reset;
   // This here is neede because in control path when stall is asserted, rs1 and rs2 are reseted.
   // And because of that forwarding unit doesnt forward, but that is not an error because it should
   // forward to a nop instruction. And this logic is here to reset rs1 and rs2.
   always @(posedge clk)begin
      if(!reset || !stall || id_ex_flush_i)begin
	 rs1_address_ex_r <= 0;
	 rs2_address_ex_r <= 0;	
      end
      else begin
	 rs1_address_ex_r <= rs1_address_id_i;
	 rs2_address_ex_r <= rs2_address_id_i;
      end
   end // always @ (posedge clk)
   

   
   
   
   

   /****************************ASSERTS THAT CHECK FORWARDING TO ALU UNIT**************************/
  
   //Logic needed to formaly verify forwarding to alu unit inputs
   assign mem_alu_forward_a_check = rs1_address_ex_r == rd_address_mem_i && rd_address_mem_i != 0;
   assign ex_alu_a_opcode_check = $past(opcode_id_i) != 7'b0010111 && $past(opcode_id_i) != 7'b0110111;   

   assign mem_alu_forward_b_check = rs2_address_ex_r == rd_address_mem_i && rd_address_mem_i != 0;
   assign ex_alu_b_opcode_check = ($past(opcode_id_i) == 7'b1101111 || $past(opcode_id_i) == 7'b0110011);   

   assign wb_alu_forward_b_check = rs2_address_ex_r == rd_address_wb_i && rd_address_wb_i != 0;
   
   assign wb_alu_forward_a_check = rs1_address_ex_r == rd_address_wb_i && rd_address_wb_i != 0;
  
   
   // Asserts that correct value will be forwarded to alu input 'a' from mem stage to ex stage
   mem_alu_a_forward_assert: assert property ((mem_alu_forward_a_check && ex_alu_a_opcode_check) ##1 reg_write_i |-> $past(alu_result_mem_i) == $past(alu_in_a_i ));

   // Asserts that correct value will be forwarded to alu input 'b' from mem stage to ex stage
   mem_alu_b_forward_assert: assert property (mem_alu_forward_b_check && ex_alu_b_opcode_check ##1 reg_write_i |-> $past(alu_result_mem_i) == $past(alu_in_b_i));

   // Asserts that correct value will be forwarded to alu input 'a' from wb stage to ex stage when there was no previous forwarding from mem_stage
   wb_alu_a_forward_assert: assert property ((wb_alu_forward_a_check && ex_alu_a_opcode_check)  and (reg_write_i ##1 !reg_write_i) |-> $past(rd_data_wb_i) == $past(alu_in_a_i));

   // Asserts that correct value will be forwarded to alu input 'b' from wb stage to ex stage when there was no previous forwarding from mem_stage
   wb_alu_b_forward_assert: assert property ((wb_alu_forward_b_check && ex_alu_b_opcode_check) and (reg_write_i ##1 !reg_write_i) |-> $past(rd_data_wb_i) == $past(alu_in_b_i));
   
   
   /**********************************************************************************************/
   
   
   /****************************ASSERTS THAT CHECK FORWARDING TO BRANCH CONDITION*****************/

   //Logic needed to formaly verify forwarding to branch condition inputs
   assign mem_branch_forward_a_check = rs1_address_id_i == rd_address_mem_i && rd_address_mem_i != 0;
   assign mem_branch_forward_b_check = rs2_address_id_i == rd_address_mem_i && rd_address_mem_i != 0;
   assign wb_branch_forward_b_check = rs2_address_id_i == rd_address_wb_i && rd_address_wb_i != 0;
   assign wb_branch_forward_a_check = rs1_address_id_i == rd_address_wb_i && rd_address_wb_i != 0;

   // Asserts that correct value will be forwarded to branch condition input 'a' from mem stage to id stage
   mem_branch_a_forward_assert:assert property (mem_branch_forward_a_check and ##1 reg_write_i |-> $past(branch_condition_a_id_s) == $past(alu_result_mem_i));

   // Asserts that correct value will be forwarded to branch condition input 'b' from mem stage to id stage
   mem_branch_b_forward_assert:assert property (mem_branch_forward_b_check and ##1 reg_write_i |-> $past(branch_condition_b_id_s) == $past(alu_result_mem_i));

   // Asserts that correct value will be forwarded to branch condition input 'a' from wb stage to id stage
   wb_branch_a_forward_assert:assert property (wb_branch_forward_a_check and (reg_write_i ##1 !reg_write_i) |-> $past(branch_condition_a_id_s) == $past(rd_data_wb_i));
   
   // Asserts that correct value will be forwarded to branch condition input 'b' from wb stage to id stage
   wb_branch_b_forward_assert:assert property (wb_branch_forward_b_check and (reg_write_i ##1 !reg_write_i) |-> $past(branch_condition_b_id_s) == $past(rd_data_wb_i));
   
   
   
   /**********************************************************************************************/
   

endmodule
