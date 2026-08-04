`timescale 1ns / 1ps
module tb_RISCV_Single_Cycle;

    // 1. Khai bao tin hieu ket noi
    reg clk;
    reg rst_n;

    // 2. Chu ky clock
    localparam CLK_PERIOD = 10;
	

    // 3. Dia chi DMEM.
    localparam [31:0] SIGNATURE_ADDR = 32'h00000400;

    // Gia tri signature phai khop voi PASS_SIG / FAIL_SIG trong test.c
    localparam [31:0] PASS_SIG = 32'0x600DC0DEu;
    localparam [31:0] FAIL_SIG = 32'0xBAADC0DEu;

    // Thoi gian toi da cho phep chay
    localparam integer SIM_TIMEOUT_NS = 2000;

    reg found_result;
    integer pass_count;
    integer fail_flag;

    // 4. Ket noi voi DUT
    RISCV_Single_Cycle dut (
        .clk   (clk),
        .rst_n (rst_n)
    );
	
    // 4. Nạp file hex 
    initial begin
        $readmemh("mem/imem.hex", dut.IMEM_inst.memory);
        $readmemh("mem/dmem_init.hex", dut.DMEM_inst.memory);

        $display("==================================================");
        $display("[INFO] Loaded instruction memory from mem/imem.hex");
        $display("[INFO] Loaded data memory from mem/dmem_init.hex");
        $display("==================================================");
    end

    // 5. Tao xung clock
    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    // 6. Monitor in tien trinh thuc thi theo chu ky 
    initial begin
        @(posedge rst_n);
        $monitor("Time: %5t | PC: 0x%08h | Instr: 0x%08h | ALU_Out: 0x%08h | WB_Data: 0x%08h",
                 $time,
                 dut.PC_out_top,
                 dut.Instruction_out_top,
                 dut.ALU_out_top,
                 dut.DataD_top);
    end

    // 7. Monitor: theo doi lenh store vao dung dia chi SIGNATURE_ADDR
    initial found_result = 1'b0;

    always @(posedge clk) begin
        if (rst_n && !found_result &&
            dut.MemRW_top && (dut.ALU_out_top == SIGNATURE_ADDR)) begin

            found_result = 1'b1;

            if (dut.DataB_top == PASS_SIG) begin
                $display("[%0t ns] *** TEST PASSED *** (signature = 0x%08h)",
                          $time, dut.DataB_top);
            end else if (dut.DataB_top == FAIL_SIG) begin
                $display("[%0t ns] *** TEST FAILED *** (signature = 0x%08h)",
                          $time, dut.DataB_top);
            end else begin
                $display("[%0t ns] *** UNEXPECTED SIGNATURE *** (giu tri = 0x%08h)",
                          $time, dut.DataB_top);
            end

            // cho vai chu ky de wave/log flush truoc khi ket thuc
            #(CLK_PERIOD * 2);
            $finish;
        end
    end

    // 8. Quy trinh Reset va chay mo phong
    initial begin
        $dumpfile("tb_RISCV_Single_Cycle.vcd");
        $dumpvars(0, tb_RISCV_Single_Cycle);

        rst_n = 0;
        #(CLK_PERIOD * 2);
        rst_n = 1;
        $display("[%0t ns] --- Bat dau giai doan thuc thi ---", $time);

        #(SIM_TIMEOUT_NS);

        if (!found_result) begin
            $display("[%0t ns] *** TIMEOUT *** khong quan sat duoc lenh ghi signature vao DMEM tai dia chi 0x%08h",
                      $time, SIGNATURE_ADDR);
        end

        $display("[%0t ns] --- Hoan thanh mo phong ---", $time);
        $finish;
    end

endmodule