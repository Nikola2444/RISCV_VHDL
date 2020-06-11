`ifndef CONFIGURATION_PKG_SV
 `define CONFIGURATION_PKG_SV

package configurations_pkg;

   import uvm_pkg::*;      // import the UVM library   
 `include "uvm_macros.svh" // Include the UVM macros
   parameter DATA_WIDTH = 32;   
   parameter VECTOR_LENGTH = 1024; // this should be a multiple of two (eg. 32, 64, 128, 256, ..)
   
`include "config.sv"


endpackage : configurations_pkg

`endif

