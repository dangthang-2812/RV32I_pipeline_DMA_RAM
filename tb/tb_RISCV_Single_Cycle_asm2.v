`timescale 1ns / 1ps

module tb_RISCV_Single_Cycle;

    // =======================================================================
    // 1. SIGNAL DECLARATIONS
    // =======================================================================
    reg clk;
    reg rst_n;
    integer cycle_cnt;
    integer fail_count; // Biến đếm số lượng lỗi

    // Clock period: 10ns (100 MHz)
    parameter CLK_PERIOD = 10;

    // =======================================================================
    // 2. INSTANTIATE DESIGN UNDER TEST (DUT)
    // =======================================================================
    RISCV_Single_Cycle uut (
        .clk   (clk),
        .rst_n (rst_n)
    );

    // =======================================================================
    // 3. CLOCK GENERATION
    // =======================================================================
    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    // =======================================================================
    // 4. LOAD HEX MEMORY FILES
    // =======================================================================
    initial begin
        $readmemh("mem/imem.hex", uut.IMEM_inst.memory);
        $readmemh("mem/dmem_init.hex", uut.DMEM_inst.memory);

        $display("==================================================");
        $display("[INFO] Loaded instruction memory from mem/imem.hex");
        $display("[INFO] Loaded data memory from mem/dmem_init.hex");
        $display("==================================================");
    end

    // =======================================================================
    // 5. DEBUG TASK: IN THÔNG SỐ TỪNG CHU KỲ
    // =======================================================================
    task print_cycle_info;
        begin
            $display("[Cycle %02d] PC=0x%08h | Instr=0x%08h | ALU=0x%08h", 
                     cycle_cnt, uut.PC_out_top, uut.Instruction_out_top, uut.ALU_out_top);
        end
    endtask

    // =======================================================================
    // 6. VERIFY TASKS (DATA MEMORY)
    // =======================================================================
    task verify_dmem;
        input [31:0] byte_addr;   // Địa chỉ theo byte
        input [31:0] expected_val;
        input [80*8:1] test_name; 
        
        reg [7:0] word_addr;      // Chuyển đổi sang địa chỉ word cho bộ nhớ RAM[cite: 2]
        begin
            word_addr = byte_addr[9:2]; //[cite: 2]
            if (uut.DMEM_inst.memory[word_addr] === expected_val) begin //[cite: 1]
                $display("[PASS] %s: DMEM[0x%02h] = 0x%08h", test_name, byte_addr, expected_val);
            end else begin
                $display("[FAIL] %s: DMEM[0x%02h] expected 0x%08h, got 0x%08h", 
                         test_name, byte_addr, expected_val, uut.DMEM_inst.memory[word_addr]); //[cite: 1]
                fail_count = fail_count + 1; //[cite: 1]
            end
        end
    endtask

    // =======================================================================
    // 7. TASK ĐỐI CHIẾU KẾT QUẢ CUỐI CÙNG SAU KHI CHẠY XONG
    // =======================================================================
    task check_final_state;
        begin
            fail_count = 0; //[cite: 1]
            $display("\n=================================================================="); //[cite: 1]
            $display("       VERIFYING FINAL STATE: DATA MEMORY (DMEM)                  "); 
            $display("=================================================================="); //[cite: 1]

            // 1. Kiểm tra khối lệnh B-Type (Kỳ vọng lưu giá trị PASS = 0x000000AA)
            $display("--- 1. Kiểm tra khối lệnh Branch (B-Type) ---");
            verify_dmem(32'h00, 32'h000000AA, "BEQ Taken");
            verify_dmem(32'h04, 32'h000000AA, "BEQ Not Taken");
            verify_dmem(32'h08, 32'h000000AA, "BNE Taken");
            verify_dmem(32'h0C, 32'h000000AA, "BNE Not Taken");
            verify_dmem(32'h10, 32'h000000AA, "BLT Taken");
            verify_dmem(32'h14, 32'h000000AA, "BLT Not Taken");
            verify_dmem(32'h18, 32'h000000AA, "BGE Taken");
            verify_dmem(32'h1C, 32'h000000AA, "BGE Not Taken");

            // 2. Kiểm tra khối lệnh I-Type (Số học, Logic & Truy cập bộ nhớ)
            $display("\n--- 2. Kiểm tra khối lệnh I-Type ---");
            verify_dmem(32'h20, 32'h0000000F, "I-Type: ADDI  (15)");       // 15
            verify_dmem(32'h24, 32'h00000001, "I-Type: SLTI  (1)");        // 1
            verify_dmem(32'h28, 32'h00000001, "I-Type: SLTIU (1)");        // 1
            verify_dmem(32'h2C, 32'h00000008, "I-Type: XORI  (8)");        // 8
            verify_dmem(32'h30, 32'h00000018, "I-Type: ORI   (24)");       // 24
            verify_dmem(32'h34, 32'h00000008, "I-Type: ANDI  (8)");        // 8
            verify_dmem(32'h38, 32'h00000020, "I-Type: SLLI  (32)");       // 32
            verify_dmem(32'h3C, 32'h00000010, "I-Type: SRLI  (16)");       // 16
            verify_dmem(32'h40, 32'h00000004, "I-Type: SRAI  (4)");        // 4
            verify_dmem(32'h44, 32'h0000000F, "I-Type: LW    (15)");       // 15

            $display("\n=================================================================="); //[cite: 1]
            if (fail_count == 0) //[cite: 1]
                $display("       >>> ALL TESTS PASSED SUCCESSFULLY! <<<                     "); 
            else
                $display("       >>> %0d TESTS FAILED! CHECK YOUR LOG. <<<                 ", fail_count); //[cite: 1]
            $display("==================================================================\n"); //[cite: 1]
        end
    endtask

    // =======================================================================
    // 8. AUTOMATIC CYCLE MONITORING
    // =======================================================================
    initial begin
        cycle_cnt = 0;
        @(posedge rst_n); 
        $display("\n======== BEGIN CPU INSTRUCTION EXECUTION ========");
        
        while (rst_n) begin
            #(CLK_PERIOD - 1);
            cycle_cnt = cycle_cnt + 1;
            print_cycle_info();
            #1; 
        end
    end

    // =======================================================================
    // 9. CONTROL SIGNAL & RESET GENERATION SEQUENCE
    // =======================================================================
    initial begin
        rst_n = 1'b0;
        #(CLK_PERIOD * 2);

        rst_n = 1'b1;
        $display("--> Reset released. CPU execution started...\n");

        // Delay khoảng 80 chu kỳ clock để đảm bảo CPU chạy tới vòng lặp vô hạn cuối cùng
        #(CLK_PERIOD * 80);

        // Chạy verify để kiểm tra xem DMEM có ghi đúng các giá trị kỳ vọng không
        check_final_state();

        // (Tùy chọn) Xuất kết quả memory ra file hex để xem
        $writememh("mem/dmem_out.hex", uut.DMEM_inst.memory);
        $writememh("mem/regfile_out.hex", uut.Reg_inst.registers);

        $finish;
    end

    // =======================================================================
    // 10. WAVEFORM DUMP
    // =======================================================================
    initial begin
        $dumpfile("RISCV_Sing.vcd"); //[cite: 1]
        $dumpvars(0, tb_RISCV_Single_Cycle); //[cite: 1]
    end

endmodule