`timescale 1ns/1ps

module tb_control_unit;

    // ---------------- DUT signals ----------------
    reg  [4:0] opcode_eff;
    reg        funct7_fif;
    reg  [2:0] funct3;
    reg        BrEq;
    reg        BrLT;

    wire        PCSel;
    wire [2:0]  ImmSel;
    wire        RegWEn;
    wire        BrUn;
    wire        ASel;
    wire        BSel;
    wire [3:0]  ALUSel;
    wire        MemRW;
    wire [1:0]  WBSel;

    // ---------------- Opcode map ----------------
    localparam OP_LOAD    = 5'b00000;
    localparam OP_IMM     = 5'b00100;
    localparam OP_AUIPC   = 5'b00101;
    localparam OP_STORE   = 5'b01000;
    localparam OP_R       = 5'b01100;
    localparam OP_LUI     = 5'b01101;
    localparam OP_BRANCH  = 5'b11000;
    localparam OP_JALR    = 5'b11001;
    localparam OP_JAL     = 5'b11011;

    localparam IMM_I = 3'b000;
    localparam IMM_S = 3'b001;
    localparam IMM_B = 3'b010;
    localparam IMM_U = 3'b011;
    localparam IMM_J = 3'b100;

    localparam ADD    = 4'h0;
    localparam SUB    = 4'h1;
    localparam AND_OP = 4'h2;
    localparam OR_OP  = 4'h3;
    localparam XOR_OP = 4'h4;
    localparam SLL_OP = 4'h5;
    localparam SRL_OP = 4'h6;
    localparam SRA_OP = 4'h7;
    localparam SLT_OP = 4'h8;

    integer pass_count = 0;
    integer fail_count = 0;
    integer test_num   = 0;

    // ---------------- DUT instantiation ----------------
    control_unit DUT (
        .opcode_eff (opcode_eff),
        .funct7_fif (funct7_fif),
        .funct3     (funct3),
        .BrEq       (BrEq),
        .BrLT       (BrLT),
        .PCSel      (PCSel),
        .ImmSel     (ImmSel),
        .RegWEn     (RegWEn),
        .BrUn       (BrUn),
        .ASel       (ASel),
        .BSel       (BSel),
        .ALUSel     (ALUSel),
        .MemRW      (MemRW),
        .WBSel      (WBSel)
    );

    // =====================================================
    // Task: Apply inputs, wait, compare with expected, and print results
    // =====================================================
    task run_test;
        input [127:0] name;          // name instruction
        input [4:0]   t_opcode;
        input         t_funct7;
        input [2:0]   t_funct3;
        input         t_BrEq;
        input         t_BrLT;
        input         e_PCSel;
        input [2:0]   e_ImmSel;
        input         e_RegWEn;
        input         e_BrUn;
        input         e_ASel;
        input         e_BSel;
        input [3:0]   e_ALUSel;
        input         e_MemRW;
        input [1:0]   e_WBSel;
        begin
            test_num = test_num + 1;
            opcode_eff = t_opcode;
            funct7_fif = t_funct7;
            funct3     = t_funct3;
            BrEq       = t_BrEq;
            BrLT       = t_BrLT;
            #5; // chờ combinational logic ổn định

            if ( (PCSel   === e_PCSel)  &&
                 (ImmSel  === e_ImmSel) &&
                 (RegWEn  === e_RegWEn) &&
                 (BrUn    === e_BrUn)   &&
                 (ASel    === e_ASel)   &&
                 (BSel    === e_BSel)   &&
                 (ALUSel  === e_ALUSel) &&
                 (MemRW   === e_MemRW)  &&
                 (WBSel   === e_WBSel) ) begin
                pass_count = pass_count + 1;
                $display("[PASS] Test %0d - %0s", test_num, name);
            end else begin
                fail_count = fail_count + 1;
                $display("[FAIL] Test %0d - %0s", test_num, name);
                $display("       Got : PCSel=%b ImmSel=%b RegWEn=%b BrUn=%b ASel=%b BSel=%b ALUSel=%h MemRW=%b WBSel=%b",
                          PCSel, ImmSel, RegWEn, BrUn, ASel, BSel, ALUSel, MemRW, WBSel);
                $display("       Exp : PCSel=%b ImmSel=%b RegWEn=%b BrUn=%b ASel=%b BSel=%b ALUSel=%h MemRW=%b WBSel=%b",
                          e_PCSel, e_ImmSel, e_RegWEn, e_BrUn, e_ASel, e_BSel, e_ALUSel, e_MemRW, e_WBSel);
            end
        end
    endtask

    // =====================================================
    // Test sequence
    // =====================================================
    initial begin
        $display("========== TESTBENCH CONTROL UNIT ==========");

        // ---------------- R-TYPE ----------------
        // ADD: opcode=OP_R, funct3=000, funct7=0
        run_test("ADD",  OP_R, 1'b0, 3'b000, 0,0,  0,IMM_I,1,0,0,0,ADD,0,2'b01);
        // SUB: funct3=000, funct7=1
        run_test("SUB",  OP_R, 1'b1, 3'b000, 0,0,  0,IMM_I,1,0,0,0,SUB,0,2'b01);
        // SLL
        run_test("SLL",  OP_R, 1'b0, 3'b001, 0,0,  0,IMM_I,1,0,0,0,SLL_OP,0,2'b01);
        // SLT
        run_test("SLT",  OP_R, 1'b0, 3'b010, 0,0,  0,IMM_I,1,0,0,0,SLT_OP,0,2'b01);
        // SLTU (map ve SLT_OP theo ALU hien tai)
        run_test("SLTU", OP_R, 1'b0, 3'b011, 0,0,  0,IMM_I,1,0,0,0,SLT_OP,0,2'b01);
        // XOR
        run_test("XOR",  OP_R, 1'b0, 3'b100, 0,0,  0,IMM_I,1,0,0,0,XOR_OP,0,2'b01);
        // SRL
        run_test("SRL",  OP_R, 1'b0, 3'b101, 0,0,  0,IMM_I,1,0,0,0,SRL_OP,0,2'b01);
        // SRA
        run_test("SRA",  OP_R, 1'b1, 3'b101, 0,0,  0,IMM_I,1,0,0,0,SRA_OP,0,2'b01);
        // OR
        run_test("OR",   OP_R, 1'b0, 3'b110, 0,0,  0,IMM_I,1,0,0,0,OR_OP,0,2'b01);
        // AND
        run_test("AND",  OP_R, 1'b0, 3'b111, 0,0,  0,IMM_I,1,0,0,0,AND_OP,0,2'b01);

        // ---------------- I-TYPE ALU (OP-IMM) ----------------
        run_test("ADDI",  OP_IMM, 1'b0, 3'b000, 0,0,  0,IMM_I,1,0,0,1,ADD,0,2'b01);
        run_test("SLTI",  OP_IMM, 1'b0, 3'b010, 0,0,  0,IMM_I,1,0,0,1,SLT_OP,0,2'b01);
        run_test("SLTIU", OP_IMM, 1'b0, 3'b011, 0,0,  0,IMM_I,1,0,0,1,SLT_OP,0,2'b01);
        run_test("XORI",  OP_IMM, 1'b0, 3'b100, 0,0,  0,IMM_I,1,0,0,1,XOR_OP,0,2'b01);
        run_test("ORI",   OP_IMM, 1'b0, 3'b110, 0,0,  0,IMM_I,1,0,0,1,OR_OP,0,2'b01);
        run_test("ANDI",  OP_IMM, 1'b0, 3'b111, 0,0,  0,IMM_I,1,0,0,1,AND_OP,0,2'b01);
        run_test("SLLI",  OP_IMM, 1'b0, 3'b001, 0,0,  0,IMM_I,1,0,0,1,SLL_OP,0,2'b01);
        run_test("SRLI",  OP_IMM, 1'b0, 3'b101, 0,0,  0,IMM_I,1,0,0,1,SRL_OP,0,2'b01);
        run_test("SRAI",  OP_IMM, 1'b1, 3'b101, 0,0,  0,IMM_I,1,0,0,1,SRA_OP,0,2'b01);

        // ---------------- LOAD ----------------
        run_test("LB",  OP_LOAD, 1'b0, 3'b000, 0,0,  0,IMM_I,1,0,0,1,ADD,0,2'b00);
        run_test("LH",  OP_LOAD, 1'b0, 3'b001, 0,0,  0,IMM_I,1,0,0,1,ADD,0,2'b00);
        run_test("LW",  OP_LOAD, 1'b0, 3'b010, 0,0,  0,IMM_I,1,0,0,1,ADD,0,2'b00);
        run_test("LBU", OP_LOAD, 1'b0, 3'b100, 0,0,  0,IMM_I,1,0,0,1,ADD,0,2'b00);
        run_test("LHU", OP_LOAD, 1'b0, 3'b101, 0,0,  0,IMM_I,1,0,0,1,ADD,0,2'b00);

        // ---------------- STORE ----------------
        run_test("SB", OP_STORE, 1'b0, 3'b000, 0,0,  0,IMM_S,0,0,0,1,ADD,1,2'b01);
        run_test("SH", OP_STORE, 1'b0, 3'b001, 0,0,  0,IMM_S,0,0,0,1,ADD,1,2'b01);
        run_test("SW", OP_STORE, 1'b0, 3'b010, 0,0,  0,IMM_S,0,0,0,1,ADD,1,2'b01);

        // ---------------- BRANCH ----------------
        // BEQ: taken khi BrEq=1
        run_test("BEQ_taken",     OP_BRANCH, 1'b0, 3'b000, 1,0,  1,IMM_B,0,0,1,1,ADD,0,2'b01);
        run_test("BEQ_not_taken", OP_BRANCH, 1'b0, 3'b000, 0,0,  0,IMM_B,0,0,1,1,ADD,0,2'b01);
        // BNE: taken khi BrEq=0
        run_test("BNE_taken",     OP_BRANCH, 1'b0, 3'b001, 0,0,  1,IMM_B,0,0,1,1,ADD,0,2'b01);
        run_test("BNE_not_taken", OP_BRANCH, 1'b0, 3'b001, 1,0,  0,IMM_B,0,0,1,1,ADD,0,2'b01);
        // BLT: taken khi BrLT=1, BrUn=0
        run_test("BLT_taken",     OP_BRANCH, 1'b0, 3'b100, 0,1,  1,IMM_B,0,0,1,1,ADD,0,2'b01);
        run_test("BLT_not_taken", OP_BRANCH, 1'b0, 3'b100, 0,0,  0,IMM_B,0,0,1,1,ADD,0,2'b01);
        // BGE: taken khi BrLT=0, BrUn=0
        run_test("BGE_taken",     OP_BRANCH, 1'b0, 3'b101, 0,0,  1,IMM_B,0,0,1,1,ADD,0,2'b01);
        run_test("BGE_not_taken", OP_BRANCH, 1'b0, 3'b101, 0,1,  0,IMM_B,0,0,1,1,ADD,0,2'b01);
        // BLTU: taken khi BrLT=1, BrUn=1
        run_test("BLTU_taken",     OP_BRANCH, 1'b0, 3'b110, 0,1,  1,IMM_B,0,1,1,1,ADD,0,2'b01);
        run_test("BLTU_not_taken", OP_BRANCH, 1'b0, 3'b110, 0,0,  0,IMM_B,0,1,1,1,ADD,0,2'b01);
        // BGEU: taken khi BrLT=0, BrUn=1
        run_test("BGEU_taken",     OP_BRANCH, 1'b0, 3'b111, 0,0,  1,IMM_B,0,1,1,1,ADD,0,2'b01);
        run_test("BGEU_not_taken", OP_BRANCH, 1'b0, 3'b111, 0,1,  0,IMM_B,0,1,1,1,ADD,0,2'b01);

        // ---------------- JAL ----------------
        run_test("JAL", OP_JAL, 1'b0, 3'b000, 0,0,  1,IMM_J,1,0,1,1,ADD,0,2'b10);

        // ---------------- JALR ----------------
        run_test("JALR", OP_JALR, 1'b0, 3'b000, 0,0,  1,IMM_I,1,0,0,1,ADD,0,2'b10);

        // ---------------- LUI ----------------
        run_test("LUI", OP_LUI, 1'b0, 3'b000, 0,0,  0,IMM_U,1,0,0,1,ADD,0,2'b01);

        // ---------------- AUIPC ----------------
        run_test("AUIPC", OP_AUIPC, 1'b0, 3'b000, 0,0,  0,IMM_U,1,0,1,1,ADD,0,2'b01);

        // ---------------- Undefined opcode (FENCE/SYSTEM) ----------------
        run_test("UNDEFINED", 5'b00011, 1'b0, 3'b000, 0,0,  0,IMM_I,0,0,0,0,ADD,0,2'b01);

        // ---------------- Summary ----------------
        $display("========== Final ==========");
        $display("Tong so test : %0d", test_num);
        $display("PASS         : %0d", pass_count);
        $display("FAIL         : %0d", fail_count);
        if (fail_count == 0)
            $display(">>> ALL PASS TEST <<<");
        else
            $display(">>> %0d TEST FAIL <<<", fail_count);

        $finish;
    end

endmodule