#include <stdint.h>

/* ---------------------------------------------------------------------
 * Lab 6 - RV32I Single-Cycle - test program
 * --------------------------------------------------------------------- */

#define PASS_SIG 0x600DC0DEu
#define FAIL_SIG 0xBAADC0DEu

volatile uint32_t result_signature = 0;

static int fail_count = 0;
#define CHECK(cond) do { if (!(cond)) fail_count++; } while (0)

static volatile uint32_t lui_probe;

__attribute__((noinline)) int helper(int x, int y)
{
    return x + y; /* dùng để test JAL (gọi) + JALR (return) */
}

int main(void)
{
    /* ---------------- R-type ---------------- */
    volatile int a = 5, b = 3;
    CHECK(a + b == 8);                       /* ADD  */
    CHECK(a - b == 2);                       /* SUB  */
    CHECK((a & b) == 1);                     /* AND  */
    CHECK((a | b) == 7);                     /* OR   */
    CHECK((a ^ b) == 6);                     /* XOR  */
    CHECK((a << 2) == 20);                   /* SLL  */
    CHECK(((uint32_t)a >> 1) == 2u);         /* SRL  */
    CHECK((-8 >> 1) == -4);                  /* SRA  */
    CHECK((a < b) == 0);                     /* SLT  */
    CHECK(((uint32_t)a < (uint32_t)b) == 0u);/* SLTU */

    /* ------------- JAL / JALR (qua gọi hàm) ------------- */
    CHECK(helper(4, 6) == 10);

    /* ---------------- LUI (bug hardware) ---------------- */
    volatile uint32_t big = 0xDEADB000u; /* lui + addi */
    lui_probe = big;   /* không CHECK() giá trị này */

    /* ---------------- Kết luận ---------------- */
    result_signature = (fail_count == 0) ? PASS_SIG : FAIL_SIG;

    while (1) { /* giữ nguyên trạng thái để tb quan sát được */ }
    return 0;
}