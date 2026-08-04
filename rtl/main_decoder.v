// =========================================================
// MAIN DECODER
// =========================================================
module main_decoder (
    input  wire [4:0] opcode_eff,   // Instruction[6:2]

    output reg  [2:0] ImmSel,
    output reg        RegWEn,
    output reg        ASel,
    output reg        BSel,
    output reg        BrUn,
    output reg	[1:0] ALUOp,        // for ALU decoder
    output reg         MemRW,
    output reg  [1:0] WBSel,
    output reg        Branch,       // is Branch 
    output reg        Jump          // is jal/jalr
);

    // ---------------- Opcode map (Instruction[6:2]) ----------------
    localparam OP_LOAD    = 5'b00000; // I-type: LB/LH/LW/LBU/LHU
    localparam OP_IMM     = 5'b00100; // I-type: ADDI/SLTI/.../SLLI/SRLI/SRAI
    localparam OP_AUIPC   = 5'b00101; // U-type
    localparam OP_STORE   = 5'b01000; // S-type
    localparam OP_R       = 5'b01100; // R-type: ADD/SUB/...
    localparam OP_LUI     = 5'b01101; // U-type
    localparam OP_BRANCH  = 5'b11000; // B-type
    localparam OP_JALR    = 5'b11001; // I-type
    localparam OP_JAL     = 5'b11011; // J-type

    // ImmSel encoding
    localparam IMM_I = 3'b000;
    localparam IMM_S = 3'b001;
    localparam IMM_B = 3'b010;
    localparam IMM_U = 3'b011;
    localparam IMM_J = 3'b100;

    // Intermediate, not final ALUSel
    localparam ALUOP_ADD = 2'b00; // ADD
	localparam ALUOP_LUI= 2'b10;
    localparam ALUOP_RTYPE_ITYPE= 2'b01; // need funct3/funct7

    always @(*) begin
        // default
        ImmSel  = IMM_I;
        RegWEn  = 1'b0;
        ASel    = 1'b0;
        BSel    = 1'b0;
        BrUn    = 1'b0;
        ALUOp   = ALUOP_ADD;
        MemRW   = 1'b0;
        WBSel   = 2'b01;
        Branch  = 1'b0;
        Jump    = 1'b0;

        case (opcode_eff)
            OP_R: begin
                ImmSel = IMM_I;      // not use
                ASel   = 1'b0;
                BSel   = 1'b0;       // use DataB, not use Imm
                RegWEn = 1'b1;
                WBSel  = 2'b01;      // ALU_out
                ALUOp  = ALUOP_RTYPE_ITYPE;
            end

            OP_IMM: begin
                ImmSel = IMM_I;
                ASel   = 1'b0;
                BSel   = 1'b1;
                RegWEn = 1'b1;
                WBSel  = 2'b01;
                ALUOp  = ALUOP_RTYPE_ITYPE;
            end

            OP_LOAD: begin
                ImmSel = IMM_I;
                ASel   = 1'b0;
                BSel   = 1'b1;
                RegWEn = 1'b1;
                MemRW  = 1'b0;       // read
                WBSel  = 2'b00;      // DataR
                ALUOp  = ALUOP_ADD;
            end

            OP_STORE: begin
                ImmSel = IMM_S;
                ASel   = 1'b0;
                BSel   = 1'b1;
                RegWEn = 1'b0;
                MemRW  = 1'b1;       // write
                ALUOp  = ALUOP_ADD;
            end

            OP_BRANCH: begin
                ImmSel = IMM_B;
                ASel   = 1'b1;       // PC + imm -> target
                BSel   = 1'b1;
                RegWEn = 1'b0;
                ALUOp  = ALUOP_ADD;
                Branch = 1'b1;		//// BrUn depends on funct3 -> handled in top control_unit
            end

            OP_JAL: begin
                ImmSel = IMM_J;
                ASel   = 1'b1;       // PC + imm -> target
                BSel   = 1'b1;
                RegWEn = 1'b1;
                WBSel  = 2'b10;      // PC+4
                ALUOp  = ALUOP_ADD; // just ADD
                Jump   = 1'b1;
            end

            OP_JALR: begin
                ImmSel = IMM_I;
                ASel   = 1'b0;       // rs1 + imm -> target
                BSel   = 1'b1;
                RegWEn = 1'b1;
                WBSel  = 2'b10;      // PC+4
                ALUOp  = ALUOP_ADD; // just ADD
                Jump   = 1'b1;
            end

            OP_LUI: begin
                ImmSel = IMM_U;
                ASel   = 1'b0;
                BSel   = 1'b1;
                RegWEn = 1'b1;
                WBSel  = 2'b01;      // ALU_out
                ALUOp  = ALUOP_LUI;  // Incorrect if rs1(x0-encoded) != 0
            end

            OP_AUIPC: begin
                ImmSel = IMM_U;
                ASel   = 1'b1;       // PC + imm
                BSel   = 1'b1;
                RegWEn = 1'b1;
                WBSel  = 2'b01;
                ALUOp  = ALUOP_ADD; // just ADD
            end

            default: begin end // FENCE/SYSTEM/undefined/... -> NOP
        endcase
    end
endmodule