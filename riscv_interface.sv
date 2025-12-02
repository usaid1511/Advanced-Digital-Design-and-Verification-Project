interface cpu_if (input logic clk);

    // ---------- DUT I/O ----------
    logic reset;
    logic [31:0] instruction;
    logic [31:0] regfile_rdata1, regfile_rdata2, regfile_wdata;
    logic [4:0]  regfile_raddr1, regfile_raddr2, regfile_waddr;
    logic        regfile_write;
    logic [31:0] data_mem_rdata, data_mem_wdata;
    logic [7:0]  data_mem_addr;
    logic        mem_write, mem_read;
    logic [31:0] PC;

    // ---------- Internal Models ----------
    //The testbench can initialize these arrays, and the interface updates them on mem_write / regfile_write
    logic [31:0] instruction_memory [0:31];
    logic [31:0] data_memory [0:31];
    logic [31:0] register_file [0:31];

    // ---------- Clocking ----------
    clocking cb @(posedge clk);
        default input #1 output #0;
        output reset;
        output instruction;
        output data_mem_rdata;
        input  mem_write, mem_read;
        input  regfile_write;
        input  PC;
    endclocking

    // ---------- Behavioral Models ----------

    // Instruction Fetch (like Verilog TB)
    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            instruction <= '0;
        else
            instruction <= instruction_memory[PC[7:0]];
    end

    // Data Memory Model
    // - STORE happens on posedge clk
    // - LOAD is combinational (same-cycle visibility)
    always_comb begin  //writing data_memory when mem_write is asserted.
        if (mem_write) begin
            data_memory[data_mem_addr] = data_mem_wdata;
            $monitor("STORE: Addr=%0d, Data=%0d", data_mem_addr, data_mem_wdata);
        end
    end

    // Combinational LOAD
    always_comb begin
        if (mem_read) begin
            data_mem_rdata = data_memory[data_mem_addr];
            $monitor("LOAD: Addr=%0d, Data=%0d", data_mem_addr, data_memory[data_mem_addr]);
        end else begin
            data_mem_rdata = '0;
        end
    end

    // Register File Write
    always_comb begin
        if (regfile_write) begin
            register_file[regfile_waddr] = regfile_wdata;  //Combinational writes can hide pipeline bugs
            $monitor("REGFILE WRITE: Addr=%0d, Data=%0d", regfile_waddr, regfile_wdata);
        end
    end

    // Register File Read (combinational)
    always_comb begin
        if (reset) begin
            regfile_rdata1 = '0;
            regfile_rdata2 = '0;
        end else begin
            regfile_rdata1 = register_file[regfile_raddr1];
            regfile_rdata2 = register_file[regfile_raddr2];
        end
    end

    // ---------- Modports ----------

    // DUT modport
    //signals listed as input are inputs to the DUT (i.e., the DUT reads them), and output are outputs from the DUT (i.e., the DUT drives them).
    modport DUT (
        input clk,
        input reset,
        input instruction,
        input data_mem_rdata,
        input regfile_rdata1,
        input regfile_rdata2,
        output PC,
        output regfile_write,
        output regfile_wdata,
        output mem_write,
        output mem_read,
        output data_mem_wdata,
        output regfile_raddr1,
        output regfile_raddr2,
        output regfile_waddr,
        output data_mem_addr
    );

    // Testbench modport
    //modport TB defines how the testbench program will access the interface.
    modport TB (
        clocking cb,
        input clk,
        output reset,
        input PC,
        ref instruction_memory,
        ref data_memory,
        ref register_file
    );

endinterface
