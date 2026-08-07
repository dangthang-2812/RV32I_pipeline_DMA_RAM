`timescale 1ns / 1ps

module tb_RISCV_Pipeline_compare;

    reg clk;
    reg rst_n;

    localparam CLK_PERIOD = 10;
    localparam integer MAX_CYCLES = 400;

    integer i;
    integer mismatch_count;
    integer golden_reg_fd;
    integer golden_dmem_fd;
    integer cycle_count;

    reg [31:0] golden_regs [0:31];
    reg [31:0] golden_dmem  [0:255];

    RISCV_Pipeline dut (
        .clk   (clk),
        .rst_n (rst_n)
    );

    initial begin
        $readmemh("mem/imem.hex", dut.IMEM_inst.memory);
        $readmemh("mem/dmem_init.hex", dut.DMEM_inst.memory);

        golden_reg_fd = $fopen("mem/golden_regfile_out.hex", "r");
        if (golden_reg_fd == 0) begin
            $display("[ERROR] Missing mem/golden_regfile_out.hex. Run sw/golden_model.exe first.");
            $finish;
        end
        golden_dmem_fd = $fopen("mem/golden_dmem_out.hex", "r");
        if (golden_dmem_fd == 0) begin
            $display("[ERROR] Missing mem/golden_dmem_out.hex. Run sw/golden_model.exe first.");
            $finish;
        end

        $readmemh("mem/golden_regfile_out.hex", golden_regs);
        $readmemh("mem/golden_dmem_out.hex", golden_dmem);

        $display("==================================================");
        $display("[INFO] Loaded mem/imem.hex, mem/dmem_init.hex");
        $display("[INFO] Loaded golden outputs from mem/golden_regfile_out.hex and mem/golden_dmem_out.hex");
        $display("==================================================");
    end

    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    initial begin
        $monitor("Time: %5t | PC: 0x%08h | Instr: 0x%08h | ALU_Out: 0x%08h | WB_Data: 0x%08h",
                 $time,
                 dut.PC_out_F,
                 dut.Instr_F,
                 dut.ALU_out_E,
                 dut.DataD_W);
    end

    initial begin
        cycle_count = 0;
        rst_n = 1'b0;
        #(CLK_PERIOD * 2);
        rst_n = 1'b1;

        repeat (MAX_CYCLES) begin
            @(posedge clk);
            if (rst_n) begin
                cycle_count = cycle_count + 1;
            end
        end

        $display("[%0t ns] --- Reached %0d cycles, dumping DUT state ---", $time, cycle_count);

        $writememh("mem/rtl_regfile_out.hex", dut.Reg_inst.registers);
        $writememh("mem/rtl_dmem_out.hex", dut.DMEM_inst.memory);

        mismatch_count = 0;
        for (i = 0; i < 32; i = i + 1) begin
            if (dut.Reg_inst.registers[i] !== golden_regs[i]) begin
                mismatch_count = mismatch_count + 1;
                $display("[MISMATCH] x%0d RTL=0x%08h GOLDEN=0x%08h", i, dut.Reg_inst.registers[i], golden_regs[i]);
            end
        end

        for (i = 0; i < 256; i = i + 1) begin
            if (dut.DMEM_inst.memory[i] !== golden_dmem[i]) begin
                mismatch_count = mismatch_count + 1;
                $display("[MISMATCH] DMEM[%0d] RTL=0x%08h GOLDEN=0x%08h", i, dut.DMEM_inst.memory[i], golden_dmem[i]);
            end
        end

        if (mismatch_count == 0) begin
            $display("[%0t ns] *** GOLDEN COMPARISON PASSED ***", $time);
        end else begin
            $display("[%0t ns] *** GOLDEN COMPARISON FAILED: %0d mismatches ***", $time, mismatch_count);
        end

        $finish;
    end

    initial begin
        $dumpfile("tb_RISCV_Pipeline_compare.vcd");
        $dumpvars(0, tb_RISCV_Pipeline_compare);
    end

endmodule