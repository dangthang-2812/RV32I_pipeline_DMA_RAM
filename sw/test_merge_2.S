# ==============================================================================
# RISC-V MERGED TEST BENCH: R, J, U -> B, I, S (INCL. LB, LH, LBU, LHU, SB, SH)
# ==============================================================================

.section .text.init, "ax", @progbits
.align  2
.globl  main
.type   main, @function

main:
    # ==========================================================================
    # PART 1: TEST R, J, U TYPE 
    # ==========================================================================
    addi t0, zero, 5            /* x5 = 5   */ 
    addi t1, zero, 3            /* x6 = 3   */ 
    addi t2, zero, -1           /* x7 = -1  */ 

    /* --- R-TYPE --- */
    add  t3, t0, t1             /* x28 = 8                                */ 
    sub  t4, t0, t1             /* x29 = 2                                */ 
    and  t5, t0, t1             /* x30 = 1                                */ 
    or   t6, t0, t1             /* x31 = 7                                */ 
    xor  s0, t0, t1             /* x8  = 6                                */ 
    sll  s1, t0, t1             /* x9  = 40                               */ 
    srl  s2, t0, t1             /* x18 = 0                                */ 
    sra  s3, t2, t1             /* x19 = -1                               */ 
    slt  s4, t2, t0             /* x20 = 1  (signed -1<5)                 */ 

    /* --- JAL --- */
    jal  t1, jal_target        
jal_linkcheck_landing:
    addi t1, zero, 1            /* x6 = 1 (PC jumps back) */ 
    j    jal_afterlink         
jal_target:
    addi gp, zero, 1            /* x3 = 1 (JAL jumps to the correct target) */ 
    jalr zero, t1, 0            
jal_afterlink: 
 
    /* --- JALR --- */
    auipc t0, 0                 /* t0 = current PC */ 
    jalr  t2, t0, 16            /* t2 = PC+4, target = PC+16 */ 
jalr_linkcheck_landing:
    addi t2, zero, 1            /* x7 = 1 (Jump back to target) */ 
    j    jalr_afterlink         
jalr_target:                    
    addi tp, zero, 1            /* x4 = 1 (JALR jumps to the correct target) */ 
    jalr zero, t2, 0            
jalr_afterlink:

    /* --- LUI & AUIPC --- */
    lui  t0, 0xDEADB            /* x5 = 0xDEADB000 */ 
    auipc s5, 1                 /* s5 = PC + 4096  */ 
    auipc s8, 0                 /* s8 = current PC  */ 
    sub   s5, s5, s8            /* s5 (x21) = 4096 - 4 = 4092 */ 


    # ==========================================================================
    # PART 2: TEST B, I, S TYPE 
    # ==========================================================================
    
    # Initialize data
    addi x27, zero, 0   # x27 = DMEM base address (0x00000000)
    addi x26, zero, 0xAA# x26 = PASS value
    addi x25, zero, 0xFF# x25 = FAIL value

    addi x10, zero, 10  # = 10
    addi x11, zero, 10  # = 10
    addi x12, zero, 20  # = 20
    addi x13, zero, -5  # = -5 (Unsigned: 0xFFFFFFFB)

    /* --- B-TYPE --- */
    # [1] BEQ
    beq  x10, x11, BEQ_T_YES    
    sw   x25, 0(x27)             
    j    BEQ_T_END              
BEQ_T_YES:
    sw   x26, 0(x27)            
BEQ_T_END:

    beq  x10, x12, BEQ_NT_YES   
    sw   x26, 4(x27)            
    j    BEQ_NT_END             
BEQ_NT_YES:
    sw   x25, 4(x27)            
BEQ_NT_END:

    # [2] BNE
    bne  x10, x12, BNE_T_YES    
    sw   x25, 8(x27)            
    j    BNE_T_END              
BNE_T_YES:
    sw   x26, 8(x27)            
BNE_T_END:

    bne  x10, x11, BNE_NT_YES   
    sw   x26, 12(x27)           
    j    BNE_NT_END             
BNE_NT_YES:
    sw   x25, 12(x27)           
BNE_NT_END:

    # [3] BLT (Signed)
    blt  x13, x10, BLT_T_YES    
    sw   x25, 16(x27)           
    j    BLT_T_END              
BLT_T_YES:
    sw   x26, 16(x27)           
