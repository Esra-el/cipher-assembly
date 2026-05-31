.data
myplaintext: .string "MYSTR0NG_P4SSW0RD LAUREATO"
             .zero 185

sostK: .word 1
mychyper: .string "ABCDE"
blocKey: .string "OLE"
mychyper_buffer: .zero 200
visited: .zero 256

.text
#  global registers 
la s0, myplaintext       # s0 = pointer to current text 
li s1, 65                # A
li s2, 90                # Z
li s3, 122               # z
li s4, 97                # a
lw a2, sostK             # a2 = shift value K
li s5, 32                # space
la s6, mychyper          # s6 = pointer to cipher config string
li s11, 0                # s11 = counter for how many ciphers applied

main:
loop_mang:
    # Reload temp registers 
    li t1, 66            # B
    li t2, 67            # C
    li t3, 68            # D
    li t4, 65            # A
    li t5, 69            # E
    
    lb t0, 0(s6)         # Load next cipher character from mychyper
    beq t0, zero, end_all   
    
    # Save cipher char on stack
    addi sp, sp, -4
    sw t0, 0(sp)
    addi s11, s11, 1
    
 
    beq t0, t4, do_A     # A = 65
    beq t0, t1, do_B     # B = 66
    beq t0, t2, do_C     # C = 67
    beq t0, t3, do_D     # D = 68
    beq t0, t5, do_E     #'E = 69
    j next_char          # skip Unknown char

do_A:
    jal funzione_A
    j printing

do_B:
    jal funzione_B
    j printing

do_C:
    jal funzione_C
    # C writes to mychyper_buffer, must copy back to myplaintext
    jal copy_buffer
    j printing

do_D:
    jal funzione_D
    # D writes to mychyper_buffer, must copy back to myplaintext
    jal copy_buffer
    j printing

do_E:
    jal funzione_E
    j printing

printing:
    la a0, myplaintext
    li a7, 4
    ecall
    li a0, 10            # newline
    li a7, 11
    ecall

next_char:
    addi s6, s6, 1       # Move to next cipher char
    j loop_mang

end_all:
    j start_decryption   # jump yto decryption doesnt end it

start_decryption:
    beq s11, zero, finish_everything
    
    lw t0, 0(sp)             # Pop last cipher from stack
    addi sp, sp, 4
    addi s11, s11, -1
    
    li t1, 65                # A
    beq t0, t1, call_decA
    li t1, 66                # B
    beq t0, t1, call_decB
    li t1, 67                # C
    beq t0, t1, call_decC
    li t1, 68                # D
    beq t0, t1, call_decD
    li t1, 69                # E
    beq t0, t1, call_decE
    j start_decryption

call_decA:
    jal decA
    j print_dec_step

call_decB:
    jal decB
    j print_dec_step

call_decC:
    jal decC
    j print_dec_step

call_decD:
    jal funzione_D           # self-inverse
    jal copy_buffer
    j print_dec_step

call_decE:
    jal funzione_E           #self-inverse
    j print_dec_step

print_dec_step:
    la a0, myplaintext
    li a7, 4
    ecall
    li a0, 10
    li a7, 11
    ecall
    j start_decryption

finish_everything:
    li a7, 10
    ecall

# Copies mychyper_buffer back to myplaintext
copy_buffer:
    addi sp, sp, -4
    sw ra, 0(sp)
    la t0, mychyper_buffer
    la t1, myplaintext
copy_loop:
    lb t2, 0(t0)
    sb t2, 0(t1)
    beq t2, zero, copy_done
    addi t0, t0, 1
    addi t1, t1, 1
    j copy_loop
copy_done:
    lw ra, 0(sp)
    addi sp, sp, 4
    jr ra

funzione_A:
    addi sp, sp, -4
    sw ra, 0(sp)
    lw a2, sostK        # reload every time
    li t0, 0
A_loop:
    li t4, 26
    add t1, t0, s0
    lb t2, 0(t1)
    beq t2, zero, A_done
    blt t2, s1, A_next
    bgt t2, s3, A_next
    bgt t2, s2, A_check_low   # changed from A_lower to A_check_low
A_upper:
    sub t2, t2, s1
    add t2, t2, a2
    jal loop_mod26
    add t2, t2, s1
    j A_next
A_check_low:               
    blt t2, s4, A_next        #skip if < a (97)
A_lower:
    sub t2, t2, s4
    add t2, t2, a2
    jal loop_mod26
    add t2, t2, s4
A_next:
    sb t2, 0(t1)
    addi t0, t0, 1
    j A_loop
A_done:
    lw ra, 0(sp)
    addi sp, sp, 4
    jr ra

loop_mod26:
    bge t2, zero, check_high
    add t2, t2, t4
    j loop_mod26
    
check_high:
    blt t2, t4, done_mod26
    sub t2, t2, t4
    j check_high
    
done_mod26:
    jr ra

funzione_B:
    addi sp, sp, -8
    sw ra, 4(sp)
    sw s1, 0(sp)
    li t0, 0
    la s1, blocKey
    li t3, 0
