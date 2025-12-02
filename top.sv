//======================================================
// File: top.sv
// Purpose: Top-level for riscv processor simulation
//======================================================
`timescale 1ns/1ps
`include "riscv_interface.sv"
`include "riscv_sva.sv"
`include "riscv_tb_program.sv"

module top;

    // ---------- Clock ----------
    bit clk;
    always #5 clk = ~clk; // 10ns period
    
    // ---------- Interface ----------
    cpu_if intf(clk);

    // ---------- DUT Instance ----------
    riscv_proc dut (
        .clk(clk),
        .reset(intf.DUT.reset),
        .instruction(intf.DUT.instruction),
        .data_mem_rdata(intf.DUT.data_mem_rdata),
        .regfile_rdata1(intf.DUT.regfile_rdata1),
        .regfile_rdata2(intf.DUT.regfile_rdata2),
        .PC(intf.DUT.PC),
        .regfile_write(intf.DUT.regfile_write),
        .regfile_wdata(intf.DUT.regfile_wdata),
        .mem_write(intf.DUT.mem_write),
        .mem_read(intf.DUT.mem_read),
        .data_mem_wdata(intf.DUT.data_mem_wdata),
        .regfile_raddr1(intf.DUT.regfile_raddr1),
        .regfile_raddr2(intf.DUT.regfile_raddr2),
        .regfile_waddr(intf.DUT.regfile_waddr),
        .data_mem_addr(intf.DUT.data_mem_addr)
    );

    // ---------- Program-Based Testbench ----------
    riscv_tb tb(intf.TB);

endmodule

