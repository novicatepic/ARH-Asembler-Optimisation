SECTION .data align=16
    tmp dd 1.0, 2.0, 3.0, 4.0
    tmp2 dd 50.0,45.0,65.0,78.0
    temp3 dq 50.0,45.0,65.0,78.0
    error_string db "Something went wrong!", 0
    error_string_length EQU $ - error_string
    final_helper dq 1.0, 2.0, 3.0, 4.0
    ones dq 1.0, 1.0
    tmpHelper dd 1.0
    rez2 resq 0
    
SECTION .bss
    entry_file_path resq 1
    output_file_path resq 1
    num_of_elements resq 1   
    x_values resq 1
    y_values resq 1
    rez resd 1
    tmpBSS resd 4
    
SECTION .text
global _start
_start:

    call .clean_registers

    ;allocate 4 bytes so we know num of elements we're working with
    call .set_up_parameters_for_allocation
    mov rsi, 4         ;allocating 4 bytes, which represents an integer so I could store number of things I should process
    syscall
    mov [num_of_elements], rax 

    ;number of arguments
    pop rax

    ;even though two arguments are required, there is a third one implicitly
    ;one argument is entry file which already exists, and the second one is the output file that should be created
    cmp rax, 3
    jne .mistakes_have_been_made

    ;next argument not needed
    pop rax 
    
    xor rax, rax                        ;clear rax, just in case 
    pop rax                             ;pop source file

    mov [entry_file_path], rax          
    xor rax, rax
    mov rax, 2 
    mov rdi, [entry_file_path]
    mov rsi, 0                          ;read only flag          
    syscall                             ;open file

    ;if file doesn't exist
    cmp rax, -1
    je .mistakes_have_been_made

    ;else we're going to read from it
    ;but before that, put the descriptor in rdi
    ;this works as expected
    mov rdi, rax
    mov rax, 0                          ;read from file
    mov rsi, num_of_elements          
    mov rdx, 4                          ;reading 4 bytes => integer which represents number of elements
    push rdi                            ;gonna need rdi later, file not closed
    syscall

    call .num_elements_to_rax

    ;allocating space for x values   
    mov rsi, rax                         ;rax should have num of elements placed inside times double data for example 5 values of x * 8 = 40
    call .set_up_parameters_for_allocation
    syscall
    mov [x_values], rax                 ;memory allocated in rax

    call .num_elements_to_rax

    ;allocating space for y values                        
    mov rsi, rax                        ;allocating number_of_elements bytes for y array, it was rax before, now just testing
    call .set_up_parameters_for_allocation
    ;mov rax, 9
    syscall
    mov [y_values], rax

    call .num_elements_to_rax 

    pop rdi  ;file descriptor was on stack, poping it back so I can work with files
    push rdi 
    mov rsi, [x_values]   ;this should read into x_values, right?
    mov rdx, rax      ;test, was 40
    mov rax, 0 
    syscall

    call .num_elements_to_rax           ;DATA IS LOST???????

    pop rdi  ;file descriptor was on stack, poping it back so I can work with files
    push rdi  
    mov rsi, [y_values]   ;this should read into y_values
    mov rdx, rax     
    mov rax, 0 
    syscall


    ;exiting the entry binary file 
    call .close_file

    pop rdi 
    call .clean_registers

    ;reading second argument, which is the output file
    pop rax 
    mov [output_file_path], rax
    xor rax, rax 

    ;create that output file
    mov rax, 85
    mov rdi, [output_file_path]
    mov rsi, 777o                   ;rwx for all
    syscall


    call .clean_registers

    call .no_parallelism
    call .write_parameters_into_output_file

    call .clean_registers

.end:
    mov rax, 60
    mov rdi, 0
    syscall


.mistakes_have_been_made:
    mov rax, 1
    mov rdi, 1
    mov rsi, error_string
    mov rdx, error_string_length
    syscall 
    call .end 

.clean_registers:
    xor rax, rax 
    xor rbx, rbx 
    xor rcx, rcx 
    xor rdx, rdx 
    xor rsi, rsi 
    xor rdi, rdi 
    ret 

