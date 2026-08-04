// =========================================================
// ALU DECODER
// =========================================================
module alu_decoder (
    input  wire 	  ALUOp,
    input  wire [2:0] funct3,
    input  wire       funct7_fif,
    input  wire [4:0] opcode_eff,    // // Used to different R-type vs I-type when ALUOp = 2'b10

    output reg  [3:0] ALUSel
);
    localparam ADD    = 4'h0;
    localparam SUB    = 4'h1;
    localparam AND_OP = 4'h2;
    localparam OR_OP  = 4'h3;
    localparam XOR_OP = 4'h4;
    localparam SLL_OP = 4'h5;
    localparam SRL_OP = 4'h6;
    localparam SRA_OP = 4'h7;
    localparam SLT_OP = 4'h8;

    localparam OP_R = 5'b01100;

    wire is_Rtype = (opcode_eff == OP_R);

    always @(*) begin
        case (ALUOp)
            1'b0: ALUSel = ADD;   // always ADD
            1'b1: begin // R-type or I-type ALU (OP_IMM)
                case (funct3)
                    3'b000:  ALUSel = (is_Rtype && funct7_fif) ? SUB : ADD; // ADD/ADDI/SUB
                    3'b001:  ALUSel = SLL_OP;
                    3'b010:  ALUSel = SLT_OP;
                    3'b011:  ALUSel = SLT_OP;    // SLTU/SLTIU: ALU dont have
                    3'b100:  ALUSel = XOR_OP;
                    3'b101:  ALUSel = funct7_fif ? SRA_OP : SRL_OP; // SRL/SRA, SRLI/SRAI
                    3'b110:  ALUSel = OR_OP;
                    3'b111:  ALUSel = AND_OP;
                    default: ALUSel = ADD;
                endcase
            end

            default: ALUSel = ADD;
        endcase
    end
endmodule