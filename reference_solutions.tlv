\m5_TLV_version 1d: tl-x.org
\m5
   use(m5-1.0)

   // ==========================================
   // Provides reference solutions
   // without visibility to source code.
   // ==========================================
   
   // ----------------------------------
   // Instructions:
   //    - When stuck on a particular lab, provide the LabId below, and compile/simulate.
   //    - A reference solution will build, but the source code will not be visible.
   //    - You may use waveforms, diagrams, and visualization to understand the proper circuit, but you
   //      will have to come up with the code. Logic expression syntax can be found by hovering over the
   //      signal assignment in the diagram.
   // ----------------------------------
   
   // Provide the Lab ID given at the lower right of the slide.
   var(LabId, DONE)



   // ================================================
   // No need to touch anything below this line.

   // Is this a calculator lab?
   var(CalcLab, m5_if_regex(m5_LabId, ^\(C\)-, (C), 1, 0))
   // ---SETTINGS---
   var(my_design, m5_if(m5_CalcLab, tt_um_calc, tt_um_riscv_cpu)) /// Change to tt_um_<your-github-username>_riscv_cpu. (See Tiny Tapeout repo README.md.)
   var(debounce_inputs, 0)         /// Set to 1 to provide synchronization and debouncing on all input signals.
                                   /// use "m5_neq(m5_MAKERCHIP, 1)" to debounce unless in Makerchip.
   // --------------
   
   // If debouncing, a user's module is within a wrapper, so it has a different name.
   var(user_module_name, m5_if(m5_debounce_inputs, my_design, m5_my_design))
   var(debounce_cnt, m5_if_eq(m5_MAKERCHIP, 1, 8'h03, 8'hff))
\SV
   // Include Tiny Tapeout Lab.
   m4_include_lib(['https:/']['/raw.githubusercontent.com/os-fpga/Virtual-FPGA-Lab/79e40995aab07f65c1616c30c046f26893de3df5/tlv_lib/tiny_tapeout_lib.tlv'])   

   // Strict checking.
   `default_nettype none

   // Default Makerchip TL-Verilog Code Template
   m4_include_makerchip_hidden(['mest_course_solutions.private.tlv'])


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
   m5+board(/top, /fpga, 7, $, , hidden_solution)
   // Label the switch inputs [0..7] (1..8 on the physical switch panel) (bottom-to-top).
   m5+tt_input_labels_viz(['"UNUSED", "UNUSED", "UNUSED", "UNUSED", "UNUSED", "UNUSED", "UNUSED", "UNUSED"'])

\SV
endmodule
