module forwarding_checker
  (
    input logic 	 reset,
    input logic 	 clk,

    input logic 	 id_ex_flush_i,
    input logic 	 stall,
    input logic [31 : 0] alu_result_mem_i,
    input logic [31 : 0] rd_data_wb_i,
    input logic [31 : 0] alu_in_a_i,
    input logic [31 : 0] alu_in_b_i,

    input logic [4 : 0]  rs1_address_id_i,
    input logic [4 : 0]  rs2_address_id_i,

   
    input logic [6 : 0]  opcode_id_i,
    input logic 	 reg_write_i,
    input logic [4 : 0]  rd_address_mem_i,
    input logic [4 : 0]  rd_address_wb_i   
 
);   

   
   logic 		 alu_forward_a_check;
   logic 		 opcode_check;
   logic [4 : 0] 	 rs1_address_ex_r;
   logic [4 : 0] 	 rs2_address_ex_r;
   logic [6 : 0] 	 opcode_ex_r, opcode_mem_r;
   
   
   default clocking @(posedge clk); endclocking
   default disable iff !reset;
	    
   always @(posedge clk)begin
      if(!reset || !stall || id_ex_flush_i)begin
	 rs1_address_ex_r <= 0;
	 rs2_address_ex_r <= 0;
	 opcode_ex_r <= 0;
      end
      else begin
	 rs1_address_ex_r <= rs1_address_id_i;
	 rs2_address_ex_r <= rs2_address_id_i;
	 opcode_ex_r <= opcode_id_i;	    	 
      end
      opcode_mem_r <= opcode_ex_r;
   end // always @ (posedge clk)
   
   
   
   assign mem_alu_forward_a_check = rs1_address_ex_r == rd_address_mem_i && rd_address_mem_i != 0;

   assign mem_alu_forward_b_check = rs2_address_ex_r == rd_address_mem_i && rd_address_mem_i != 0;

   assign wb_alu_forward_b_check = rs2_address_ex_r == rd_address_wb_i && rd_address_wb_i != 0;
   
   assign wb_alu_forward_a_check = rs1_address_ex_r == rd_address_wb_i && rd_address_wb_i != 0;

   
   // Asserts that correct value will be forwarded to alu input 'a' from mem stage to ex stage
   mem_alu_a_forward_assert: assert property ((mem_alu_forward_a_check && opcode_ex_r != 7'b0010111 && opcode_ex_r != 7'b0110111) ##1 reg_write_i  |-> $past(alu_result_mem_i) == $past(alu_in_a_i ));

   // Asserts that correct value will be forwarded to alu input 'b' from mem stage to ex stage
   mem_alu_b_forward_assert: assert property (mem_alu_forward_b_check && (opcode_ex_r == 7'b1101111 || opcode_ex_r == 7'b0110011) ##1 reg_write_i |-> $past(alu_result_mem_i) == $past(alu_in_b_i));

   // Asserts that correct value will be forwarded to alu input 'b' from wb stage to ex stage when there was no previous forwarding from mem_stage
   wb_alu_b_forward_assert: assert property ((wb_alu_forward_b_check && (opcode_ex_r == 7'b0110011 || opcode_ex_r == 7'h1101111)) and (reg_write_i ##1 !reg_write_i) |-> $past(rd_data_wb_i) == $past(alu_in_b_i));
   // Asserts that correct value will be forwarded to alu input 'a' from wb stage to ex stage when there was no previous forwarding from mem_stage
   wb_alu_a_forward_assert: assert property ((wb_alu_forward_a_check && opcode_ex_r != 7'b0010111 && opcode_ex_r != 7'b0110111) and (reg_write_i ##1 !reg_write_i) |-> $past(rd_data_wb_i) == $past(alu_in_a_i));

   
   
   
   

endmodule
