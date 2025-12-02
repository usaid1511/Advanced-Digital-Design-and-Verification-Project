`timescale 1ns/1ps

//======================================================
// Class: Rand_Instruction_Generator
// Purpose: To generate random RISC-V instructions
//======================================================
class Rand_Instruction_Generator;

    // ---------- Randomizable Variables ----------
    rand bit [6:0] opcode;
    rand bit [6:0] funct7;
    rand bit [2:0] funct3;
    rand bit [4:0] rs1, rs2, rd;
    rand bit [11:0] imm;

    bit [31:0] instruction;

    // ---------- Constraints ----------
    constraint opcode_c { opcode inside {7'b0110011, 7'b0010011, 7'b0000011, 7'b0100011}; }
    constraint opcode_c1 { opcode inside {7'b0010011, 7'b0000011, 7'b0100011}; }
    constraint funct3_c { funct3 inside {3'b000, 3'b001, 3'b010, 3'b100, 3'b110, 3'b111}; }
    constraint funct3_c1 { funct3 inside {3'b111}; }
    constraint funct7_c { funct7 inside {7'b0000000, 7'b0100000}; }
    constraint reg_c {
        rs1 inside {[0:31]};
        rs2 inside {[0:31]};
        rd  inside {[0:31]};
    }
    constraint reg_c1 {rd  inside {[8:15]};}
    constraint imm_c { imm inside {[0:4095]}; }
    constraint imm_c1 {
	imm dist {[0:31] := 80, [32:4095] := 20};}

    // ---------- Covergroup Definition ----------
    covergroup instr_cov;
        
        // Coverpoints for instruction fields
        opcode_cp: coverpoint opcode {
            bins R_type   = {7'b0110011};
            bins I_type   = {7'b0010011};
            bins Load     = {7'b0000011};
            bins Store    = {7'b0100011};
	    bins default_case = {[0:127]} with (!(item inside {7'b0110011, 7'b0010011, 7'b0000011, 7'b0100011}));
        }

        funct3_cp: coverpoint funct3 {

	    bins add_sub = {3'b000};
	    bins and_b     = {3'b111};
  	    bins nand_b    = {3'b001};
	    bins nor_b 	 = {3'b010};
	    bins xor_b     = {3'b100};
	    bins or_b      = {3'b110};
	    bins default_case = {[0:3]} with (!(item inside {3'b000, 3'b111, 3'b001, 3'b010, 3'b100, 3'b110}));
        }

        funct7_cp: coverpoint funct7 {
            bins add    = {7'b0000000};
            bins sub    = {7'b0100000};
	    bins default_case = {[0:127]} with (!(item inside {7'b0000000, 7'b0100000}));
        }

        rs1_cp: coverpoint rs1 {
            bins byte_0  = {[0:7]};
            bins byte_1  = {[8:15]};
            bins byte_2 = {[16:23]};
	    bins byte_3 = {[24:31]};
        }

        rs2_cp: coverpoint rs2 {
            bins byte_0  = {[0:7]};
            bins byte_1  = {[8:15]};
            bins byte_2 = {[16:23]};
	    bins byte_3 = {[24:31]};
        }

        rd_cp: coverpoint rd {
            bins byte_0  = {[0:7]};
            bins byte_1  = {[8:15]};
            bins byte_2 = {[16:23]};
	    bins byte_3 = {[24:31]};
        }

        imm_cp: coverpoint imm {
            bins byte_0_to_3 = {[0:31]};
            bins byte_rest   = {[32:4095]};
        }


    endgroup : instr_cov

    // ---------- Constructor ----------
    //Creates the covergroup instance when object is created.
    function new();
        instr_cov = new();
    endfunction


    // ---------- Function to Generate Encoded Instruction ----------
    function bit [31:0] generate_encoded_instr();
        bit [31:0] instr;

        case (opcode)
            7'b0110011: instr = {funct7, rs2, rs1, funct3, rd, opcode};
            7'b0010011: instr = {imm, rs1, funct3, rd, opcode};
            7'b0000011: instr = {7'b0000000, imm[4:0], rs1, funct3, rd, opcode};
            7'b0100011: instr = {7'b0000000, rs2, rs1, funct3, imm[4:0], opcode};
            default:    instr = 32'b0;
        endcase

        instruction = instr;
        return instr;
    endfunction

    // ---------- Display ----------
    function void display_instr();
        $display("-------------------------------------------------------------");
        $display("Encoded 32-bit Instruction: %b", instruction);
        $display("Hex Format: 0x%08h", instruction);
        $display("-------------------------------------------------------------");
    endfunction

endclass

//======================================================
// Program: riscv_tb
// Purpose: Random instruction-based functional testbench
//======================================================
program automatic riscv_tb (cpu_if.TB intf);

    // ---------- Local Declarations ----------
    int i;
    int status;
    Rand_Instruction_Generator gen;   // Random generator object

    initial begin
        // ---------- Create Generator Object ----------
        gen = new();   //Allocates object. create object with random data
	gen.instr_cov.start();   //Starts covergroup sampling.

	//-------Turn off constraints-------
	gen.opcode_c.constraint_mode(0);
	gen.opcode_c1.constraint_mode(0);
	gen.funct3_c.constraint_mode(0);
	gen.funct3_c1.constraint_mode(0);
	gen.funct7_c.constraint_mode(0);
	gen.reg_c.constraint_mode(0);
	gen.reg_c1.constraint_mode(0);
	gen.imm_c.constraint_mode(0);
	gen.imm_c1.constraint_mode(0);


        // ---------- Initialize Memories ----------
        for (i = 0; i < 32; i++) intf.data_memory[i] = i;
        for (i = 0; i < 32;  i++) intf.register_file[i] = 0;

        // ---------- Random Instruction Generation ----------
        $display("\n================ Random Stimuli Generation Started ================");
        for (i = 0; i < 15; i++) begin
            status = gen.randomize();
	    $display("Randomization Status: %d", status);
	    //Then instruction is encoded and stored into instruction memory.
            intf.instruction_memory[i] = gen.generate_encoded_instr();
	    gen.display_instr();
	    gen.instr_cov.sample();
        end
        

	
	//-------Turn on constraints-------
	gen.opcode_c1.constraint_mode(1);
	gen.funct3_c1.constraint_mode(1);
	gen.funct7_c.constraint_mode(1);
	gen.reg_c1.constraint_mode(1);
	gen.imm_c1.constraint_mode(1);



	for (i = 16; i < 25; i++) begin
            status = gen.randomize();
	    $display("Randomization Status: %d", status);
            intf.instruction_memory[i] = gen.generate_encoded_instr();
	    gen.display_instr();
	    gen.instr_cov.sample();
        end

	$display("================ Random Stimuli Generation Completed ================\n");

	//--------------Cover Group----------------------
	
	gen.instr_cov.stop();
	
	// ---------- Report Functional Coverage ----------
        $display("\n===============================================================");
        $display("Functional Coverage Collected: %0d\%", gen.instr_cov.get_coverage());
        $display("===============================================================\n");

      // ---------- Reset ----------
      intf.reset = 1;
      @(posedge intf.clk);
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
      for (int instr = 0; instr < 32; instr++) begin
          @(posedge intf.clk);

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

        // ---------- Finish ---------	
        $finish;
    end
endprogram