B_loop:
    li t6, 96
    add t2, t3, s1
    lb t4, 0(t2)
    beq t4, zero, B_reset
    add t1, t0, s0
    lb t2, 0(t1)
    beq t2, zero, B_done
    add t5, t2, t4
    jal loop_mod96
    add t5, t5, s5
    sb t5, 0(t1)
    addi t0, t0, 1
    addi t3, t3, 1
    j B_loop
B_reset:
    li t3, 0
    j B_loop
B_done:
    lw ra, 4(sp)
    lw s1, 0(sp)
    addi sp, sp, 8
    jr ra

loop_mod96:
    blt t5, t6, done_mod96
    sub t5, t5, t6
    j loop_mod96
done_mod96:
    add t5, zero, t5
    jr ra


funzione_C:
    addi sp, sp, -4
    sw ra, 0(sp)
    
    la t0, visited
    li t1, 0
    li t2, 256
C_clear:
    bge t1, t2, C_clear_done
    add t3, t0, t1
    sb zero, 0(t3)
    addi t1, t1, 1
    j C_clear
C_clear_done:
    la a1, mychyper_buffer
    li t3, 0              # outer index 
    li t0, 0              # inner index 
    li s7, 0              # printable postions counter 
C_outer:
    add t1, t3, s0
    lb t4, 0(t1)
    beq t4, zero, C_done
    
    # Skip non-printable
    li t6, 32
    blt t4, t6, C_skip_outer
    li t6, 126
    bgt t4, t6, C_skip_outer
    
    la t2, visited
    add t2, t2, t4
    lb t5, 0(t2)
    bne t5, zero, C_skip_outer
    li t5, 1
    sb t5, 0(t2)
    sb t4, 0(a1)
    addi a1, a1, 1
    
    li t0, 0
    li s7, 0              # reset printable counter for inner loop
C_inner:
    add t1, t0, s0
    lb t2, 0(t1)
    beq t2, zero, C_next_char
    
    # Count printable chars for position
    li t6, 32
    blt t2, t6, C_inner_next_no_count
    li t6, 126
    bgt t2, t6, C_inner_next_no_count
    addi s7, s7, 1        # increase printable position
C_inner_next_no_count:
    bne t2, t4, C_inner_next
    li t5, 45
    sb t5, 0(a1)
    addi a1, a1, 1
    
    add a0, s7, zero          # a0 = printable position (1-indexed)
    li t6, 9
    bgt a0, t6, C_two_digits
    addi a0, a0, 48
    sb a0, 0(a1)
    addi a1, a1, 1
    j C_inner_next
C_two_digits:
    li t2, 0
    li t5, 10
C_count_tens:
    blt a0, t5, C_write_digits
    sub a0, a0, t5
    addi t2, t2, 1
    j C_count_tens
C_write_digits:
    addi t2, t2, 48
    sb t2, 0(a1)
    addi a1, a1, 1
    addi a0, a0, 48
    sb a0, 0(a1)
    addi a1, a1, 1
C_inner_next:
    addi t0, t0, 1
    j C_inner
C_next_char:
    addi t6, t3, 1
    add t1, t6, s0
    lb t2, 0(t1)
    beq t2, zero, C_no_space
    li t5, 32
    sb t5, 0(a1)
    addi a1, a1, 1
C_no_space:
    addi t3, t3, 1
    j C_outer
C_skip_outer:
    addi t3, t3, 1
    j C_outer
C_done:
    sb zero, 0(a1)
    lw ra, 0(sp)
    addi sp, sp, 4
    jr ra


funzione_D:
    addi sp, sp, -4
    sw ra, 0(sp)
    li t0, 0
    la a1, mychyper_buffer
    li t3, 48
    li t4, 57
D_loop:
    add t1, t0, s0
    lb t2, 0(t1)
    beq t2, zero, D_done
    li t1, 187
    blt t2, s4, D_check_upper
    bgt t2, s3, D_check_upper
    sub t2, t1, t2
    j D_store
D_check_upper:
    blt t2, s1, D_check_digit
    bgt t2, s2, D_check_digit
    sub t2, t1, t2
    j D_store
D_check_digit:
    blt t2, t3, D_store
    bgt t2, t4, D_store
    li t1, 105
    sub t2, t1, t2
D_store:
    sb t2, 0(a1)
    addi a1, a1, 1
    addi t0, t0, 1
    j D_loop
D_done:
    sb zero, 0(a1)
    lw ra, 0(sp)
    addi sp, sp, 4
    jr ra

funzione_E:
    addi sp, sp, -4
    sw ra, 0(sp)
    # Find end of string
    add t0, s0, zero    # t0 = left pointer
    add t1, s0, zero    # t1 = right pointer 
E_find_end:
    lb t2, 0(t1)
    beq t2, zero, E_found
    addi t1, t1, 1
    j E_find_end
