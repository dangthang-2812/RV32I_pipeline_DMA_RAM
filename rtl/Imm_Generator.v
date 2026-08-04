module Immediate_Generator(
    input  wire [31:0] Inst,
    input  wire [2:0] ImmSel,
    output reg  [31:0] Imm
);

    localparam I_TYPE = 3'b000;
    localparam S_TYPE = 3'b001;
    localparam B_TYPE = 3'b010;
    localparam U_TYPE = 3'b011;
    localparam J_TYPE = 3'b100;

    always@(*) begin
        case(ImmSel)
            I_TYPE: Imm = {{20{Inst[31]}}, Inst[31:20]}; // I-type immediate
            S_TYPE: Imm = {{20{Inst[31]}}, Inst[31:25], Inst[11:7]}; // S-type immediate
            B_TYPE: Imm = {{19{Inst[31]}}, Inst[31], Inst[7], Inst[30:25], Inst[11:8], 1'b0}; // B-type immediate
            U_TYPE: Imm = {Inst[31:12], 12'b0}; // U-type immediate
            J_TYPE: Imm = {{11{Inst[31]}}, Inst[31], Inst[19:12], Inst[20], Inst[30:21], 1'b0}; // J-type immediate
            default: Imm = 32'd0;
        endcase
    end


endmodule