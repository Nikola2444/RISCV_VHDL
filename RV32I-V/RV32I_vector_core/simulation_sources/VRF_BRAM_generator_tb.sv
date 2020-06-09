

module VRF_BRAM_addr_generator_tb #(parameter VECTOR_LENGTH = 1024) ();
   
   


      

   logic clk;   
   logic reset;   
   logic [1:0 ] vrf_type_of_access_i  = 2'b11;
   logic [ 4: 0] vs1_address_i = 0; 
   logic [4 : 0] vs2_address_i = 1;
   
   logic [ 4: 0] vd_address_i = 0; 
   logic [$clog2(VECTOR_LENGTH/32) : 0 ] vector_length_i  = 7'b100000;
   logic [$clog2(VECTOR_LENGTH) - 1 : 0 ] BRAM1_r_address_o;   
   logic [$clog2(VECTOR_LENGTH ) - 1 : 0 ] BRAM1_w_address_o;   
   logic 				       BRAM1_we_o;
   logic 				       BRAM1_re_o;
   
   logic [$clog2(VECTOR_LENGTH ) - 1 : 0 ] BRAM2_r_address_o;   
   logic [$clog2(VECTOR_LENGTH ) - 1 : 0 ] BRAM2_w_address_o;   
   logic 				       BRAM2_we_o;
   logic 				       BRAM2_re_o;
   logic 				       ready_o;
   logic [1 :0] 			       vmul_i = 2'b00;   
   logic [2:0 ] 			       alu_exe_time_i = 4;
   logic [$clog2(VECTOR_LENGTH ) - 1 : 0 ]     mask_BRAM_r_address_o;
   logic 				       mask_BRAM_we_o;

   VRF_BRAM_addr_generator
     #(
       .VECTOR_LENGTH(1024))      
   DUT(
       .clk(clk),
       .reset(reset),
       .vrf_type_of_access_i (vrf_type_of_access_i),
       .alu_exe_time_i (alu_exe_time_i),
       .vs1_address_i(vs1_address_i),
       .vs2_address_i (vs2_address_i),
       .vd_address_i        (vd_address_i),
       .vmul_i(vmul_i),
       .vector_length_i     (vector_length_i),
       .BRAM1_r_address_o    (BRAM1_r_address_o),
       .BRAM_w_address_o    (BRAM1_w_address_o),
       .BRAM_we_o (BRAM1_we_o),
       .BRAM_re_o(BRAM1_re_o),
       .BRAM2_r_address_o (BRAM2_r_address_o),     
       .mask_BRAM_r_address_o(mask_BRAM_r_address_o),
       .mask_BRAM_we_o(mask_BRAM_we_o),
       .ready_o (ready_o));

   always #50 clk = ~clk;

   initial begin
       clk <= 1;       
       reset <= 1'b0;
       #200 reset = 1;       	        
   end 
   int i = 0;
   
   initial  begin
      forever begin
         if (ready_o == 1) begin
           @(posedge clk); 
             vrf_type_of_access_i <= vrf_type_of_access_i + i;	     
             i = i + 1;	     
         end;	  
	  #1;
	  
      end ;
      
   end 
   
endmodule
