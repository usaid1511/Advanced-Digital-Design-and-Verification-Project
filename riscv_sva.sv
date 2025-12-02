`timescale 1ns / 1ps

module riscv_proc (
    input clk,
    input reset,
    input [31:0] instruction,
    input [31:0] data_mem_rdata,
    input [31:0] regfile_rdata1,
    input [31:0] regfile_rdata2,
    output [31:0] PC,
    output regfile_write,     //write-enable to the register file (WB stage)
    output [31:0] regfile_wdata,
    output mem_write,
    output mem_read,
    output [31:0] data_mem_wdata,
    output [4:0] regfile_raddr1,
    output [4:0] regfile_raddr2,
    output [4:0] regfile_waddr,
    output [7:0] data_mem_addr
    );   

    // Pipeline registers
    reg [31:0] IF_ID_instr;

    reg [31:0] ID_EX_read_data1;
    reg [31:0] ID_EX_read_data2;
    reg [4:0] ID_EX_rd;
    reg [2:0] ID_EX_funct3;
    reg [6:0] ID_EX_funct7;
    reg [6:0] ID_EX_opcode;
    reg [31:0] ID_EX_imm;
    
    reg [31:0] EX_MEM_alu_result;
    reg [4:0]  EX_MEM_rd;
    reg EX_MEM_mem_write;
    reg EX_MEM_mem_read;
    reg EX_MEM_reg_write;
    reg EX_MEM_mem_to_reg;
    reg [31:0] EX_MEM_read_data2;

    reg [31:0] MEM_WB_alu_result;
    reg [31:0] MEM_WB_mem_data;
    reg [4:0]  MEM_WB_rd;
    reg MEM_WB_reg_write;
    reg MEM_WB_mem_to_reg;

    // Program Counter (PC)
    reg [31:0] PC_reg;
    assign PC = PC_reg;   //connects the internal register PC_reg to the module’s output port PC
    
    // Control signals
    //control data memory operations (STORE vs LOAD).
    reg reg_mem_write;
    reg reg_mem_read;
    reg [31:0] reg_regfile_wdata;
    reg [31:0] reg_data_mem_wdata;
    
    // Assign output control signals
    //if the internal reg changes, the output port changes simultaneously.
    assign regfile_wdata = reg_regfile_wdata;
    assign mem_write = reg_mem_write;
    assign mem_read = reg_mem_read;
    assign data_mem_wdata = reg_data_mem_wdata;
    
    // FETCH stage
    wire [31:0] PC_next;
    assign PC_next = PC_reg + 32'b1;    

    always @(posedge clk) begin
        if (reset) begin
            IF_ID_instr <= 0;
            PC_reg <= 0;
        end 
        else begin
        //Nonblocking assignments ensure that multiple register updates inside the same always @(posedge clk) use old values (as in real flip-flops) rather than the newly assigned ones. This avoids unintended combinational feedback during clock edge updates.
            IF_ID_instr <= instruction;  
            PC_reg <= PC_next;
        end
    end

    // DECODE stage
    // Wire declarations for instruction fields
    wire [6:0] opcode = IF_ID_instr[6:0];
    wire [4:0] rd = IF_ID_instr[11:7];
    wire [2:0] funct3 = IF_ID_instr[14:12];
    wire [4:0] rs1 = IF_ID_instr[19:15]; 
    wire [4:0] rs2 = IF_ID_instr[24:20]; 
    wire [6:0] funct7 = IF_ID_instr[31:25];
    
    // Output to register file
    assign regfile_raddr1 = rs1;
    assign regfile_raddr2 = rs2;
    
    // Immediate value generation
    reg [31:0] imm_value;
    
    // Immediate generation logic
    //a combinational block — it recalculates imm_value whenever any signal used inside changes.
    always @(*) begin
        case (opcode)
            7'b0010011: // I-type
                imm_value = {{20{IF_ID_instr[31]}}, IF_ID_instr[31:20]};
            7'b0000011: // Load (I-type)
                imm_value = {{20{IF_ID_instr[31]}}, IF_ID_instr[31:20]};
            7'b0100011: // Store (S-type)
                imm_value = {{20{IF_ID_instr[31]}}, IF_ID_instr[31:25], IF_ID_instr[11:7]};
            7'b1100011: // Branch (B-type)
                imm_value = {{19{IF_ID_instr[31]}}, IF_ID_instr[31], IF_ID_instr[7], IF_ID_instr[30:25], IF_ID_instr[11:8], 1'b0};
            default: 
                imm_value = 32'b0;
        endcase
    end
    
    // ID/EX pipeline register update
    always @(posedge clk) begin
        if (reset) begin
            ID_EX_read_data1 <= 0;
            ID_EX_read_data2 <= 0;
            ID_EX_rd <= 0;
            ID_EX_funct3 <= 0;
            ID_EX_funct7 <= 0;
            ID_EX_opcode <= 0;
            ID_EX_imm <= 0;
        end 
        else begin
        //<= (non-blocking) is used to model simultaneous register updates.
            ID_EX_read_data1 <= regfile_rdata1;
            ID_EX_read_data2 <= regfile_rdata2;
            ID_EX_rd <= rd;
            ID_EX_funct3 <= funct3;
            ID_EX_funct7 <= funct7;
            ID_EX_opcode <= opcode;
            ID_EX_imm <= imm_value;
        end
    end

    // EXECUTE stage    
    reg [31:0] alu_result;
    
    always @(*) begin
        case (ID_EX_opcode)
            7'b0110011: begin // R-type instructions
                case (ID_EX_funct3)
                    3'b000: begin
                        if (ID_EX_funct7 == 7'b0000000)
                            alu_result = ID_EX_read_data1 + ID_EX_read_data2; // ADD
                        else if (ID_EX_funct7 == 7'b0100000)
                            alu_result = ID_EX_read_data1 - ID_EX_read_data2; // SUB
                        else
                            alu_result = 0;
                    end
		    3'b001: alu_result = ~(ID_EX_read_data1 & ID_EX_read_data2); // NAND
                    3'b010: alu_result = ~(ID_EX_read_data1 | ID_EX_read_data2); // NOR
                    3'b100: alu_result = ID_EX_read_data1 ^ ID_EX_read_data2; // XOR
                    3'b110: alu_result = ID_EX_read_data1 | ID_EX_read_data2; // OR
                    3'b111: alu_result = ID_EX_read_data1 & ID_EX_read_data2; // AND
			
                    default: alu_result = 0;
                endcase
            end
            7'b0010011: begin // I-type ALU operations
                case (ID_EX_funct3)
                    3'b000: alu_result = ID_EX_read_data1 + ID_EX_imm; // ADDI
		    3'b001: alu_result = ~(ID_EX_read_data1 & ID_EX_imm); // NAND
                    3'b010: alu_result = ~(ID_EX_read_data1 | ID_EX_imm); // NOR
                    3'b100: alu_result = ID_EX_read_data1 ^ ID_EX_imm; // XORI
                    3'b110: alu_result = ID_EX_read_data1 | ID_EX_imm; // ORI
                    3'b111: alu_result = ID_EX_read_data1 & ID_EX_imm; // ANDI
                    default: alu_result = 0;
                endcase
            end
            7'b0000011: begin // Load
                alu_result = ID_EX_read_data1 + ID_EX_imm; // Address calculation
            end
            7'b0100011: begin // Store
                alu_result = ID_EX_read_data1 + ID_EX_imm; // Address calculation
            end
            default: alu_result = 0;
        endcase
    end

    
    // EX/MEM pipeline register update
    always @(posedge clk) begin
        if (reset) begin
            EX_MEM_alu_result <= 0;
            EX_MEM_rd <= 0;
            EX_MEM_read_data2 <= 0;
            EX_MEM_mem_write <= 0;
            EX_MEM_mem_read <= 0;
            EX_MEM_reg_write <= 0;
            EX_MEM_mem_to_reg <= 0;
        end 
        else begin
	
            EX_MEM_alu_result <= alu_result;
            EX_MEM_rd <= ID_EX_rd;
            EX_MEM_read_data2 <= ID_EX_read_data2;
            EX_MEM_mem_write <= (ID_EX_opcode == 7'b0100011); // Store
            EX_MEM_mem_read <= (ID_EX_opcode == 7'b0000011);  // Load
            EX_MEM_reg_write <= (ID_EX_opcode == 7'b0010011 || ID_EX_opcode == 7'b0110011 || ID_EX_opcode == 7'b0000011); // R/I-type or Load
            EX_MEM_mem_to_reg <= (ID_EX_opcode == 7'b0000011); // Load
		
	   if (ID_EX_opcode == 7'b0100011)
            reg_data_mem_wdata <= ID_EX_read_data2;

	   reg_mem_write <= ID_EX_opcode == 7'b0100011;
           reg_mem_read <= ID_EX_opcode == 7'b0000011;
        end
    end

    // MEMORY stage
    assign data_mem_addr = EX_MEM_alu_result[7:0];
    
    // MEM/WB pipeline register update
    always @(posedge clk) begin
        if (reset) begin
        //loads/stores, EX_MEM_alu_result holds the calculated effective address
            MEM_WB_alu_result <= 0;
            MEM_WB_mem_data <= 0;
            MEM_WB_rd <= 0;
            MEM_WB_reg_write <= 0;
            MEM_WB_mem_to_reg <= 0;
        end else begin
            MEM_WB_alu_result <= EX_MEM_alu_result;
            MEM_WB_rd <= EX_MEM_rd;
            MEM_WB_reg_write <= EX_MEM_reg_write;
            MEM_WB_mem_to_reg <= EX_MEM_mem_to_reg;
            if (EX_MEM_mem_read) begin
                MEM_WB_mem_data <= data_mem_rdata; // Load
            end
        end
    end

    // WRITEBACK stage
    assign regfile_write = MEM_WB_reg_write;
    assign regfile_waddr = MEM_WB_rd;
    
    always @(*) begin
        if (MEM_WB_reg_write) begin
            reg_regfile_wdata = MEM_WB_mem_to_reg ? MEM_WB_mem_data : MEM_WB_alu_result;
        end
        else begin
            reg_regfile_wdata = 32'b0;
        end
    end






// ====================================================================
// In-module SVA 
// ====================================================================
///////////////////////////////////////////////////////////////////

// --------------- Signal tracking ---------------
// Detect when a new instruction is fetched
logic [31:0] prev_IF_ID_instr;
always_ff @(posedge clk or posedge reset) begin
    if (reset)
        prev_IF_ID_instr <= 32'b0;
    else
        prev_IF_ID_instr <= IF_ID_instr;
end

// Condition: instruction changes (new instruction fetched)
wire instr_fetched = (IF_ID_instr != prev_IF_ID_instr) && (IF_ID_instr != 0);

// Condition: instruction has completed (writeback stage valid)
wire instr_completed = (MEM_WB_reg_write || reg_mem_write);

property instr_exec_within_5;
	@(posedge clk) disable iff (reset)
		instr_fetched |-> ##[1:5] instr_completed;
endproperty

assert property (instr_exec_within_5)
	else $error("Instruction did not complete within 5 cycles");


// -------------------- COVER PROPERTIES --------------------

// Cover that instruction completes within 5 cycles (observed)
cover_instr_latency: cover property (@(posedge clk) disable iff (reset)
    instr_fetched ##[1:5] instr_completed
);

// ====================================================================


endmodule
