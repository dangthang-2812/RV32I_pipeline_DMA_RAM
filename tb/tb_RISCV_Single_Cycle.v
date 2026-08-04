`timescale 1ns / 1ps

module tb_RISCV_Single_Cycle;

    // 1. Khai báo các tín hiệu
    reg clk;
    reg rst_n;

    // Chu kỳ xung clock: 10ns (100 MHz)
    parameter CLK_PERIOD = 10;

    // 2. Instance Top Module (DUT)
    RISCV_Single_Cycle uut (
        .clk   (clk),
        .rst_n (rst_n)
    );

    // 3. Tạo xung Clock
    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    // 4. Nạp file hex vào mảng 'memory' của IMEM và DMEM
    initial begin
        // Đường dẫn tương đối từ Lab6/tb sang Lab6/mem
        $readmemh("mem/imem.hex", uut.IMEM_inst.memory);
        $readmemh("mem/dmem_init.hex", uut.DMEM_inst.memory);

        $display("==================================================");
        $display("[INFO] Loaded instruction memory from mem/imem.hex");
        $display("[INFO] Loaded data memory from mem/dmem_init.hex");
        $display("==================================================");
    end

    // 5. Tiến trình tạo tín hiệu điều khiển và Reset
    initial begin
        // Giữ reset ở mức 0 trong 2 chu kỳ clock
        rst_n = 1'b0;
        #(CLK_PERIOD * 2);

        // Thả reset để CPU bắt đầu thực thi
        rst_n = 1'b1;
        $display("--> Reset released. CPU execution started...\n");

        // Chạy trong 100 chu kỳ clock (bạn có thể điều chỉnh số lượng cycle ở đây)
        #(CLK_PERIOD * 100);

        $display("\n==================================================");
        $display("       SIMULATION FINISHED                       ");
        $display("==================================================");
        $finish;
    end

    // 6. Hiển thị thông số CPU từng chu kỳ clock ra Console
    initial begin
        @(posedge rst_n);
        $monitor("Time: %5t | PC: 0x%08h | Instr: 0x%08h | ALU_Out: 0x%08h | WB_Data: 0x%08h",
                 $time,
                 uut.PC_out_top,
                 uut.Instruction_out_top,
                 uut.ALU_out_top,
                 uut.DataD_top);
    end

    // 7. Ghi nhận dạng sóng (Waveform VCD cho GTKWave)
    initial begin
        $dumpfile("wave_riscv.vcd");
        $dumpvars(0, tb_RISCV_Single_Cycle);
    end

endmodule