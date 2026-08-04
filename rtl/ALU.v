module ALU(
    input   wire [3:0] ALU_sel,
    input   wire [31:0] operand_0,
    input   wire [31:0] operand_1,
    output  reg  [31:0] result
);

    localparam ADD = 4'h0;
    localparam SUB = 4'h1;
    localparam AND_OP = 4'h2;
    localparam OR_OP = 4'h3;
    localparam XOR_OP = 4'h4;
    localparam SLL_OP = 4'h5;
    localparam SRL_OP = 4'h6;
    localparam SRA_OP = 4'h7;
    localparam SLT_OP = 4'h8;

    always@(*) begin 
        case(ALU_sel)
            ADD: result = operand_0 + operand_1;
            SUB: result = operand_0 - operand_1;
            AND_OP: result = operand_0 & operand_1;
            OR_OP: result = operand_0 | operand_1;
            XOR_OP: result = operand_0 ^ operand_1;
            SLL_OP: result = operand_0 << operand_1[4:0];
            SRL_OP: result = operand_0 >> operand_1[4:0];
            SRA_OP: result = $signed(operand_0) >>> operand_1[4:0];
            SLT_OP: result = ($signed(operand_0) < $signed(operand_1));
            default: result = 32'd0;
        endcase
    end




endmodule