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
   logic 		 known_instr_check;
   logic [6 : 0] 	 instruction_opcodes[9] = {7'h13, 7'h37, 7'h23, 7'h33, 7'h63, 7'h67, 7'h6f, 7'h17, 7'h17};
   
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
   
   always @(opcode_id_i)begin
      for (int i = 0; i < 9; i++)begin
	 if ((opcode_mem_r) == instruction_opcodes[i])begin
	    known_instr_check = 1;
	    break;	    
	 end
	 else
	   known_instr_check = 0;	 
      end
   end

   
   assign mem_alu_forward_a_check = $past(rs1_address_ex_r) == $past(rd_address_mem_i) && reg_write_i && $past(rd_address_mem_i) != 0;

   assign mem_alu_forward_b_check = $past(rs2_address_ex_r) == $past(rd_address_mem_i) && reg_write_i && $past(rd_address_mem_i) != 0;

   assign wb_alu_forward_b_check = $past(rs2_address_ex_r) == $past(rd_address_wb_i) && $past(reg_write_i) && $past(rd_address_wb_i) != 0 && !$past(mem_alu_forward_b_check);

   
   //opcode_contraint: assume property ()
   mem_alu_a_forward_assert: assert property (mem_alu_forward_a_check && opcode_mem_r != 7'b0010111 && opcode_mem_r != 7'b0110111|-> $past(alu_result_mem_i) == $past(alu_in_a_i));

   
   mem_alu_b_forward_assert: assert property (mem_alu_forward_b_check && (known_instr_check) && (opcode_mem_r == 7'b1101111 || opcode_mem_r == 7'b0110011) |-> $past(alu_result_mem_i) == $past(alu_in_b_i));

   wb_alu_b_forward_assert: assert property (wb_alu_forward_b_check && known_instr_check && ($past(opcode_ex_r) == 7'b0110011 || $past(opcode_ex_r) != 7'h6f) |-> $past(rd_data_wb_i) == $past(alu_in_b_i));
   
   
   

endmodule
