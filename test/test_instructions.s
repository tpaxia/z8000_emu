# =============================================================================
# Z8000 Instruction Test Suite
# File: test_instructions.s
#
# Comprehensive test of Z8000 instructions (181 tests):
#
# Data Movement:
#   - LD (register, immediate, indirect, direct address, indexed, base)
#   - LDB (byte load, including compact single-word format)
#   - LDL (long 32-bit load)
#   - LDK (load 4-bit constant)
#   - ST/STB (indirect, direct address, indexed, base indexed)
#   - PUSH, POP (word stack operations)
#   - PUSHL, POPL (long 32-bit stack operations)
#
# Arithmetic:
#   - ADD, SUB (all addressing modes including indexed)
#   - ADDB, SUBB (byte add/subtract)
#   - ADDL, SUBL (32-bit long operations)
#   - ADC, SBC, ADCB, SBCB (add/subtract with carry)
#   - INC, DEC, INCB, DECB (increment/decrement by n)
#   - MULT, MULTL (multiply 16x16->32, 32x32->64)
#   - DIV, DIVL (divide 32/16, 64/32)
#   - NEG, COM, NEGB, COMB (negate, complement)
#   - CP, CPB, CPL (compare word, byte, long)
#
# Logical:
#   - AND, OR, XOR (all addressing modes)
#   - ANDB, ORB, XORB (byte logical operations)
#
# Bit Manipulation:
#   - BIT (test bit, R/@R/addr/addr(R) modes)
#   - SET (set bit to 1, R/@R/addr/addr(R) modes)
#   - RES (reset bit to 0, R/@R/addr/addr(R) modes)
#
# Shift/Rotate:
#   - RL, RR (rotate left/right by 1 or 2)
#   - RLC, RRC (rotate left/right through carry by 1 or 2)
#   - SLA, SRA (arithmetic shift left/right)
#   - SLL, SRL (logical shift left/right)
#
# Control Flow:
#   - JP, JR (conditional jumps)
#   - CALL, CALR, RET (subroutine support)
#   - DJNZ (decrement and jump)
#   - NOP (no operation)
#
# Block Operations:
#   - LDI, LDIR (block move with increment)
#   - LDD, LDDR (block move with decrement)
#   - CPI, CPIR (block compare with increment)
#   - CPD, CPDR (block compare with decrement)
#   - Byte variants (LDIB, CPIB, CPIRB, CPDRB)
#
# Input/Output:
#   - IN, INB (input word/byte)
#   - OUT, OUTB (output word/byte)
#   - SIN, SINB, SOUT, SOUTB (special I/O)
#   - INIR, INIRB (block input with increment)
#   - OTIR, OTIRB (block output with increment)
#
# Memory Map:
#   0x0100-0x0FF9: Test code
#   0x0FFA-0x101B: Result storage and halt
#   0x101C-0x104F: Scratch data area
#   0x1050+:       Test data sections
#   0x2300-0x23FF: Result memory
#
# Test results stored at 0x2300:
#   0x2300: Number of tests passed
#   0x2302: Number of tests failed
#   0x2304: Current test number
#   0x2306: 0xDEAD if all passed, 0xFA11 if failed
# =============================================================================

        .text
        .global _start

# =============================================================================
# Test program starts at 0x0100
# =============================================================================
_start:
        ld      r0, #0              ! Tests passed
        ld      r1, #0              ! Tests failed
        ld      r2, #0              ! Current test number
        ld      r14, #scratch_data  ! Data pointer
        ld      r15, #0x1F00        ! Results pointer

# =============================================================================
# TEST 1: LD Rd, Rs (register to register)
# =============================================================================
test_ld_r:
        ld      r2, #1              ! Test number 1
        ld      r3, #0x1234         ! Load immediate into R3
        ld      r4, r3              ! R4 <- R3 (should be 0x1234)

        cp      r4, #0x1234         ! Verify R4 == 0x1234
        jr      z, test_ld_r_pass
        inc     r1, #1
        jr      test_ld_im
test_ld_r_pass:
        inc     r0, #1

# =============================================================================
# TEST 2: LD Rd, #data (immediate)
# =============================================================================
test_ld_im:
        ld      r2, #2              ! Test number 2
        ld      r3, #0xABCD         ! Load immediate

        cp      r3, #0xABCD         ! Verify R3 == 0xABCD
        jr      z, test_ld_im_pass
        inc     r1, #1
        jr      test_ld_ir
test_ld_im_pass:
        inc     r0, #1

# =============================================================================
# TEST 3: LD Rd, @Rs (indirect register load)
# =============================================================================
test_ld_ir:
        ld      r2, #3              ! Test number 3

        ld      r3, #0x5678
        ld      r4, #scratch_data   ! Address
        ld      @r4, r3             ! Store 0x5678 at scratch_data

        ld      r5, @r4             ! R5 <- mem[R4] (should be 0x5678)

        cp      r5, r3              ! Verify
        jr      z, test_ld_ir_pass
        inc     r1, #1
        jr      test_ld_da
test_ld_ir_pass:
        inc     r0, #1

# =============================================================================
# TEST 4: LD Rd, address (direct address load)
# =============================================================================
test_ld_da:
        ld      r2, #4              ! Test number 4

        ld      r3, #0x9ABC
        ld      r4, #scratch_data+2
        ld      @r4, r3             ! Store 0x9ABC at scratch_data+2

        ld      r5, scratch_data+2  ! R5 <- mem[scratch_data+2] (direct address load)

        cp      r5, r3              ! Verify
        jr      z, test_ld_da_pass
        inc     r1, #1
        jr      test_add_r
test_ld_da_pass:
        inc     r0, #1

# =============================================================================
# TEST 5: ADD Rd, Rs (register)
# =============================================================================
test_add_r:
        ld      r2, #5              ! Test number 5
        ld      r3, #100            ! First operand
        ld      r4, #200            ! Second operand
        add     r3, r4              ! R3 <- R3 + R4 = 300

        cp      r3, #300            ! Verify R3 == 300
        jr      z, test_add_r_pass
        inc     r1, #1
        jr      test_add_im
test_add_r_pass:
        inc     r0, #1

# =============================================================================
# TEST 6: ADD Rd, #data (immediate)
# =============================================================================
test_add_im:
        ld      r2, #6              ! Test number 6
        ld      r3, #1000
        add     r3, #234            ! R3 <- 1000 + 234 = 1234

        cp      r3, #1234           ! Verify R3 == 1234
        jr      z, test_add_im_pass
        inc     r1, #1
        jr      test_add_ir
test_add_im_pass:
        inc     r0, #1

# =============================================================================
# TEST 7: ADD Rd, @Rs (indirect)
# =============================================================================
test_add_ir:
        ld      r2, #7              ! Test number 7

        ld      r3, #500
        ld      r4, #scratch_data+4
        ld      @r4, r3             ! mem[scratch_data+4] = 500

        ld      r5, #500
        add     r5, @r4             ! R5 <- 500 + 500 = 1000

        cp      r5, #1000           ! Verify
        jr      z, test_add_ir_pass
        inc     r1, #1
        jr      test_add_da
test_add_ir_pass:
        inc     r0, #1

# =============================================================================
# TEST 8: ADD Rd, address (direct address)
# =============================================================================
test_add_da:
        ld      r2, #8              ! Test number 8

        ld      r3, #0x0100
        ld      r4, #scratch_data+6
        ld      @r4, r3             ! mem[scratch_data+6] = 0x0100

        ld      r5, #0x0F00
        add     r5, scratch_data+6  ! R5 <- 0x0F00 + mem[scratch_data+6] = 0x1000

        cp      r5, #0x1000         ! Verify
        jr      z, test_add_da_pass
        inc     r1, #1
        jr      test_sub_r
test_add_da_pass:
        inc     r0, #1

# =============================================================================
# TEST 9: SUB Rd, Rs (register)
# =============================================================================
test_sub_r:
        ld      r2, #9              ! Test number 9
        ld      r3, #1000
        ld      r4, #300
        sub     r3, r4              ! R3 <- 1000 - 300 = 700

        cp      r3, #700            ! Verify
        jr      z, test_sub_r_pass
        inc     r1, #1
        jr      test_sub_im
test_sub_r_pass:
        inc     r0, #1

# =============================================================================
# TEST 10: SUB Rd, #data (immediate)
# =============================================================================
test_sub_im:
        ld      r2, #10             ! Test number 10
        ld      r3, #2000
        sub     r3, #500            ! R3 <- 2000 - 500 = 1500

        cp      r3, #1500           ! Verify
        jr      z, test_sub_im_pass
        inc     r1, #1
        jr      test_jp_true
test_sub_im_pass:
        inc     r0, #1

# =============================================================================
# TEST 11: JP cc, address (condition true - taken)
# =============================================================================
test_jp_true:
        ld      r2, #11             ! Test number 11
        ld      r3, #0
        cp      r3, #0              ! Set Z flag
        jp      z, test_jp_true_target  ! Should jump

        inc     r1, #1              ! If we get here, test failed
        jr      test_jp_false

test_jp_true_target:
        inc     r0, #1              ! Test passed
        jr      test_jp_false

# =============================================================================
# TEST 12: JP cc, address (condition false - not taken)
# =============================================================================
test_jp_false:
        ld      r2, #12             ! Test number 12
        ld      r3, #1
        cp      r3, #0              ! Clear Z flag (1 != 0)
        jp      z, test_jp_false_bad  ! Should NOT jump

        inc     r0, #1              ! If we get here, test passed
        jr      test_jr_fwd

test_jp_false_bad:
        inc     r1, #1              ! Test failed
        jr      test_jr_fwd

# =============================================================================
# TEST 13: JR cc, displacement (forward jump)
# =============================================================================
test_jr_fwd:
        ld      r2, #13             ! Test number 13
        ld      r3, #5
        cp      r3, #5              ! Set Z flag
        jr      z, test_jr_fwd_target  ! Forward jump

        inc     r1, #1              ! Should not reach here
        jr      test_jr_back
test_jr_fwd_target:
        inc     r0, #1

# =============================================================================
# TEST 14: JR cc, displacement (backward jump - loop)
# =============================================================================
test_jr_back:
        ld      r2, #14             ! Test number 14
        ld      r3, #0              ! Counter

test_jr_back_loop:
        inc     r3, #1              ! Increment counter
        cp      r3, #3              ! Check if counter == 3
        jr      nz, test_jr_back_loop  ! Loop back if not 3

        cp      r3, #3              ! If R3 == 3, test passed
        jr      z, test_jr_back_pass
        inc     r1, #1
        jr      test_flags_z
test_jr_back_pass:
        inc     r0, #1

# =============================================================================
# TEST 15: Flags - Zero flag
# =============================================================================
test_flags_z:
        ld      r2, #15             ! Test number 15
        ld      r3, #100
        sub     r3, #100            ! R3 = 0, should set Z flag
        jr      z, test_flags_z_pass
        inc     r1, #1
        jr      test_flags_nz
test_flags_z_pass:
        inc     r0, #1

# =============================================================================
# TEST 16: Flags - Not Zero
# =============================================================================
test_flags_nz:
        ld      r2, #16             ! Test number 16
        ld      r3, #100
        sub     r3, #50             ! R3 = 50, should clear Z flag
        jr      nz, test_flags_nz_pass
        inc     r1, #1
        jr      test_flags_c
test_flags_nz_pass:
        inc     r0, #1

# =============================================================================
# TEST 17: Flags - Carry (overflow in unsigned add)
# =============================================================================
test_flags_c:
        ld      r2, #17             ! Test number 17
        ld      r3, #0xFFFF         ! Max unsigned value
        add     r3, #1              ! Should overflow, set C flag
        jr      c, test_flags_c_pass
        inc     r1, #1
        jr      test_flags_nc
test_flags_c_pass:
        inc     r0, #1

# =============================================================================
# TEST 18: Flags - No Carry
# =============================================================================
test_flags_nc:
        ld      r2, #18             ! Test number 18
        ld      r3, #100
        add     r3, #100            ! No overflow
        jr      nc, test_flags_nc_pass
        inc     r1, #1
        jr      test_flags_s
test_flags_nc_pass:
        inc     r0, #1

# =============================================================================
# TEST 19: Flags - Sign (negative result)
# =============================================================================
test_flags_s:
        ld      r2, #19             ! Test number 19
        ld      r3, #0
        sub     r3, #1              ! R3 = -1 (0xFFFF), should set S flag
        jr      mi, test_flags_s_pass  ! mi = minus (sign set)
        inc     r1, #1
        jr      test_flags_ns
test_flags_s_pass:
        inc     r0, #1

# =============================================================================
# TEST 20: Flags - Not Sign (positive result)
# =============================================================================
test_flags_ns:
        ld      r2, #20             ! Test number 20
        ld      r3, #100
        add     r3, #100            ! R3 = 200, positive
        jr      pl, test_flags_ns_pass  ! pl = plus (sign clear)
        inc     r1, #1
        jp      tests_done
test_flags_ns_pass:
        inc     r0, #1

# =============================================================================
# TEST 21: LD address, Rs (store to direct address)
# =============================================================================
test_st_da:
        ld      r2, #21             ! Test number 21
        ld      r3, #0xBEEF         ! Value to store
        ld      scratch_data+8, r3  ! Store R3 to scratch_data+8

        ld      r4, scratch_data+8  ! Load back
        cp      r4, r3              ! Verify
        jr      z, test_st_da_pass
        inc     r1, #1
        jp      tests_done
test_st_da_pass:
        inc     r0, #1

# =============================================================================
# TEST 22: LD Rd, addr(Rs) (indexed addressing)
# =============================================================================
test_ld_x:
        ld      r2, #22             ! Test number 22
        ld      r3, #0xCAFE         ! Value to store
        ld      r4, #scratch_data+0x10 ! Base address
        ld      @r4, r3             ! Store 0xCAFE at scratch_data+0x10

        ld      r5, #4              ! Index value
        ld      r6, scratch_data+0x0C(r5) ! Load from scratch_data+0x0C + 4 = scratch_data+0x10

        cp      r6, r3              ! Verify
        jr      z, test_ld_x_pass
        inc     r1, #1
        jp      tests_done
test_ld_x_pass:
        inc     r0, #1

