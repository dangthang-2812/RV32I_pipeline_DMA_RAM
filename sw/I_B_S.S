# ==============================================================================
# RISC-V MERGED TEST BENCH (Single Cycle - DMEM Verification)
# - Địa chỉ cơ sở DMEM: x20 = 0x00000000
# - Quy ước cho lệnh Nhánh (Branch):
#     + 0x000000AA (0xAA) : Case test ĐÚNG (PASS)
#     + 0x000000FF (0xFF) : Case test SAI (FAIL)
#
# BẢNG ĐIỀU HƯỚNG BỘ NHỚ DMEM:
# --- KHỐI B-TYPE (BRANCH) ---
# [0x00] Word 0 : BEQ Taken       | [0x04] Word 1 : BEQ Not Taken
# [0x08] Word 2 : BNE Taken       | [0x0C] Word 3 : BNE Not Taken
# [0x10] Word 4 : BLT Taken       | [0x14] Word 5 : BLT Not Taken
# [0x18] Word 6 : BGE Taken       | [0x1C] Word 7 : BGE Not Taken
#
# --- KHỐI I-TYPE (ARITHMETIC & LOGIC) ---
# [0x20] Word 8 : ADDI            | [0x24] Word 9 : SLTI
# [0x28] Word 10: SLTIU           | [0x2C] Word 11: XORI
# [0x30] Word 12: ORI             | [0x34] Word 13: ANDI
# [0x38] Word 14: SLLI            | [0x3C] Word 15: SRLI
# [0x40] Word 16: SRAI            | [0x44] Word 17: LW (Test Load Word)
# ==============================================================================

.text
.globl _start

_start:
    # --------------------------------------------------------------------------
    # KHỞI TẠO DỮ LIỆU CHUNG
    # --------------------------------------------------------------------------
    li  x20, 0          # x20 = Địa chỉ cơ sở DMEM (Base Address = 0x00000000)
    li  x21, 0xAA       # x21 = Giá trị PASS
    li  x22, 0xFF       # x22 = Giá trị FAIL

    # Khởi tạo data cho khối B-type
    li  x1, 10          # x1 = 10
    li  x2, 10          # x2 = 10
    li  x3, 20          # x3 = 20
    li  x4, -5          # x4 = -5 (Test so sánh có dấu)

    # ==========================================================================
    # PHẦN 1: TEST B-TYPE (4 LỆNH, MỖI LỆNH 2 CASE)
    # ==========================================================================

    # --------------------------------------------------------------------------
    # [1] BEQ
    # --------------------------------------------------------------------------
    # Case 1.1: BEQ Taken (10 == 10 -> PHẢI NHẢY)
    beq  x1, x2, BEQ_T_YES
    sw   x22, 0(x20)    # [DMEM 0x00] FAIL: BEQ không nhảy
    j    BEQ_T_END
BEQ_T_YES:
    sw   x21, 0(x20)    # [DMEM 0x00] PASS: BEQ đã nhảy đúng
BEQ_T_END:

    # Case 1.2: BEQ Not Taken (10 == 20 -> KHÔNG ĐƯỢC NHẢY)
    beq  x1, x3, BEQ_NT_YES
    sw   x21, 4(x20)    # [DMEM 0x04] PASS: BEQ không nhảy (chạy tuần tự)
    j    BEQ_NT_END
BEQ_NT_YES:
    sw   x22, 4(x20)    # [DMEM 0x04] FAIL: BEQ bị nhảy sai
BEQ_NT_END:

    # --------------------------------------------------------------------------
    # [2] BNE
    # --------------------------------------------------------------------------
    # Case 2.1: BNE Taken (10 != 20 -> PHẢI NHẢY)
    bne  x1, x3, BNE_T_YES
    sw   x22, 8(x20)    # [DMEM 0x08] FAIL: BNE không nhảy
    j    BNE_T_END
BNE_T_YES:
    sw   x21, 8(x20)    # [DMEM 0x08] PASS: BNE đã nhảy đúng
BNE_T_END:

    # Case 2.2: BNE Not Taken (10 != 10 -> KHÔNG ĐƯỢC NHẢY)
    bne  x1, x2, BNE_NT_YES
    sw   x21, 12(x20)   # [DMEM 0x0C] PASS: BNE không nhảy
    j    BNE_NT_END
BNE_NT_YES:
    sw   x22, 12(x20)   # [DMEM 0x0C] FAIL: BNE bị nhảy sai
