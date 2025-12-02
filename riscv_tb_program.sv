`timescale 1ns/1ps

program automatic riscv_tb (cpu_if.TB intf);

    // Local integer for loops
    int i;

    initial begin
      // ---------- Initialize Memories ----------
      for (i = 0; i < 32; i++) intf.data_memory[i] = i;
      //CPU’s register file resides inside the interface, NOT inside the CPU RTL.
      for (i = 0; i < 32;  i++) intf.register_file[i] = 0;

      // ---------- Load Instruction Memory ----------
      intf.instruction_memory[0]  = 32'b000000001010_00000_000_00001_0010011; // ADDI x1, x0, 10
      intf.instruction_memory[1]  = 32'b000000010100_00000_000_00010_0010011; // ADDI x2, x0, 20
      intf.instruction_memory[2]  = 32'b000000011111_00000_010_00100_0000011; // LW x4, 31(x0)
      intf.instruction_memory[3]  = 32'b000000001100_00000_010_00101_0000011; // LW x5, 12(x0)
      intf.instruction_memory[4]  = 32'b0000000_00010_00001_000_00011_0110011; // ADD x3, x1, x2
      intf.instruction_memory[5]  = 32'b0100000_00001_00010_000_00110_0110011; // SUB x6, x2, x1
      intf.instruction_memory[6]  = 32'b0000000_00010_00001_100_00111_0110011; // XOR x7, x1, x2
      intf.instruction_memory[7]  = 32'b0000000_00010_00001_110_01000_0110011; // OR x8, x1, x2
      intf.instruction_memory[8]  = 32'b0000000_00010_00001_111_01001_0110011; // AND x9, x1, x2
      intf.instruction_memory[9]  = 32'b0000000_00011_00000_010_00011_0100011; // SW x3, 3(x0)
      intf.instruction_memory[10] = 32'b0000000_00011_00000_010_00100_0100011; // SW x3, 4(x0)
      intf.instruction_memory[11] = 32'b0000000_00110_00000_010_00110_0100011; // SW x6, 6(x0)
      intf.instruction_memory[12] = 32'b0000000_00111_00000_010_00111_0100011; // SW x7, 7(x0)
      intf.instruction_memory[13] = 32'b0000000_01000_00000_010_01000_0100011; // SW x8, 8(x0)
      intf.instruction_memory[14] = 32'b0000000_01001_00000_010_01001_0100011; // SW x9, 9(x0)
      intf.instruction_memory[15] = 32'b111110111111_00000_000_01010_0010011; // ADDI x10, x0, 4294967231
      intf.instruction_memory[16] = 32'b111110101011_00000_000_01011_0010011; // ADDI x11, x0, 4294967211
      intf.instruction_memory[17] = 32'b0;                                    // NOP 
      intf.instruction_memory[18] = 32'b0;                                    // NOP      
      intf.instruction_memory[19] = 32'b0000000_01011_01010_001_01100_0110011; // NAND x12, x10, x11
      intf.instruction_memory[20] = 32'b0000000_01011_01010_010_01101_0110011; // NOR x13, x10, x11
      intf.instruction_memory[21] = 32'b111111111111_01010_001_01110_0010011; // NANDI x14, x10, 4294967295
      intf.instruction_memory[22] = 32'b000000100001_01010_010_01111_0010011; // NORI x15, x10, 33

      // ---------- Reset ----------(This is a synchronous reset sequence.)
      intf.reset = 1;
      @(posedge intf.clk);  //Pause until the clock rises, then continue.
      intf.reset = 0;

      // ---------- Display Header ----------
      $display("\n Values at beginning: \n Time(ns) | PC | x0  x1  x2  x3  x4  x5  x6  x7  x8  x9  x10 x11 x12 x13 x14 x15 x16 x17 x18 x19 x20 x21 x22 x23 x24 x25 x26 x27 x28 x29 x30 x31 | Mem[0:31]");
      $display("----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------");

      //---------First Print---------
      $display("Time=%0t | PC=%0d | %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d | \
      %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d",
          $time, intf.PC,
          intf.register_file[0], intf.register_file[1], intf.register_file[2], intf.register_file[3],
          intf.register_file[4], intf.register_file[5], intf.register_file[6], intf.register_file[7],
          intf.register_file[8], intf.register_file[9], intf.register_file[10], intf.register_file[11],
          intf.register_file[12], intf.register_file[13], intf.register_file[14], intf.register_file[15],
          intf.register_file[16], intf.register_file[17], intf.register_file[18], intf.register_file[19],
          intf.register_file[20], intf.register_file[21], intf.register_file[22], intf.register_file[23],
          intf.register_file[24], intf.register_file[25], intf.register_file[26], intf.register_file[27],
          intf.register_file[28], intf.register_file[29], intf.register_file[30], intf.register_file[31],
          intf.data_memory[0], intf.data_memory[1], intf.data_memory[2], intf.data_memory[3],
          intf.data_memory[4], intf.data_memory[5], intf.data_memory[6], intf.data_memory[7],
          intf.data_memory[8], intf.data_memory[9], intf.data_memory[10], intf.data_memory[11],
          intf.data_memory[12], intf.data_memory[13], intf.data_memory[14], intf.data_memory[15],
          intf.data_memory[16], intf.data_memory[17], intf.data_memory[18], intf.data_memory[19],
          intf.data_memory[20], intf.data_memory[21], intf.data_memory[22], intf.data_memory[23],
          intf.data_memory[24], intf.data_memory[25], intf.data_memory[26], intf.data_memory[27],
          intf.data_memory[28], intf.data_memory[29], intf.data_memory[30], intf.data_memory[31]
      );

      // ---------- Run and Monitor ----------
      for (int instr = 0; instr < 32; instr++) begin  //It runs exactly 32 cycles.
          @(posedge intf.clk);  //This loop waits for a posedge for each iteration.

          // Display register and memory snapshot
          $monitor("Time=%0t | PC=%0d | %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d | \
              %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d",
              $time, intf.PC,
              intf.register_file[0], intf.register_file[1], intf.register_file[2], intf.register_file[3],
              intf.register_file[4], intf.register_file[5], intf.register_file[6], intf.register_file[7],
              intf.register_file[8], intf.register_file[9], intf.register_file[10], intf.register_file[11],
              intf.register_file[12], intf.register_file[13], intf.register_file[14], intf.register_file[15],
              intf.register_file[16], intf.register_file[17], intf.register_file[18], intf.register_file[19],
              intf.register_file[20], intf.register_file[21], intf.register_file[22], intf.register_file[23],
              intf.register_file[24], intf.register_file[25], intf.register_file[26], intf.register_file[27],
              intf.register_file[28], intf.register_file[29], intf.register_file[30], intf.register_file[31],
              intf.data_memory[0], intf.data_memory[1], intf.data_memory[2], intf.data_memory[3],
              intf.data_memory[4], intf.data_memory[5], intf.data_memory[6], intf.data_memory[7],
              intf.data_memory[8], intf.data_memory[9], intf.data_memory[10], intf.data_memory[11],
              intf.data_memory[12], intf.data_memory[13], intf.data_memory[14], intf.data_memory[15],
              intf.data_memory[16], intf.data_memory[17], intf.data_memory[18], intf.data_memory[19],
              intf.data_memory[20], intf.data_memory[21], intf.data_memory[22], intf.data_memory[23],
              intf.data_memory[24], intf.data_memory[25], intf.data_memory[26], intf.data_memory[27],
              intf.data_memory[28], intf.data_memory[29], intf.data_memory[30], intf.data_memory[31]
          );
      end
      
      // ---------- Finish ----------
      //$display("\nSimulation finished at time %0t ns", $time);
      
      $finish;
    end
endprogram