E_found:
    addi t1, t1, -1     # t1 now points to last character
    
    # Swap characters from outside inward
E_swap:
    bge t0, t1, E_done  
    lb t2, 0(t0)        # Ld left char
    lb t3, 0(t1)        # Ld right char
    sb t3, 0(t0)        # St right at left
    sb t2, 0(t1)        # St left at right
    addi t0, t0, 1      # Move left right
    addi t1, t1, -1     # Move right left
    j E_swap
E_done:
    lw ra, 0(sp)
    addi sp, sp, 4
    jr ra
   
decA:
    addi sp, sp, -4
    sw ra, 0(sp)
    lw a2, sostK        # reloading K every time
    li t0, 0

decA_loop:
    add t1, t0, s0
    lb t2, 0(t1)
    beq t2, zero, decA_done
    blt t2, s1, decA_next       # skip if < A 
    bgt t2, s3, decA_next       # skip if > z
    bgt t2, s2, decA_check_low  # if > Z check lowercase range

decA_upper:
    sub t2, t2, s1              # offset from A
    sub t2, t2, a2              # subtract K
    jal decA_mod26
    add t2, t2, s1              # add back A
    j decA_store

decA_check_low:
    blt t2, s4, decA_next       # skip chars between Z and a

decA_lower:
    sub t2, t2, s4          
    sub t2, t2, a2           
    jal decA_mod26
    add t2, t2, s4         

decA_store:
    sb t2, 0(t1)

decA_next:
    addi t0, t0, 1
    j decA_loop

decA_mod26:
    li t4, 26
decA_mod26_loop:
    blt t2, zero, decA_mod26_add
    blt t2, t4, decA_mod26_done
    sub t2, t2, t4
    j decA_mod26_loop
decA_mod26_add:
    add t2, t2, t4
    j decA_mod26_loop
decA_mod26_done:
    jr ra

decA_done:
    lw ra, 0(sp)
    addi sp, sp, 4
    jr ra
    

decB:
    addi sp, sp, -8
    sw ra, 4(sp)
    sw s1, 0(sp)
    li t0, 0
    la s1, blocKey
    li t3, 0

decB_loop:
    add t2, t3, s1
    lb t4, 0(t2)
    beq t4, zero, decB_reset
    add t1, t0, s0
    lb t2, 0(t1)
    beq t2, zero, decB_done

    li t6, 32         
    sub t5, t2, t6         # t5 = ct - 32
    sub t5, t5, t4
    
decB_mod:
    bge t5, zero, decB_store  
    addi t5, t5, 96
    j decB_mod


decB_store:
    sb t5, 0(t1)
    addi t0, t0, 1
    addi t3, t3, 1
    j decB_loop

decB_reset:
    li t3, 0
    j decB_loop

decB_done:
    lw ra, 4(sp)
    lw s1, 0(sp)
    addi sp, sp, 8
    jr ra

decC:
    addi sp, sp, -4
    sw ra, 0(sp)
    la t0, myplaintext
    li t1, 0
    li t2, 200
decC_clear:
    sb zero, 0(t0)
    addi t0, t0, 1
    addi t1, t1, 1
    blt t1, t2, decC_clear

    la t0, mychyper_buffer   # begining 
    la t1, myplaintext       # end

decC_parse_main:
    lb t2, 0(t0)             # t2 = The Character 
    beq t2, zero, decC_done  
    
    # Look for the dash marker at index + 1
    lb t3, 1(t0)
    li t4, 45                # -
    bne t3, t4, decC_skip_one

    addi t0, t0, 1           # Move pointer to the dash

decC_read_positions:
    li a0, 0     
    
decC_digit_gather:
    addi t0, t0, 1           # Move to digits
    lb t3, 0(t0)
    
    li t4, 48                # 0
    li t5, 57                # 9
    blt t3, t4, decC_place_now 
    bgt t3, t5, decC_place_now
    # a0 = a0 * 10 + digit
    addi t3, t3, -48
    slli t4, a0, 3           
    slli t5, a0, 1           
    add a0, t4, t5           
    add a0, a0, t3
    j decC_digit_gather

decC_place_now:
    beq a0, zero, decC_skip_one 
    addi a0, a0, -1          
    add t5, t1, a0           # t5 = myplaintext address + position
    sb t2, 0(t5)          

    # Check for chained positions (e.g., e-2-12)
    lb t3, 0(t0)
    li t4, 45            
    beq t3, t4, decC_read_positions 
    j decC_parse_main        

decC_skip_one:
    addi t0, t0, 1           
    j decC_parse_main

decC_done:
    lw ra, 0(sp)
    addi sp, sp, 4
    jr ra


decD:
    addi sp, sp, -4
    sw ra, 0(sp)
    jal funzione_D
    jal copy_buffer
    lw ra, 0(sp)
    addi sp, sp, 4
    jr ra


decE:
    addi sp, sp, -4
    sw ra, 0(sp)
    jal funzione_E
    lw ra, 0(sp)
    addi sp, sp, 4
    jr ra