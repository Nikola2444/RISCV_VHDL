`ifndef INSTRUCTION_CONSTANTS_PKG
  `define INSTRUCTION_CONSTANTS_PKG

package instruction_constants_pkg;

   // Arith instructions funct6
   const logic [5 : 0] v_add_funct6 = 6'b000000; //implemented
   const logic [5 : 0] v_sub_funct6 = 6'b000010;    //implemented
   
   const logic [5 : 0] v_and_funct6 = 6'b001001; //implemented
   const logic [5 : 0] v_or_funct6 = 6'b001010; //implemented
   const logic [5 : 0] v_xor_funct6 = 6'b001011; //implementeda
   
   const logic [5 : 0] v_merge_funct6 = 6'b010111; //implemented
   
   const logic [5 : 0] v_mul_funct6 = 6'b100101; // signed mul //implemented
   const logic [5 : 0] v_mulhsu_funct6 = 6'b100110;// signed (VS2) unsigned mul //implemented
   const logic [5 : 0] v_mulhs_funct6 = 6'b100111; //signed higher mul   //implemented
   const logic [5 : 0] v_mulhu_funct6 = 6'b100100; // unsigned higher mul //implemented
   
   const logic [5 : 0] v_shll_funct6 = 6'b100101; // shift left logic //implemented
   const logic [5 : 0] v_shrl_funct6 = 6'b101000; // shift right logic //implemented
   const logic [5 : 0] v_shra_funct6 = 6'b101001; // shift right arith //implemented

   const logic [5 : 0] v_vmseq_funct6 = 6'b011000 ; // set if equal //implemented
   const logic [5 : 0] v_vmsne_funct6 = 6'b011001 ; // set if not equal //implemented
   const logic [5 : 0] v_vmsltu_funct6 = 6'b011010 ; // set if less than unsigned  //implemented
   const logic [5 : 0] v_vmslt_funct6 = 6'b011011 ; // set if less than signed //implemented
   const logic [5 : 0] v_vmsleu_funct6 = 6'b011100 ; // set if less than or equal unsigned //implemented
   const logic [5 : 0] v_vmsle_funct6 = 6'b011101 ; // set if less than or equal signed //implemented
   const logic [5 : 0] v_vmsgtu_funct6 = 6'b011110 ; // set if greater than or equal unsigned //implemented
   const logic [5 : 0] v_vmsgt_funct6 = 6'b011111 ; // set if greater than or equal signed //implemented

   const logic [5 : 0] v_vminu_funct6 = 6'b000100 ; // unsigned min //implemented
   const logic [5 : 0] v_vmin_funct6 = 6'b000101 ; // signed min   //implemented

   // Instruction opcodes
   const logic [6 : 0] arith_opcode = 7'b1010111;
   const logic [6 : 0] store_opcode = 7'b0100111;
   const logic [6 : 0] load_opcode = 7'b0100111;

   // Diferent types of arith instructions
   const logic [2 : 0] OPIVV_funct3 = 3'b000;
   const logic [2 : 0] OPIVX_funct3 = 3'b100;
   const logic [2 : 0] OPIVI_funct3 = 3'b011;
   const logic [2 : 0] OPMVV_funct3 = 3'b010;
   const logic [2 : 0] OPMVX_funct3 = 3'b110;
   const logic [2 : 0] OPCFG_funct3 = 3'b111;
endpackage

`endif
