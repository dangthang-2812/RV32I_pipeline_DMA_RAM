`timescale 1ns / 1ps
module tb_RISCV_Single_Cycle;

    reg clk;
    reg rst_n;

    localparam CLK_PERIOD = 10;

    // test.S co 28 lenh dong (main).
    // tong so chu ky = so lenh trong test + 1. Cong them 2 lenh crt0.S (_start) chay
    localparam integer NUM_INSTR_CRT0 = 2;
    localparam integer NUM_INSTR_MAIN = 28;
    localparam integer RUN_CYCLES     = NUM_INSTR_CRT0 + NUM_INSTR_MAIN + 1;

    // ------------------------------------------------------------------
    // DUT
    // ------------------------------------------------------------------
    RISCV_Single_Cycle dut (
        .clk   (clk),
        .rst_n (rst_n)
    );

    // ------------------------------------------------------------------
    // Clock
    // ------------------------------------------------------------------
    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    // ------------------------------------------------------------------
    // Nap INST / DATA khoi tao vao IMEM va DMEM.
    // ------------------------------------------------------------------
    initial begin
        $readmemh("mem/imem.hex",      dut.IMEM_inst.memory);
        $readmemh("mem/dmem_init.hex", dut.DMEM_inst.memory);
    end

    // ------------------------------------------------------------------
    // Bang ky vong, khop theo PC (dia chi lenh).
    // Tat ca ket qua deu nam trong RegFile (test.S moi khong con lenh
    // SW/LW nao) nen khong can co che kiem tra DMEM.
    // ------------------------------------------------------------------
    localparam integer NUM_CHECKS = 14;

    reg [31:0]  chk_pc    [0:NUM_CHECKS-1]; // dia chi lenh (PC) can bat
    reg [31:0]  chk_target[0:NUM_CHECKS-1]; // so hieu thanh ghi
    reg [31:0]  chk_exp   [0:NUM_CHECKS-1];
    reg [159:0] chk_name  [0:NUM_CHECKS-1];
    reg [0:0]   chk_done  [0:NUM_CHECKS-1]; // da bat duoc chua

    integer i, pass_total, fail_total;

    initial begin
        // ---------------- R-TYPE ----------------
        chk_pc[0]=32'h0018;  chk_target[0]=28;  chk_exp[0]=32'h00000008;  chk_name[0]="ADD";
        chk_pc[1]=32'h001C;  chk_target[1]=29;  chk_exp[1]=32'h00000002;  chk_name[1]="SUB";
        chk_pc[2]=32'h0020;  chk_target[2]=30;  chk_exp[2]=32'h00000001;  chk_name[2]="AND";
        chk_pc[3]=32'h0024;  chk_target[3]=31;  chk_exp[3]=32'h00000007;  chk_name[3]="OR";
        chk_pc[4]=32'h0028;  chk_target[4]=8;   chk_exp[4]=32'h00000006;  chk_name[4]="XOR";
        chk_pc[5]=32'h002C;  chk_target[5]=9;   chk_exp[5]=32'h00000028;  chk_name[5]="SLL";
        chk_pc[6]=32'h0030;  chk_target[6]=18;  chk_exp[6]=32'h00000000;  chk_name[6]="SRL";
        chk_pc[7]=32'h0034;  chk_target[7]=19;  chk_exp[7]=32'hFFFFFFFF;  chk_name[7]="SRA";
        chk_pc[8]=32'h0038;  chk_target[8]=20;  chk_exp[8]=32'h00000001;  chk_name[8]="SLT";
        // ---------------- JAL (dich nhay + gia tri tra ve) ----------------
        chk_pc[25]=32'h00D0; chk_is_mem[25]=0; chk_target[25]=3;  chk_exp[25]=32'h00000001; chk_name[25]="JAL_jump_target";
        chk_pc[26]=32'h00C8; chk_is_mem[26]=0; chk_target[26]=6;  chk_exp[26]=32'h00000001; chk_name[26]="JAL_return_addr";
        // ---------------- JALR (dich nhay + gia tri tra ve) ----------------
        chk_pc[27]=32'h00E8; chk_is_mem[27]=0; chk_target[27]=4;  chk_exp[27]=32'h00000001; chk_name[27]="JALR_jump_target";
        chk_pc[28]=32'h00E0; chk_is_mem[28]=0; chk_target[28]=7;  chk_exp[28]=32'h00000001; chk_name[28]="JALR_return_addr";
        // ---------------- AUIPC (tu doi chieu) ----------------
        chk_pc[13]=32'h0074; chk_target[13]=21; chk_exp[13]=32'h00000FFC; chk_name[13]="AUIPC";

        for (i = 0; i < NUM_CHECKS; i = i + 1) chk_done[i] = 1'b0;
    end

    // ------------------------------------------------------------------
    // Bat lenh THEO DUNG PC: khi PC_out_top khop voi 1 dia chi dang
    // theo doi VA co tin hieu ghi (RegWEn), in PASS/FAIL NGAY tai
    // thoi diem do
    // ------------------------------------------------------------------
    reg [31:0] rt_value;

    always @(posedge clk) begin
        if (rst_n) begin
            for (i = 0; i < NUM_CHECKS; i = i + 1) begin
                if (!chk_done[i] && (dut.PC_out_top == chk_pc[i]) && dut.RegWEn_top) begin
                    rt_value = dut.DataD_top;
                    chk_done[i] = 1'b1;
                    if (rt_value === chk_exp[i])
                        $display("[%0t ns] PASS  %-18s x[%0d] = 0x%08h",
                                  $time, chk_name[i], chk_target[i], rt_value);
                    else
                        $display("[%0t ns] FAIL  %-18s x[%0d] = 0x%08h (expect 0x%08h)",
                                  $time, chk_name[i], chk_target[i], rt_value, chk_exp[i]);
                end
            end
        end
    end

    // ------------------------------------------------------------------
    // Reset, chay dung RUN_CYCLES chu ky, roi tong ket
    // ------------------------------------------------------------------
    initial begin
        $dumpfile("tb_RISCV_Single_Cycle.vcd");
        $dumpvars(0, tb_RISCV_Single_Cycle);

        rst_n = 0;
        #20;
        rst_n = 1;
        $display("[%0t ns] --- Bat dau thuc thi (%0d lenh, %0d chu ky) ---", $time, NUM_INSTR_CRT0 + NUM_INSTR_MAIN, RUN_CYCLES);

        repeat (RUN_CYCLES) @(posedge clk);

        $display("=====================================================");
        $display("[%0t ns] Hoan thanh %0d lenh trong %0d chu ky", $time, NUM_INSTR_CRT0 + NUM_INSTR_MAIN, RUN_CYCLES);
        $display("-----------------------------------------------------");

        pass_total = 0;
        fail_total = 0;
        for (i = 0; i < NUM_CHECKS; i = i + 1) begin
            if (!chk_done[i])
                $display("KHONG QUAN SAT DUOC: %-18s (PC=0x%04h chua bao gio duoc thuc thi/ghi)",
                          chk_name[i], chk_pc[i]);

            rt_value = dut.Reg_inst.registers[chk_target[i]];

            if (chk_done[i] && (rt_value === chk_exp[i]))
                pass_total = pass_total + 1;
            else
                fail_total = fail_total + 1;
        end

        $display("KET QUA: %0d PASS / %0d FAIL (tong %0d, khong tinh LUI)",
                  pass_total, fail_total, NUM_CHECKS);
        if (fail_total == 0)
            $display("*** TAT CA CAC LENH DUOC KIEM TRA DEU PASS ***");
        else
            $display("*** CON %0d LENH FAIL - XEM CHI TIET O TREN ***", fail_total);
        $display("=====================================================");

        $finish;
    end

endmodule