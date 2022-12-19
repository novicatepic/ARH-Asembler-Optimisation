SECTION .data align=16
    tmp dd 1.0, 2.0, 3.0, 4.0
    tmp2 dd 50.0,45.0,65.0,78.0
    temp3 dq 50.0,45.0,65.0,78.0
    realtmp dq 50.0
    realtmp2 dd 2.1
    error_string db "Something went wrong!", 0
    error_string_length EQU $ - error_string
    final_helper dd 1.0, 2.0, 3.0, 4.0
    ones dd 1.0, 1.0, 1.0, 1.0
    tmpHelper dd 1.0
    ;rez do 1.0
    
SECTION .bss
    entry_file_path resq 1
    output_file_path resq 1
    num_of_elements resq 1   
    x_values resd 10000000
    y_values resd 10000000
    rez resd 1
    ;final_helper resd 4
    
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
    syscall
    mov [y_values], rax

    call .num_elements_to_rax 

    pop rdi  ;file descriptor was on stack, poping it back so I can work with files
    push rdi 
    mov rsi, x_values   ;this should read into x_values, right?
    mov rdx, rax      ;test, was 40
    mov rax, 0 
    syscall

    call .num_elements_to_rax           ;DATA IS LOST???????

    pop rdi  ;file descriptor was on stack, poping it back so I can work with files
    push rdi  
    mov rsi, y_values   ;this should read into y_values
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

    ;parameters written into output file as they should be

    call .clean_registers

    ;call .parallelism
    ;call .write_parameters_into_output_file

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
    mov rbx, 4  ;moved to float data                      ;each number is double, which should be 8 bytes, so multiplying with that
    mul rbx  
    ret 

.no_parallelism:
    call .clear_xmm_registers
    mov ecx, dword[num_of_elements]      ;how many times it's going to loop
    mov rsi, 0                          
    .sumX:  
        movss xmm1, dword[x_values + rsi * 4]
        addss xmm3, xmm1                        ;IN XMM3 IS PLACED SUM(Xi) i = 1,...,num_of_elements

        ;cmp rsi, 9999998
        ;je .heh 
        
        ;.heh

        ;movss xmm1, dword[y_values + rsi * 4]
        ;addss xmm2, xmm1                        ;sum(yi)
        ;movss xmm1, dword[x_values + rsi * 4]
        ;movss xmm4, dword[y_values + rsi * 4]
        ;mulss xmm1, xmm4 
        ;addss xmm5, xmm1                        ;sum(xi*yi)
        ;movss xmm6, dword[x_values + rsi * 4]
        ;movss xmm7, dword[x_values + rsi * 4]
        ;mulss xmm6, xmm7 
        ;addss xmm8, xmm6 
        inc rsi 
        loop .sumX

    ;.heh:

    mov ecx, dword[num_of_elements]
    mov rsi, 0
    .sumY:
        movss xmm1, dword[y_values + rsi * 4]
        addss xmm2, xmm1                        ;IN XMM2 IS PLACED SUM(Yi) i = 1,...,num_of_elements
        inc rsi 
        loop .sumY

    mov ecx, dword[num_of_elements]
    mov rsi, 0
    .sumXMultiplY: 
        movss xmm1, dword[x_values + rsi * 4]
        movss xmm4, dword[y_values + rsi * 4]
        mulss xmm1, xmm4    ;Xi*Yi
        addss xmm5, xmm1 ;Sum(Xi*Yi)             ;PLACED IN XMM5 (COMMENTING BECAUSE IT'S EASIER FOR ME)
        inc rsi 
        loop .sumXMultiplY

    mov ecx, dword[num_of_elements]
    mov rsi, 0
    .sumXSquare:
        movss xmm6, dword[x_values + rsi * 4]
        movss xmm7, dword[x_values + rsi * 4]
        mulss xmm6, xmm7 ;Xi*Xi
        addss xmm8, xmm6 ;Sum(Xi^2)
        inc rsi 
        loop .sumXSquare

    movss xmm1, xmm3 
    xor rax, rax 
    mov eax, dword[num_of_elements]
    cvtsi2sd xmm4, eax              ;CONVERTED TO DOUBLE SINCE I NEED NUMBER OF ELEMENTS
    cvtpd2ps xmm4, xmm4 
    movss xmm6, xmm3 

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
    movss xmm7, xmm5  ;first operand upper side
    movss xmm9, xmm2  
    divss xmm9, xmm1 
    mulss xmm9, xmm8 
    subss xmm7, xmm9 ;WE GOT THE FIRST PART OF A, XMM7 TAKEN AWAY

    movss xmm9, xmm1
    movss xmm10, xmm4 
    divss xmm10, xmm1 
    mulss xmm10, xmm8
    subss xmm9, xmm10 ;xmm9 TAKEN AWAY

    divss xmm7, xmm9 ;xmm9 NOW FREE => b parameter STORED IN XMM7

    movss xmm9, xmm2 
    movss xmm10, xmm4 
    mulss xmm10, xmm7 
    subss xmm9, xmm10 
    divss xmm9, xmm1 ;a parameter STORED IN XMM9
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
    mov rbx, 4
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
        movdqu xmm1, oword[rsi]     ;xi
        movdqu xmm2, oword[rdi]     ;yi
        movdqu xmm3, oword[rsi]     ;xi
        movdqu xmm4, oword[rsi]     ;xi 
        ;movdqu xmm4, 
        addps xmm0, xmm1        ;sum(Xi) -> partial sums
        addps xmm5, xmm2        ;sum(Yi) -> partial sums
        mulps xmm3, xmm2        ;xi*yi
        addps xmm6, xmm3        ;sum(xi*yi) -> partial sums
        mulps xmm4, xmm1        ;xi*xi
        addps xmm7, xmm4        ;sum(xi*xi) -> partial sums
        add rdi, 16
        add rsi, 16
        add rax, 4
        add rbx, 4
        loop .parallelSumsTwo

    .helpLabel:
        mov rcx, rdx    ;mod -> number of iterations for leftovers

    cmp rcx, 0
    je .helpLabel2

    ;so I can access the correct location
    ;inc rax  
    ;inc rbx

    .sumLeftovers:  ;not every number mod 4 = 0 :/
        ;call .help_function_for_parallel_sums
        ;movaps xmm4, [tmp]
        movss xmm12, dword[x_values + rax * 4]
        movss xmm13, dword[y_values + rbx * 4]
        movdqu xmm14, oword[ones]
        movdqu xmm15, oword[ones]
        movss xmm14, xmm12 
        movss xmm15, xmm12 
        mulps xmm14, xmm13
        mulps xmm15, xmm12 
        ;movdqu oword[tmpHelper], xmm14 ;because I added ones before 
        ;movdqu oword[tmpHelper], xmm15 ;because I added ones before
        ;movdqu xmm14, oword[tmpHelper]
        ;movdqu xmm15, oword[tmpHelper]
        addps xmm0, xmm12       ;further add to sum(xi)
        addps xmm5, xmm13       ;further add to sum(yi)
        addps xmm6, xmm14
        addps xmm7, xmm15
        inc rax 
        inc rbx 
        loop .sumLeftovers


        .helpLabel2:
        mov ecx, 3 
        movdqu xmm8, xmm0       ;copy of xi sums 
        movdqu xmm9, xmm5       ;copy of  yi sums
        movdqu xmm10, xmm6      ;copy of (xi*yi) sums
        movdqu xmm11, xmm7      ;copy of (xi*xi) sums

    .shuffleLoop:
        pshufd xmm8,xmm8,10_01_00_11b
        pshufd xmm9,xmm9,10_01_00_11b
        pshufd xmm10,xmm10,10_01_00_11b
        pshufd xmm11,xmm11,10_01_00_11b
        ;shuffle sums
        addps xmm0, xmm8                ;sum xi
        addps xmm5, xmm9                ;sum yi
        addps xmm6, xmm10               ;sum (xi * yi)
        addps xmm7, xmm11                ;sum (xi ^ 2)
        loop .shuffleLoop

    
    ;.helpLabel2:
    ;XMM1(SUM(Xi))
    ;XMM2(SUM(Yi))
    ;XMM3(SUM(Xi))
    ;XMM4(n)
    ;XMM5(SUM(Xi*Yi))
    ;XMM6(SUM(Xi))
    ;XMM8(SUM(Xi^2))
    call .clear_necessary_registers

    movdqu oword[final_helper], xmm0 
    movdqu oword[final_helper + 4], xmm5 
    movdqu oword[final_helper + 8], xmm6 
    movdqu oword[final_helper + 12], xmm7 

    call .clean_registers
    call .clear_xmm_registers

    movss xmm1, dword[final_helper]
    movss xmm3, dword[final_helper] 
    movss xmm6, dword[final_helper] 
    movss xmm2, dword[final_helper + 4]
    movss xmm5, dword[final_helper + 8]
    movss xmm8, dword[final_helper + 12]
    mov eax, dword[num_of_elements]
    cvtsi2sd xmm4, eax
    cvtpd2ps xmm4, xmm4

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
    mov rdx, 4                
    mov rsi, rez      ;writting a parameter to output file 
    syscall

    movdqu oword[rez],xmm7  ;b parameter was stored in xmm7
    ;mov rbx, [rez]

    pop rdi 
    mov rax, 1
    mov rdx, 4
    mov rsi, rez
    syscall

    call .close_file
    ret 