.num_elements_to_rax:
    xor rax, rax 
    mov eax, dword[num_of_elements]
    mov rbx, 8  ;each number is double, which should be 8 bytes, so multiplying with that
    mul rbx  
    ret 

.no_parallelism:
    call .clear_xmm_registers
    mov ecx, dword[num_of_elements]      ;how many times it's going to loop
    mov rsi, [x_values]
    mov rdi, [y_values]
    mov rax, 0                        
    .sumX:  
        movsd xmm1, qword [rsi]
        addsd xmm3, xmm1                        ;IN XMM3 IS PLACED SUM(Xi) i = 1,...,num_of_elements
        movsd xmm1, qword[rdi]
        addsd xmm2, xmm1                        ;sum(yi)
        movsd xmm1, qword[rsi]
        movsd xmm4, qword[rdi]
        mulsd xmm1, xmm4 
        addsd xmm5, xmm1                        ;sum(xi*yi)
        movsd xmm6, qword[rsi]
        movsd xmm7, qword[rsi]
        mulsd xmm6, xmm7 
        addsd xmm8, xmm6 
        add rsi, 8
        add rdi, 8
        loop .sumX

    movsd xmm1, xmm3 
    xor rax, rax 
    mov eax, dword[num_of_elements]
    cvtsi2sd xmm4, eax              ;CONVERTED TO DOUBLE SINCE I NEED NUMBER OF ELEMENTS
    ;cvtpd2ps xmm4, xmm4 
    movsd xmm6, xmm3 

    ;XMM1(SUM(Xi))
    ;XMM2(SUM(Yi))
    ;XMM3(SUM(Xi))
    ;XMM4(n)
    ;XMM5(SUM(Xi*Yi))
    ;XMM6(SUM(Xi))
    ;XMM8(SUM(Xi^2))

    ;15 xmm registers
    call .calculate_parameters
    ret 

.calculate_parameters:
    movsd xmm7, xmm5  ;first operand upper side
    movsd xmm9, xmm2  
    divsd xmm9, xmm1 
    mulsd xmm9, xmm8 
    subsd xmm7, xmm9 ;WE GOT THE FIRST PART OF A, XMM7 TAKEN AWAY

    movsd xmm9, xmm1
    movsd xmm10, xmm4 
    divsd xmm10, xmm1 
    mulsd xmm10, xmm8
    subsd xmm9, xmm10 ;xmm9 TAKEN AWAY

    divsd xmm7, xmm9 ;xmm9 NOW FREE => b parameter STORED IN XMM7

    movsd xmm9, xmm2 
    movsd xmm10, xmm4 
    mulsd xmm10, xmm7 
    subsd xmm9, xmm10 
    divsd xmm9, xmm1 ;a parameter STORED IN XMM9
    ret

.clear_xmm_registers:
    xorps xmm1, xmm1 
    xorps xmm2, xmm2 
    xorps xmm3, xmm3 
    xorps xmm4, xmm4 
    xorps xmm5, xmm5 
    xorps xmm6, xmm6
    xorps xmm7, xmm7 
    xorps xmm8, xmm8 
    xorps xmm9, xmm9 
    xorps xmm10, xmm10 
    xorps xmm11, xmm11 
    xorps xmm12, xmm12 
    xorps xmm13, xmm13 
    xorps xmm14, xmm14 
    xorps xmm15, xmm15 
    ret 

.help_function_for_parallel_sums:
        ;mov rax, qword[x_values + rsi * 4]
        movss xmm0, dword[x_values + rsi * 4]
        movss xmm2, xmm0 
        movss xmm3, xmm0
        movss xmm1, dword[y_values + rsi * 4]      
        mulss xmm2, xmm1                                   ;xmm2 holds float value of xi*yi       
        mulss xmm3, xmm0                                   ;xmm3 holds float value of xi*xi
        ;EVERYTHING IS READY TO BE SET INTO POSITIONS!
        ;mov qword[tmp], rax 
        movdqu oword[tmp], xmm0
        movdqu oword[tmp+4], xmm1 
        movdqu oword[tmp+8], xmm2
        movdqu oword[tmp+12], xmm3 
        ret 

.clear_necessary_registers:
    xorps xmm1, xmm1
    xorps xmm2, xmm2
    xorps xmm3, xmm3
    xorps xmm4, xmm4
    xorps xmm8, xmm8
    xorps xmm9, xmm9
    xorps xmm10, xmm10
    xorps xmm11, xmm11
    xorps xmm12, xmm12
    xorps xmm13, xmm13
    xorps xmm14, xmm14
    xorps xmm15, xmm15
    ret

.parallelism:
    call .clear_xmm_registers
    call .clean_registers
    mov eax, dword[num_of_elements]
    mov rbx, 4 ;TWO DOUBLES CAN BE PUT IN ONE XMM REGISTER
    cqo 
    div rbx 
    mov rcx, rax        ;rdx holds mod 
    mov rsi, 0
    xorps xmm8, xmm8 
    cmp rax, 0
    je .helpLabel
    mov rsi, x_values
    mov rdi, y_values  
    mov rax, 0
    mov rbx, 0
    .parallelSumsTwo:
        vmovdqu ymm1, yword[rsi]     ;xi
        vmovdqu ymm2, yword[rdi]     ;yi
        vmovdqu ymm3, yword[rsi]     ;xi
        vmovdqu ymm4, yword[rsi]     ;xi 
        ;movdqu xmm4, 
        vaddpd ymm0, ymm1        ;sum(Xi) -> partial sums
        vaddpd ymm5, ymm2        ;sum(Yi) -> partial sums
        vmulpd ymm3, ymm2        ;xi*yi
        vaddpd ymm6, ymm3        ;sum(xi*yi) -> partial sums
        vmulpd ymm4, ymm1        ;xi*xi
        vaddpd ymm7, ymm4        ;sum(xi*xi) -> partial sums
        add rdi, 32
        add rsi, 32
        ;add rax, 4 
        ;add rbx, 4
        loop .parallelSumsTwo

    .helpLabel:
        mov rcx, rdx    ;mod -> number of iterations for leftovers

    cmp rcx, 0
    je .helpLabel2

    .sumLeftovers:  ;not every number mod 4 = 0 :/
        ;movsd xmm12, qword[x_values + rax * 8]
        movsd xmm12, qword[rsi]
        ;movsd xmm13, qword[y_values + rbx * 8]
        movsd xmm13, qword[rdi]
        ;movdqu xmm14, oword[ones]
        ;movdqu xmm15, oword[ones]
        movsd xmm14, xmm12 
        movsd xmm15, xmm12 
        mulsd xmm14, xmm13
        mulsd xmm15, xmm12 
        ;movdqu oword[tmpHelper], xmm14 ;because I added ones before 
        ;movdqu oword[tmpHelper], xmm15 ;because I added ones before
        ;movdqu xmm14, oword[tmpHelper]
        ;movdqu xmm15, oword[tmpHelper]
        addsd xmm0, xmm12       ;further add to sum(xi)
        addsd xmm5, xmm13       ;further add to sum(yi)
        addsd xmm6, xmm14
        addsd xmm7, xmm15
        ;inc rax 
        ;inc rbx
        add rsi, 8 
        add rdi, 8 
        loop .sumLeftovers


        .helpLabel2:
        ;mov ecx, 3 
        ;vmovdqu ymm8, ymm0       ;copy of xi sums 
        ;vmovdqu ymm9, ymm5       ;copy of  yi sums
        ;vmovdqu ymm10, ymm6      ;copy of (xi*yi) sums
        ;vmovdqu ymm11, ymm7      ;copy of (xi*xi) sums

    mov rsi, 1
    mov rcx, 3
    vmovdqu yword[tmpBSS],ymm0
    .loopX1:
        movsd xmm12, qword[tmpBSS + rsi * 8]
        addsd xmm0, xmm12
        inc rsi 
        loop .loopX1
    
    mov rsi, 1
    mov rcx, 3
    vmovdqu yword[tmpBSS],ymm5
    .loopY1:
        movsd xmm12, qword[tmpBSS + rsi * 8]
        addsd xmm5, xmm12 
        inc rsi 
        loop .loopY1
    
    mov rsi, 1
    mov rcx, 3
    vmovdqu yword[tmpBSS],ymm6
    .loopXY:
        movsd xmm12, qword[tmpBSS + rsi * 8]
        addsd xmm6, xmm12 
        inc rsi 
        loop .loopXY
   
    mov rsi, 1
    mov rcx, 3
    vmovdqu yword[tmpBSS],ymm7
    .loopXX:
        movsd xmm12, qword[tmpBSS + rsi * 8]
        addsd xmm7, xmm12 
        inc rsi 
        loop .loopXX

    call .clear_necessary_registers

    vmovdqu yword[final_helper], ymm0 
    vmovdqu yword[final_helper + 8], ymm5 
    vmovdqu yword[final_helper + 16], ymm6 
    vmovdqu yword[final_helper + 24], ymm7 

    call .clean_registers
    call .clear_xmm_registers

    movsd xmm1, qword[final_helper]
    movsd xmm3, qword[final_helper] 
    movsd xmm6, qword[final_helper] 
    movsd xmm2, qword[final_helper + 8]
    movsd xmm5, qword[final_helper + 16]
    movsd xmm8, qword[final_helper + 24]
    mov eax, dword[num_of_elements]
    cvtsi2sd xmm4, eax
    ;cvtpd2ps xmm4, xmm4

    ;1,3,6,2,5,8,15 cleared!
    ;xmm7 -> xmm14
    ;xmm9 -> xmm13, cuz i copied from up somewhere
    call .calculate_parameters

    ret 

;unnecessary procedure
.rewrite_elements_into_output_file:
    mov rax, 2
    mov rdi, [output_file_path]
    mov rsi, 1                   ;read/write flag, only write flag (2) also a viable option
    syscall                         ;open output file

    cmp rax, 0
    jbe .mistakes_have_been_made 

    mov rdi, rax ;save file descriptor

    ;why am i writting this into file? so i can understand what's happening a little bit better
    push rdi
    mov rax, 1
    mov rdx, 4                  ;this one is valid, I suppose that num of elements is going to be an integer
    mov rsi, num_of_elements
    syscall

    call .num_elements_to_rax
    pop rdi 
    push rdi
    mov rdx, rax                 ;only testing because I know that there are 5 x elements in a file, was 40
    xor rax, rax 
    mov rax, 1
    mov rsi, x_values
    syscall


    call .num_elements_to_rax
    pop rdi 
    push rdi
    ;mov rdx, rax
    mov rdx, rax
    xor rax, rax  
    mov rax, 1
    mov rsi, y_values 
    syscall

    mov rax, 3
    syscall

    pop rdi         ;didn't have to do the last push, whatever
    ret 

.set_up_parameters_for_allocation:
    mov r10, 22h
    mov r8, -1
    mov r9, 0
    mov rdi, 0 
    mov rdx, 2
    mov rax, 9
    ret 

.close_file:
    mov rax, 3
    syscall
    ret 

.write_parameters_into_output_file:
    mov rax, 2
    mov rdi, [output_file_path]
    mov rsi, 1                      ;read/write flag, only write flag (2) also a viable option
    syscall                         ;open output file

    cmp rax, 0
    jbe .mistakes_have_been_made 

    ;was movdqu
    movdqu oword[rez],xmm9  ;a parameter was stored in xmm9

    mov rbx, [rez]
    mov rdi, rax ;save file descriptor

    push rdi
    mov rax, 1
    mov rdx, 8                
    mov rsi, rez      ;writting a parameter to output file 
    syscall

    movdqu oword[rez],xmm7  ;b parameter was stored in xmm7
    ;mov rbx, [rez]

    pop rdi 
    mov rax, 1
    mov rdx, 8
    mov rsi, rez
    syscall

    call .close_file
    ret 
