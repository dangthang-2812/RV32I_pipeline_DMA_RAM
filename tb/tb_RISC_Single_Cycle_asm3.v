`timescale 1ns / 1ps

module tb_RISCV_Single_Cycle;

    // =======================================================================
    // 1. SIGNAL DECLARATIONS
    // =======================================================================
    reg clk;
    reg rst_n;
    integer cycle_cnt;
    integer fail_count; // Error counter

    // Clock period: 10ns (100 MHz)
    parameter CLK_PERIOD = 10;

    // =======================================================================
    // 2. DUT INSTANTIATION
    // =======================================================================
    RISCV_Single_Cycle uut (
        .clk   (clk),
        .rst_n (rst_n)
    );

    // =======================================================================
    // 3. CLOCK & INIT MEMORY
    // =======================================================================
    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    initial begin
        $readmemh("mem/imem.hex", uut.IMEM_inst.memory);
        $readmemh("mem/dmem_init.hex", uut.DMEM_inst.memory);
    end

    // =======================================================================
    // 4. VERIFY TASKS
    // =======================================================================
    task verify_reg;
        input integer reg_idx;
        input [31:0] expected_val;
        input [80*8:1] test_name;
        begin
            if (uut.Reg_inst.registers[reg_idx] === expected_val) begin
                $display("[PASS] REG %s: x%0d = 0x%08h", test_name, reg_idx, expected_val);
            end else begin
                $display("[FAIL] REG %s: x%0d expected 0x%08h, got 0x%08h", 
                         test_name, reg_idx, expected_val, uut.Reg_inst.registers[reg_idx]);
                fail_count = fail_count + 1;
            end
        end
    endtask

    task verify_dmem;
        input [31:0] byte_addr;   
        input [31:0] expected_val;
        input [80*8:1] test_name; 
        
        reg [7:0] word_addr;      
        begin
            word_addr = byte_addr[9:2]; // Convert byte address to word address
            if (uut.DMEM_inst.memory[word_addr] === expected_val) begin
                $display("[PASS] MEM %s: DMEM[0x%02h] = 0x%08h", test_name, byte_addr, expected_val);
            end else begin
                $display("[FAIL] MEM %s: DMEM[0x%02h] expected 0x%08h, got 0x%08h", 
                         test_name, byte_addr, expected_val, uut.DMEM_inst.memory[word_addr]);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // =======================================================================
    // 5. FINAL STATE CHECKER
    // =======================================================================
    task check_final_state;
        begin
            fail_count = 0;
            $display("\n==================================================================");
            $display("       VERIFYING FINAL STATE (REGISTERS & DMEM)                   "); 
            $display("==================================================================");

            // --------- CHECK R, J, U BLOCKS (From Registers) ---------
            $display("--- 1. Checking R-Type Instructions ---");
            verify_reg(28, 32'h00000008, "ADD");
            verify_reg(29, 32'h00000002, "SUB");
            verify_reg(30, 32'h00000001, "AND");
            verify_reg(31, 32'h00000007, "OR");
            verify_reg(8,  32'h00000006, "XOR");
            verify_reg(9,  32'h00000028, "SLL");
            verify_reg(18, 32'h00000000, "SRL");
            verify_reg(19, 32'hFFFFFFFF, "SRA");
            verify_reg(20, 32'h00000001, "SLT");
            $display("\n--- 2. Checking J-Type Instructions ---");
            verify_reg(3,  32'h00000001, "JAL target");
            verify_reg(6,  32'h00000001, "JAL linkaddr");
            verify_reg(4,  32'h00000001, "JALR target");
            verify_reg(7,  32'h00000001, "JALR linkaddr");
            $display("\n--- 3. Checking U-Type Instructions ---");
            verify_reg(5,  32'hDEADB000, "LUI (Bug test)");
            verify_reg(21, 32'h00000FFC, "AUIPC diff");

            // --------- CHECK I, B, S BLOCKS (From DMEM) ---------
            $display("\n--- 4. Checking B-Type Block ---");
            verify_dmem(32'h00, 32'h000000AA, "BEQ Taken");
            verify_dmem(32'h04, 32'h000000AA, "BEQ Not Taken");
            verify_dmem(32'h08, 32'h000000AA, "BNE Taken");
            verify_dmem(32'h0C, 32'h000000AA, "BNE Not Taken");
            verify_dmem(32'h10, 32'h000000AA, "BLT Taken");
            verify_dmem(32'h14, 32'h000000AA, "BLT Not Taken");
            verify_dmem(32'h18, 32'h000000AA, "BGE Taken");
            verify_dmem(32'h1C, 32'h000000AA, "BGE Not Taken");

            $display("\n--- 5. Checking I-Type Block ---");
            verify_dmem(32'h20, 32'h0000000F, "ADDI (15)");
            verify_dmem(32'h24, 32'h00000001, "SLTI (1)");
            verify_dmem(32'h28, 32'h00000001, "SLTIU (1)");
            verify_dmem(32'h2C, 32'h00000008, "XORI (8)");
            verify_dmem(32'h30, 32'h00000018, "ORI (24)");
            verify_dmem(32'h34, 32'h00000008, "ANDI (8)");
            verify_dmem(32'h38, 32'h00000020, "SLLI (32)");
            verify_dmem(32'h3C, 32'h00000010, "SRLI (16)");
            verify_dmem(32'h40, 32'h00000004, "SRAI (4)");
            verify_dmem(32'h44, 32'h0000000F, "LW (15)");

            $display("\n==================================================================");
            if (fail_count == 0)
                $display("       >>> ALL TESTS PASSED SUCCESSFULLY! <<<                     "); 
            else
                $display("       >>> %0d TESTS FAILED! CHECK YOUR LOG. <<<                 ", fail_count);
            $display("==================================================================\n");
        end
    endtask

    // =======================================================================
    // 6. CONTROL RUN SEQUENCE
    // =======================================================================
    initial begin
        rst_n = 1'b0;
        #(CLK_PERIOD * 2);

        rst_n = 1'b1;
        $display("--> Reset released. CPU execution started...\n");

        // Increase delay to 150 cycles since the combined instruction count is quite large
        #(CLK_PERIOD * 150);

        check_final_state();

        $writememh("mem/dmem_out.hex", uut.DMEM_inst.memory);
        $writememh("mem/regfile_out.hex", uut.Reg_inst.registers);

        $finish;
    end

    // =======================================================================
    // 7. WAVEFORM DUMP
    // =======================================================================
    initial begin
        $dumpfile("RISCV_Sing.vcd");
        $dumpvars(0, tb_RISCV_Single_Cycle);
    end

endmodule