module forwarding_unit_checker
(
 
 input logic 	      reset,
 input logic 	      clk,
 
 input logic 	      reg_write_mem_i,
 input logic [4 : 0]  rd_address_mem_i,
 
 // wb inputs
 input logic 	      reg_write_wb_i,
 input logic [4 : 0]  rd_address_wb_i,

 // ex inputs
 input logic [4 : 0]  rs1_address_ex_i,
 input logic [4 : 0]  rs2_address_ex_i,

 //id inputs
 input logic [4 : 0]  rs1_address_id_i,
 input logic [4 : 0]  rs2_address_id_i,
 //forward control outputs
 input logic [1 : 0] alu_forward_a_o,
 input logic [1 : 0] alu_forward_b_o,
 //forward control outputs
 //They control multiplexers infront of equality test
 input logic [1 : 0] branch_forward_a_o,
 input logic [1 : 0] branch_forward_b_o
 );
   logic 	     forward_both;
   
   default clocking @(posedge clk); endclocking
   default disable iff reset;

   assign forward_both = (rs1_address_ex_i == rs2_address_ex_i) & ((rs1_address_ex_i == rd_address_mem_i & reg_write_mem_i) || (rs1_address_ex_i == rd_address_wb_i & reg_write_wb_i));   

   
   mem_over_wb_alu: assert property (always (rd_address_wb_i == rd_address_mem_i && (reg_write_mem_i == reg_write_wb_i)) |-> (alu_forward_a_o != 2'b01 && alu_forward_b_o != 2'b01));
   mem_over_wb_branch: assert property (always (rd_address_wb_i == rd_address_mem_i && (reg_write_mem_i == reg_write_wb_i)) |-> (branch_forward_a_o != 2'b01 && branch_forward_b_o != 2'b01));
   forward_both_rs1_and_rs2: assert property (always (forward_both) |-> alu_forward_a_o == alu_forward_b_o);
   
   

   


endmodule
