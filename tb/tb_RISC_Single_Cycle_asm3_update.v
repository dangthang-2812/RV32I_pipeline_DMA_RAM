`timescale 1ns / 1ps

module tb_RISCV_Single_Cycle;

    // =======================================================================
    // 1. SIGNAL DECLARATIONS
    // =======================================================================
    reg clk;
    reg rst_n;
    integer cycle_cnt;
    integer fail_count;
    integer i;

    parameter CLK_PERIOD = 10;

    // Update instruction count: +16 instructions from BLTU/BGEU, -2 instructions from removed SLTIU
    parameter NUM_INSTR_CRT0 = 2;
    parameter NUM_INSTR_MAIN = 83;
    parameter TOTAL_INSTR    = NUM_INSTR_CRT0 + NUM_INSTR_MAIN;
    parameter RUN_CYCLES     = TOTAL_INSTR + 1;

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

    initial cycle_cnt = 0;
    always @(posedge clk) begin
        if (rst_n) cycle_cnt = cycle_cnt + 1;
    end

    // =======================================================================
    // 4. CHECK TABLE - Match by PC (Instruction Address)
    // =======================================================================
    // Increase NUM_CHECKS from 33 to 36 (+4 B-type tests, -1 sltiu test)
    localparam integer NUM_CHECKS = 36;

    reg [31:0]  chk_pc    [0:NUM_CHECKS-1];
    reg [0:0]   chk_is_mem[0:NUM_CHECKS-1];
    reg [31:0]  chk_target[0:NUM_CHECKS-1];
    reg [31:0]  chk_exp   [0:NUM_CHECKS-1];
    reg [30*8:1] chk_name [0:NUM_CHECKS-1];
    reg [0:0]   chk_done  [0:NUM_CHECKS-1];

    initial begin
        // ---------------- R-TYPE ----------------
        chk_pc[0]=32'h0018; chk_is_mem[0]=0; chk_target[0]=32'd28; chk_exp[0]=32'h00000008; chk_name[0]="ADD";
        chk_pc[1]=32'h001C; chk_is_mem[1]=0; chk_target[1]=32'd29; chk_exp[1]=32'h00000002; chk_name[1]="SUB";
        chk_pc[2]=32'h0020; chk_is_mem[2]=0; chk_target[2]=32'd30; chk_exp[2]=32'h00000001; chk_name[2]="AND";
        chk_pc[3]=32'h0024; chk_is_mem[3]=0; chk_target[3]=32'd31; chk_exp[3]=32'h00000007; chk_name[3]="OR";
        chk_pc[4]=32'h0028; chk_is_mem[4]=0; chk_target[4]=32'd8;  chk_exp[4]=32'h00000006; chk_name[4]="XOR";
        chk_pc[5]=32'h002C; chk_is_mem[5]=0; chk_target[5]=32'd9;  chk_exp[5]=32'h00000028; chk_name[5]="SLL";
        chk_pc[6]=32'h0030; chk_is_mem[6]=0; chk_target[6]=32'd18; chk_exp[6]=32'h00000000; chk_name[6]="SRL";
        chk_pc[7]=32'h0034; chk_is_mem[7]=0; chk_target[7]=32'd19; chk_exp[7]=32'hFFFFFFFF; chk_name[7]="SRA";
        chk_pc[8]=32'h0038; chk_is_mem[8]=0; chk_target[8]=32'd20; chk_exp[8]=32'h00000001; chk_name[8]="SLT";
        // ---------------- J-TYPE ----------------
        chk_pc[9]=32'h0048;  chk_is_mem[9]=0;  chk_target[9]=32'd3;  chk_exp[9]=32'h00000001;  chk_name[9]="JAL_target";
        chk_pc[10]=32'h0040; chk_is_mem[10]=0; chk_target[10]=32'd6; chk_exp[10]=32'h00000001; chk_name[10]="JAL_linkaddr";
        chk_pc[11]=32'h0060; chk_is_mem[11]=0; chk_target[11]=32'd4; chk_exp[11]=32'h00000001; chk_name[11]="JALR_target";
        chk_pc[12]=32'h0058; chk_is_mem[12]=0; chk_target[12]=32'd7; chk_exp[12]=32'h00000001; chk_name[12]="JALR_linkaddr";
        // ---------------- U-TYPE ----------------
        chk_pc[13]=32'h0068; chk_is_mem[13]=0; chk_target[13]=32'd5;  chk_exp[13]=32'hDEADB000; chk_name[13]="LUI";
        chk_pc[14]=32'h0074; chk_is_mem[14]=0; chk_target[14]=32'd21; chk_exp[14]=32'h00000FFC; chk_name[14]="AUIPC_diff";
        // ---------------- B-TYPE ----------------
        chk_pc[15]=32'h00A0; chk_is_mem[15]=1; chk_target[15]=32'd0;  chk_exp[15]=32'h000000AA; chk_name[15]="BEQ_Taken";
        chk_pc[16]=32'h00A8; chk_is_mem[16]=1; chk_target[16]=32'd4;  chk_exp[16]=32'h000000AA; chk_name[16]="BEQ_NotTaken";
        chk_pc[17]=32'h00C0; chk_is_mem[17]=1; chk_target[17]=32'd8;  chk_exp[17]=32'h000000AA; chk_name[17]="BNE_Taken";
        chk_pc[18]=32'h00C8; chk_is_mem[18]=1; chk_target[18]=32'd12; chk_exp[18]=32'h000000AA; chk_name[18]="BNE_NotTaken";
        chk_pc[19]=32'h00E0; chk_is_mem[19]=1; chk_target[19]=32'd16; chk_exp[19]=32'h000000AA; chk_name[19]="BLT_Taken";
        chk_pc[20]=32'h00E8; chk_is_mem[20]=1; chk_target[20]=32'd20; chk_exp[20]=32'h000000AA; chk_name[20]="BLT_NotTaken";
        chk_pc[21]=32'h0100; chk_is_mem[21]=1; chk_target[21]=32'd24; chk_exp[21]=32'h000000AA; chk_name[21]="BGE_Taken";
        chk_pc[22]=32'h0108; chk_is_mem[22]=1; chk_target[22]=32'd28; chk_exp[22]=32'h000000AA; chk_name[22]="BGE_NotTaken";
        chk_pc[23]=32'h0120; chk_is_mem[23]=1; chk_target[23]=32'd32; chk_exp[23]=32'h000000AA; chk_name[23]="BLTU_Taken";
        chk_pc[24]=32'h0128; chk_is_mem[24]=1; chk_target[24]=32'd36; chk_exp[24]=32'h000000AA; chk_name[24]="BLTU_NotTaken";
        chk_pc[25]=32'h0140; chk_is_mem[25]=1; chk_target[25]=32'd40; chk_exp[25]=32'h000000AA; chk_name[25]="BGEU_Taken";
        chk_pc[26]=32'h0148; chk_is_mem[26]=1; chk_target[26]=32'd44; chk_exp[26]=32'h000000AA; chk_name[26]="BGEU_NotTaken";
        // ---------------- I-TYPE & MEMORY ----------------
        chk_pc[27]=32'h0158; chk_is_mem[27]=1; chk_target[27]=32'd48; chk_exp[27]=32'h0000000F; chk_name[27]="ADDI";
        chk_pc[28]=32'h0160; chk_is_mem[28]=1; chk_target[28]=32'd52; chk_exp[28]=32'h00000001; chk_name[28]="SLTI";
        chk_pc[29]=32'h0168; chk_is_mem[29]=1; chk_target[29]=32'd56; chk_exp[29]=32'h00000008; chk_name[29]="XORI";
        chk_pc[30]=32'h0170; chk_is_mem[30]=1; chk_target[30]=32'd60; chk_exp[30]=32'h00000018; chk_name[30]="ORI";
        chk_pc[31]=32'h0178; chk_is_mem[31]=1; chk_target[31]=32'd64; chk_exp[31]=32'h00000008; chk_name[31]="ANDI";
        chk_pc[32]=32'h0180; chk_is_mem[32]=1; chk_target[32]=32'd68; chk_exp[32]=32'h00000020; chk_name[32]="SLLI";
        chk_pc[33]=32'h0188; chk_is_mem[33]=1; chk_target[33]=32'd72; chk_exp[33]=32'h00000010; chk_name[33]="SRLI";
        chk_pc[34]=32'h0190; chk_is_mem[34]=1; chk_target[34]=32'd76; chk_exp[34]=32'h00000004; chk_name[34]="SRAI";
        chk_pc[35]=32'h0198; chk_is_mem[35]=1; chk_target[35]=32'd80; chk_exp[35]=32'h0000000F; chk_name[35]="LW";

        for (i = 0; i < NUM_CHECKS; i = i + 1) chk_done[i] = 1'b0;
    end

    // =======================================================================
    // 5. REAL-TIME CHECKER - Print PASS/FAIL immediately when the instruction executes
    // =======================================================================
    reg [31:0] rt_value;

    always @(posedge clk) begin
        if (rst_n) begin
            for (i = 0; i < NUM_CHECKS; i = i + 1) begin
                if (!chk_done[i] && (uut.PC_out_top == chk_pc[i])) begin
                    if (!chk_is_mem[i] && uut.RegWEn_top) begin
                        rt_value   = uut.DataD_top;
                        chk_done[i] = 1'b1;
                        if (rt_value === chk_exp[i])
                            $display("[%6t ns] [PASS] REG %30s: x%0d = 0x%08h",
                                     $time, chk_name[i], chk_target[i], rt_value);
                        else
                            $display("[%6t ns] [FAIL] REG %30s: x%0d expected 0x%08h, got 0x%08h",
                                     $time, chk_name[i], chk_target[i], chk_exp[i], rt_value);
                    end else if (chk_is_mem[i] && uut.MemRW_top) begin
                        rt_value   = uut.DataB_top;
                        chk_done[i] = 1'b1;
                        if (rt_value === chk_exp[i])
                            $display("[%6t ns] [PASS] MEM %30s: DMEM[0x%02h] = 0x%08h",
                                     $time, chk_name[i], chk_target[i], rt_value);
                        else
                            $display("[%6t ns] [FAIL] MEM %30s: DMEM[0x%02h] expected 0x%08h, got 0x%08h",
                                     $time, chk_name[i], chk_target[i], chk_exp[i], rt_value);
                    end
                end
            end
        end
    end

    // =======================================================================
    // 6. FINAL STATE CHECKER
    // =======================================================================
    task check_final_state;
        begin
            fail_count = 0;
            $display("\n==================================================================");
            $display("       FINAL STATE SUMMARY (REGISTERS & DMEM)");
            $display("==================================================================");

            for (i = 0; i < NUM_CHECKS; i = i + 1) begin
                if (chk_is_mem[i])
                    rt_value = uut.DMEM_inst.memory[chk_target[i][9:2]];
                else
                    rt_value = uut.Reg_inst.registers[chk_target[i]];

                if (!chk_done[i]) begin
                    $display("[NOT OBSERVED] %0s (PC=0x%04h never executed)", chk_name[i], chk_pc[i]);
                    fail_count = fail_count + 1;
                end else if (rt_value !== chk_exp[i]) begin
                    $display("[FAIL] %0s: final value 0x%08h, expected 0x%08h",
                             chk_name[i], rt_value, chk_exp[i]);
                    fail_count = fail_count + 1;
                end
            end

            $display("       Executed %0d instructions in %0d cycles", TOTAL_INSTR, cycle_cnt);
            $display("       Result: %0d PASS / %0d FAIL (total %0d)",
                     NUM_CHECKS - fail_count, fail_count, NUM_CHECKS);
            if (fail_count == 0)
                $display("       >>> ALL TESTS PASSED SUCCESSFULLY! <<<");
            else
                $display("       >>> %0d TESTS FAILED! CHECK YOUR LOG. <<<", fail_count);
            $display("==================================================================\n");
        end
    endtask

    // =======================================================================
    // 7. CONTROL RUN SEQUENCE
    // =======================================================================
    initial begin
        rst_n = 1'b0;
        #20;
        rst_n = 1'b1;
        $display("--> Reset released at %0t ns. Running %0d cycles (%0d instructions + 1)...\n",
                 $time, RUN_CYCLES, TOTAL_INSTR);

        repeat (RUN_CYCLES) @(posedge clk);

        check_final_state();

        $writememh("mem/dmem_out.hex", uut.DMEM_inst.memory);
        $writememh("mem/regfile_out.hex", uut.Reg_inst.registers);

        $finish;
    end

    // =======================================================================
    // 8. WAVEFORM DUMP
    // =======================================================================
    initial begin
        $dumpfile("tb_RISCV_Single_Cycle.vcd");
        $dumpvars(0, tb_RISCV_Single_Cycle);
    end

endmodule