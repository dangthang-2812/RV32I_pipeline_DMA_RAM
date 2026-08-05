// ================================================================
//  RV32I 5-stage pipeline : IF | ID | EX | MEM | WB
//  - Branch/jump resolve o EX  -> predict not-taken, phat 2 chu ky
//  - Forwarding EX <- MEM/WB
//  - Load-use hazard -> stall 1 chu ky
//  - WB -> ID write-through bypass cho RegisterFile
// ================================================================
module RISCV_Pipeline (
    input  wire        clk,
    input  wire        rst_n
);


// ================================================================
//  IF stage
// ================================================================
    // Uu tien: EX redirect > load-use stall
    assign PC_en       = PCSel_E | ~stall_F;
    assign PC_Plus4_F  = PC_F + 32'd4;
    assign PC_next_F   = PCSel_E ? BrTarget_E : PC_Plus4_F;

    assign Addr_instr_mem = {2'b0, PC_F[31:2]};

    Program_Counter PC_inst (
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (PC_en),
        .PC_in  (PC_next_F),
        .PC_out (PC_F)
    );

    Instruction_Memory IMEM_inst (
        .addr (Addr_instr_mem),
        .inst (Instr_F)
    );

    assign IFID_stall = stall_D & ~PCSel_E;
    assign IFID_flush = PCSel_E;

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

    control_unit Control_logic_inst (
    );

    Immediate_Generator Imm_Gen_inst (
    );

    // Mot instance duy nhat: doc o ID, ghi o WB
    RegisterFile Reg_inst (
        .clk       (clk),
        .reset     (rst_n),
        .addrA     (addrA_D),
        .addrB     (addrB_D),
        .addrD     (addrD_W),
        .dataD     (DataD_W),
        .reg_write (RegWEn_W),
        .dataA     (DataA_D),
        .dataB     (DataB_D)
    );

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
	
	
	
	
        .fwdA     (fwdA),
        .fwdB     (fwdB)
    );

    assign fwd_DataA_E = (fwdA == 2'b01) ? ALU_out_M :
                       (fwdA == 2'b10) ? DataD_W   : DataA_E;
    assign fwd_DataB_E = (fwdB == 2'b01) ? ALU_out_M :
                       (fwdB == 2'b10) ? DataD_W   : DataB_E;

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
    assign BrTarget_E = Is_JALR_E ? {ALU_out_E[31:1], 1'b0} : ALU_out_E;

    EX_MEM_reg u_EX_MEM_reg (
        .clk         (clk),
        .rst_n       (rst_n),
        .ALU_out_E   (ALU_out_E),
        .DataB_fwd_E (OpB_fwd_E),      // du lieu store da qua forwarding
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