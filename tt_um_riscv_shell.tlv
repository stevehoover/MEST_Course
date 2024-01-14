\m5_TLV_version 1d: tl-x.org
\m5
   use(m5-1.0)
   
   // ---SETTINGS---
   var(my_design, tt_um_riscv_cpu) /// Change to tt_um_<your-github-username>_riscv_cpu. (See Tiny Tapeout repo README.md.)
   var(debounce_inputs, 0)         /// Set to 1 to provide synchronization and debouncing on all input signals.
                                   /// use "m5_neq(m5_MAKERCHIP, 1)" to debounce unless in Makerchip.
   // --------------
   
   // If debouncing, a user's module is within a wrapper, so it has a different name.
   var(user_module_name, m5_if(m5_debounce_inputs, my_design, m5_my_design))
   var(debounce_cnt, m5_if_eq(m5_MAKERCHIP, 1, 8'h03, 8'hff))
   
   TLV_fn(riscv_sum_prog, {
      ~assemble(['
         # /====================\
         # | Sum 1 to 9 Program |
         # \====================/
         #
         # Program for RISC-V Workshop to test RV32I
         # Add 1,2,3,...,9 (in that order).
         #
         # Regs:
         #  x10 (a0): In: 0, Out: final sum
         #  x12 (a2): 10
         #  x13 (a3): 1..10
         #  x14 (a4): Sum
         # 
         # External to function:
         reset:
            ADD x10, x0, x0             # Initialize r10 (a0) to 0.
         # Function:
            ADD x14, x10, x0            # Initialize sum register a4 with 0x0
            ADDI x12, x10, 10            # Store count of 10 in register a2.
            ADD x13, x10, x0            # Initialize intermediate sum register a3 with 0
         loop:
            ADD x14, x13, x14           # Incremental addition
            ADDI x13, x13, 1            # Increment count register by 1
            BLT x13, x12, loop          # If a3 is less than a2, branch to label named <loop>
         done:
            ADD x10, x14, x0            # Store final result to register a0 so that it can be read by main program

         # Optional:
            JAL x7, 00000000000000000000  # Done. Jump to itself (infinite loop). (Up to 20-bit signed immediate plus implicit 0 bit (unlike JALR) provides byte address; last immediate bit should also be 0)
      '])
   })
   
\SV
   // Include Tiny Tapeout Lab.
   m4_include_lib(['https://raw.githubusercontent.com/os-fpga/Virtual-FPGA-Lab/84e7c389a63b4fbb5483238146168ed4188d1b8b/tlv_lib/tiny_tapeout_lib.tlv'])   
   m4_include_lib(['https://raw.githubusercontent.com/stevehoover/MEST_Course/master/tlv_lib/risc-v_shell_lib.tlv'])

   // Strict checking.
   `default_nettype none


\TLV cpu()
   
   m5+riscv_gen()
   m5+riscv_sum_prog()
   m5_define_hier(IMEM, m5_NUM_INSTRS)
   |cpu
      @0
         $reset = *reset;

      // ==============
      // Your Code Here
      // ==============

      // Note: Because of the magic we are using for visualisation, if visualisation is enabled below,
      //       be sure to avoid having unassigned signals (which you might be using for random inputs)
      //       other than those specifically expected in the labs. You'll get strange errors for these.

   
   // Assert these to end simulation (before Makerchip cycle limit).
   *passed = *top.cyc_cnt > 40;
   *failed = 1'b0;
   
   // Connect Tiny Tapeout outputs.
   // Note that my_design will be under /fpga_pins/fpga.
   *uo_out = {6'b0, *failed, *passed};
   *uio_out = 8'b0;
   *uio_oe = 8'b0;
   
   // Macro instantiations to be uncommented when instructed for:
   //  o instruction memory
   //  o register file
   //  o data memory
   //  o CPU visualization
   |cpu
      //m4+imem(@1)    // Args: (read stage)
      //m4+rf(@1, @1)  // Args: (read stage, write stage) - if equal, no register bypass is required
      //m4+dmem(@4)    // Args: (read/write stage)

   //m4+cpu_viz(@4)    // For visualisation, argument should be at least equal to the last stage of CPU logic. @4 would work for all labs.


\SV


// ================================================
// A simple Makerchip Verilog test bench driving random stimulus.
// Modify the module contents to your needs.
// ================================================

// Include the Makerchip module only in Makerchip. (Only because Yosys chokes on $urandom.)
m4_ifelse_block(m5_MAKERCHIP, 1, ['

module top(input logic clk, input logic reset, input logic [31:0] cyc_cnt, output logic passed, output logic failed);
   // Tiny tapeout I/O signals.
   logic [7:0] ui_in, uio_in, uo_out, uio_out, uio_oe;
   assign ui_in = 8'b0;
   assign uio_in = 8'b0;
   logic ena = 1'b0;
   logic rst_n = ! reset;
      
   // Instantiate the Tiny Tapeout module.
   m5_user_module_name tt(.*);
   
   assign passed = uo_out[0];
   assign failed = uo_out[1];
endmodule

'])   /// end Makerchip-only

// Provide a wrapper module to debounce input signals if requested.
m5_if(m5_debounce_inputs, ['m5_tt_top(m5_my_design)'])
// The above macro expands to multiple lines. We enter a new \SV block to reset line tracking.
\SV



// =======================
// The Tiny Tapeout module
// =======================

module m5_user_module_name (
    input  wire [7:0] ui_in,    // Dedicated inputs - connected to the input switches
    output wire [7:0] uo_out,   // Dedicated outputs - connected to the 7 segment display
    input  wire [7:0] uio_in,   // IOs: Bidirectional Input path
    output wire [7:0] uio_out,  // IOs: Bidirectional Output path
    output wire [7:0] uio_oe,   // IOs: Bidirectional Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);
   logic passed, failed;  // Connected to uo_out[0] and uo_out[1] respectively, which connect to Makerchip passed/failed.

   wire reset = ! rst_n;
   
\TLV
   /* verilator lint_off UNOPTFLAT */
   // Connect Tiny Tapeout I/Os to Virtual FPGA Lab.
   m5+tt_connections()
   
   // Instantiate the Virtual FPGA Lab.
   m5+board(/top, /fpga, 7, $, , cpu)
   // Label the switch inputs [0..7] (1..8 on the physical switch panel) (bottom-to-top).
   m5+tt_input_labels_viz(['"UNUSED", "UNUSED", "UNUSED", "UNUSED", "UNUSED", "UNUSED", "UNUSED", "UNUSED"'])

\SV
endmodule