BLT_T_END:

    blt  x10, x13, BLT_NT_YES   
    sw   x26, 20(x27)           
    j    BLT_NT_END             
BLT_NT_YES:
    sw   x25, 20(x27)           
BLT_NT_END:

    # [4] BGE (Signed)
    bge  x10, x13, BGE_T_YES    
    sw   x25, 24(x27)           
    j    BGE_T_END              
BGE_T_YES:
    sw   x26, 24(x27)           
BGE_T_END:

    bge  x13, x10, BGE_NT_YES   
    sw   x26, 28(x27)           
    j    BGE_NT_END             
BGE_NT_YES:
    sw   x25, 28(x27)           
BGE_NT_END:

    # [5] BLTU (Unsigned)
    bltu x10, x13, BLTU_T_YES   
    sw   x25, 32(x27)           
    j    BLTU_T_END             
BLTU_T_YES:
    sw   x26, 32(x27)           
BLTU_T_END:

    bltu x13, x10, BLTU_NT_YES  
    sw   x26, 36(x27)           
    j    BLTU_NT_END            
BLTU_NT_YES:
    sw   x25, 36(x27)           
BLTU_NT_END:

    # [6] BGEU (Unsigned)
    bgeu x13, x10, BGEU_T_YES   
    sw   x25, 40(x27)           
    j    BGEU_T_END             
BGEU_T_YES:
    sw   x26, 40(x27)           
BGEU_T_END:

    bgeu x10, x13, BGEU_NT_YES  
    sw   x26, 44(x27)           
    j    BGEU_NT_END            
BGEU_NT_YES:
    sw   x25, 44(x27)           
BGEU_NT_END:

    /* --- I-TYPE --- */
    addi  x10, x0, 15           
    sw    x10, 48(x27)          

    slti  x11, x10, 20          
    sw    x11, 52(x27)          

    xori  x13, x10, 7           
    sw    x13, 56(x27)          

    ori   x14, x13, 16          
    sw    x14, 60(x27)          

    andi  x15, x14, 10          
    sw    x15, 64(x27)          

    slli  x16, x15, 2           
    sw    x16, 68(x27)          

    srli  x17, x16, 1           
    sw    x17, 72(x27)          

    srai  x22, x17, 2           
    sw    x22, 76(x27)          

    /* --- LW --- */
    lw    x23, 48(x27)          
    sw    x23, 80(x27)          

    # ==========================================================================
    # PART 3: TEST SB, SH, LB, LH, LBU, LHU
    # Valid 12-bit immediates (< 2047 / 0x7FF) used for addi
    # ==========================================================================
    
    # --------------------------------------------------------------------------
    # [1] TEST SB (Store Byte) & LB / LBU (Load Byte Signed/Unsigned)
    # Target value: 0x1234568F
    # --------------------------------------------------------------------------
    lui   t4, 0x12345           # t4 = 0x12345000
    addi  t4, t4, 0x68F         # t4 = 0x12345000 + 0x68F = 0x1234568F (0x68F = 1679 < 2047)
    sb    t4, 84(x27)           # SB stores 0x8F to DMEM @ 84

    lb    t5, 84(x27)           # Sign-extended: Loads 0x8F -> 0xFFFFFF8F
    sw    t5, 88(x27)           # Save LB result to DMEM @ 88

    lbu   t6, 84(x27)           # Zero-extended: Loads 0x8F -> 0x0000008F
    sw    t6, 92(x27)           # Save LBU result to DMEM @ 92

    # --------------------------------------------------------------------------
    # [2] TEST SH (Store Halfword) & LH / LHU (Load Halfword Signed/Unsigned)
    # Target value: 0x12348234
    # --------------------------------------------------------------------------
    lui   t4, 0x12348           # t4 = 0x12348000
    addi  t4, t4, 0x234         # t4 = 0x12348000 + 0x234 = 0x12348234 (0x234 = 564 < 2047)
    sh    t4, 96(x27)           # SH stores 0x8234 to DMEM @ 96

    lh    t5, 96(x27)           # Sign-extended: Loads 0x8234 -> 0xFFFF8234
    sw    t5, 100(x27)          # Save LH result to DMEM @ 100

    lhu   t6, 96(x27)           # Zero-extended: Loads 0x8234 -> 0x00008234
    sw    t6, 104(x27)          # Save LHU result to DMEM @ 104

TEST_DONE:
END_LOOP:
    j    END_LOOP               

    .size main, . - main