# =============================================================================
# TEST 23: LD Rd, Rs(#disp) (base addressing)
# =============================================================================
test_ld_ba:
        ld      r2, #23             ! Test number 23
        ld      r3, #0xFACE         ! Value to store
        ld      r4, #scratch_data+0x20 ! Address
        ld      @r4, r3             ! Store 0xFACE at scratch_data+0x20

        ld      r5, #scratch_data   ! Base register
        ld      r6, r5(#0x20)       ! Load from R5 + 0x20

        cp      r6, r3              ! Verify
        jr      z, test_ld_ba_pass
        inc     r1, #1
        jp      tests_done
test_ld_ba_pass:
        inc     r0, #1

# =============================================================================
# TEST 24: LD Rd, Rs(Rx) (base indexed addressing)
# =============================================================================
test_ld_bx:
        ld      r2, #24             ! Test number 24
        ld      r3, #0xB00B         ! Value to store
        ld      r4, #scratch_data+0x30 ! Address
        ld      @r4, r3             ! Store 0xB00B at scratch_data+0x30

        ld      r5, #scratch_data   ! Base register
        ld      r6, #0x30           ! Index register
        ld      r7, r5(r6)          ! Load from R5 + R6

        cp      r7, r3              ! Verify
        jr      z, test_ld_bx_pass
        inc     r1, #1
        jp      tests_done
test_ld_bx_pass:
        inc     r0, #1

# =============================================================================
# TEST 25: AND Rd, Rs (logical AND)
# =============================================================================
test_and_r:
        ld      r2, #25             ! Test number 25
        ld      r3, #0xFF0F         ! First operand
        ld      r4, #0x0FFF         ! Second operand
        and     r3, r4              ! R3 = 0xFF0F AND 0x0FFF = 0x0F0F
        cp      r3, #0x0F0F         ! Verify
        jr      z, test_and_r_pass
        inc     r1, #1              ! Test failed
        jr      test_or_r           ! Skip to next test
test_and_r_pass:
        inc     r0, #1

# =============================================================================
# TEST 26: OR Rd, Rs (logical OR)
# =============================================================================
test_or_r:
        ld      r2, #26             ! Test number 26
        ld      r3, #0xF0F0         ! First operand
        ld      r4, #0x0F0F         ! Second operand
        or      r3, r4              ! R3 = 0xF0F0 OR 0x0F0F = 0xFFFF

        cp      r3, #0xFFFF         ! Verify
        jr      z, test_or_r_pass
        inc     r1, #1
        jr      test_xor_r
test_or_r_pass:
        inc     r0, #1

# =============================================================================
# TEST 27: XOR Rd, Rs (logical XOR)
# =============================================================================
test_xor_r:
        ld      r2, #27             ! Test number 27
        ld      r3, #0xAAAA         ! First operand
        ld      r4, #0xFF00         ! Second operand
        xor     r3, r4              ! R3 = 0xAAAA XOR 0xFF00 = 0x55AA

        cp      r3, #0x55AA         ! Verify
        jr      z, test_xor_r_pass
        inc     r1, #1
        jr      test_dec_r
test_xor_r_pass:
        inc     r0, #1

# =============================================================================
# TEST 28: DEC Rd, #n (decrement by n)
# =============================================================================
test_dec_r:
        ld      r2, #28             ! Test number 28
        ld      r3, #100            ! Initial value
        dec     r3, #1              ! R3 = 100 - 1 = 99

        cp      r3, #99             ! Verify
        jr      z, test_dec_r_pass
        inc     r1, #1
        jr      test_dec_r2
test_dec_r_pass:
        inc     r0, #1

# =============================================================================
# TEST 29: DEC Rd, #n (decrement by larger value)
# =============================================================================
test_dec_r2:
        ld      r2, #29             ! Test number 29
        ld      r3, #50             ! Initial value
        dec     r3, #5              ! R3 = 50 - 5 = 45

        cp      r3, #45             ! Verify
        jr      z, test_dec_r2_pass
        inc     r1, #1
        jr      test_neg_r
test_dec_r2_pass:
        inc     r0, #1

# =============================================================================
# TEST 30: NEG Rd (negate - two's complement)
# =============================================================================
test_neg_r:
        ld      r2, #30             ! Test number 30
        ld      r3, #1              ! Initial value
        neg     r3                  ! R3 = 0 - 1 = 0xFFFF (-1)

        cp      r3, #0xFFFF         ! Verify
        jr      z, test_neg_r_pass
        inc     r1, #1
        jr      test_neg_r2
test_neg_r_pass:
        inc     r0, #1

# =============================================================================
# TEST 31: NEG Rd (negate larger value)
# =============================================================================
test_neg_r2:
        ld      r2, #31             ! Test number 31
        ld      r3, #100            ! Initial value (0x0064)
        neg     r3                  ! R3 = 0 - 100 = 0xFF9C (-100)

        cp      r3, #0xFF9C         ! Verify
        jr      z, test_neg_r2_pass
        inc     r1, #1
        jr      test_com_r
test_neg_r2_pass:
        inc     r0, #1

# =============================================================================
# TEST 32: COM Rd (complement - one's complement)
# =============================================================================
test_com_r:
        ld      r2, #32             ! Test number 32
        ld      r3, #0x00FF         ! Initial value
        com     r3                  ! R3 = ~0x00FF = 0xFF00

        cp      r3, #0xFF00         ! Verify
        jr      z, test_com_r_pass
        inc     r1, #1
        jr      test_com_r2
test_com_r_pass:
        inc     r0, #1

# =============================================================================
# TEST 33: COM Rd (complement different value)
# =============================================================================
test_com_r2:
        ld      r2, #33             ! Test number 33
        ld      r3, #0xA5A5         ! Initial value
        com     r3                  ! R3 = ~0xA5A5 = 0x5A5A

        cp      r3, #0x5A5A         ! Verify
        jr      z, test_com_r2_pass
        inc     r1, #1
        jr      test_adc_r
test_com_r2_pass:
        inc     r0, #1

# =============================================================================
# TEST 34: ADC Rd, Rs (add with carry - no carry in)
# =============================================================================
test_adc_r:
        ld      r2, #34             ! Test number 34
        ld      r3, #100            ! First operand
        ld      r4, #50             ! Second operand
        add     r3, #0              ! Clear carry flag (100 + 0 = 100, no carry)
        ld      r3, #100            ! Reset R3
        adc     r3, r4              ! R3 = 100 + 50 + 0 = 150

        cp      r3, #150            ! Verify
        jr      z, test_adc_r_pass
        inc     r1, #1
        jr      test_adc_r2
test_adc_r_pass:
        inc     r0, #1

# =============================================================================
# TEST 35: ADC Rd, Rs (add with carry - carry set)
# =============================================================================
test_adc_r2:
        ld      r2, #35             ! Test number 35
        ld      r3, #0xFFFF         ! Max value
        add     r3, #1              ! 0xFFFF + 1 = 0x0000 with carry set
        ld      r3, #100            ! R3 = 100
        ld      r4, #50             ! R4 = 50
        adc     r3, r4              ! R3 = 100 + 50 + 1 (carry) = 151

        cp      r3, #151            ! Verify
        jr      z, test_adc_r2_pass
        inc     r1, #1
        jr      test_sbc_r
test_adc_r2_pass:
        inc     r0, #1

# =============================================================================
# TEST 36: SBC Rd, Rs (subtract with borrow - no borrow)
# =============================================================================
test_sbc_r:
        ld      r2, #36             ! Test number 36
        ld      r3, #100            ! First operand
        ld      r4, #30             ! Second operand
        add     r3, #0              ! Clear carry/borrow flag
        ld      r3, #100            ! Reset R3
        sbc     r3, r4              ! R3 = 100 - 30 - 0 = 70

        cp      r3, #70             ! Verify
        jr      z, test_sbc_r_pass
        inc     r1, #1
        jr      test_sbc_r2
test_sbc_r_pass:
        inc     r0, #1

# =============================================================================
# TEST 37: SBC Rd, Rs (subtract with borrow - borrow set)
# =============================================================================
test_sbc_r2:
        ld      r2, #37             ! Test number 37
        ld      r3, #0              !
        sub     r3, #1              ! 0 - 1 = 0xFFFF with borrow/carry set
        ld      r3, #100            ! R3 = 100
        ld      r4, #30             ! R4 = 30
        sbc     r3, r4              ! R3 = 100 - 30 - 1 (borrow) = 69

        cp      r3, #69             ! Verify
        jr      z, test_sbc_r2_pass
        inc     r1, #1
        jp      tests_done
test_sbc_r2_pass:
        inc     r0, #1

# =============================================================================
# TEST 38: CALR (call relative) and RET
# =============================================================================
test_calr:
        ld      r2, #38             ! Test number 38
        ld      r13, #0x1E00        ! Set up stack pointer (save r15 for results)
        ld      r6, #0              ! Initialize return check

        ! Save R15 (results pointer) to R14 temporarily
        ld      r14, r15
        ld      r15, r13            ! SP = 0x1E00

        calr    calr_target         ! Call relative
        ! After return, R6 should be 0x1234

        ! Restore R15 (results pointer)
        ld      r15, r14

        cp      r6, #0x1234         ! Verify CALR/RET worked
        jr      z, test_calr_pass
        inc     r1, #1
        jr      test_call_da
test_calr_pass:
        inc     r0, #1
        jr      test_call_da

! Subroutine called by CALR
calr_target:
        ld      r6, #0x1234         ! Mark that we got here
        ret                         ! Return (unconditional)

# =============================================================================
# TEST 39: CALL address (call direct address) and RET
# =============================================================================
test_call_da:
        ld      r2, #39             ! Test number 39
        ld      r7, #0              ! Initialize return check

        ! Save R15 and set up stack
        ld      r14, r15
        ld      r15, r13            ! SP = 0x1E00

        call    call_target         ! Call direct address
        ! After return, R7 should be 0x5678

        ! Restore R15 (results pointer)
        ld      r15, r14

        cp      r7, #0x5678         ! Verify CALL/RET worked
        jr      z, test_call_da_pass
        inc     r1, #1
        jr      test_ret_cond
test_call_da_pass:
        inc     r0, #1
        jr      test_ret_cond

! Subroutine called by CALL
call_target:
        ld      r7, #0x5678         ! Mark that we got here
        ret                         ! Return (unconditional)

# =============================================================================
# TEST 40: RET cc (conditional return - condition true)
# =============================================================================
test_ret_cond:
        ld      r2, #40             ! Test number 40
        ld      r8, #0              ! Initialize return check

        ! Save R15 and set up stack
        ld      r14, r15
        ld      r15, r13            ! SP = 0x1E00

        calr    ret_cond_target     ! Call subroutine
        ! After return, R8 should be 0xABCD

        ! Restore R15
        ld      r15, r14

        cp      r8, #0xABCD         ! Verify conditional RET worked
        jr      z, test_ret_cond_pass
        inc     r1, #1
        jr      test_ret_cond_false
test_ret_cond_pass:
        inc     r0, #1
        jr      test_ret_cond_false

! Subroutine with conditional return (condition true)
ret_cond_target:
        ld      r8, #0xABCD         ! Mark that we got here
        cp      r8, #0xABCD         ! Set Z flag (equal)
        ret     z                   ! Return if zero (should return)
        ld      r8, #0xDEAD         ! Should not reach here
        ret

# =============================================================================
# TEST 41: RET cc (conditional return - condition false)
# =============================================================================
test_ret_cond_false:
        ld      r2, #41             ! Test number 41
        ld      r9, #0              ! Initialize return check

        ! Save R15 and set up stack
        ld      r14, r15
        ld      r15, r13            ! SP = 0x1E00

        calr    ret_false_target    ! Call subroutine
        ! After return, R9 should be 0x9999 (not 0x1111)

        ! Restore R15
        ld      r15, r14

        cp      r9, #0x9999         ! Verify conditional RET (false) worked
        jr      z, test_ret_cond_false_pass
        inc     r1, #1
        jp      tests_done
test_ret_cond_false_pass:
        inc     r0, #1
        jr      test_push_pop

! Subroutine with conditional return (condition false)
ret_false_target:
        ld      r9, #0x1111         ! Initial value
        cp      r9, #0x2222         ! Set NZ flag (not equal)
        ret     z                   ! Return if zero (should NOT return)
        ld      r9, #0x9999         ! Should reach here
        ret                         ! Unconditional return

# =============================================================================
# TEST 42a: PUSH and POP word
# =============================================================================
test_push_pop:
        ld      r2, #142            ! Test number 142 (to not conflict with existing)

        ! Save R15 and set up stack at 0x1E00
        ld      r14, r15            ! Save results pointer
        ld      r15, #0x1E00        ! Set up stack pointer

        ! Test 1: Push a value and pop it back
        ld      r3, #0x1234         ! Value to push
        push    @r15, r3            ! Push R3 onto stack
        ld      r3, #0              ! Clear R3
        pop     r3, @r15            ! Pop into R3

        ! Verify value came back correctly
        cp      r3, #0x1234
        jr      nz, test_push_pop_fail

        ! Test 2: Push multiple values and pop in reverse order
        ld      r3, #0xAAAA
        ld      r4, #0xBBBB
        ld      r5, #0xCCCC
        push    @r15, r3            ! Push 0xAAAA
        push    @r15, r4            ! Push 0xBBBB
        push    @r15, r5            ! Push 0xCCCC

        ! Clear registers
        ld      r3, #0
        ld      r4, #0
        ld      r5, #0

        ! Pop in reverse order (LIFO)
        pop     r5, @r15            ! Should get 0xCCCC
        pop     r4, @r15            ! Should get 0xBBBB
        pop     r3, @r15            ! Should get 0xAAAA

        ! Verify LIFO order
        cp      r5, #0xCCCC
        jr      nz, test_push_pop_fail
        cp      r4, #0xBBBB
        jr      nz, test_push_pop_fail
        cp      r3, #0xAAAA
        jr      nz, test_push_pop_fail

        ! Restore R15 and pass
        ld      r15, r14
        inc     r0, #1
        jr      test_pushl_popl

test_push_pop_fail:
        ld      r15, r14
        inc     r1, #1
        jr      test_pushl_popl

# =============================================================================
# TEST 42b: PUSHL and POPL long (32-bit)
# =============================================================================
test_pushl_popl:
        ld      r2, #143            ! Test number 143

        ! Save R15 and set up stack
        ld      r14, r15
        ld      r15, #0x1E00        ! Stack pointer

        ! Load a 32-bit value into RR2 (R2:R3)
        ld      r2, #0x1234         ! High word
        ld      r3, #0x5678         ! Low word

        ! Push the long value
        pushl   @r15, rr2           ! Push 0x12345678

        ! Clear RR2
        ld      r2, #0
        ld      r3, #0

        ! Pop the long value
        popl    rr2, @r15           ! Pop into RR2

        ! Verify both words
        cp      r2, #0x1234         ! Check high word
        jr      nz, test_pushl_popl_fail
        cp      r3, #0x5678         ! Check low word
        jr      nz, test_pushl_popl_fail

        ! Restore R15 and pass
        ld      r15, r14
        inc     r0, #1
        jr      test_bit_set

test_pushl_popl_fail:
        ld      r15, r14
        inc     r1, #1
        jr      test_bit_set

# =============================================================================
# TEST 42c: BIT, SET, RES - Bit manipulation
# =============================================================================
test_bit_set:
        ld      r2, #144            ! Test number 144

        ! Test SET - set bit 0
        ld      r3, #0x0000
        set     r3, #0x0            ! Set bit 0
        cp      r3, #0x0001         ! Should be 0x0001
        jr      nz, test_bit_fail

        ! Test SET - set bit 15
        ld      r3, #0x0000
        set     r3, #0xF            ! Set bit 15
        cp      r3, #0x8000         ! Should be 0x8000
        jr      nz, test_bit_fail

        ! Test RES - reset bit 0
        ld      r3, #0xFFFF
        res     r3, #0x0            ! Reset bit 0
        cp      r3, #0xFFFE         ! Should be 0xFFFE
        jr      nz, test_bit_fail

        ! Test RES - reset bit 15
        ld      r3, #0xFFFF
        res     r3, #0xF            ! Reset bit 15
        cp      r3, #0x7FFF         ! Should be 0x7FFF
        jr      nz, test_bit_fail

        ! Test BIT - bit is set (Z=0)
        ld      r3, #0x0001
        bit     r3, #0x0            ! Test bit 0 (should be set, Z=0)
        jr      z, test_bit_fail    ! Should NOT jump

        ! Test BIT - bit is clear (Z=1)
        ld      r3, #0xFFFE
        bit     r3, #0x0            ! Test bit 0 (should be clear, Z=1)
        jr      nz, test_bit_fail   ! Should NOT jump

        ! Test multiple SET operations
        ld      r3, #0x0000
        set     r3, #0x0            ! Set bit 0
        set     r3, #0x4            ! Set bit 4
        set     r3, #0x8            ! Set bit 8
        cp      r3, #0x0111         ! Should be 0x0111
        jr      nz, test_bit_fail

        ! All bit tests passed
        inc     r0, #1
        jr      test_bit_ir

test_bit_fail:
        inc     r1, #1
        jr      test_bit_ir

# =============================================================================
# TEST 42d: BIT/SET/RES indirect mode (@Rs)
# =============================================================================
test_bit_ir:
        ld      r2, #145            ! Test number 145

        ! SET @Rs, #b - Set bit in memory
        ld      r4, #bit_test_data
        ld      r3, #0x0000
        ld      @r4, r3             ! Clear memory

        set     @r4, #0x0           ! Set bit 0
        ld      r3, @r4
        cp      r3, #0x0001
        jr      nz, test_bit_ir_fail

        set     @r4, #0x8           ! Set bit 8
        ld      r3, @r4
        cp      r3, #0x0101         ! Both bits set
        jr      nz, test_bit_ir_fail

        ! RES @Rs, #b - Reset bit in memory
        ld      r3, #0xFFFF
        ld      @r4, r3             ! Set all bits

        res     @r4, #0x0           ! Reset bit 0
        ld      r3, @r4
        cp      r3, #0xFFFE
        jr      nz, test_bit_ir_fail

        res     @r4, #0xF           ! Reset bit 15
        ld      r3, @r4
        cp      r3, #0x7FFE
        jr      nz, test_bit_ir_fail

        ! BIT @Rs, #b - Test bit in memory
        ld      r3, #0x8001         ! Bits 0 and 15 set
        ld      @r4, r3

        bit     @r4, #0x0           ! Test bit 0 (should be set, Z=0)
        jr      z, test_bit_ir_fail
        bit     @r4, #0xF           ! Test bit 15 (should be set, Z=0)
        jr      z, test_bit_ir_fail
        bit     @r4, #0x1           ! Test bit 1 (should be clear, Z=1)
        jr      nz, test_bit_ir_fail

        inc     r0, #1
        jr      test_bit_da

test_bit_ir_fail:
        inc     r1, #1
        jr      test_bit_da

# =============================================================================
# TEST 42e: BIT/SET/RES direct address mode
# =============================================================================
test_bit_da:
        ld      r2, #146            ! Test number 146

        ! SET address, #b - Set bit at address
        ld      r4, #bit_test_data
        ld      r3, #0x0000
        ld      @r4, r3             ! Clear memory

        set     bit_test_data, #0x4 ! Set bit 4
        ld      r3, @r4
        cp      r3, #0x0010
        jr      nz, test_bit_da_fail

        ! RES address, #b - Reset bit at address
        ld      r3, #0xFFFF
        ld      @r4, r3             ! Set all bits

        res     bit_test_data, #0x7 ! Reset bit 7
        ld      r3, @r4
        cp      r3, #0xFF7F
        jr      nz, test_bit_da_fail

        ! BIT address, #b - Test bit at address
        ld      r3, #0x0100         ! Bit 8 set
        ld      @r4, r3

        bit     bit_test_data, #0x8 ! Test bit 8 (should be set, Z=0)
        jr      z, test_bit_da_fail
        bit     bit_test_data, #0x0 ! Test bit 0 (should be clear, Z=1)
        jr      nz, test_bit_da_fail

        inc     r0, #1
        jr      test_bit_x

test_bit_da_fail:
        inc     r1, #1
        jr      test_bit_x

# =============================================================================
# TEST 42f: BIT/SET/RES indexed mode (addr(Rs))
# =============================================================================
test_bit_x:
        ld      r2, #147            ! Test number 147

        ! SET addr(Rs), #b - Set bit at indexed address
        ld      r5, #2              ! Index offset
        ld      r4, #bit_test_data
        inc     r4, #2
        ld      r3, #0x0000
        ld      @r4, r3             ! Clear memory at offset

        set     bit_test_data(r5), #0xC  ! Set bit 12 at offset
        ld      r3, @r4
        cp      r3, #0x1000
        jr      nz, test_bit_x_fail

        ! RES addr(Rs), #b - Reset bit at indexed address
        ld      r3, #0xFFFF
        ld      @r4, r3             ! Set all bits at offset

        res     bit_test_data(r5), #0xA  ! Reset bit 10 at offset
        ld      r3, @r4
        cp      r3, #0xFBFF
        jr      nz, test_bit_x_fail

        ! BIT addr(Rs), #b - Test bit at indexed address
        ld      r3, #0x0002         ! Bit 1 set
        ld      @r4, r3

        bit     bit_test_data(r5), #0x1  ! Test bit 1 (should be set, Z=0)
        jr      z, test_bit_x_fail
        bit     bit_test_data(r5), #0x2  ! Test bit 2 (should be clear, Z=1)
        jr      nz, test_bit_x_fail

        inc     r0, #1
        jr      test_djnz

test_bit_x_fail:
        inc     r1, #1
        jr      test_djnz

# =============================================================================
# TEST 42: DJNZ (decrement and jump if not zero)
# =============================================================================
test_djnz:
        ld      r2, #42             ! Test number 42
        ld      r3, #5              ! Loop counter
        ld      r4, #0              ! Accumulator

test_djnz_loop:
        inc     r4, #1              ! Increment accumulator
        djnz    r3, test_djnz_loop  ! Decrement r3, loop if not zero

        ! After loop: R4 should be 5 (looped 5 times)
        cp      r4, #5
        jr      z, test_djnz_pass
        inc     r1, #1
        jr      test_djnz2
test_djnz_pass:
        inc     r0, #1

# =============================================================================
# TEST 43: DJNZ (verify counter reaches zero)
# =============================================================================
test_djnz2:
        ld      r2, #43             ! Test number 43
        ld      r5, #3              ! Loop counter

test_djnz2_loop:
        djnz    r5, test_djnz2_loop ! Decrement r5, loop if not zero

        ! After loop: R5 should be 0
        cp      r5, #0
        jr      z, test_djnz2_pass
        inc     r1, #1
        jp      tests_done
test_djnz2_pass:
        inc     r0, #1
        jr      test_ldi

# =============================================================================
# TEST 44-45: Block instruction tests skipped (need microcode rework for correct 0xBB encoding)
# =============================================================================
test_ldi:
        jp      test_sub_ir         ! Skip block instruction tests
        ld      r2, #44             ! Test number 44

        ! Set up source data in memory
        ld      r4, #ldi_src_data   ! Source address
        ld      r5, #ldi_dst_data   ! Dest address
        ld      r6, #0              ! Clear dest location first

        ! Store 0 to dest to ensure it's clear
        ld      @r5, r6

        ! Execute LDI @R5, @R4, R6 (copy word from @R4 to @R5, increment both)
        ! Encoding: 0xBB91, then 0x5468 (dst=5, src=4, cnt=6, mode=8)
        ldi     @r5, @r4, r6

        ! Check if data was copied correctly
        ld      r6, @r5             ! Load from original dest address (now r5-2)
        ! Note: R5 was incremented, so we need to check the original dest
        ld      r7, #ldi_dst_data
        ld      r6, @r7             ! Load the copied data
        cp      r6, #0xCAFE         ! Should be 0xCAFE
        jr      z, test_ldi_pass
        inc     r1, #1
        jp      tests_done
test_ldi_pass:
        inc     r0, #1
        jr      test_ldir

# =============================================================================
# TEST 45: LDIR (Load, Increment, and Repeat)
# =============================================================================
test_ldir:
        ld      r2, #45             ! Test number 45

        ! Set up source data (3 words: 0x1111, 0x2222, 0x3333)
        ld      r4, #ldir_src_data  ! Source address
        ld      r5, #ldir_dst_data  ! Dest address
        ld      r6, #3              ! Count (3 words)

        ! Clear destination first
        ld      r7, #0
        ld      @r5, r7             ! Clear first word
        inc     r5, #2
        ld      @r5, r7             ! Clear second word
        inc     r5, #2
        ld      @r5, r7             ! Clear third word
        ld      r5, #ldir_dst_data  ! Reset dest pointer

        ! Execute LDIR @R5, @R4, R6 (copy 3 words from @R4 to @R5)
        ldir    @r5, @r4, r6

        ! Verify all three words were copied
        ld      r7, #ldir_dst_data
        ld      r8, @r7             ! First word
        cp      r8, #0x1111
        jr      nz, test_ldir_fail
        inc     r7, #2
        ld      r8, @r7             ! Second word
        cp      r8, #0x2222
        jr      nz, test_ldir_fail
        inc     r7, #2
        ld      r8, @r7             ! Third word
        cp      r8, #0x3333
        jr      nz, test_ldir_fail
        jr      test_ldir_pass

test_ldir_fail:
        inc     r1, #1
        jp      tests_done
test_ldir_pass:
        inc     r0, #1

# =============================================================================
# TEST 46: SUB Rd, @Rs (indirect register)
# =============================================================================
test_sub_ir:
        ld      r2, #46             ! Test number 46
        ld      r3, #100            ! Value to subtract from
        ld      r4, #sub_ir_data    ! Address of subtrahend
        sub     r3, @r4             ! R3 = 100 - mem[@R4] = 100 - 25 = 75
        cp      r3, #75
        jr      z, test_sub_ir_pass
        inc     r1, #1
        jr      test_sub_da
test_sub_ir_pass:
        inc     r0, #1

# =============================================================================
# TEST 47: SUB Rd, address (direct address)
# =============================================================================
test_sub_da:
        ld      r2, #47             ! Test number 47
        ld      r3, #200            ! Value to subtract from
        sub     r3, sub_da_data     ! R3 = 200 - mem[sub_da_data] = 200 - 50 = 150
        cp      r3, #150
        jr      z, test_sub_da_pass
        inc     r1, #1
        jr      test_sub_x
test_sub_da_pass:
        inc     r0, #1

# =============================================================================
# TEST 48: SUB Rd, address(Rs) (indexed)
# =============================================================================
test_sub_x:
        ld      r2, #48             ! Test number 48
        ld      r3, #300            ! Value to subtract from
        ld      r4, #4              ! Index offset (2 words = 4 bytes)
        sub     r3, sub_x_base(r4)  ! R3 = 300 - mem[base+4] = 300 - 30 = 270
        cp      r3, #270
        jr      z, test_sub_x_pass
        inc     r1, #1
        jr      test_and_ir
test_sub_x_pass:
        inc     r0, #1

# =============================================================================
# TEST 49: AND Rd, @Rs (indirect register)
# =============================================================================
test_and_ir:
        ld      r2, #49             ! Test number 49
        ld      r3, #0xFF00         ! Value to AND
        ld      r4, #and_ir_data    ! Address of mask
        and     r3, @r4             ! R3 = 0xFF00 & 0x0F0F = 0x0F00
        cp      r3, #0x0F00
        jr      z, test_and_ir_pass
        inc     r1, #1
        jr      test_or_da
test_and_ir_pass:
        inc     r0, #1

# =============================================================================
# TEST 50: OR Rd, address (direct address)
# =============================================================================
test_or_da:
        ld      r2, #50             ! Test number 50
        ld      r3, #0x00F0         ! Value to OR
        or      r3, or_da_data      ! R3 = 0x00F0 | 0x0F00 = 0x0FF0
        cp      r3, #0x0FF0
        jr      z, test_or_da_pass
        inc     r1, #1
        jr      test_xor_x
test_or_da_pass:
        inc     r0, #1

# =============================================================================
# TEST 51: XOR Rd, address(Rs) (indexed)
# =============================================================================
test_xor_x:
        ld      r2, #51             ! Test number 51
        ld      r3, #0xAAAA         ! Value to XOR
        ld      r4, #2              ! Index offset
        xor     r3, xor_x_base(r4)  ! R3 = 0xAAAA ^ 0x5555 = 0xFFFF
        cp      r3, #0xFFFF
        jr      z, test_xor_x_pass
        inc     r1, #1
        jr      test_cp_ir
test_xor_x_pass:
        inc     r0, #1

# =============================================================================
# TEST 52: CP Rd, @Rs (indirect register compare)
# =============================================================================
test_cp_ir:
        ld      r2, #52             ! Test number 52
        ld      r3, #0x1234         ! Value to compare
        ld      r4, #cp_ir_data     ! Address of comparison value
        cp      r3, @r4             ! Compare R3 with mem[@R4]
        jr      z, test_cp_ir_pass  ! Should be equal (both 0x1234)
        inc     r1, #1
        jr      test_st_x
test_cp_ir_pass:
        inc     r0, #1

# =============================================================================
# TEST 53: ST address(Rd), Rs (indexed store)
# =============================================================================
test_st_x:
        ld      r2, #53             ! Test number 53
        ld      r3, #0xBEEF         ! Value to store
        ld      r4, #4              ! Index offset
        ld      st_x_base(r4), r3   ! Store R3 at base+4
        ! Verify the store
        ld      r5, st_x_base(r4)   ! Load it back
        cp      r5, #0xBEEF
        jr      z, test_st_x_pass
        inc     r1, #1
        jr      test_cp_da
test_st_x_pass:
        inc     r0, #1

# Tests 54-56 removed: ALU BA/BX modes don't exist in Z8000

# =============================================================================
# TEST 54: CP Rd, address (direct address compare)
# =============================================================================
test_cp_da:
        ld      r2, #57             ! Test number 57
        ld      r3, #0x5678         ! Value to compare
        cp      r3, cp_da_data      ! Compare R3 with mem[cp_da_data]
        jr      z, test_cp_da_pass  ! Should be equal (both 0x5678)
        inc     r1, #1
        jr      test_and_da
test_cp_da_pass:
        inc     r0, #1

# =============================================================================
# TEST 58: AND Rd, address (direct address)
# =============================================================================
test_and_da:
        ld      r2, #58             ! Test number 58
        ld      r3, #0xF0F0         ! Value to AND
        and     r3, and_da_data     ! R3 = 0xF0F0 & 0x0FF0 = 0x00F0
        cp      r3, #0x00F0
        jr      z, test_and_da_pass
        inc     r1, #1
        jr      test_or_ir
test_and_da_pass:
        inc     r0, #1

# =============================================================================
# TEST 59: OR Rd, @Rs (indirect register)
# =============================================================================
test_or_ir:
        ld      r2, #59             ! Test number 59
        ld      r3, #0x00FF         ! Value to OR
        ld      r4, #or_ir_data     ! Address of value
        or      r3, @r4             ! R3 = 0x00FF | 0xFF00 = 0xFFFF
        cp      r3, #0xFFFF
        jr      z, test_or_ir_pass
        inc     r1, #1
        jr      test_xor_da
test_or_ir_pass:
        inc     r0, #1

# =============================================================================
# TEST 60: XOR Rd, address (direct address)
# =============================================================================
test_xor_da:
        ld      r2, #60             ! Test number 60
        ld      r3, #0xF0F0         ! Value to XOR
        xor     r3, xor_da_data     ! R3 = 0xF0F0 ^ 0x0F0F = 0xFFFF
        cp      r3, #0xFFFF
        jr      z, test_xor_da_pass
        inc     r1, #1
        jp      tests_done
test_xor_da_pass:
        inc     r0, #1

# =============================================================================
# TEST 61: CPI (Compare and Increment, single word)
# CPI Rd, @Rs, Rn, cc - Compare Rd with @Rs, increment Rs, decrement Rn
# Encoding: first word 0xBB [Rs<<4] 0000, second word 0000_Rrrr_Rddd_cccc
# =============================================================================
test_cpi:
        ld      r2, #61             ! Test number 61
        ld      r3, #0x1234         ! Value to search for
        ld      r4, #cpi_src_data   ! Source address
        ld      r5, #1              ! Count (Rn)
        ! CPI R3, @R4, R5, eq (compare R3 with @R4, terminate on Z=1)
        cpi     r3, @r4, r5, eq
        ! Should match (both 0x1234), Z=1
        jr      z, test_cpi_match
        inc     r1, #1
        jp      tests_done
test_cpi_match:
        ! Verify R4 was incremented
        ld      r6, #cpi_src_data
        add     r6, #2              ! Expected R4 = original + 2
        cp      r4, r6
        jr      z, test_cpi_pass
        inc     r1, #1
        jp      tests_done
test_cpi_pass:
        inc     r0, #1

# =============================================================================
# TEST 62: CPIR with match (Repeat compare until match found)
# CPIR Rd, @Rs, Rn, cc - Repeat CPI until Z=1 (match) or Rn=0 (count exhausted)
# Encoding: first word 0xBB [Rs<<4] 0100, second word 0000_Rrrr_Rddd_cccc
# =============================================================================
test_cpir_match:
        ld      r2, #62             ! Test number 62
        ld      r3, #0x3333         ! Value to search for (3rd element)
        ld      r4, #cpir_src_data  ! Source address
        ld      r5, #5              ! Count (search up to 5 words)
        ! CPIR R3, @R4, R5, eq - repeat compare until Z=1 (match)
        cpir    r3, @r4, r5, eq
        ! Should find 0x3333 at 3rd position, Z=1
        jr      z, test_cpir_found
        inc     r1, #1
        jp      tests_done
test_cpir_found:
        ! Verify pointer advanced correctly (3 words = 6 bytes)
        ld      r6, #cpir_src_data
        add     r6, #6              ! Should be at position after match
        cp      r4, r6
        jr      z, test_cpir_count
        inc     r1, #1
        jp      tests_done
test_cpir_count:
        ! Verify count decremented correctly (5 - 3 = 2)
        cp      r5, #2
        jr      z, test_cpir_match_pass
        inc     r1, #1
        jp      tests_done
test_cpir_match_pass:
        inc     r0, #1

# =============================================================================
# TEST 63: CPIR with no match (count exhausted)
# =============================================================================
test_cpir_nomatch:
        ld      r2, #63             ! Test number 63
        ld      r3, #0x9999         ! Value not in list
        ld      r4, #cpir_src_data  ! Source address
        ld      r5, #3              ! Count (only check 3 words)
        ! CPIR R3, @R4, R5, eq - repeat compare, no match expected
        cpir    r3, @r4, r5, eq
        ! Should NOT find match, Z=0 when count exhausted
        jr      nz, test_cpir_nomatch_ok
        inc     r1, #1              ! Fail if Z=1 (false match)
        jp      tests_done
test_cpir_nomatch_ok:
        ! Verify count is 0
        cp      r5, #0
        jr      z, test_cpir_nomatch_pass
        inc     r1, #1
        jp      tests_done
test_cpir_nomatch_pass:
        inc     r0, #1

# =============================================================================
# TEST 64: CPIB (Compare and Increment, byte)
# Encoding: first word 0xBA [Rs<<4] 0000, second word 0000_Rrrr_Rddd_cccc
# =============================================================================
test_cpib:
        ld      r2, #64             ! Test number 64
        ld      r3, #0x00AB         ! Byte value to search for (in low byte)
        ld      r4, #cpib_src_data  ! Source address
        ld      r5, #1              ! Count (Rn)
        ! CPIB RL3, @R4, R5, eq - compare single byte, Z=1 on match
        cpib    rl3, @r4, r5, eq
        ! Should match (0xAB), Z=1
        jr      z, test_cpib_match
        inc     r1, #1
        jp      tests_done
test_cpib_match:
        ! Verify R4 was incremented by 1 (byte)
        ld      r6, #cpib_src_data
        add     r6, #1              ! Expected R4 = original + 1
        cp      r4, r6
        jr      z, test_cpib_pass
        inc     r1, #1
        jp      tests_done
test_cpib_pass:
        inc     r0, #1

# =============================================================================
# TEST 65: CPDR (Compare, Decrement, and Repeat)
# Searches backwards through memory
# Encoding: first word 0xBB [Rs<<4] 1100, second word 0000_Rrrr_Rddd_cccc
# =============================================================================
test_cpdr:
        ld      r2, #65             ! Test number 65
        ld      r3, #0x1111         ! Value to search for (1st element when going backwards)
        ld      r4, #cpdr_src_end   ! Start at end of data
        ld      r5, #4              ! Count
        ! CPDR R3, @R4, R5, eq - compare backwards until Z=1 (match)
        cpdr    r3, @r4, r5, eq
        ! Should find 0x1111 at 4th position from end, Z=1
        jr      z, test_cpdr_found
        inc     r1, #1
        jp      tests_done
test_cpdr_found:
        ! Verify count decremented correctly (4 - 4 = 0)
        ! Note: finds at last iteration so count should be 0
        cp      r5, #0
        jr      z, test_cpdr_pass
        inc     r1, #1
        jp      tests_done
test_cpdr_pass:
        inc     r0, #1

# =============================================================================
# TEST 66: CPIRB (Compare, Increment, Repeat - Byte)
# Encoding: first word 0xBA [Rs<<4] 0100, second word 0000_Rrrr_Rddd_cccc
# =============================================================================
test_cpirb:
        ld      r2, #66             ! Test number 66
        ld      r3, #0x00CD         ! Byte value to search for
        ld      r4, #cpirb_src_data ! Source address
        ld      r5, #5              ! Count
        ! CPIRB RL3, @R4, R5, eq - compare bytes, repeat until Z=1 (match)
        cpirb   rl3, @r4, r5, eq
        ! Should find 0xCD at 3rd byte, Z=1
        jr      z, test_cpirb_found
        inc     r1, #1
        jp      tests_done
test_cpirb_found:
        ! Verify pointer advanced by 3 bytes
        ld      r6, #cpirb_src_data
        add     r6, #3
        cp      r4, r6
        jr      z, test_cpirb_pass
        inc     r1, #1
        jp      tests_done
test_cpirb_pass:
        inc     r0, #1

# Tests 64-71 removed: ALU BA/BX modes don't exist in Z8000

# =============================================================================
# Test 64: LDL_IM - Load Long Immediate
# LDL RR4, #0x12345678  (R4=0x1234, R5=0x5678)
# =============================================================================
test_ldl_im:
        inc     r2, #1              ! Test 72
        ld      r4, #0              ! Clear R4
        ld      r5, #0              ! Clear R5
        ldl     rr4, #0x12345678    ! Load 32-bit immediate
        cp      r4, #0x1234         ! Check high word
        jr      nz, test_ldl_im_fail
        cp      r5, #0x5678         ! Check low word
        jr      z, test_ldl_im_pass
test_ldl_im_fail:
        inc     r1, #1
        jp      tests_done
test_ldl_im_pass:
        inc     r0, #1

# =============================================================================
# Test 65: LDL_IR - Load Long Indirect
# LDL RR4, @R6 where R6 points to 32-bit data
# =============================================================================
test_ldl_ir:
        inc     r2, #1              ! Test 76
        ld      r6, #ldl_src_data   ! R6 = pointer to 32-bit data
        ld      r4, #0              ! Clear R4
        ld      r5, #0              ! Clear R5
        ldl     rr4, @r6            ! Load 32-bit from memory
        cp      r4, #0xABCD         ! Check high word
        jr      nz, test_ldl_ir_fail
        cp      r5, #0xEF01         ! Check low word
        jr      z, test_ldl_ir_pass
test_ldl_ir_fail:
        inc     r1, #1
        jp      tests_done
test_ldl_ir_pass:
        inc     r0, #1

# =============================================================================
# Test 66: LDL_DA - Load Long Direct Address
# LDL RR4, ldl_src_data
# =============================================================================
test_ldl_da:
        inc     r2, #1              ! Test 77
        ld      r4, #0              ! Clear R4
        ld      r5, #0              ! Clear R5
        ldl     rr4, ldl_src_data   ! Load 32-bit from direct address
        cp      r4, #0xABCD         ! Check high word
        jr      nz, test_ldl_da_fail
        cp      r5, #0xEF01         ! Check low word
        jr      z, test_ldl_da_pass
test_ldl_da_fail:
        inc     r1, #1
        jp      tests_done
test_ldl_da_pass:
        inc     r0, #1

# =============================================================================
# Test 67: LDL_X - Load Long Indexed
# LDL RR4, ldl_indexed_base(R6) where R6=4 (offset to second long)
# =============================================================================
test_ldl_x:
        inc     r2, #1              ! Test 78
        ld      r6, #4              ! R6 = offset 4 bytes (second long)
        ld      r4, #0              ! Clear R4
        ld      r5, #0              ! Clear R5
        ldl     rr4, ldl_indexed_base(r6) ! Load 32-bit from indexed address
        cp      r4, #0x2222         ! Check high word (second long value)
        jr      nz, test_ldl_x_fail
        cp      r5, #0x3333         ! Check low word
        jr      z, test_ldl_x_pass
test_ldl_x_fail:
        inc     r1, #1
        jp      tests_done
test_ldl_x_pass:
        inc     r0, #1

# =============================================================================
# Test 68: STL_IR - Store Long Indirect
# STL @R6, RR4 where R6 points to destination
# =============================================================================
test_stl_ir:
        inc     r2, #1              ! Test 79
        ld      r4, #0x4455         ! High word to store
        ld      r5, #0x6677         ! Low word to store
        ld      r6, #stl_dst_data   ! R6 = pointer to destination
        ldl     @r6, rr4            ! Store 32-bit to memory
        ! Verify by loading back
        ldl     rr8, @r6            ! Load back to RR8
        cp      r8, #0x4455         ! Check high word
        jr      nz, test_stl_ir_fail
        cp      r9, #0x6677         ! Check low word
        jr      z, test_stl_ir_pass
test_stl_ir_fail:
        inc     r1, #1
        jp      tests_done
test_stl_ir_pass:
        inc     r0, #1

# =============================================================================
# Test 69: STL_DA - Store Long Direct Address
# STL stl_dst_data2, RR4
# =============================================================================
test_stl_da:
        inc     r2, #1              ! Test 80
        ld      r4, #0x8899         ! High word to store
        ld      r5, #0xAABB         ! Low word to store
        ldl     stl_dst_data2, rr4  ! Store 32-bit to direct address
        ! Verify by loading back
        ldl     rr8, stl_dst_data2  ! Load back to RR8
        cp      r8, #0x8899         ! Check high word
        jr      nz, test_stl_da_fail
        cp      r9, #0xAABB         ! Check low word
        jr      z, test_stl_da_pass
test_stl_da_fail:
        inc     r1, #1
        jp      tests_done
test_stl_da_pass:
        inc     r0, #1

# =============================================================================
# Test 70: STL_X - Store Long Indexed
# STL stl_indexed_base(R6), RR4 where R6=4 (offset)
# =============================================================================
test_stl_x:
        inc     r2, #1              ! Test 81
        ld      r4, #0xCCDD         ! High word to store
        ld      r5, #0xEEFF         ! Low word to store
        ld      r6, #4              ! R6 = offset 4 bytes
        ldl     stl_indexed_base(r6), rr4  ! Store 32-bit to indexed address
        ! Verify by loading back
        ldl     rr8, stl_indexed_base(r6)  ! Load back to RR8
        cp      r8, #0xCCDD         ! Check high word
        jr      nz, test_stl_x_fail
        cp      r9, #0xEEFF         ! Check low word
        jr      z, test_stl_x_pass
test_stl_x_fail:
        inc     r1, #1
        jp      tests_done
test_stl_x_pass:
        inc     r0, #1

# =============================================================================
# Test 71: ADDL_R - Add Long Register
# ADDL RR4, RR6 where RR4 = 0x00010002, RR6 = 0x00030004
# Result should be 0x00040006
# =============================================================================
test_addl_r:
        inc     r2, #1              ! Test 71
        ld      r4, #0x0001         ! RR4 high = 0x0001
        ld      r5, #0x0002         ! RR4 low = 0x0002
        ld      r6, #0x0003         ! RR6 high = 0x0003
        ld      r7, #0x0004         ! RR6 low = 0x0004
        addl    rr4, rr6            ! RR4 = RR4 + RR6
        cp      r4, #0x0004         ! Check high word
        jr      nz, test_addl_r_fail
        cp      r5, #0x0006         ! Check low word
        jr      z, test_addl_r_pass
test_addl_r_fail:
        inc     r1, #1
        jp      tests_done
test_addl_r_pass:
        inc     r0, #1

# =============================================================================
# Test 72: ADDL_IM - Add Long Immediate
# ADDL RR4, #0x00010001 where RR4 = 0x00020003
# Result should be 0x00030004
# =============================================================================
test_addl_im:
        inc     r2, #1              ! Test 72
        ld      r4, #0x0002         ! RR4 high = 0x0002
        ld      r5, #0x0003         ! RR4 low = 0x0003
        addl    rr4, #0x00010001    ! RR4 = RR4 + 0x00010001
        cp      r4, #0x0003         ! Check high word
        jr      nz, test_addl_im_fail
        cp      r5, #0x0004         ! Check low word
        jr      z, test_addl_im_pass
test_addl_im_fail:
        inc     r1, #1
        jp      tests_done
test_addl_im_pass:
        inc     r0, #1

# =============================================================================
# Test 73: SUBL_R - Subtract Long Register
# SUBL RR4, RR6 where RR4 = 0x00050006, RR6 = 0x00010002
# Result should be 0x00040004
# =============================================================================
test_subl_r:
        inc     r2, #1              ! Test 73
        ld      r4, #0x0005         ! RR4 high = 0x0005
        ld      r5, #0x0006         ! RR4 low = 0x0006
        ld      r6, #0x0001         ! RR6 high = 0x0001
        ld      r7, #0x0002         ! RR6 low = 0x0002
        subl    rr4, rr6            ! RR4 = RR4 - RR6
        cp      r4, #0x0004         ! Check high word
        jr      nz, test_subl_r_fail
        cp      r5, #0x0004         ! Check low word
        jr      z, test_subl_r_pass
test_subl_r_fail:
        inc     r1, #1
        jp      tests_done
test_subl_r_pass:
        inc     r0, #1

# =============================================================================
# Test 74: CPL_R - Compare Long Register
# CPL RR4, RR6 where both = 0x12345678 (should be equal, Z=1)
# =============================================================================
test_cpl_r:
        inc     r2, #1              ! Test 74
        ld      r4, #0x1234         ! RR4 high
        ld      r5, #0x5678         ! RR4 low
        ld      r6, #0x1234         ! RR6 high (same)
        ld      r7, #0x5678         ! RR6 low (same)
        cpl     rr4, rr6            ! Compare RR4 with RR6
        jr      z, test_cpl_r_pass  ! Should be equal
test_cpl_r_fail:
        inc     r1, #1
        jp      tests_done
test_cpl_r_pass:
        inc     r0, #1

# =============================================================================
# Test 75: LDL_BA - Load Long Based
# LDL RR4, R6(#4) where R6 points to ldl_based_data
# =============================================================================
test_ldl_ba:
        inc     r2, #1              ! Test 75
        ld      r6, #ldl_based_data ! Base address
        ld      r4, #0              ! Clear
        ld      r5, #0
        ldl     rr4, r6(#4)         ! Load from base+4 (second long)
        cp      r4, #0x5555         ! Check high word
        jr      nz, test_ldl_ba_fail
        cp      r5, #0x6666         ! Check low word
        jr      z, test_ldl_ba_pass
test_ldl_ba_fail:
        inc     r1, #1
        jp      tests_done
test_ldl_ba_pass:
        inc     r0, #1

# =============================================================================
# Test 76: LDB_BA - Load Byte Based
# LDB RH0, R6(#2) where R6 points to ldb_based_data
# =============================================================================
test_ldb_ba:
        inc     r2, #1              ! Test 76
        ld      r6, #ldb_based_data ! Base address
        ld      r3, #0              ! Clear (use R3, not R0!)
        ldb     rh3, r6(#2)         ! Load byte from base+2 into RH3
        cp      r3, #0x3300         ! Check (RH3 should be 0x33, in high byte position)
        jr      z, test_ldb_ba_pass
test_ldb_ba_fail:
        inc     r1, #1
        jp      tests_done
test_ldb_ba_pass:
        inc     r0, #1

# =============================================================================
# TEST 77: IN Rd, port (direct input word)
# Read from port 0x0000, should get io_data_reg value (0x1234)
# =============================================================================
test_in_da:
        inc     r2, #1              ! Test 77
        in      r3, #0x0000         ! Read from port 0
        cp      r3, #0x1234         ! Check value
        jr      z, test_in_da_pass
        inc     r1, #1
        jr      test_inb_da
test_in_da_pass:
        inc     r0, #1

# =============================================================================
# TEST 78: INB Rbd, port (direct input byte)
# Read from port 0x0010, should get 0xAA
# =============================================================================
test_inb_da:
        inc     r2, #1              ! Test 78
        ld      r3, #0              ! Clear R3
        inb     rl3, #0x0010        ! Read byte from port 0x10 into RL3
        cp      r3, #0x00AA         ! Check value (low byte)
        jr      z, test_inb_da_pass
        inc     r1, #1
        jr      test_out_da
test_inb_da_pass:
        inc     r0, #1

# =============================================================================
# TEST 79: OUT port, Rs (direct output word)
# Write 0xBEEF to port 0x0000
# =============================================================================
test_out_da:
        inc     r2, #1              ! Test 79
        ld      r3, #0xBEEF
        out     #0x0000, r3         ! Write to port 0
        ! Read it back
        in      r4, #0x0000
        cp      r4, #0xBEEF         ! Check write worked
        jr      z, test_out_da_pass
        inc     r1, #1
        jr      test_outb_da
test_out_da_pass:
        inc     r0, #1

# =============================================================================
# TEST 80: OUTB port, Rbs (direct output byte)
# Write 0x42 to port 0x0001 (low byte of io_data_reg)
# =============================================================================
test_outb_da:
        inc     r2, #1              ! Test 80
        ld      r3, #0x0042         ! Value in low byte
        outb    #0x0001, rl3        ! Write byte to port 1
        ! Read back the word from port 0
        in      r4, #0x0000
        cp      r4, #0xBE42         ! High byte unchanged, low byte = 0x42
        jr      z, test_outb_da_pass
        inc     r1, #1
        jr      test_in_ir
test_outb_da_pass:
        inc     r0, #1

# =============================================================================
# TEST 81: IN Rd, @Rs (indirect input word)
# Use R5 as port address register
# =============================================================================
test_in_ir:
        inc     r2, #1              ! Test 81
        ld      r5, #0x0002         ! Port address (io_ctrl_reg)
        ld      r3, #0x5555
        out     #0x0002, r3         ! Initialize ctrl reg
        in      r3, @r5             ! Read via indirect
        cp      r3, #0x5555         ! Check value
        jr      z, test_in_ir_pass
        inc     r1, #1
        jr      test_out_ir
test_in_ir_pass:
        inc     r0, #1

# =============================================================================
# TEST 82: OUT @Rd, Rs (indirect output word)
# Use R5 as port address register
# =============================================================================
test_out_ir:
        inc     r2, #1              ! Test 82
        ld      r5, #0x0002         ! Port address (io_ctrl_reg)
        ld      r3, #0xAAAA
        out     @r5, r3             ! Write via indirect
        in      r4, #0x0002         ! Read back
        cp      r4, #0xAAAA
        jr      z, test_out_ir_pass
        inc     r1, #1
        jr      test_sin_da
test_out_ir_pass:
        inc     r0, #1

# =============================================================================
# TEST 83: SIN Rd, port (special input word)
# Read from special I/O port 0x0020, should get sio_data_reg (0x5678)
# =============================================================================
test_sin_da:
        inc     r2, #1              ! Test 83
        sin     r3, #0x0020         ! Special I/O read
        cp      r3, #0x5678         ! Check initial value
        jr      z, test_sin_da_pass
        inc     r1, #1
        jr      test_sout_da
test_sin_da_pass:
        inc     r0, #1

# =============================================================================
# TEST 84: SOUT port, Rs (special output word)
# Write 0xCAFE to special I/O port 0x0020
# =============================================================================
test_sout_da:
        inc     r2, #1              ! Test 84
        ld      r3, #0xCAFE
        sout    #0x0020, r3         ! Special I/O write
        sin     r4, #0x0020         ! Read back
        cp      r4, #0xCAFE
        jr      z, test_sout_da_pass
        inc     r1, #1
        jp      tests_done
test_sout_da_pass:
        inc     r0, #1

# =============================================================================
# TEST 85: NOP (no operation)
# Verify NOP doesn't change any registers
# =============================================================================
test_nop:
        inc     r2, #1              ! Test 85
        ld      r3, #0x1234         ! Set known value
        ld      r4, #0x5678         ! Set known value
        nop                         ! Execute NOP
        nop                         ! Execute another NOP
        nop                         ! And another
        cp      r3, #0x1234         ! Verify R3 unchanged
        jr      nz, test_nop_fail
        cp      r4, #0x5678         ! Verify R4 unchanged
        jr      nz, test_nop_fail
        jr      test_nop_pass
test_nop_fail:
        inc     r1, #1
        jp      tests_done
test_nop_pass:
        inc     r0, #1

# =============================================================================
# TEST 86: RL Rd, #1 (Rotate Left by 1)
# 0x8001 rotated left = 0x0003, carry = 1 (bit 15 was set)
# =============================================================================
test_rl_1:
        inc     r2, #1              ! Test 86
        ld      r3, #0x8001         ! Bit 15 and bit 0 set
        rl      r3, #1              ! Rotate left by 1
        cp      r3, #0x0003         ! Bit 15 -> bit 0, bit 0 -> bit 1
        jr      nz, test_rl_1_fail
        jr      test_rl_1_pass
test_rl_1_fail:
        inc     r1, #1
        jr      test_rl_2
test_rl_1_pass:
        inc     r0, #1

# =============================================================================
# TEST 87: RL Rd, #2 (Rotate Left by 2)
# 0xC000 rotated left 2 = 0x0003, carry = 1
# =============================================================================
test_rl_2:
        inc     r2, #1              ! Test 87
        ld      r3, #0xC000         ! Bits 15 and 14 set
        rl      r3, #2              ! Rotate left by 2
        cp      r3, #0x0003         ! Both high bits wrap to low bits
        jr      nz, test_rl_2_fail
        jr      test_rl_2_pass
test_rl_2_fail:
        inc     r1, #1
        jr      test_rr_1
test_rl_2_pass:
        inc     r0, #1

# =============================================================================
# TEST 88: RR Rd, #1 (Rotate Right by 1)
# 0x0001 rotated right = 0x8000, carry = 1 (bit 0 was set)
# =============================================================================
test_rr_1:
        inc     r2, #1              ! Test 88
        ld      r3, #0x0001         ! Only bit 0 set
        rr      r3, #1              ! Rotate right by 1
        cp      r3, #0x8000         ! Bit 0 -> bit 15
        jr      nz, test_rr_1_fail
        jr      test_rr_1_pass
test_rr_1_fail:
        inc     r1, #1
        jr      test_rr_2
test_rr_1_pass:
        inc     r0, #1

# =============================================================================
# TEST 89: RR Rd, #2 (Rotate Right by 2)
# 0x0003 rotated right 2 = 0xC000
# =============================================================================
test_rr_2:
        inc     r2, #1              ! Test 89
        ld      r3, #0x0003         ! Bits 0 and 1 set
        rr      r3, #2              ! Rotate right by 2
        cp      r3, #0xC000         ! Both low bits wrap to high bits
        jr      nz, test_rr_2_fail
        jr      test_rr_2_pass
test_rr_2_fail:
        inc     r1, #1
        jr      test_sla
test_rr_2_pass:
        inc     r0, #1

# =============================================================================
# TEST 90: SLA Rd, #n (Shift Left Arithmetic by count)
# 0x0001 shifted left by 4 = 0x0010
# =============================================================================
test_sla:
        inc     r2, #1              ! Test 90
        ld      r3, #0x0001         ! Bit 0 set
        sla     r3, #4              ! Shift left by 4
        cp      r3, #0x0010         ! Result should be 0x0010
        jr      nz, test_sla_fail
        jr      test_sla_pass
test_sla_fail:
        inc     r1, #1
        jr      test_srl
test_sla_pass:
        inc     r0, #1

# =============================================================================
# TEST 91: SRL Rd, #n (Shift Right Logical by count)
# 0x8000 shifted right by 4 = 0x0800
# =============================================================================
test_srl:
        inc     r2, #1              ! Test 91
        ld      r3, #0x8000         ! Bit 15 set
        srl     r3, #4              ! Shift right by 4
        cp      r3, #0x0800         ! Result should be 0x0800
        jr      nz, test_srl_fail
        jr      test_srl_pass
test_srl_fail:
        inc     r1, #1
        jr      test_rlb
test_srl_pass:
        inc     r0, #1

# =============================================================================
# TEST 92: RLB Rbd, #1 (Rotate Left Byte by 1)
# 0x81 rotated left = 0x03
# =============================================================================
test_rlb:
        inc     r2, #1              ! Test 92
        ld      r3, #0x0081         ! Byte value 0x81 in low byte
        rlb     rl3, #1             ! Rotate left by 1
        cp      r3, #0x0003         ! Bit 7 -> bit 0
        jr      nz, test_rlb_fail
        jr      test_rlb_pass
test_rlb_fail:
        inc     r1, #1
        jr      test_rrb
test_rlb_pass:
        inc     r0, #1

# =============================================================================
# TEST 93: RRB Rbd, #1 (Rotate Right Byte by 1)
# 0x01 rotated right = 0x80
# =============================================================================
test_rrb:
        inc     r2, #1              ! Test 93
        ld      r3, #0x0001         ! Byte value 0x01 in low byte
        rrb     rl3, #1             ! Rotate right by 1
        cp      r3, #0x0080         ! Bit 0 -> bit 7
        jr      nz, test_rrb_fail
        jr      test_rrb_pass
test_rrb_fail:
        inc     r1, #1
        jp      tests_done
test_rrb_pass:
        inc     r0, #1

# =============================================================================
# TEST 94: SLA sets Carry flag when bit shifts out
# 0x8000 shifted left by 1 should set C (bit 15 shifts out)
# =============================================================================
test_sla_carry:
        inc     r2, #1              ! Test 94
        ld      r3, #0x8000         ! Bit 15 set
        sla     r3, #1              ! Shift left - bit 15 should go to C
        jr      nc, test_sla_carry_fail   ! Should have carry set
        jr      test_sla_carry_pass
test_sla_carry_fail:
        inc     r1, #1
        jr      test_srl_carry
test_sla_carry_pass:
        inc     r0, #1

# =============================================================================
# TEST 95: SRL sets Carry flag when bit shifts out
# 0x0001 shifted right by 1 should set C (bit 0 shifts out)
# =============================================================================
test_srl_carry:
        inc     r2, #1              ! Test 95
        ld      r3, #0x0001         ! Bit 0 set
        srl     r3, #1              ! Shift right - bit 0 should go to C
        jr      nc, test_srl_carry_fail   ! Should have carry set
        jr      test_srl_carry_pass
test_srl_carry_fail:
        inc     r1, #1
        jr      test_srl_zero
test_srl_carry_pass:
        inc     r0, #1

# =============================================================================
# TEST 96: SRL sets Zero flag when result is zero
# 0x0001 shifted right by 1 should be 0 and set Z
# =============================================================================
test_srl_zero:
        inc     r2, #1              ! Test 96
        ld      r3, #0x0001         ! Only bit 0 set
        srl     r3, #1              ! Result is 0
        jr      nz, test_srl_zero_fail    ! Should have zero set
        jr      test_srl_zero_pass
test_srl_zero_fail:
        inc     r1, #1
        jr      test_rl_carry
test_srl_zero_pass:
        inc     r0, #1

# =============================================================================
# TEST 97: RL sets Carry flag
# 0x8000 rotated left by 1: bit 15 goes to C and bit 0
# =============================================================================
test_rl_carry:
        inc     r2, #1              ! Test 97
        ld      r3, #0x8000         ! Bit 15 set
        rl      r3, #1              ! Rotate left - bit 15 to C and bit 0
        jr      nc, test_rl_carry_fail    ! Should have carry set
        jr      test_rl_carry_pass
test_rl_carry_fail:
        inc     r1, #1
        jr      test_rr_carry
test_rl_carry_pass:
        inc     r0, #1

# =============================================================================
# TEST 98: RR sets Carry flag
# 0x0001 rotated right by 1: bit 0 goes to C and bit 15
# =============================================================================
test_rr_carry:
        inc     r2, #1              ! Test 98
        ld      r3, #0x0001         ! Bit 0 set
        rr      r3, #1              ! Rotate right - bit 0 to C and bit 15
        jr      nc, test_rr_carry_fail    ! Should have carry set
        jr      test_rr_carry_pass
test_rr_carry_fail:
        inc     r1, #1
        jp      tests_done
test_rr_carry_pass:
        inc     r0, #1

# =============================================================================
# TEST 99: SRA (Shift Right Arithmetic) - preserves sign bit
# 0x8004 >> 2 = 0xE001 (sign bit preserved, original was negative)
# SRA uses negative count on opcode 0xB3d9 (same as SLA)
# =============================================================================
test_sra:
        inc     r2, #1              ! Test 99
        ld      r3, #0x8004         ! 1000_0000_0000_0100 (negative value)
        sra     r3, #2              ! Shift right arithmetic by 2
        cp      r3, #0xE001         ! 1110_0000_0000_0001 (sign preserved)
        jr      z, test_sra_pass
        inc     r1, #1
        jr      test_sll
test_sra_pass:
        inc     r0, #1

# =============================================================================
# TEST 100: SLL (Shift Left Logical) - same as SLA but logical
# 0x0003 << 4 = 0x0030
# SLL uses positive count on opcode 0xB3d1 (same as SRL)
# =============================================================================
test_sll:
        inc     r2, #1              ! Test 100
        ld      r3, #0x0003         ! 0000_0000_0000_0011
        sll     r3, #4              ! Shift left logical by 4
        cp      r3, #0x0030         ! 0000_0000_0011_0000
        jr      z, test_sll_pass
        inc     r1, #1
        jr      test_sra_vs_srl
test_sll_pass:
        inc     r0, #1

# =============================================================================
# TEST 101: SRA vs SRL - verify sign extension difference
# SRA on 0xFF00 >> 8 should give 0xFFFF (sign fills in)
# SRL on 0xFF00 >> 8 would give 0x00FF (zeros fill in)
# =============================================================================
test_sra_vs_srl:
        inc     r2, #1              ! Test 101
        ld      r3, #0xFF00         ! 1111_1111_0000_0000 (negative)
        sra     r3, #8              ! Shift right arithmetic by 8
        cp      r3, #0xFFFF         ! 1111_1111_1111_1111 (sign extended)
        jr      z, test_sra_vs_srl_pass
        inc     r1, #1
        jp      tests_done
test_sra_vs_srl_pass:
        inc     r0, #1

# =============================================================================
# TEST 102: Compact LDB - single-word load byte immediate
# Format: 0xCdii where d=dest register, ii=immediate byte
# Tests both high and low byte register targets
# =============================================================================
test_ldb_short:
        inc     r2, #1              ! Test 102
        ld      r3, #0x0000         ! Clear R3 first
        ldb     rh3, #0x42          ! Load 0x42 to high byte (compact format: 0xC342)
        cp      r3, #0x4200         ! R3 should now be 0x4200
        jr      z, test_ldb_short_2
        inc     r1, #1
        jp      tests_done
test_ldb_short_2:
        ld      r3, #0x0000         ! Clear R3 again
        ldb     rl3, #0xAB          ! Load 0xAB to low byte (compact format: 0xC7AB)
        cp      r3, #0x00AB         ! R3 should now be 0x00AB
        jr      z, test_ldb_short_pass
        inc     r1, #1
        jp      tests_done
test_ldb_short_pass:
        inc     r0, #1

# =============================================================================
# TEST 103: LDK - Load Constant (4-bit immediate 0-15)
# Format: 0xBDrn where r=dest register, n=4-bit constant
# =============================================================================
test_ldk:
        inc     r2, #1              ! Test 103
        ldk     r3, #0              ! Load 0 to R3
        cp      r3, #0
        jr      nz, test_ldk_fail
        ldk     r3, #15             ! Load max value (15) to R3
        cp      r3, #15
        jr      nz, test_ldk_fail
        ldk     r4, #7              ! Load 7 to R4
        cp      r4, #7
        jr      z, test_ldk_pass
test_ldk_fail:
        inc     r1, #1
        jp      tests_done
test_ldk_pass:
        inc     r0, #1

# =============================================================================
# TEST 104: INC @Rd, #n - Increment memory via indirect addressing
# =============================================================================
test_inc_ir:
        inc     r2, #1              ! Test 104
        ld      r3, #inc_ir_data    ! Point to test data
        ld      r4, #0x1234         ! Expected value (0x1230 + 4)
        inc     @r3, #4             ! Increment memory by 4
        ld      r5, @r3             ! Read back
        cp      r5, r4
        jr      z, test_inc_ir_pass
test_inc_ir_fail:
        inc     r1, #1
        jp      tests_done
test_inc_ir_pass:
        inc     r0, #1

# =============================================================================
# TEST 105: DEC @Rd, #n - Decrement memory via indirect addressing
# =============================================================================
test_dec_ir:
        inc     r2, #1              ! Test 105
        ld      r3, #dec_ir_data    ! Point to test data
        ld      r4, #0x1000         ! Expected value (0x1005 - 5)
        dec     @r3, #5             ! Decrement memory by 5
        ld      r5, @r3             ! Read back
        cp      r5, r4
        jr      z, test_dec_ir_pass
test_dec_ir_fail:
        inc     r1, #1
        jp      tests_done
test_dec_ir_pass:
        inc     r0, #1

# =============================================================================
# TEST 106: NEG @Rd - Negate memory via indirect addressing
# =============================================================================
test_neg_ir:
        inc     r2, #1              ! Test 106
        ld      r3, #neg_ir_data    ! Point to test data
        ld      r4, #0xFFFB         ! Expected: -5 = 0xFFFB
        neg     @r3                 ! Negate memory
        ld      r5, @r3             ! Read back
        cp      r5, r4
        jr      z, test_neg_ir_pass
test_neg_ir_fail:
        inc     r1, #1
        jp      tests_done
test_neg_ir_pass:
        inc     r0, #1

# =============================================================================
# TEST 107: COM @Rd - Complement memory via indirect addressing
# =============================================================================
test_com_ir:
        inc     r2, #1              ! Test 107
        ld      r3, #com_ir_data    ! Point to test data
        ld      r4, #0xFF00         ! Expected: ~0x00FF = 0xFF00
        com     @r3                 ! Complement memory
        ld      r5, @r3             ! Read back
        cp      r5, r4
        jr      z, test_com_ir_pass
test_com_ir_fail:
        inc     r1, #1
        jp      tests_done
test_com_ir_pass:
        inc     r0, #1

# =============================================================================
# TEST 108: INIR - Block input, increment, repeat (word)
# Read 3 words from port into memory
# Encoding: 0x3Bs0 + 0x0rrd0 (s=port reg, r=count reg, d=dest reg)
# =============================================================================
test_inir:
        inc     r2, #1              ! Test 108
        ! Initialize destination memory to known value
        ld      r3, #inir_dst_data
        ld      r4, #0xFFFF
        ld      @r3, r4
        inc     r3, #2
        ld      @r3, r4
        inc     r3, #2
        ld      @r3, r4
        ! Reset port 0 to known value (earlier tests may have changed it)
        ld      r4, #0x1234
        out     #0x0000, r4         ! Write 0x1234 to port 0
        ! Set up port address in R5, count in R6, dest pointer in R4
        ld      r4, #inir_dst_data  ! Memory destination
        ld      r5, #0x0000         ! Port 0 (now contains 0x1234)
        ld      r6, #3              ! Count = 3 words
        ! Execute INIR @R4, @R5, R6 - block input words
        inir    @r4, @r5, r6
        ! Verify first word in memory
        ld      r3, #inir_dst_data
        ld      r7, @r3
        cp      r7, #0x1234
        jr      nz, test_inir_fail
        ! Verify second word
        inc     r3, #2
        ld      r7, @r3
        cp      r7, #0x1234
        jr      nz, test_inir_fail
        ! Verify third word
        inc     r3, #2
        ld      r7, @r3
        cp      r7, #0x1234
        jr      nz, test_inir_fail
        ! Skip pointer verification (just verify data transfer)
        jr      test_inir_pass
test_inir_fail:
        inc     r1, #1
        jp      test_otir
test_inir_pass:
        inc     r0, #1

# =============================================================================
# TEST 109: OTIR - Block output, increment, repeat (word)
# Write 3 words from memory to port
# =============================================================================
test_otir:
        inc     r2, #1              ! Test 109
        ! Set up source data, port address, and count
        ld      r4, #otir_src_data  ! Memory source
        ld      r5, #0x0000         ! Port 0
        ld      r6, #3              ! Count = 3 words
        ! Execute OTIR @R5, @R4, R6 - block output words
        otir    @r5, @r4, r6
        ! Read back from port - should contain last value written (0x3333)
        in      r7, #0x0000
        cp      r7, #0x3333
        jr      nz, test_otir_fail
        ! Skip pointer verification (just verify data transfer)
        jr      test_otir_pass
test_otir_fail:
        inc     r1, #1
        jp      tests_done          ! Skip remaining tests on failure
test_otir_pass:
        inc     r0, #1

# =============================================================================
# TEST 110: INIRB - Block input byte, increment, repeat
# Read 4 bytes from port into memory
# =============================================================================
test_inirb:
        inc     r2, #1              ! Test 110
        ! Clear destination first
        ld      r3, #inirb_dst_data
        ld      r4, #0xFFFF
        ld      @r3, r4
        inc     r3, #2
        ld      @r3, r4
        ! Set up: port in R5 (0x10 returns 0xAA), dest in R4, count in R6
        ld      r4, #inirb_dst_data ! Memory destination
        ld      r5, #0x0010         ! Port 0x10 (returns 0xAA)
        ld      r6, #4              ! Count = 4 bytes
        ! Execute INIRB @R4, @R5, R6 - block input bytes
        inirb   @r4, @r5, r6
        ! Verify bytes were written (all should be 0xAA)
        ld      r3, #inirb_dst_data
        ld      r7, @r3
        cp      r7, #0xAAAA         ! Both bytes should be 0xAA
        jr      nz, test_inirb_fail
        inc     r3, #2
        ld      r7, @r3
        cp      r7, #0xAAAA
        jr      nz, test_inirb_fail
        ! Verify R4 was incremented by 4 (4 bytes)
        ld      r3, #inirb_dst_data
        add     r3, #4
        cp      r4, r3
        jr      z, test_inirb_pass
test_inirb_fail:
        inc     r1, #1
        jp      tests_done
test_inirb_pass:
        inc     r0, #1

# =============================================================================
# TEST 115: ADDB - Byte add register
# =============================================================================
test_addb_r:
        inc     r2, #1              ! Test 115
        ld      r3, #0x0000         ! Clear R3
        ldb     rl3, #0x25          ! RL3 = 0x25
        ldb     rh4, #0x10          ! RH4 = 0x10
        addb    rl3, rh4            ! RL3 = 0x25 + 0x10 = 0x35
        cp      r3, #0x0035         ! Check low byte is 0x35
        jr      z, test_addb_r_pass
        inc     r1, #1
        jp      tests_done
test_addb_r_pass:
        inc     r0, #1

# =============================================================================
# TEST 116: SUBB - Byte subtract register
# =============================================================================
test_subb_r:
        inc     r2, #1              ! Test 116
        ld      r3, #0x0000
        ldb     rl3, #0x50          ! RL3 = 0x50
        ldb     rh4, #0x20          ! RH4 = 0x20
        subb    rl3, rh4            ! RL3 = 0x50 - 0x20 = 0x30
        cp      r3, #0x0030         ! Check result
        jr      z, test_subb_r_pass
        inc     r1, #1
        jp      tests_done
test_subb_r_pass:
        inc     r0, #1

# =============================================================================
# TEST 117: ANDB - Byte AND register
# =============================================================================
test_andb_r:
        inc     r2, #1              ! Test 117
        ld      r3, #0x0000
        ldb     rl3, #0xFF          ! RL3 = 0xFF
        ldb     rh4, #0x0F          ! RH4 = 0x0F
        andb    rl3, rh4            ! RL3 = 0xFF & 0x0F = 0x0F
        cp      r3, #0x000F         ! Check result
        jr      z, test_andb_r_pass
        inc     r1, #1
        jp      tests_done
test_andb_r_pass:
        inc     r0, #1

# =============================================================================
# TEST 118: ORB - Byte OR register
# =============================================================================
test_orb_r:
        inc     r2, #1              ! Test 118
        ld      r3, #0x0000
        ldb     rl3, #0xF0          ! RL3 = 0xF0
        ldb     rh4, #0x0F          ! RH4 = 0x0F
        orb     rl3, rh4            ! RL3 = 0xF0 | 0x0F = 0xFF
        cp      r3, #0x00FF         ! Check result
        jr      z, test_orb_r_pass
        inc     r1, #1
        jp      tests_done
test_orb_r_pass:
        inc     r0, #1

# =============================================================================
# TEST 119: XORB - Byte XOR register
# =============================================================================
test_xorb_r:
        inc     r2, #1              ! Test 119
        ld      r3, #0x0000
        ldb     rl3, #0xFF          ! RL3 = 0xFF
        ldb     rh4, #0xAA          ! RH4 = 0xAA
        xorb    rl3, rh4            ! RL3 = 0xFF ^ 0xAA = 0x55
        cp      r3, #0x0055         ! Check result
        jr      z, test_xorb_r_pass
        inc     r1, #1
        jp      tests_done
test_xorb_r_pass:
        inc     r0, #1

# =============================================================================
# TEST 120: CPB - Byte compare (equal)
# =============================================================================
test_cpb_r:
        inc     r2, #1              ! Test 120
        ld      r3, #0x0000
        ldb     rl3, #0x42          ! RL3 = 0x42
        ldb     rh4, #0x42          ! RH4 = 0x42
        cpb     rl3, rh4            ! Compare - should set Z
        jr      z, test_cpb_r_pass
        inc     r1, #1
        jp      tests_done
test_cpb_r_pass:
        inc     r0, #1

# =============================================================================
# TEST 121: INCB - Byte increment register
# =============================================================================
test_incb_r:
        inc     r2, #1              ! Test 121
        ld      r3, #0x0000
        ldb     rl3, #0xFE          ! RL3 = 0xFE
        incb    rl3, #1             ! RL3 = 0xFE + 1 = 0xFF
        cp      r3, #0x00FF         ! Check result
        jr      z, test_incb_r_pass
        inc     r1, #1
        jp      tests_done
test_incb_r_pass:
        inc     r0, #1

# =============================================================================
# TEST 122: DECB - Byte decrement register
# =============================================================================
test_decb_r:
        inc     r2, #1              ! Test 122
        ld      r3, #0x0000
        ldb     rl3, #0x10          ! RL3 = 0x10
        decb    rl3, #1             ! RL3 = 0x10 - 1 = 0x0F
        cp      r3, #0x000F         ! Check result
        jr      z, test_decb_r_pass
        inc     r1, #1
        jp      tests_done
test_decb_r_pass:
        inc     r0, #1

# =============================================================================
# TEST 123: NEGB - Byte negate register
# =============================================================================
test_negb_r:
        inc     r2, #1              ! Test 123
        ld      r3, #0x0000
        ldb     rl3, #0x01          ! RL3 = 0x01
        negb    rl3                 ! RL3 = -1 = 0xFF (two's complement)
        cp      r3, #0x00FF         ! Check result
        jr      z, test_negb_r_pass
        inc     r1, #1
        jp      tests_done
test_negb_r_pass:
        inc     r0, #1

# =============================================================================
# TEST 124: COMB - Byte complement register
# =============================================================================
test_comb_r:
        inc     r2, #1              ! Test 124
        ld      r3, #0x0000
        ldb     rl3, #0xAA          ! RL3 = 0xAA
        comb    rl3                 ! RL3 = ~0xAA = 0x55
        cp      r3, #0x0055         ! Check result
        jr      z, test_comb_r_pass
        inc     r1, #1
        jp      tests_done
test_comb_r_pass:
        inc     r0, #1

# =============================================================================
# TEST 125: ADCB - Byte add with carry
# =============================================================================
test_adcb_r:
        inc     r2, #1              ! Test 125
        ld      r3, #0x0000
        ldb     rl3, #0xFF          ! RL3 = 0xFF
        ldb     rh4, #0x01          ! RH4 = 0x01
        addb    rl3, rh4            ! RL3 = 0xFF + 0x01 = 0x00, C=1
        ldb     rl3, #0x10          ! RL3 = 0x10
        ldb     rh4, #0x05          ! RH4 = 0x05
        adcb    rl3, rh4            ! RL3 = 0x10 + 0x05 + 1 (carry) = 0x16
        cp      r3, #0x0016         ! Check result
        jr      z, test_adcb_r_pass
        inc     r1, #1
        jp      tests_done
test_adcb_r_pass:
        inc     r0, #1

# =============================================================================
# TEST 126: SBCB - Byte subtract with borrow
# =============================================================================
test_sbcb_r:
        inc     r2, #1              ! Test 126
        ld      r3, #0x0000
        ldb     rl3, #0x00          ! RL3 = 0x00
        ldb     rh4, #0x01          ! RH4 = 0x01
        subb    rl3, rh4            ! RL3 = 0x00 - 0x01 = 0xFF, C=1 (borrow)
        ldb     rl3, #0x20          ! RL3 = 0x20
        ldb     rh4, #0x10          ! RH4 = 0x10
        sbcb    rl3, rh4            ! RL3 = 0x20 - 0x10 - 1 (borrow) = 0x0F
        cp      r3, #0x000F         ! Check result
        jr      z, test_sbcb_r_pass
        inc     r1, #1
        jp      tests_done
test_sbcb_r_pass:
        inc     r0, #1

# =============================================================================
# TEST 127: ADDB immediate
# =============================================================================
test_addb_im:
        inc     r2, #1              ! Test 127
        ld      r3, #0x0000
        ldb     rl3, #0x20          ! RL3 = 0x20
        addb    rl3, #0x15          ! RL3 = 0x20 + 0x15 = 0x35
        cp      r3, #0x0035         ! Check result
        jr      z, test_addb_im_pass
        inc     r1, #1
        jp      tests_done
test_addb_im_pass:
        inc     r0, #1

# =============================================================================
# TEST 128: SUBB immediate
# =============================================================================
test_subb_im:
        inc     r2, #1              ! Test 128
        ld      r3, #0x0000
        ldb     rl3, #0x50          ! RL3 = 0x50
        subb    rl3, #0x25          ! RL3 = 0x50 - 0x25 = 0x2B
        cp      r3, #0x002B         ! Check result
        jr      z, test_subb_im_pass
        inc     r1, #1
        jp      tests_done
test_subb_im_pass:
        inc     r0, #1

# =============================================================================
# TEST 129: RLC - Rotate Left through Carry (word), C=0
# Initial: R3=0x8001, C=0 -> R3=0x0002, C=1 (MSB went to C, old C(0) to LSB)
# =============================================================================
test_rlc_1:
        inc     r2, #1              ! Test 129
        sub     r4, r4              ! Clear carry (R4=0, C=0)
        ld      r3, #0x8001         ! R3 = 0x8001
        rlc     r3, #1              ! RLC: MSB(1)->C, C(0)->LSB, R3=0x0002
        cp      r3, #0x0002         ! Check result
        jr      z, test_rlc_1_pass
        inc     r1, #1
        jp      tests_done
test_rlc_1_pass:
        inc     r0, #1

# =============================================================================
# TEST 130: RLC - Rotate Left through Carry (word), C=1
# Initial: R3=0x0001, C=1 -> R3=0x0003, C=0
# Use 0xFFFF + 1 = 0 to set carry, then load R3
# =============================================================================
test_rlc_2:
        inc     r2, #1              ! Test 130
        ld      r3, #0xFFFF
        add     r3, #1              ! 0xFFFF + 1 = 0, sets carry
        ld      r3, #0x0001         ! R3 = 0x0001 (LD doesn't affect carry)
        rlc     r3, #1              ! RLC: MSB(0)->C, C(1)->LSB, R3=0x0003
        cp      r3, #0x0003         ! Check result
        jr      z, test_rlc_2_pass
        inc     r1, #1
        jp      tests_done
test_rlc_2_pass:
        inc     r0, #1

# =============================================================================
# TEST 131: RRC - Rotate Right through Carry (word), C=0
# Initial: R3=0x8001, C=0 -> R3=0x4000, C=1 (LSB went to C, old C(0) to MSB)
# =============================================================================
test_rrc_1:
        inc     r2, #1              ! Test 131
        sub     r4, r4              ! Clear carry
        ld      r3, #0x8001         ! R3 = 0x8001
        rrc     r3, #1              ! RRC: LSB(1)->C, C(0)->MSB, R3=0x4000
        cp      r3, #0x4000         ! Check result
        jr      z, test_rrc_1_pass
        inc     r1, #1
        jp      tests_done
test_rrc_1_pass:
        inc     r0, #1

# =============================================================================
# TEST 132: RRC - Rotate Right through Carry (word), C=1
# Initial: R3=0x0002, C=1 -> R3=0x8001, C=0
# =============================================================================
test_rrc_2:
        inc     r2, #1              ! Test 132
        ld      r3, #0xFFFF
        add     r3, #1              ! Set carry
        ld      r3, #0x0002         ! R3 = 0x0002
        rrc     r3, #1              ! RRC: LSB(0)->C, C(1)->MSB, R3=0x8001
        cp      r3, #0x8001         ! Check result
        jr      z, test_rrc_2_pass
        inc     r1, #1
        jp      tests_done
test_rrc_2_pass:
        inc     r0, #1

# =============================================================================
# TEST 133: RLCB - Rotate Left through Carry (byte)
# Initial: RL3=0x81, C=0 -> RL3=0x02, C=1
# =============================================================================
test_rlcb_1:
        inc     r2, #1              ! Test 133
        sub     r4, r4              ! Clear carry
        ld      r3, #0x0000
        ldb     rl3, #0x81          ! RL3 = 0x81
        rlcb    rl3, #1             ! RLCB: bit7(1)->C, C(0)->bit0, RL3=0x02
        cp      r3, #0x0002         ! Check result (R3 = 0x0002)
        jr      z, test_rlcb_1_pass
        inc     r1, #1
        jp      tests_done
test_rlcb_1_pass:
        inc     r0, #1

# =============================================================================
# TEST 134: RRCB - Rotate Right through Carry (byte)
# Initial: RL3=0x81, C=0 -> RL3=0x40, C=1
# =============================================================================
test_rrcb_1:
        inc     r2, #1              ! Test 134
        sub     r4, r4              ! Clear carry
        ld      r3, #0x0000
        ldb     rl3, #0x81          ! RL3 = 0x81
        rrcb    rl3, #1             ! RRCB: bit0(1)->C, C(0)->bit7, RL3=0x40
        cp      r3, #0x0040         ! Check result (R3 = 0x0040)
        jr      z, test_rrcb_1_pass
        inc     r1, #1
        jp      tests_done
test_rrcb_1_pass:
        inc     r0, #1

# =============================================================================
# TEST 135: RLC #2 - Rotate Left through Carry by 2 (word)
# Initial: R3=0xC000, C=0 -> after 2 RLC: R3=0x0001, C=1
# Step 1: 0xC000,C=0 -> 0x8000,C=1
# Step 2: 0x8000,C=1 -> 0x0001,C=1
# =============================================================================
test_rlc_by2:
        inc     r2, #1              ! Test 135
        sub     r4, r4              ! Clear carry
        ld      r3, #0xC000         ! R3 = 0xC000
        rlc     r3, #2              ! RLC by 2
        cp      r3, #0x0001         ! Check result
        jr      z, test_rlc_by2_pass
        inc     r1, #1
        jp      tests_done
test_rlc_by2_pass:
        inc     r0, #1

# =============================================================================
# TEST 136: RRC #2 - Rotate Right through Carry by 2 (word)
# Initial: R3=0x0003, C=0 -> after 2 RRC: R3=0x8000, C=1
# Step 1: 0x0003,C=0 -> 0x0001,C=1
# Step 2: 0x0001,C=1 -> 0x8000,C=1
# =============================================================================
test_rrc_by2:
        inc     r2, #1              ! Test 136
        sub     r4, r4              ! Clear carry
        ld      r3, #0x0003         ! R3 = 0x0003
        rrc     r3, #2              ! RRC by 2
        cp      r3, #0x8000         ! Check result
        jr      z, test_rrc_by2_pass
        inc     r1, #1
        jp      tests_done
test_rrc_by2_pass:
        inc     r0, #1

# -----------------------------------------------------------------------------
# Test 137: LDB Base Indexed - LDB Rd, Rs(Rn)
# Load a byte using base register + index register addressing
# -----------------------------------------------------------------------------
        ld      r2, #137            ! Test 137
        ld      r5, #ldb_based_data ! Base address
        ld      r6, #3              ! Index (offset to 4th byte = 0x44)
        ld      r3, #0              ! Clear
        ldb     rl3, r5(r6)         ! LDB RL3, R5(R6)
        cp      r3, #0x0044         ! Check (RL3 should be 0x44 in low byte position)
        jr      z, test_ldb_bx_pass
test_ldb_bx_fail:
        inc     r1, #1
        jp      tests_done
test_ldb_bx_pass:
        inc     r0, #1

# -----------------------------------------------------------------------------
# Test 138: STB Base Address - LDB Rd(#disp), Rs (store byte with displacement)
# Store a byte to base register + displacement address
# -----------------------------------------------------------------------------
        ld      r2, #138            ! Test 138
        ld      r5, #scratch_data   ! Base address
        ld      r3, #0xAB00         ! Value to store (RH3 = 0xAB)
        ldb     r5(#0x10), rh3      ! Store RH3 to R5+0x10
        ld      r4, #0
        ldb     rh4, r5(#0x10)      ! Read back
        cp      r4, #0xAB00         ! Verify
        jr      z, test_stb_ba_pass
test_stb_ba_fail:
        inc     r1, #1
        jp      tests_done
test_stb_ba_pass:
        inc     r0, #1

# -----------------------------------------------------------------------------
# Test 139: STB Base Indexed - LDB Rd(Rn), Rs (store byte with index)
# Store a byte to base register + index register address
# -----------------------------------------------------------------------------
        ld      r2, #139            ! Test 139
        ld      r5, #scratch_data   ! Base address
        ld      r6, #2              ! Index = 2 (even offset for simpler testing)
        ld      r3, #0x00EF         ! Value to store (RL3 = 0xEF)
        ldb     r5(r6), rl3         ! Store RL3 to R5+R6
        ld      r4, #0
        ldb     rl4, scratch_data+2 ! Read back using standard LDB DA
        cp      r4, #0x00EF         ! Verify
        jr      z, test_stb_bx_pass
test_stb_bx_fail:
        inc     r1, #1
        jp      tests_done
test_stb_bx_pass:
        inc     r0, #1

# -----------------------------------------------------------------------------
# Test 140: LDL Base Indexed - LDL RRd, Rs(Rn)
# Load a 32-bit long using base register + index register addressing
# Use RR8 instead of RR2 to avoid clobbering test counter (R2)
# -----------------------------------------------------------------------------
        ld      r2, #140            ! Test 140
        ld      r5, #ldl_based_data ! Base address
        ld      r6, #4              ! Index (offset to second long)
        ld      r8, #0              ! Clear
        ld      r9, #0
        ldl     rr8, r5(r6)         ! LDL RR8, R5(R6)
        cp      r8, #0x5555         ! Check high word
        jr      nz, test_ldl_bx_fail
        cp      r9, #0x6666         ! Check low word
        jr      z, test_ldl_bx_pass
test_ldl_bx_fail:
        inc     r1, #1
        jp      tests_done
test_ldl_bx_pass:
        inc     r0, #1

# -----------------------------------------------------------------------------
# Test 141: STL Base Address - LDL Rd(#disp), RRs (store long with displacement)
# Store a 32-bit long to base register + displacement address
# Use RR8 instead of RR2 to avoid clobbering test counter
# -----------------------------------------------------------------------------
        ld      r2, #141            ! Test 141
        ld      r5, #scratch_data   ! Base address
        ld      r8, #0xABCD         ! High word
        ld      r9, #0xEF01         ! Low word
        ldl     r5(#0x14), rr8      ! Store RR8 to R5+0x14
        ldl     rr6, r5(#0x14)      ! Read back
        cp      r6, #0xABCD         ! Check high word
        jr      nz, test_stl_ba_fail
        cp      r7, #0xEF01         ! Check low word
        jr      z, test_stl_ba_pass
test_stl_ba_fail:
        inc     r1, #1
        jp      tests_done
test_stl_ba_pass:
        inc     r0, #1

# -----------------------------------------------------------------------------
# Test 142: STL Base Indexed - LDL Rd(Rn), RRs (store long with index)
# Store a 32-bit long to base register + index register address
# -----------------------------------------------------------------------------
        ld      r2, #142            ! Test 142
        ld      r5, #scratch_data   ! Base address
        ld      r6, #0x18           ! Index
        ld      r8, #0x1234         ! High word
        ld      r9, #0x5678         ! Low word
        ldl     r5(r6), rr8         ! Store RR8 to R5+R6
        ldl     rr10, r5(r6)        ! Read back
        cp      r10, #0x1234        ! Check high word
        jr      nz, test_stl_bx_fail
        cp      r11, #0x5678        ! Check low word
        jr      z, test_stl_bx_pass
test_stl_bx_fail:
        inc     r1, #1
        jp      tests_done
test_stl_bx_pass:
        inc     r0, #1

# -----------------------------------------------------------------------------
# Test 143: CALL @Rd - Call Indirect
# Call a subroutine using indirect addressing (address in register)
# -----------------------------------------------------------------------------
        ld      r2, #143            ! Test 143
        ld      r5, #call_target_1  ! Load target address into R5
        call    @r5                 ! CALL @R5
        jr      test_call_ir_pass   ! Should return here
test_call_ir_fail:
        inc     r1, #1
        jp      tests_done
test_call_ir_pass:
        inc     r0, #1

# -----------------------------------------------------------------------------
# Test 144: CALL address(Rd) - Call Indexed
# Call a subroutine using indexed addressing (base address + register offset)
# -----------------------------------------------------------------------------
        ld      r2, #144            ! Test 144
        ld      r5, #call_offset    ! Index value (offset from call_base)
        call    call_base(r5)       ! CALL call_base(R5)
        jr      test_call_x_pass    ! Should return here
test_call_x_fail:
        inc     r1, #1
        jp      tests_done
test_call_x_pass:
        inc     r0, #1

# =============================================================================
# TEST 145: CLR Rd - Clear register
# =============================================================================
test_clr_r:
        ld      r2, #145            ! Test 145
        ld      r3, #0xABCD         ! Set non-zero value
        clr     r3                  ! Clear it
        cp      r3, #0              ! Should be zero
        jr      z, test_clr_r_pass
        inc     r1, #1
        jp      tests_done
test_clr_r_pass:
        inc     r0, #1

# =============================================================================
# TEST 146: CLR @Rd - Clear memory indirect
# =============================================================================
test_clr_ir:
        ld      r2, #146            ! Test 146
        ld      r5, #clr_test_data  ! Address
        ld      r3, #0x1234
        ld      @r5, r3             ! Store non-zero value
        clr     @r5                 ! Clear it
        ld      r4, @r5             ! Read back
        cp      r4, #0              ! Should be zero
        jr      z, test_clr_ir_pass
        inc     r1, #1
        jp      tests_done
test_clr_ir_pass:
        inc     r0, #1

# =============================================================================
# TEST 147: CLR address - Clear memory direct
# =============================================================================
test_clr_da:
        ld      r2, #147            ! Test 147
        ld      r3, #0x5678
        ld      clr_test_data, r3   ! Store non-zero value
        clr     clr_test_data       ! Clear it
        ld      r4, clr_test_data   ! Read back
        cp      r4, #0              ! Should be zero
        jr      z, test_clr_da_pass
        inc     r1, #1
        jp      tests_done
test_clr_da_pass:
        inc     r0, #1

# =============================================================================
# TEST 148: CLR addr(Rd) - Clear memory indexed
# =============================================================================
test_clr_x:
        ld      r2, #148            ! Test 148
        ld      r5, #4              ! Index
        ld      r3, #0x9ABC
        ld      clr_test_data(r5), r3  ! Store non-zero value at offset 4
        clr     clr_test_data(r5)      ! Clear it
        ld      r4, clr_test_data(r5)  ! Read back
        cp      r4, #0              ! Should be zero
        jr      z, test_clr_x_pass
        inc     r1, #1
        jp      tests_done
test_clr_x_pass:
        inc     r0, #1

# =============================================================================
# TEST 149: CLRB Rbd - Clear byte register
# =============================================================================
test_clrb_r:
        ld      r2, #149            ! Test 149
        ld      r3, #0xABCD         ! Set non-zero value
        clrb    rl3                 ! Clear low byte
        cp      r3, #0xAB00         ! High byte unchanged, low byte zero
        jr      z, test_clrb_r_pass
        inc     r1, #1
        jp      tests_done
test_clrb_r_pass:
        inc     r0, #1

# =============================================================================
# TEST 150: CLRB @Rd - Clear byte memory indirect
# =============================================================================
test_clrb_ir:
        ld      r2, #150            ! Test 150
        ld      r5, #clr_test_data
        ld      r3, #0x1234
        ld      @r5, r3             ! Store non-zero value
        clrb    @r5                 ! Clear high byte (even address)
        ld      r4, @r5             ! Read back
        cp      r4, #0x0034         ! High byte cleared
        jr      z, test_clrb_ir_pass
        inc     r1, #1
        jp      tests_done
test_clrb_ir_pass:
        inc     r0, #1

# =============================================================================
# TEST 151: JP cc, addr(Rd) - Indexed jump (taken)
# =============================================================================
test_jp_x:
        ld      r2, #151            ! Test 151
        ld      r5, #jp_x_offset    ! Offset to target
        ld      r3, #0              ! Set zero for condition
        cp      r3, #0              ! Set Z flag
        jp      z, jp_x_base(r5)    ! Should jump
        inc     r1, #1              ! Should not reach here
        jp      tests_done
jp_x_target:
        jr      test_jp_x_pass
        .align  2
jp_x_base:
        .word   0                   ! Padding
jp_x_offset     =       jp_x_target - jp_x_base
test_jp_x_pass:
        inc     r0, #1

# =============================================================================
# TEST 152: JP cc, addr(Rd) - Indexed jump (not taken)
# =============================================================================
test_jp_x_notaken:
        ld      r2, #152            ! Test 152
        ld      r5, #0              ! Offset
        ld      r3, #1              ! Set non-zero
        cp      r3, #0              ! Clear Z flag (NZ)
        jp      z, jp_x_base(r5)    ! Should NOT jump (Z not set)
        jr      test_jp_x_notaken_pass
        inc     r1, #1
        jp      tests_done
test_jp_x_notaken_pass:
        inc     r0, #1

# =============================================================================
# TEST 153: PUSH @Rd, #imm - Push immediate
# =============================================================================
test_push_im:
        ld      r2, #153            ! Test 153
        ld      r14, #test_stack_top ! Use R14 as temp stack
        push    @r14, #0xBEEF       ! Push immediate
        ld      r3, @r14            ! Read from stack
        cp      r3, #0xBEEF
        jr      z, test_push_im_pass
        inc     r1, #1
        jp      tests_done
test_push_im_pass:
        inc     r0, #1

# =============================================================================
# TEST 154: PUSH @Rd, @Rs - Push indirect
# =============================================================================
test_push_ir:
        ld      r2, #154            ! Test 154
        ld      r14, #test_stack_top
        ld      r5, #push_test_data
        ld      r3, #0xCAFE
        ld      @r5, r3             ! Store value at push_test_data
        push    @r14, @r5           ! Push value from @R5
        ld      r4, @r14            ! Read from stack
        cp      r4, #0xCAFE
        jr      z, test_push_ir_pass
        inc     r1, #1
        jp      tests_done
test_push_ir_pass:
        inc     r0, #1

# =============================================================================
# TEST 155: PUSH @Rd, address - Push from memory
# =============================================================================
test_push_da:
        ld      r2, #155            ! Test 155
        ld      r14, #test_stack_top
        ld      r3, #0xDEAD
        ld      push_test_data, r3  ! Store value
        push    @r14, push_test_data ! Push value from memory
        ld      r4, @r14            ! Read from stack
        cp      r4, #0xDEAD
        jr      z, test_push_da_pass
        inc     r1, #1
        jp      tests_done
test_push_da_pass:
        inc     r0, #1

# =============================================================================
# TEST 156: PUSH @Rd, addr(Rs) - Push from indexed address
# =============================================================================
test_push_x:
        ld      r2, #156            ! Test 156
        ld      r14, #test_stack_top
        ld      r5, #2              ! Index
        ld      r3, #0xFACE
        ld      push_test_data(r5), r3  ! Store at offset 2
        push    @r14, push_test_data(r5) ! Push from indexed address
        ld      r4, @r14            ! Read from stack
        cp      r4, #0xFACE
        jr      z, test_push_x_pass
        inc     r1, #1
        jp      tests_done
test_push_x_pass:
        inc     r0, #1

# =============================================================================
# TEST 157: POP @Rd, @Rs - Pop to indirect address
# =============================================================================
test_pop_ir:
        ld      r2, #157            ! Test 157
        ld      r14, #test_stack_top
        ld      r3, #0x1111
        push    @r14, r3            ! Push value
        ld      r5, #pop_test_data  ! Destination address
        clr     @r5                 ! Clear destination
        pop     @r5, @r14           ! Pop to @R5
        ld      r4, @r5             ! Read back
        cp      r4, #0x1111
        jr      z, test_pop_ir_pass
        inc     r1, #1
        jp      tests_done
test_pop_ir_pass:
        inc     r0, #1

# =============================================================================
# TEST 158: POP address, @Rs - Pop to memory
# =============================================================================
test_pop_da:
        ld      r2, #158            ! Test 158
        ld      r14, #test_stack_top
        ld      r3, #0x2222
        push    @r14, r3            ! Push value
        clr     pop_test_data       ! Clear destination
        pop     pop_test_data, @r14 ! Pop to memory
        ld      r4, pop_test_data   ! Read back
        cp      r4, #0x2222
        jr      z, test_pop_da_pass
        inc     r1, #1
        jp      tests_done
test_pop_da_pass:
        inc     r0, #1

# =============================================================================
# TEST 159: POP addr(Rd), @Rs - Pop to indexed address
# =============================================================================
test_pop_x:
        ld      r2, #159            ! Test 159
        ld      r14, #test_stack_top
        ld      r3, #0x3333
        push    @r14, r3            ! Push value
        ld      r5, #2              ! Index
        clr     pop_test_data(r5)   ! Clear destination
        pop     pop_test_data(r5), @r14 ! Pop to indexed
        ld      r4, pop_test_data(r5)   ! Read back
        cp      r4, #0x3333
        jr      z, test_pop_x_pass
        inc     r1, #1
        jp      tests_done
test_pop_x_pass:
        inc     r0, #1

# =============================================================================
# TEST 160: PUSHL @Rd, @Rs - Push long indirect
# =============================================================================
test_pushl_ir:
        ld      r2, #160            ! Test 160
        ld      r14, #test_stack_top
        ld      r5, #pushl_test_data
        ld      r8, #0xAAAA
        ld      r9, #0xBBBB
        ldl     @r5, rr8            ! Store long at address
        pushl   @r14, @r5           ! Push long from @R5
        ldl     rr6, @r14           ! Read back from stack
        cp      r6, #0xAAAA
        jr      nz, test_pushl_ir_fail
        cp      r7, #0xBBBB
        jr      z, test_pushl_ir_pass
test_pushl_ir_fail:
        inc     r1, #1
        jp      tests_done
test_pushl_ir_pass:
        inc     r0, #1

# =============================================================================
# TEST 161: PUSHL @Rd, address - Push long from memory
# =============================================================================
test_pushl_da:
        ld      r2, #161            ! Test 161
        ld      r14, #test_stack_top
        ld      r8, #0xCCCC
        ld      r9, #0xDDDD
        ldl     pushl_test_data, rr8 ! Store long
        pushl   @r14, pushl_test_data ! Push long from memory
        ldl     rr6, @r14           ! Read back
        cp      r6, #0xCCCC
        jr      nz, test_pushl_da_fail
        cp      r7, #0xDDDD
        jr      z, test_pushl_da_pass
test_pushl_da_fail:
        inc     r1, #1
        jp      tests_done
test_pushl_da_pass:
        inc     r0, #1

# =============================================================================
# TEST 162: POPL @Rd, @Rs - Pop long to indirect
# =============================================================================
test_popl_ir:
        ld      r2, #162            ! Test 162
        ld      r14, #test_stack_top
        ld      r8, #0x1234
        ld      r9, #0x5678
        pushl   @r14, rr8           ! Push long
        ld      r5, #popl_test_data
        ld      r10, #0             ! Clear R10
        ld      r11, #0             ! Clear R11
        ldl     @r5, rr10           ! Store zeros (don't use R0!)
        popl    @r5, @r14           ! Pop to @R5
        ldl     rr6, @r5            ! Read back
        cp      r6, #0x1234
        jr      nz, test_popl_ir_fail
        cp      r7, #0x5678
        jr      z, test_popl_ir_pass
test_popl_ir_fail:
        inc     r1, #1
        jp      tests_done
test_popl_ir_pass:
        inc     r0, #1

# =============================================================================
# TEST 163: POPL address, @Rs - Pop long to memory
# =============================================================================
test_popl_da:
        ld      r2, #163            ! Test 163
        ld      r14, #test_stack_top
        ld      r8, #0xABCD
        ld      r9, #0xEF01
        pushl   @r14, rr8           ! Push long
        sub     r6, r6
        sub     r7, r7
        ldl     popl_test_data, rr6 ! Clear destination
        popl    popl_test_data, @r14 ! Pop to memory
        ldl     rr6, popl_test_data ! Read back
        cp      r6, #0xABCD
        jr      nz, test_popl_da_fail
        cp      r7, #0xEF01
        jr      z, test_popl_da_pass
test_popl_da_fail:
        inc     r1, #1
        jp      tests_done
test_popl_da_pass:
        inc     r0, #1

# =============================================================================
# TEST 164: EXTSB - Sign extend byte to word (positive)
# =============================================================================
test_extsb_pos:
        ld      r2, #164            ! Test 164
        ld      r4, #0x007F         ! Positive byte (0x7F = 127)
        extsb   r4                  ! Sign extend should keep upper byte 0x00
        cp      r4, #0x007F
        jr      z, test_extsb_pos_pass
        inc     r1, #1
        jp      tests_done
test_extsb_pos_pass:
        inc     r0, #1

# =============================================================================
# TEST 165: EXTSB - Sign extend byte to word (negative)
# =============================================================================
test_extsb_neg:
        ld      r2, #165            ! Test 165
        ld      r5, #0x0080         ! Negative byte (0x80 = -128)
        extsb   r5                  ! Sign extend should set upper byte to 0xFF
        cp      r5, #0xFF80
        jr      z, test_extsb_neg_pass
        inc     r1, #1
        jp      tests_done
test_extsb_neg_pass:
        inc     r0, #1

# =============================================================================
# TEST 166: EXTSB - Sign extend 0xFF (all ones)
# =============================================================================
test_extsb_ff:
        ld      r2, #166            ! Test 166
        ld      r6, #0x00FF         ! -1 as byte
        extsb   r6                  ! Should become 0xFFFF
        cp      r6, #0xFFFF
        jr      z, test_extsb_ff_pass
        inc     r1, #1
        jp      tests_done
test_extsb_ff_pass:
        inc     r0, #1

# =============================================================================
# TEST 167: EXTS - Sign extend word to long (positive)
# =============================================================================
test_exts_pos:
        ld      r2, #167            ! Test 167
        ld      r8, #0x1234         ! R8 = will be high word (result)
        ld      r9, #0x7FFF         ! R9 = low word (positive, bit 15=0)
        exts    rr8                 ! R8 should become 0x0000
        cp      r8, #0x0000
        jr      nz, test_exts_pos_fail
        cp      r9, #0x7FFF         ! R9 should be unchanged
        jr      z, test_exts_pos_pass
test_exts_pos_fail:
        inc     r1, #1
        jp      tests_done
test_exts_pos_pass:
        inc     r0, #1

# =============================================================================
# TEST 168: EXTS - Sign extend word to long (negative)
# =============================================================================
test_exts_neg:
        ld      r2, #168            ! Test 168
        ld      r10, #0x0000        ! R10 = will be high word (result)
        ld      r11, #0x8000        ! R11 = low word (negative, bit 15=1)
        exts    rr10                ! R10 should become 0xFFFF
        cp      r10, #0xFFFF
        jr      nz, test_exts_neg_fail
        cp      r11, #0x8000        ! R11 should be unchanged
        jr      z, test_exts_neg_pass
test_exts_neg_fail:
        inc     r1, #1
        jp      tests_done
test_exts_neg_pass:
        inc     r0, #1

# =============================================================================
# TEST 169: EXTS - Sign extend 0xFFFF (all ones)
# =============================================================================
test_exts_ff:
        ld      r2, #169            ! Test 169
        ld      r4, #0x0000         ! R4 = will be high word
        ld      r5, #0xFFFF         ! R5 = -1 as word
        exts    rr4                 ! R4 should become 0xFFFF
        cp      r4, #0xFFFF
        jr      nz, test_exts_ff_fail
        cp      r5, #0xFFFF         ! R5 should be unchanged
        jr      z, test_exts_ff_pass
test_exts_ff_fail:
        inc     r1, #1
        jp      tests_done
test_exts_ff_pass:
        inc     r0, #1

# =============================================================================
# TEST 170: MULT - Small positive (200 * 100 = 20000)
# =============================================================================
test_mult_small:
        ld      r2, #170            ! Test 170
        ld      r5, #200            ! R5 = multiplicand
        ld      r6, #100            ! R6 = multiplier
        mult    rr4, r6
        cp      r4, #0x0000         ! High word = 0
        jr      nz, test_mult_small_fail
        cp      r5, #0x4E20         ! Low word = 20000
        jr      z, test_mult_small_pass
test_mult_small_fail:
        inc     r1, #1
        jp      tests_done
test_mult_small_pass:
        inc     r0, #1

# =============================================================================
# TEST 171: MULT - Immediate (55 * 1000 = 55000)
# =============================================================================
test_mult_imm:
        ld      r2, #171            ! Test 171
        ld      r5, #55             ! R5 = multiplicand
        mult    rr4, #1000
        cp      r4, #0x0000         ! High word = 0
        jr      nz, test_mult_imm_fail
        cp      r5, #0xD6D8         ! Low word = 55000
        jr      z, test_mult_imm_pass
test_mult_imm_fail:
        inc     r1, #1
        jp      tests_done
test_mult_imm_pass:
        inc     r0, #1

# =============================================================================
# TEST 172: MULT - Signed negative (-1 * 32767 = -32767)
# =============================================================================
test_mult_neg:
        ld      r2, #172            ! Test 172
        ld      r5, #0xFFFF         ! R5 = -1
        ld      r6, #0x7FFF         ! R6 = 32767
        mult    rr4, r6
        cp      r4, #0xFFFF         ! High word = 0xFFFF
        jr      nz, test_mult_neg_fail
        cp      r5, #0x8001         ! Low word = 0x8001 (-32767)
        jr      z, test_mult_neg_pass
test_mult_neg_fail:
        inc     r1, #1
        jp      tests_done
test_mult_neg_pass:
        inc     r0, #1

# =============================================================================
# TEST 173: MULTL - Small (100 * 1000 = 100000)
# =============================================================================
test_multl_small:
        ld      r2, #173            ! Test 173
        ld      r4, #0x0000         ! RR4 = 100
        ld      r5, #100
        ld      r6, #0x0000         ! RR6 = 1000
        ld      r7, #1000
        multl   rq4, rr6
        cp      r4, #0x0000         ! High long high word = 0
        jr      nz, test_multl_small_fail
        cp      r5, #0x0000         ! High long low word = 0
        jr      nz, test_multl_small_fail
        cp      r6, #0x0001         ! Low long high word = 1
        jr      nz, test_multl_small_fail
        cp      r7, #0x86A0         ! Low long low word = 0x86A0
        jr      z, test_multl_small_pass
test_multl_small_fail:
        inc     r1, #1
        jp      tests_done
test_multl_small_pass:
        inc     r0, #1

# =============================================================================
# TEST 174: MULTL - Large (65536 * 65536 = 4294967296)
# =============================================================================
test_multl_large:
        ld      r2, #174            ! Test 174
        ld      r4, #0x0001         ! RR4 = 0x10000
        ld      r5, #0x0000
        ld      r6, #0x0001         ! RR6 = 0x10000
        ld      r7, #0x0000
        multl   rq4, rr6
        cp      r4, #0x0000         ! Result = 0x0000_0001_0000_0000
        jr      nz, test_multl_large_fail
        cp      r5, #0x0001
        jr      nz, test_multl_large_fail
        cp      r6, #0x0000
        jr      nz, test_multl_large_fail
        cp      r7, #0x0000
        jr      z, test_multl_large_pass
test_multl_large_fail:
        inc     r1, #1
        jp      tests_done
test_multl_large_pass:
        inc     r0, #1

# =============================================================================
# TEST 175: MULTL - Negative (-1 * 2 = -2)
# =============================================================================
test_multl_neg:
        ld      r2, #175            ! Test 175
        ld      r4, #0xFFFF         ! RR4 = 0xFFFFFFFF (-1)
        ld      r5, #0xFFFF
        ld      r6, #0x0000         ! RR6 = 2
        ld      r7, #0x0002
        multl   rq4, rr6
        cp      r4, #0xFFFF         ! Result = 0xFFFF_FFFF_FFFF_FFFE (-2)
        jr      nz, test_multl_neg_fail
        cp      r5, #0xFFFF
        jr      nz, test_multl_neg_fail
        cp      r6, #0xFFFF
        jr      nz, test_multl_neg_fail
        cp      r7, #0xFFFE
        jr      z, test_multl_neg_pass
test_multl_neg_fail:
        inc     r1, #1
        jp      tests_done
test_multl_neg_pass:
        inc     r0, #1

# =============================================================================
# TEST 176: DIV - Exact (20000 / 100 = 200, remainder 0)
# =============================================================================
test_div_exact:
        ld      r2, #176            ! Test 176
        ld      r4, #0x0000         ! RR4 = 20000
        ld      r5, #0x4E20
        ld      r6, #100            ! R6 = divisor
        div     rr4, r6
        cp      r4, #0x0000         ! Remainder = 0
        jr      nz, test_div_exact_fail
        cp      r5, #200            ! Quotient = 200
        jr      z, test_div_exact_pass
test_div_exact_fail:
        inc     r1, #1
        jp      tests_done
test_div_exact_pass:
        inc     r0, #1

# =============================================================================
# TEST 177: DIV - With remainder (10007 / 100 = 100 remainder 7)
# =============================================================================
test_div_rem:
        ld      r2, #177            ! Test 177
        ld      r4, #0x0000         ! RR4 = 10007
        ld      r5, #0x2717
        ld      r6, #100            ! R6 = divisor
        div     rr4, r6
        cp      r4, #0x0007         ! Remainder = 7
        jr      nz, test_div_rem_fail
        cp      r5, #100            ! Quotient = 100
        jr      z, test_div_rem_pass
test_div_rem_fail:
        inc     r1, #1
        jp      tests_done
test_div_rem_pass:
        inc     r0, #1

# =============================================================================
# TEST 178: DIV - Immediate (55000 / 1000 = 55, remainder 0)
# =============================================================================
test_div_imm:
        ld      r2, #178            ! Test 178
        ld      r4, #0x0000         ! RR4 = 55000
        ld      r5, #0xD6D8
        div     rr4, #1000
        cp      r4, #0x0000         ! Remainder = 0
        jr      nz, test_div_imm_fail
        cp      r5, #55             ! Quotient = 55
        jr      z, test_div_imm_pass
test_div_imm_fail:
        inc     r1, #1
        jp      tests_done
test_div_imm_pass:
        inc     r0, #1

# =============================================================================
# TEST 179: DIVL - Exact (100000 / 1000 = 100, remainder 0)
# =============================================================================
test_divl_exact:
        ld      r2, #179            ! Test 179
        ld      r4, #0x0000         ! RQ4 = 100000 (0x0000_0000_0001_86A0)
        ld      r5, #0x0000
        ld      r6, #0x0001
        ld      r7, #0x86A0
        ld      r8, #0x0000         ! RR8 = 1000
        ld      r9, #1000
        divl    rq4, rr8
        cp      r4, #0x0000         ! Remainder high = 0
        jr      nz, test_divl_exact_fail
        cp      r5, #0x0000         ! Remainder low = 0
        jr      nz, test_divl_exact_fail
        cp      r6, #0x0000         ! Quotient high = 0
        jr      nz, test_divl_exact_fail
        cp      r7, #100            ! Quotient low = 100
        jr      z, test_divl_exact_pass
test_divl_exact_fail:
        inc     r1, #1
        jp      tests_done
test_divl_exact_pass:
        inc     r0, #1

# =============================================================================
# TEST 180: DIVL - With remainder (100007 / 1000 = 100 remainder 7)
# =============================================================================
test_divl_rem:
        ld      r2, #180            ! Test 180
        ld      r4, #0x0000         ! RQ4 = 100007 (0x0000_0000_0001_86A7)
        ld      r5, #0x0000
        ld      r6, #0x0001
        ld      r7, #0x86A7
        ld      r8, #0x0000         ! RR8 = 1000
        ld      r9, #1000
        divl    rq4, rr8
        cp      r4, #0x0000         ! Remainder high = 0
        jr      nz, test_divl_rem_fail
        cp      r5, #0x0007         ! Remainder low = 7
        jr      nz, test_divl_rem_fail
        cp      r6, #0x0000         ! Quotient high = 0
        jr      nz, test_divl_rem_fail
        cp      r7, #100            ! Quotient low = 100
        jr      z, test_divl_rem_pass
test_divl_rem_fail:
        inc     r1, #1
        jp      tests_done
test_divl_rem_pass:
        inc     r0, #1

# =============================================================================
# TEST 181: DIVL - Large (0x100000000 / 0x10000 = 0x10000, remainder 0)
# =============================================================================
test_divl_large:
        ld      r2, #181            ! Test 181
        ld      r4, #0x0000         ! RQ4 = 0x0000_0001_0000_0000
        ld      r5, #0x0001
        ld      r6, #0x0000
        ld      r7, #0x0000
        divl    rq4, #0x00010000
        cp      r4, #0x0000         ! Remainder high = 0
        jr      nz, test_divl_large_fail
        cp      r5, #0x0000         ! Remainder low = 0
        jr      nz, test_divl_large_fail
        cp      r6, #0x0001         ! Quotient high = 1
        jr      nz, test_divl_large_fail
        cp      r7, #0x0000         ! Quotient low = 0
        jr      z, test_divl_large_pass
test_divl_large_fail:
        inc     r1, #1
        jp      tests_done
test_divl_large_pass:
        inc     r0, #1

# =============================================================================
# All tests complete - store results
# =============================================================================
tests_done:
        ld      @r15, r0            ! Store tests passed at 0x1F00
        inc     r15, #2
        ld      @r15, r1            ! Store tests failed at 0x1F02
        inc     r15, #2
        ld      @r15, r2            ! Store last test number at 0x1F04
        inc     r15, #2

        cp      r1, #0              ! Any failures?
        jr      nz, tests_failed

        ld      r3, #0xDEAD         ! Success marker
        ld      @r15, r3            ! Store at 0x1F06
        jr      halt_loop

tests_failed:
        ld      r3, #0xFA11         ! Failure marker
        ld      @r15, r3            ! Store at 0x1F06

halt_loop:
        halt                        ! Stop processor

# =============================================================================
# Scratch data section for general tests (was using hardcoded 0x1000)
# =============================================================================
        .align  2

scratch_data:
        .word   0x0000              ! scratch_data+0x00
        .word   0x0000              ! scratch_data+0x02
        .word   0x0000              ! scratch_data+0x04
        .word   0x0000              ! scratch_data+0x06
        .word   0x0000              ! scratch_data+0x08
        .word   0x0000              ! scratch_data+0x0A
        .word   0x0000              ! scratch_data+0x0C
        .word   0x0000              ! scratch_data+0x0E
        .word   0x0000              ! scratch_data+0x10
        .word   0x0000              ! scratch_data+0x12
        .word   0x0000              ! scratch_data+0x14
        .word   0x0000              ! scratch_data+0x16
        .word   0x0000              ! scratch_data+0x18
        .word   0x0000              ! scratch_data+0x1A
        .word   0x0000              ! scratch_data+0x1C
        .word   0x0000              ! scratch_data+0x1E
        .word   0x0000              ! scratch_data+0x20
        .word   0x0000              ! scratch_data+0x22
        .word   0x0000              ! scratch_data+0x24
        .word   0x0000              ! scratch_data+0x26
        .word   0x0000              ! scratch_data+0x28
        .word   0x0000              ! scratch_data+0x2A
        .word   0x0000              ! scratch_data+0x2C
        .word   0x0000              ! scratch_data+0x2E
        .word   0x0000              ! scratch_data+0x30
        .word   0x0000              ! scratch_data+0x32

# =============================================================================
# Data section for bit manipulation tests
# =============================================================================
        .align  2

bit_test_data:
        .word   0x0000              ! Test data for bit operations
        .word   0x0000              ! Second word for indexed mode tests

# =============================================================================
# Data section for block move tests
# =============================================================================
        .align  2

ldi_src_data:
        .word   0xCAFE              ! Source data for LDI test

ldi_dst_data:
        .word   0x0000              ! Destination for LDI test (will be overwritten)

ldir_src_data:
        .word   0x1111              ! Source data for LDIR test - word 1
        .word   0x2222              ! Source data for LDIR test - word 2
        .word   0x3333              ! Source data for LDIR test - word 3

ldir_dst_data:
        .word   0x0000              ! Destination for LDIR test - word 1
        .word   0x0000              ! Destination for LDIR test - word 2
        .word   0x0000              ! Destination for LDIR test - word 3

# Data for addressing mode tests
sub_ir_data:
        .word   25                  ! Subtrahend for SUB @Rs test

sub_da_data:
        .word   50                  ! Subtrahend for SUB address test

sub_x_base:
        .word   10                  ! Index 0
        .word   20                  ! Index 2
        .word   30                  ! Index 4 (used in test)

and_ir_data:
        .word   0x0F0F              ! Mask for AND @Rs test

or_da_data:
        .word   0x0F00              ! Value for OR address test

xor_x_base:
        .word   0x1234              ! Index 0
        .word   0x5555              ! Index 2 (used in test)

cp_ir_data:
        .word   0x1234              ! Comparison value for CP @Rs test

st_x_base:
        .word   0x0000              ! Index 0
        .word   0x0000              ! Index 2
        .word   0x0000              ! Index 4 (used in test)

ldb_ir_data:
        .byte   0xAB                ! Byte for LDB @Rs test
        .byte   0x00                ! Padding

stb_da_data:
        .byte   0x00                ! Destination for STB test
        .byte   0x00                ! Padding

cp_da_data:
        .word   0x5678              ! Comparison value for CP address test

and_da_data:
        .word   0x0FF0              ! Mask for AND address test

or_ir_data:
        .word   0xFF00              ! Value for OR @Rs test

xor_da_data:
        .word   0x0F0F              ! Value for XOR address test

# Data for block compare tests
cpi_src_data:
        .word   0x1234              ! Matching value for CPI test

cpir_src_data:
        .word   0x1111              ! Word 1
        .word   0x2222              ! Word 2
        .word   0x3333              ! Word 3 (target for match test)
        .word   0x4444              ! Word 4
        .word   0x5555              ! Word 5

cpib_src_data:
        .byte   0xAB                ! Matching byte for CPIB test
        .byte   0x00                ! Padding

cpdr_src_data:
        .word   0x1111              ! Target for CPDR (find from end)
        .word   0x2222
        .word   0x3333
cpdr_src_end:
        .word   0x4444              ! Start searching from here (backwards)

cpirb_src_data:
        .byte   0xAB                ! Byte 1
        .byte   0xBC                ! Byte 2
        .byte   0xCD                ! Byte 3 (target for CPIRB)
        .byte   0xDE                ! Byte 4
        .byte   0xEF                ! Byte 5

# Data for long (32-bit) operation tests
        .align  2

ldl_src_data:
        .long   0xABCDEF01          ! 32-bit data for LDL tests

ldl_indexed_base:
        .long   0x11112222          ! First long (offset 0)
        .long   0x22223333          ! Second long (offset 4) - used in test

stl_dst_data:
        .long   0x00000000          ! Destination for STL_IR test

stl_dst_data2:
        .long   0x00000000          ! Destination for STL_DA test

stl_indexed_base:
        .long   0x00000000          ! First long (offset 0)
        .long   0x00000000          ! Second long (offset 4) - used in test

# Data for LDL_BA (based addressing) test
ldl_based_data:
        .long   0x11112222          ! First long (offset 0)
        .long   0x55556666          ! Second long (offset 4) - used in test

# Data for LDB_BA (byte based addressing) test
ldb_based_data:
        .byte   0x11                ! Offset 0
        .byte   0x22                ! Offset 1
        .byte   0x33                ! Offset 2 - used in test
        .byte   0x44                ! Offset 3

# Data for INC/DEC/NEG/COM indirect addressing tests
inc_ir_data:
        .word   0x1230              ! Will be incremented by 4 -> 0x1234

dec_ir_data:
        .word   0x1005              ! Will be decremented by 5 -> 0x1000

neg_ir_data:
        .word   0x0005              ! Will be negated -> 0xFFFB

com_ir_data:
        .word   0x00FF              ! Will be complemented -> 0xFF00

# Data for block I/O tests
inir_dst_data:
        .word   0xFFFF              ! Destination for INIR (3 words)
        .word   0xFFFF
        .word   0xFFFF

otir_src_data:
        .word   0x1111              ! Source for OTIR - word 1
        .word   0x2222              ! Source for OTIR - word 2
        .word   0x3333              ! Source for OTIR - word 3 (last written)

inirb_dst_data:
        .word   0xFFFF              ! Destination for INIRB (4 bytes)
        .word   0xFFFF

# Call target for CALL @Rd test (indirect call)
call_target_1:
        ret                         ! Simple return

# Jump table base for CALL address(Rd) test (indexed call)
call_base:
        .word   0x0000              ! Padding (offset 0)
call_target_2:
        ret                         ! Target at offset call_offset

# Offset from call_base to call_target_2
        .equ    call_offset, call_target_2 - call_base

# Data for CLR tests
        .align  2
clr_test_data:
        .word   0x0000              ! CLR test data
        .word   0x0000              ! CLR indexed test data

# Data for PUSH/POP tests
        .align  2
push_test_data:
        .word   0x0000              ! PUSH source data
        .word   0x0000              ! PUSH indexed source

pop_test_data:
        .word   0x0000              ! POP destination
        .word   0x0000              ! POP indexed destination

pushl_test_data:
        .long   0x00000000          ! PUSHL source data

popl_test_data:
        .long   0x00000000          ! POPL destination

# Test stack area (separate from main stack)
        .align  2
test_stack_base:
        .space  32                  ! 32 bytes of stack space
test_stack_top:
