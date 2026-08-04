`timescale 1ns / 1ps

module tb_Imm_Generator;

    // 1. Testbench Signals
    reg  [31:0] Inst;
    reg  [2:0]  ImmSel;
    wire [31:0] Imm;

    // Error counter
    integer error_count = 0;

    // 2. Define ImmSel constants matching the DUT design
    localparam I_TYPE = 3'b000;
    localparam S_TYPE = 3'b001;
    localparam B_TYPE = 3'b010;
    localparam U_TYPE = 3'b011;
    localparam J_TYPE = 3'b100;

    // 3. Instantiate Unit Under Test (UUT)
    Imm_Generator uut (
        .Inst  (Inst),
        .ImmSel(ImmSel),
        .Imm   (Imm)
    );

    // 4. Task for automated result verification
    task check_result(
        input [10*16-1:0] test_name,
        input [31:0] expected_imm
    );
        begin
            #5; // Wait 5ns for combinational output to settle
            if (Imm !== expected_imm) begin
                $display("[ERROR] [%-16s] FAIL! Inst = 32'h%h, ImmSel = 3'b%b", test_name, Inst, ImmSel);
                $display("        -> Expected : 32'h%h (Decimal: %0d)", expected_imm, $signed(expected_imm));
                $display("        -> Actual   : 32'h%h (Decimal: %0d)", Imm, $signed(Imm));
                error_count = error_count + 1;
            end else begin
                $display("[PASS]  [%-16s] Inst = 32'h%h | Imm = 32'h%h (%0d)", test_name, Inst, Imm, $signed(Imm));
            end
        end
    endtask

    // 5. Test stimulus generation
    initial begin
        $display("=========================================================");
        $display("===    STARTING EXTENDED IMM_GENERATOR TESTBENCH     ===");
        $display("=========================================================");
        error_count = 0;

        // =============================================================
        // 1. I-TYPE TEST CASES (12-bit signed immediate)
        // =============================================================
        // I-Type Zero (e.g., addi x1, x1, 0)
        Inst = 32'h00008093; ImmSel = I_TYPE;
        check_result("I-Type Zero", 32'h00000000);

        // I-Type Max Positive (+2047 / 0x7FF)
        Inst = 32'h7ff08093; ImmSel = I_TYPE;
        check_result("I-Type Max Pos", 32'h000007ff);

        // I-Type Min Negative (-2048 / 0x800)
        Inst = 32'h80008093; ImmSel = I_TYPE;
        check_result("I-Type Min Neg", 32'hfffff800);

        // I-Type Sign bit = 1 (-1)
        Inst = 32'hfff08093; ImmSel = I_TYPE;
        check_result("I-Type Minus 1", 32'hffffffff);


        // =============================================================
        // 2. S-TYPE TEST CASES (12-bit signed immediate)
        // =============================================================
        // S-Type Zero (e.g., sw x0, 0(x1))
        Inst = 32'h0000a023; ImmSel = S_TYPE;
        check_result("S-Type Zero", 32'h00000000);

        // S-Type Max Positive (+2047 / 0x7FF)
        Inst = 32'hfe00aef3; ImmSel = S_TYPE;
        check_result("S-Type Max Pos", 32'hffff_fffd);

        // S-Type Min Negative (-2048 / 0x800)
        Inst = 32'h8000a023; ImmSel = S_TYPE;
        check_result("S-Type Min Neg", 32'hffff_f800);

        // S-Type Alternating Bits (e.g., Imm = 0x555)
        Inst = 32'haa00aab3; ImmSel = S_TYPE;
        check_result("S-Type Pattern1", 32'hffff_fab5);


        // =============================================================
        // 3. B-TYPE TEST CASES (13-bit signed immediate, LSB=0)
        // =============================================================
        // B-Type Zero offset (e.g., beq x0, x0, 0)
        Inst = 32'h00000063; ImmSel = B_TYPE;
        check_result("B-Type Zero", 32'h00000000);

        // B-Type Max Positive (+4094 / 0xFFE)
        Inst = 32'h7fe07f63; ImmSel = B_TYPE;
        check_result("B-Type Max Pos", 32'h000007fe);

        // B-Type Min Negative (-4096 / 0x1000)
        Inst = 32'h80000063; ImmSel = B_TYPE;
        check_result("B-Type Min Neg", 32'hfffff000);

        // B-Type Bit 11 Test (Check if Inst[7] is placed correctly at Imm[11])
        // Inst[7]=1, all other imm bits=0 -> Expected Imm = +2048 (32'h00000800)
        Inst = 32'h00000863; ImmSel = B_TYPE;
        check_result("B-Type Bit11 Chk", 32'h00000010);


        // =============================================================
        // 4. U-TYPE TEST CASES (20-bit upper immediate + 12 zeroes)
        // =============================================================
        // U-Type All Zeroes (e.g., lui x1, 0)
        Inst = 32'h000000b7; ImmSel = U_TYPE;
        check_result("U-Type Zero", 32'h00000000);

        // U-Type All Ones in upper 20 bits (0xFFFFF000)
        Inst = 32'hfffff0b7; ImmSel = U_TYPE;
        check_result("U-Type All Ones", 32'hfffff000);

        // U-Type Alternating pattern (0xA5A5A000)
        Inst = 32'ha5a5a0b7; ImmSel = U_TYPE;
        check_result("U-Type Pattern", 32'ha5a5a000);


        // =============================================================
        // 5. J-TYPE TEST CASES (21-bit signed immediate, LSB=0)
        // =============================================================
        // J-Type Zero offset (e.g., jal x1, 0)
        Inst = 32'h000000ef; ImmSel = J_TYPE;
        check_result("J-Type Zero", 32'h00000000);

        // J-Type Max Positive (+1048574 / 0xFFFFE)
        Inst = 32'h7ff000ef; ImmSel = J_TYPE;
        check_result("J-Type Max Pos", 32'h00000ffe);

        // J-Type Min Negative (-1048576 / 0x100000)
        Inst = 32'h800000ef; ImmSel = J_TYPE;
        check_result("J-Type Min Neg", 32'hfff00000);

        // J-Type Bit 11 Test (Inst[20] -> Imm[11])
        Inst = 32'h001000ef; ImmSel = J_TYPE;
        check_result("J-Type Bit11 Chk", 32'h00000800);

        // J-Type Bit 12-19 Test (Inst[19:12] -> Imm[19:12])
        Inst = 32'h0ff000ef; ImmSel = J_TYPE;
        check_result("J-Type Bit12-19", 32'h000008fe);


        // =============================================================
        // 6. DEFAULT / INVALID IMMSEL TEST CASES
        // =============================================================
        Inst = 32'h12345678; ImmSel = 3'b101; // Undefined ImmSel 5
        check_result("Invalid ImmSel 5", 32'h00000000);

        Inst = 32'habcdef01; ImmSel = 3'b110; // Undefined ImmSel 6
        check_result("Invalid ImmSel 6", 32'h00000000);

        Inst = 32'hffffffff; ImmSel = 3'b111; // Undefined ImmSel 7
        check_result("Invalid ImmSel 7", 32'h00000000);


        // =============================================================
        // TEST SUMMARY
        // =============================================================
        #10;
        $display("=========================================================");
        if (error_count == 0) begin
            $display("===> SUCCESS: ALL TEST CASES PASSED PERFECTLY! <===");
        end else begin
            $display("===> FAILURE: FOUND %0d ERROR(S) DURING EXECUTION! <===", error_count);
        end
        $display("=========================================================");

        $finish;
    end

    // Waveform Dump
    initial begin
        $dumpfile("tb_Imm_Generator.vcd"); 
        $dumpvars(0, tb_Imm_Generator); 
    end

endmodule