BNE_NT_END:

    # --------------------------------------------------------------------------
    # [3] BLT (Signed)
    # --------------------------------------------------------------------------
    # Case 3.1: BLT Taken (-5 < 10 -> PHẢI NHẢY)
    blt  x4, x1, BLT_T_YES
    sw   x22, 16(x20)   # [DMEM 0x10] FAIL: BLT không nhảy
    j    BLT_T_END
BLT_T_YES:
    sw   x21, 16(x20)   # [DMEM 0x10] PASS: BLT đã nhảy đúng
BLT_T_END:

    # Case 3.2: BLT Not Taken (10 < -5 -> KHÔNG ĐƯỢC NHẢY)
    blt  x1, x4, BLT_NT_YES
    sw   x21, 20(x20)   # [DMEM 0x14] PASS: BLT không nhảy
    j    BLT_NT_END
BLT_NT_YES:
    sw   x22, 20(x20)   # [DMEM 0x14] FAIL: BLT bị nhảy sai
BLT_NT_END:

    # --------------------------------------------------------------------------
    # [4] BGE (Signed)
    # --------------------------------------------------------------------------
    # Case 4.1: BGE Taken (10 >= -5 -> PHẢI NHẢY)
    bge  x1, x4, BGE_T_YES
    sw   x22, 24(x20)   # [DMEM 0x18] FAIL: BGE không nhảy
    j    BGE_T_END
BGE_T_YES:
    sw   x21, 24(x20)   # [DMEM 0x18] PASS: BGE đã nhảy đúng
BGE_T_END:

    # Case 4.2: BGE Not Taken (-5 >= 10 -> KHÔNG ĐƯỢC NHẢY)
    bge  x4, x1, BGE_NT_YES
    sw   x21, 28(x20)   # [DMEM 0x1C] PASS: BGE không nhảy
    j    BGE_NT_END
BGE_NT_YES:
    sw   x22, 28(x20)   # [DMEM 0x1C] FAIL: BGE bị nhảy sai
BGE_NT_END:


    # ==========================================================================
    # PHẦN 2: TEST 9 LỆNH SỐ HỌC & LOGIC CỦA I-TYPE
    # Lưu ý: Các thanh ghi x1->x9 sẽ bị ghi đè, hoàn toàn hợp lệ vì phần Branch đã xong.
    # ==========================================================================

    addi  x1, x0, 15        # x1 = 15
    sw    x1, 32(x20)       # [DMEM 0x20] Mem[32] = 15

    slti  x2, x1, 20        # x2 = (15 < 20) ? 1 : 0 = 1
    sw    x2, 36(x20)       # [DMEM 0x24] Mem[36] = 1

    sltiu x3, x2, 100       # x3 = (1 < 100) ? 1 : 0 = 1
    sw    x3, 40(x20)       # [DMEM 0x28] Mem[40] = 1

    xori  x4, x1, 7         # x4 = 15 ^ 7 = 8
    sw    x4, 44(x20)       # [DMEM 0x2C] Mem[44] = 8

    ori   x5, x4, 16        # x5 = 8 | 16 = 24
    sw    x5, 48(x20)       # [DMEM 0x30] Mem[48] = 24

    andi  x6, x5, 10        # x6 = 24 & 10 = 8
    sw    x6, 52(x20)       # [DMEM 0x34] Mem[52] = 8

    slli  x7, x6, 2         # x7 = 8 << 2 = 32
    sw    x7, 56(x20)       # [DMEM 0x38] Mem[56] = 32

    srli  x8, x7, 1         # x8 = 32 >> 1 = 16
    sw    x8, 60(x20)       # [DMEM 0x3C] Mem[60] = 16

    srai  x9, x8, 2         # x9 = 16 >> 2 = 4
    sw    x9, 64(x20)       # [DMEM 0x40] Mem[64] = 4

    # ==========================================================================
    # PHẦN 3: TEST LỆNH LẤY LẠI DATA TỪ DMEM (I-TYPE: lw)
    # ==========================================================================
    # Lấy lại giá trị ở Mem[32] (đang là 15 của lệnh ADDI) nạp vào x10
    lw    x10, 32(x20)      # x10 = Mem[32] = 15
    sw    x10, 68(x20)      # [DMEM 0x44] Mem[68] = 15 (Ghi ra ô 68 để check)


# ==============================================================================
# KẾT THÚC CHƯƠNG TRÌNH
# ==============================================================================
TEST_DONE:
END_LOOP:
    j    END_LOOP       # Vòng lặp vô hạn kết thúc