// ================================================================
//  RV32I 5-stage pipeline : IF | ID | EX | MEM | WB
// ================================================================
module RISCV_Pipeline (
    input  wire        clk,
    input  wire        rst_n
);

    //Wire for IF Stage
    wire [31:0] PC_in_F;
    wire [31:0] PC_Plus4_F;
    wire [31:0] PC_out_F;
    wire [31:0] PC_F;
    wire [31:0] Instr_F;
    wire [31:0] PC_F_IMEM;

    //Wire for ID Stage
    wire [31:0] PC_D;
    wire [31:0] PC_Plus4_D;
    wire [31:0] Instr_D;

    wire [4:0] addrA_D;
    wire [4:0] addrB_D;
    wire [4:0] addrD_D;
    wire [31:0] DataA_D;
    wire [31:0] DataB_D;
    wire [31:0] DataA_D_RegFile;
    wire [31:0] DataB_D_RegFile;
    wire [31:0] Imm_D;
    wire [2:0] funct3_D;

    wire [3:0] ALUSel_D;
    wire [1:0] WBSel_D;
    wire       RegWEn_D;
    wire       BrUn_D;
    wire       ASel_D;
    wire       BSel_D;
    wire       MemRW_D;
    wire       Is_Branch_D;
    wire       Is_Jump_D;
    wire       Is_JALR_D;
    wire       Is_Load_D;
    
    // Wire for EX Stage 
    wire [31:0] PC_E;
    wire [31:0] PC_Plus4_E;
    wire [31:0] Instr_E;
    wire [31:0] DataA_E;
    wire [31:0] DataB_E;
    wire [31:0] Imm_E;
    wire [4:0] addrA_E;
    wire [4:0] addrB_E;
    wire [4:0] addrD_E;
    wire [2:0] funct3_E;
    wire [3:0] ALUSel_E;
    wire [1:0] WBSel_E;
    wire       RegWEn_E;
    wire       BrUn_E;
    wire       ASel_E;
    wire       BSel_E;
    wire       MemRW_E;
    wire       Is_Branch_E;
    wire       Is_Jump_E;
    wire       Is_JALR_E;
    wire       Is_Load_E;

    wire PCSel_E;
    wire [31:0] Target_E;
    wire [31:0] ALU_inA_E;
    wire [31:0] ALU_inB_E;
    wire [31:0] ALU_out_E;
    wire [31:0] fwd_DataA_E;
    wire [31:0] fwd_DataB_E;

    // Signal for forwarding data to EX stage
    wire [1:0] fwdA;
    wire [1:0] fwdB;

    // Wire for MEM Stage
    wire [31:0] ALU_out_M;
    wire [31:0] DataB_M;
    wire [31:0] PC_Plus4_M;
    wire [4:0] addrD_M;
    wire [1:0] WBSel_M;
    wire RegWEn_M;
    wire MemRW_M;
    wire [2:0] funct3_M;
    wire [31:0] DataR_M;


    // Wire for WB Stage
    wire [31:0] ALU_out_W;
    wire [31:0] DataR_W;
    wire [31:0] PC_Plus4_W;
    wire [4:0] addrD_W;
    wire [1:0] WBSel_W;
    wire RegWEn_W;
    wire [31:0] DataD_W;

    

    //Wire for Hazard Detection module
    wire stall_D;
    wire stall_F;
    wire flush_E;
    wire IFID_stall;
    wire IFID_flush;
    wire IDEX_bubble;
    wire UsesRs1_D;
    wire UsesRs2_D;


    // Wire for Control Unit
    wire [4:0] opcode_eff;
    wire funct7_fif;
    wire [2:0] funct3;
    wire BrEq_E;
    wire BrLt_E;
    wire Is_Branch;
    wire Is_Jump;
    wire Is_JALR;
    wire Is_Load;
    wire UsesRs1;
    wire UsesRs2;
    wire [2:0] ImmSel;
    wire RegWEn;
    wire BrUn;
    wire ASel;
    wire BSel;
    wire [3:0] ALUSel;
    wire MemRW;
    wire [1:0] WBSel;

    
    




