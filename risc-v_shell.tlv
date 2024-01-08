\m5_TLV_version 1d: tl-x.org
\SV
   // This code can be found in: https://github.com/stevehoover/MEST_Course
   
   m4_include_lib(['https://raw.githubusercontent.com/stevehoover/MEST_Course/master/tlv_lib/risc-v_shell_lib.tlv'])

\SV
   m4_makerchip_module   // (Expanded in Nav-TLV pane.)
\m5
   
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
   
   
\TLV
   m5+riscv_gen()
   m5+riscv_sum_prog()
   m5_define_hier(IMEM, m5_NUM_INSTRS)
   |cpu
      @0
         $reset = *reset;



      // YOUR CODE HERE
      // ...

      // Note: Because of the magic we are using for visualisation, if visualisation is enabled below,
      //       be sure to avoid having unassigned signals (which you might be using for random inputs)
      //       other than those specifically expected in the labs. You'll get strange errors for these.

   
   // Assert these to end simulation (before Makerchip cycle limit).
   *passed = *cyc_cnt > 40;
   *failed = 1'b0;
   
   // Macro instantiations for:
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
   endmodule
