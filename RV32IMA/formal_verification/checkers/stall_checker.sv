module stall_checker
  (
   input clk,
   input reset,
   input stall
   );
   
      
   default clocking @(posedge clk); endclocking   
   default disable iff reset;
   // stall lasts not more than two cycles
   2clk_stall_check: assert property(!stall ##1 stall |=> [*0:1] stall);
      
endmodule

  