// ================================================================
//  IF stage
// ================================================================
    // Uu tien: EX redirect > load-use stall
    assign PC_Plus4_F  = PC_out_F + 32'd4;
    assign PC_in_F   = PCSel_E ? Target_E : PC_Plus4_F;
    assign PC_F      = PC_out_F;
    assign PC_F_IMEM  = {2'b0, PC_out_F[31:2]}; // For IMEM address

    Program_Counter PC_inst (
        .clk    (clk),
        .rst_n  (rst_n),
        .stall (stall_F),
        .PC_in  (PC_in_F),
        .PC_out (PC_out_F)
    );

    Instruction_Memory IMEM_inst (
        .addr (PC_F_IMEM),
        .inst (Instr_F)
    );

    assign IFID_stall = stall_D;
    assign IFID_flush = PCSel_E ; // Flush IF/ID when branch taken or jump

    IF_ID_reg u_IF_ID_reg (
        .clk        (clk),
        .rst_n      (rst_n),
        .stall      (IFID_stall),
        .flush      (IFID_flush),
        .PC_F       (PC_F),
        .PC_Plus4_F (PC_Plus4_F),
        .Instr_F    (Instr_F),
        .PC_D       (PC_D),
        .PC_Plus4_D (PC_Plus4_D),
        .Instr_D    (Instr_D)
    );

// ================================================================
//  ID stage
// ================================================================
    assign opcode_eff = Instr_D[6:2];
    assign funct7_fif = Instr_D[30];
    assign funct3 = Instr_D[14:12];


    control_unit Control_logic_inst (
        .opcode_eff (opcode_eff),
        .funct7_fif (funct7_fif),
        .funct3     (funct3),   
        .Is_Branch  (Is_Branch),
        .Is_Jump    (Is_Jump),
        .Is_JALR    (Is_JALR),
        .Is_Load    (Is_Load),
        .UsesRs1    (UsesRs1),
        .UsesRs2    (UsesRs2),
        .ImmSel     (ImmSel),
        .RegWEn     (RegWEn),
        .BrUn       (BrUn),
        .ASel       (ASel),
        .BSel       (BSel),
        .ALUSel     (ALUSel),
        .MemRW      (MemRW),
        .WBSel      (WBSel)
    );

    // Connect control signals to ID-stage pipeline signals
    assign ALUSel_D   = ALUSel;
    assign WBSel_D    = WBSel;
    assign RegWEn_D   = RegWEn;
    assign BrUn_D     = BrUn;
    assign ASel_D     = ASel;
    assign BSel_D     = BSel;
    assign MemRW_D    = MemRW;
    assign Is_Branch_D= Is_Branch;
    assign Is_Jump_D  = Is_Jump;
    assign Is_JALR_D  = Is_JALR;
    assign Is_Load_D  = Is_Load;
    assign UsesRs1_D  = UsesRs1;
    assign UsesRs2_D  = UsesRs2;

    Immediate_Generator Imm_Gen_inst (
        .Inst    (Instr_D),
        .ImmSel  (ImmSel),
        .Imm     (Imm_D)
    );

    assign addrA_D = Instr_D[19:15];
    assign addrB_D = Instr_D[24:20];
    assign addrD_D = Instr_D[11:7];
    assign funct3_D = Instr_D[14:12];

    RegisterFile Reg_inst (
        .clk       (clk),
        .reset     (rst_n),
        .addrA     (addrA_D),
        .addrB     (addrB_D),
        .addrD     (addrD_W),
        .dataD     (DataD_W),
        .reg_write (RegWEn_W),
        .dataA     (DataA_D_RegFile),
        .dataB     (DataB_D_RegFile)
    );

    assign DataA_D = (RegWEn_W && (addrD_W == addrA_D) && (addrD_W != 5'd0)) ? DataD_W : DataA_D_RegFile;
    assign DataB_D = (RegWEn_W && (addrD_W == addrB_D) && (addrD_W != 5'd0)) ? DataD_W : DataB_D_RegFile;

    hazard_detect u_hazard_detect (
        .addrA_D   (addrA_D),
        .addrB_D   (addrB_D),
        .addrD_E   (addrD_E),
        .Is_Load_E (Is_Load_E),
        .UsesRs1_D (UsesRs1_D),
        .UsesRs2_D (UsesRs2_D),
        .stall_F   (stall_F),
        .stall_D   (stall_D),
        .flush_E   (flush_E)
    );

    assign IDEX_bubble = flush_E | PCSel_E;

    ID_EX_reg u_ID_EX_reg (
        .clk         (clk),
        .rst_n       (rst_n),
        .bubble      (IDEX_bubble),
        .PC_D        (PC_D),
        .PC_Plus4_D  (PC_Plus4_D),
        .Instr_D     (Instr_D),
        .DataA_D     (DataA_D),
        .DataB_D     (DataB_D),
        .Imm_D       (Imm_D),
        .addrA_D     (addrA_D),
        .addrB_D     (addrB_D),
        .addrD_D     (addrD_D),
        .funct3_D    (funct3_D),
        .ALUSel_D    (ALUSel_D),
        .WBSel_D     (WBSel_D),
        .RegWEn_D    (RegWEn_D),
        .BrUn_D      (BrUn_D),
        .ASel_D      (ASel_D),
        .BSel_D      (BSel_D),
        .MemRW_D     (MemRW_D),
        .Is_Branch_D (Is_Branch_D),
        .Is_Jump_D   (Is_Jump_D),
        .Is_JALR_D   (Is_JALR_D),
        .Is_Load_D   (Is_Load_D),
        .PC_E        (PC_E),
        .PC_Plus4_E  (PC_Plus4_E),
        .Instr_E     (Instr_E),
        .DataA_E     (DataA_E),
        .DataB_E     (DataB_E),
        .Imm_E       (Imm_E),
        .addrA_E     (addrA_E),
        .addrB_E     (addrB_E),
        .addrD_E     (addrD_E),
        .funct3_E    (funct3_E),
        .ALUSel_E    (ALUSel_E),
        .WBSel_E     (WBSel_E),
        .RegWEn_E    (RegWEn_E),
        .BrUn_E      (BrUn_E),
        .ASel_E      (ASel_E),
        .BSel_E      (BSel_E),
        .MemRW_E     (MemRW_E),
        .Is_Branch_E (Is_Branch_E),
        .Is_Jump_E   (Is_Jump_E),
        .Is_JALR_E   (Is_JALR_E),
        .Is_Load_E   (Is_Load_E)
    );

// ================================================================
//  EX stage
// ================================================================
    forward_unit u_forward_unit (
        .addrA_E  (addrA_E),
        .addrB_E  (addrB_E),
        .addrD_M  (addrD_M),
        .addrD_W  (addrD_W),
        .RegWEn_M (RegWEn_M),
        .RegWEn_W (RegWEn_W),
        .fwdA     (fwdA),
        .fwdB     (fwdB)
    );

    assign fwd_DataA_E = (fwdA == 2'b01) ? DataD_W :
                       (fwdA == 2'b10) ?  ALU_out_M  : DataA_E;
    assign fwd_DataB_E = (fwdB == 2'b01) ? DataD_W  :
                       (fwdB == 2'b10) ? ALU_out_M  : DataB_E;

    assign ALU_inA_E = ASel_E ? PC_E  : fwd_DataA_E;
    assign ALU_inB_E = BSel_E ? Imm_E : fwd_DataB_E;

    // Branch_Comp lay operand tu mux forwarding (khong lay DataA_E/DataB_E tho)
    Branch_Comp Branch_Comp_inst (
        .operand_0 (fwd_DataA_E),
        .operand_1 (fwd_DataB_E),
        .BrUn      (BrUn_E),
        .BrEq      (BrEq_E),
        .BrLT      (BrLt_E)
    );

    Branch_Resolve u_Branch_Resolve (
        .Is_Branch_E (Is_Branch_E),
        .Is_Jump_E   (Is_Jump_E),
        .funct3_E    (funct3_E),
        .BrEq_E      (BrEq_E),
        .BrLt_E      (BrLt_E),
        .PCSel_E     (PCSel_E)
    );

    ALU ALU_mod_inst (
        .operand_0 (ALU_inA_E),
        .operand_1 (ALU_inB_E),
        .ALU_Sel   (ALUSel_E),
        .result    (ALU_out_E)
    );

    // JALR phai xoa bit 0 cua dia chi dich
    assign Target_E = Is_JALR_E ? {ALU_out_E[31:1], 1'b0} : ALU_out_E;

    EX_MEM_reg u_EX_MEM_reg (
        .clk         (clk),
        .rst_n       (rst_n),
        .ALU_out_E   (ALU_out_E),
        .DataB_fwd_E (fwd_DataB_E),      // du lieu store da qua forwarding
        .PC_Plus4_E  (PC_Plus4_E),
        .addrD_E     (addrD_E),
        .WBSel_E     (WBSel_E),
        .RegWEn_E    (RegWEn_E),
        .MemRW_E     (MemRW_E),
        .funct3_E    (funct3_E),
        .ALU_out_M   (ALU_out_M),
        .DataB_M     (DataB_M),
        .PC_Plus4_M  (PC_Plus4_M),
        .addrD_M     (addrD_M),
        .WBSel_M     (WBSel_M),
        .RegWEn_M    (RegWEn_M),
        .MemRW_M     (MemRW_M),
        .funct3_M    (funct3_M)
    );

// ================================================================
//  MEM stage
// ================================================================
    Data_Memory DMEM_inst (
        .clk    (clk),
        .MemRW  (MemRW_M),
        .funct3 (funct3_M),
        .addr   (ALU_out_M),
        .DataW  (DataB_M),
        .DataR  (DataR_M)
    );

    MEM_WB_reg u_MEM_WB_reg (
        .clk        (clk),
        .rst_n      (rst_n),
        .ALU_out_M  (ALU_out_M),
        .DataR_M    (DataR_M),
        .PC_Plus4_M (PC_Plus4_M),
        .addrD_M    (addrD_M),
        .WBSel_M    (WBSel_M),
        .RegWEn_M   (RegWEn_M),
        .ALU_out_W  (ALU_out_W),
        .DataR_W    (DataR_W),
        .PC_Plus4_W (PC_Plus4_W),
        .addrD_W    (addrD_W),
        .WBSel_W    (WBSel_W),
        .RegWEn_W   (RegWEn_W)
    );

// ================================================================
//  WB stage
// ================================================================
    assign DataD_W = (WBSel_W == 2'b00) ? DataR_W   :
                     (WBSel_W == 2'b01) ? ALU_out_W : PC_Plus4_W;

endmodule