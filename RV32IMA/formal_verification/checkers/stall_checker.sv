module stall_checker
  (
   input logic 		clk,
   input logic 		reset,
   
   input logic [4 : 0] 	rs1,
   input logic [4 : 0] 	rs2,
   input logic [6 : 0] 	opcode,   
   input logic 		stall,   
   input logic [1 : 0] 	branch_id_s,
   input logic [4 : 0] 	rd_ex_s,
   input logic [2 : 0] 	funct3
   );
   
   logic 	       load_2_clk_stall;
   logic [6 : 0]       prev_opcode;
   logic [6 : 0]       prev_funct3;
   

   default clocking @(posedge clk); endclocking   
   default disable iff !reset;
   
   always @(posedge clk)begin
      if (reset == 0)begin
	 prev_opcode <= 0;
	 prev_funct3 <= 0;
      end 
      else begin
	 prev_opcode <= opcode;
	 prev_funct3 <= funct3;
      end 
   end 
   
   
   assign load2_clk_stall = (branch_id_s == 2'b01) && (rs1 == rs2) && rd_ex_s == rs1 && funct3 == 3'b000 && (prev_opcode) == 7'b0000011;
   
   //check if 2 clk stall will happen when beq is in id and load in exe
   beq_after_load_stall: assert property(load2_clk_stall |-> not(stall ##1 !stall));
   // maximum 2 clk stall
   max_2_clk_stall_check:assert property (not(stall[*3]));


      
   
   
endmodule


