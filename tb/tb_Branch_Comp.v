`timescale 1ns / 1ps

module tb_Branch_Comp;

    // 1. Testbench Signals
    reg  [31:0] operand_0;
    reg  [31:0] operand_1;
    reg         BrUn;
    wire        BrEq;
    wire        BrLT;

    // Error Counter
    integer error_count = 0;

    // 2. Instantiate the Unit Under Test (UUT)
    Branch_Comp uut (
        .operand_0 (operand_0),
        .operand_1 (operand_1),
        .BrUn      (BrUn),
        .BrEq      (BrEq),
        .BrLT      (BrLT)
    );

    // 3. Task for automated verification and status printing
    task check_results(
        input [40*16-1:0] test_name, 
        input            expected_BrEq, 
        input            expected_BrLT
    );
        begin
            #1; // Short delay for combinational settling
            if (BrEq !== expected_BrEq || BrLT !== expected_BrLT) begin
                $display("[ERROR] %0s | Expected: BrEq=%b, BrLT=%b | Got: BrEq=%b, BrLT=%b",
                         test_name, expected_BrEq, expected_BrLT, BrEq, BrLT);
                error_count = error_count + 1;
            end else begin
                $display("[PASS]  %0s | BrEq=%b, BrLT=%b", test_name, BrEq, BrLT);
            end
        end
    endtask

    // 4. Initial block for stimulus generation
    initial begin
        $display("=== STARTING BRANCH_COMP MODULE TESTBENCH ===");
        error_count = 0;

        // -------------------------------------------------------------
        // TEST CASE 1: Unsigned Equality Tests
        // -------------------------------------------------------------
        operand_0 = 32'd100;
        operand_1 = 32'd100;
        BrUn      = 1'b1;
        #10;
        check_results("TC1a: Unsigned Equal (100 == 100)", 1'b1, 1'b0);

        operand_0 = 32'hFFFF_FFFF; // 4,294,967,295
        operand_1 = 32'hFFFF_FFFF;
        BrUn      = 1'b1;
        #10;
        check_results("TC1b: Unsigned Equal (0xFFFFFFFF == 0xFFFFFFFF)", 1'b1, 1'b0);

        // -------------------------------------------------------------
        // TEST CASE 2: Unsigned Less Than Tests (operand_0 < operand_1)
        // -------------------------------------------------------------
        operand_0 = 32'd50;
        operand_1 = 32'd100;
        BrUn      = 1'b1;
        #10;
        check_results("TC2a: Unsigned Less Than (50 < 100)", 1'b0, 1'b1);

        operand_0 = 32'd101;
        operand_1 = 32'd102;
        BrUn      = 1'b1;
        #10;
        check_results("TC2b: Unsigned Less Than (101 < 102)", 1'b0, 1'b1);

        operand_0 = -32'd2; // Treated as 0xFFFFFFFE (4,294,967,294)
        operand_1 = -32'd1; // Treated as 0xFFFFFFFF (4,294,967,295)
        BrUn      = 1'b1;
        #10;
        check_results("TC2c: Unsigned Less Than (0xFFFFFFFE < 0xFFFFFFFF)", 1'b0, 1'b1);

        // -------------------------------------------------------------
        // TEST CASE 3: Unsigned Greater Than Tests (operand_0 > operand_1)
        // -------------------------------------------------------------
        operand_0 = 32'd200;
        operand_1 = 32'd100;
        BrUn      = 1'b1;
        #10;
        check_results("TC3a: Unsigned Greater Than (200 > 100)", 1'b0, 1'b0);

        operand_0 = -32'd15; // 0xFFFFFFF1
        operand_1 = -32'd30; // 0xFFFFFFE2
        BrUn      = 1'b1;
        #10;
        check_results("TC3b: Unsigned Greater Than (0xFFFFFFF1 > 0xFFFFFFE2)", 1'b0, 1'b0);

        // -------------------------------------------------------------
        // TEST CASE 4: Signed vs Unsigned Comparison Difference
        // -------------------------------------------------------------
        operand_0 = 32'hFFFF_FFFF; // Unsigned: 4,294,967,295 | Signed: -1
        operand_1 = 32'd1;          // Unsigned: 1             | Signed: +1
        BrUn      = 1'b1;          // Unsigned Mode
        #10;
        check_results("TC4a: Unsigned Comparison (0xFFFFFFFF > 1)", 1'b0, 1'b0);

        // -------------------------------------------------------------
        // TEST CASE 5: Signed Comparison Tests
        // -------------------------------------------------------------
        operand_0 = 32'hFFFF_FFFF; // -1
        operand_1 = 32'hFFFF_FFFF; // -1
        BrUn      = 1'b0;          // Signed Mode
        #10;
        check_results("TC5a: Signed Equal (-1 == -1)", 1'b1, 1'b0);

        operand_0 = 32'hFFFF_FFFF; // -1
        operand_1 = 32'd1;          // +1
        BrUn      = 1'b0;          // Signed Mode
        #10;
        check_results("TC5b: Signed Comparison (-1 < 1)", 1'b0, 1'b1);

        operand_0 = -32'd10;       // -10 (0xFFFFFFF6)
        operand_1 = -32'd5;        // -5  (0xFFFFFFFB)
        BrUn      = 1'b0;          // Signed Mode
        #10;
        check_results("TC5c: Signed Less Than (-10 < -5)", 1'b0, 1'b1);

        operand_0 = -32'd5;        // -5  (0xFFFFFFFB)
        operand_1 = -32'd10;       // -10 (0xFFFFFFF6)
        BrUn      = 1'b0;          // Signed Mode
        #10;
        check_results("TC5d: Signed Greater Than (-5 > -10)", 1'b0, 1'b0);

        operand_0 = 32'd36;        // +36
        operand_1 = 32'd12;        // +12
        BrUn      = 1'b0;          // Signed Mode
        #10;
        check_results("TC5e: Signed Positive Greater Than (36 > 12)", 1'b0, 1'b0);

        // -------------------------------------------------------------
        // TEST SUMMARY
        // -------------------------------------------------------------
        #10;
        $display("--------------------------------------------------");
        if (error_count == 0) begin
            $display("===> ALL TEST CASES PASSED SUCCESSFULLY! <===");
        end else begin
            $display("===> DETECTED %0d ERROR(S) DURING TESTING! <===", error_count);
        end
        $display("--------------------------------------------------");

        $finish;
    end

    // 5. Cadence Xcelium / NC-Verilog waveform dumping
    initial begin
        $shm_open("build_xcelium/waves.shm");
        $shm_probe("AS");
    end 

endmodule