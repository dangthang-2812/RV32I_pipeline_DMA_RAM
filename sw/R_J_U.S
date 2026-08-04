/* ---------------------------------------------------------------------
 * Lab 6 - test.S
 * --------------------------------------------------------------------- */

.section .text.init, "ax", @progbits
.align  2
.globl  main
.type   main, @function

main:
    addi t0, zero, 5            /* x5 = 5   */
    addi t1, zero, 3            /* x6 = 3   */
    addi t2, zero, -1           /* x7 = -1  */

    /* ================= R-TYPE ================= */
    add  t3, t0, t1             /* x28 = 8                        */
    sub  t4, t0, t1             /* x29 = 2                        */
    and  t5, t0, t1             /* x30 = 1                        */
    or   t6, t0, t1             /* x31 = 7                        */
    xor  s0, t0, t1             /* x8  = 6                        */
    sll  s1, t0, t1             /* x9  = 40                       */
    srl  s2, t0, t1             /* x18 = 0                        */
    sra  s3, t2, t1             /* x19 = -1                       */
    slt  s4, t2, t0             /* x20 = 1  (signed -1<5)         */

    /* ================= JAL ================= */
    /* kiem tra CA dia chi nhay VA gia tri tra ve */
   jal  t1, jal_jump_target
jal_return_landing:
    addi t1, zero, 1                 /* PC nhay-lai */
    j    jal_afterlink
jal_jump_target:
    addi gp, zero, 1                  /* x3, JAL nhay toi dich dung */
    jalr zero, t1, 0                   /* nhay nguoc lai bang gia tri tra ve da luu trong t1 */
jal_afterlink: 
 
    /* ================= JALR ================= */
    /* kiem tra CA dia chi nhay VA gia tri tra ve*/
    auipc t0, 0                        /* t0 = PC hien tai */
    jalr  t2, t0, 16                     /* t2 = PC+4, target = PC+16 */
jalr_return_landing:
    addi t2, zero, 1                     /* nhay-lai target = A+8 */
    j    jalr_afterlink
jalr_jump_target:                              /* target = A+16 */
    addi tp, zero, 1                      /* x4, JALR nhay toi dich dung */
    jalr zero, t2, 0                       /* nhay nguoc lai t2 = PC+4 */
jalr_afterlink:

    /* ================= LUI ================= */
    lui  t0, 0xDEADB                  /* LUI bug hardware */

    /* ================= AUIPC ================= */
    auipc s5, 1                        /* s5 = PC + 4096  */
    auipc s8, 0                        /* s8 = PC hien tai  */
    sub   s5, s5, s8                    /* s5 = 4096 - 4 = 4092, KIEM TRA qua RegFile */

done:
    j done                               /* vong lap vo han, giu trang thai cuoi */

    .size main, . - main