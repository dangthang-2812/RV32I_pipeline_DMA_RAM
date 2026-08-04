// =========================================================
// TOP CONTROL UNIT (Main Decoder + ALU Decoder + Branch logic)
// =========================================================
module control_unit (
    input  wire [4:0] opcode_eff,
    input  wire       funct7_fif,
    input  wire [2:0] funct3,
    input  wire       BrEq,
    input  wire       BrLT,

    output wire        PCSel,
    output wire [2:0]  ImmSel,
    output wire        RegWEn,
    output wire        BrUn,
    output wire        ASel,
    output wire        BSel,
    output wire [3:0]  ALUSel,
    output wire        MemRW,
    output wire [1:0]  WBSel
);

    wire	   ALUOp;
    wire       Branch, Jump;
    reg        branch_taken;
    reg        BrUn_r;

    // funct3 branch code
    localparam F3_BEQ  = 3'b000;
    localparam F3_BNE  = 3'b001;
    localparam F3_BLT  = 3'b100;
    localparam F3_BGE  = 3'b101;
    localparam F3_BLTU = 3'b110;
    localparam F3_BGEU = 3'b111;

    main_decoder u_main_decoder (
        .opcode_eff (opcode_eff),
        .ImmSel     (ImmSel),
        .RegWEn     (RegWEn),
        .ASel       (ASel),
        .BSel       (BSel),
        .BrUn       (),
        .ALUOp      (ALUOp),
        .MemRW      (MemRW),
        .WBSel      (WBSel),
        .Branch     (Branch),
        .Jump       (Jump)
    );

    alu_decoder u_alu_decoder (
        .ALUOp       (ALUOp),
        .funct3      (funct3),
        .funct7_fif  (funct7_fif),
        .opcode_eff  (opcode_eff),
        .ALUSel      (ALUSel)
    );

    // BrUn and branch_taken are decided by the branch instruction's funct3.
    always @(*) begin
        BrUn_r       = 1'b0;
        branch_taken = 1'b0;
        if (Branch) begin
            case (funct3)
                F3_BEQ:  begin BrUn_r = 1'b0; branch_taken =  BrEq; end
                F3_BNE:  begin BrUn_r = 1'b0; branch_taken = ~BrEq; end
                F3_BLT:  begin BrUn_r = 1'b0; branch_taken =  BrLT; end
                F3_BGE:  begin BrUn_r = 1'b0; branch_taken = ~BrLT; end
                F3_BLTU: begin BrUn_r = 1'b1; branch_taken =  BrLT; end
                F3_BGEU: begin BrUn_r = 1'b1; branch_taken = ~BrLT; end
                default: begin BrUn_r = 1'b0; branch_taken = 1'b0; end
            endcase
        end
    end

    assign BrUn  = BrUn_r;
    assign PCSel = Jump | (Branch & branch_taken);

endmodule