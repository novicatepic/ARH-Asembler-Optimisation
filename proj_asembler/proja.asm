SECTION .data align=16
    tmp dd 1.0, 2.0, 3.0, 4.0
    tmp2 dd 50.0,45.0,65.0,78.0
    temp3 dq 50.0,45.0,65.0,78.0
    realtmp dq 50.0
    realtmp2 dd 2.1
    error_string db "Something went wrong!", 0
    error_string_length EQU $ - error_string
    final_helper do 1.1
    
SECTION .bss
    entry_file_path resq 1
    output_file_path resq 1
    num_of_elements resq 1   
    x_values resq 100000
    y_values resq 100000
    rez resq 1
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
    mov rbx, 8  ;moved to double data                      ;each number is double, which should be 8 bytes, so multiplying with that
    mul rbx  
    ret 

.no_parallelism:
    mov ecx, dword[num_of_elements]      ;how many times it's going to loop
    mov rsi, 0                          
    .sumX:  
        movsd xmm1, qword[x_values + rsi * 8]
        addsd xmm3, xmm1                        ;IN XMM3 IS PLACED SUM(Xi) i = 1,...,num_of_elements
        add rsi, 1 
        loop .sumX

    mov ecx, dword[num_of_elements]
    mov rsi, 0
    .sumY:
        movsd xmm1, qword[y_values + rsi * 8]
        addsd xmm2, xmm1                        ;IN XMM2 IS PLACED SUM(Yi) i = 1,...,num_of_elements
        inc rsi 
        loop .sumY

    mov ecx, dword[num_of_elements]
    mov rsi, 0
    .sumXMultiplY: 
        movsd xmm1, qword[x_values + rsi * 8]
        movsd xmm4, qword[y_values + rsi * 8]
        mulsd xmm1, xmm4    ;Xi*Yi
        addsd xmm5, xmm1 ;Sum(Xi*Yi)             ;PLACED IN XMM5 (COMMENTING BECAUSE IT'S EASIER FOR ME)
        inc rsi 
        loop .sumXMultiplY

    mov ecx, dword[num_of_elements]
    mov rsi, 0
    .sumXSquare:
        movsd xmm6, qword[x_values + rsi * 8]
        movsd xmm7, qword[x_values + rsi * 8]
        mulsd xmm6, xmm7 ;Xi*Xi
        addsd xmm8, xmm6 ;Sum(Xi^2)
        inc rsi 
        loop .sumXSquare

    movsd xmm1, xmm3 
    
    xor rax, rax 

    mov eax, dword[num_of_elements]

    cvtsi2sd xmm4, eax              ;CONVERTED TO DOUBLE SINCE I NEED NUMBER OF ELEMENTS

    movsd xmm6, xmm3 

    ;XMM1(SUM(Xi))
    ;XMM2(SUM(Yi))
    ;XMM3(SUM(Xi))
    ;XMM4(n)
    ;XMM5(SUM(Xi*Yi))
    ;XMM6(SUM(Xi))
    ;XMM8(SUM(Xi^2))

    ;15 xmm registers
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

.help_function_for_parallel_sums:
        ;xor rax, rax 
        ;mov rax, qword[x_values + rsi * 8]
        ;mov [realtmp], rax
        movsd xmm0, qword[x_values + rsi * 8]
        cvtpd2ps xmm0, xmm0
        ;cvtpd2ps xmm0, [realtmp]    ;xmm0 holds converted x value to float
        ;cvtpd2ps xmm2, [realtmp]    ;xmm2 also holds x value converted to float   
        movss xmm2, xmm0 
        ;cvtpd2ps xmm3, [realtmp] 
        movss xmm3, xmm0
        ;mov rax, qword[y_values + rsi * 8]
        ;mov [realtmp], rax 
        movsd xmm1, qword[y_values + rsi * 8]
        cvtpd2ps xmm1, xmm1    ;xmm1 holds converted y value to float        
        mulss xmm2, xmm1                                   ;xmm2 holds float value of xi*yi       
        mulss xmm3, xmm0                                   ;xmm3 holds float value of xi*xi
        ;EVERYTHING IS READY TO BE SET INTO POSITIONS!
        movdqu oword[tmp], xmm0
        movdqu oword[tmp+4], xmm1 
        movdqu oword[tmp+8], xmm2
        movdqu oword[tmp+12], xmm3 
        ret 

.parallelism:
    xor rax, rax 
    mov eax, dword[num_of_elements]
    mov rbx, 4 
    cqo 
    div rbx 
    mov rcx, rax        ;rdx holds mod 
    mov rsi, 0
    movsd xmm8, xmm14   ;somewhat clearing xmm8
    .parallelSums:
        call .help_function_for_parallel_sums
        movaps xmm4, [tmp]
        inc rsi 
        call .help_function_for_parallel_sums
        movaps xmm5, [tmp]
        inc rsi 
        call .help_function_for_parallel_sums
        movaps xmm6, [tmp]
        inc rsi 
        call .help_function_for_parallel_sums
        movaps xmm7, [tmp]
        inc rsi
        ;inc rsi 
        ;call .help_function_for_parallel_sums
        ;movaps xmm9, [tmp]
        ;inc rsi 
        ;call .help_function_for_parallel_sums
        ;movaps xmm10, [tmp]
        ;inc rsi 
        ;call .help_function_for_parallel_sums
        ;movaps xmm12, [tmp]
        ;inc rsi 
        ;call .help_function_for_parallel_sums
        ;movaps xmm13, [tmp]
        ;inc rsi 
        ;call .help_function_for_parallel_sums
        ;movaps xmm14, [tmp]
        ;inc rsi 
        ;call .help_function_for_parallel_sums
        ;movaps xmm15, [tmp]*/
        addps xmm8, xmm4
        addps xmm8, xmm5 
        addps xmm8, xmm6
        addps xmm8, xmm7
        loop .parallelSums
        ret 

    mov rcx, rdx    ;mod -> number of iterations for leftovers
    .sumLeftovers:  ;not every number mod 4 = 0 :/
        call .help_function_for_parallel_sums
        movaps xmm4, [tmp]
        inc rsi 
        addps xmm8, xmm4 
        loop .sumLeftovers

    call .clean_registers

    ;XMM1(SUM(Xi))
    ;XMM2(SUM(Yi))
    ;XMM3(SUM(Xi))
    ;XMM4(n)
    ;XMM5(SUM(Xi*Yi))
    ;XMM6(SUM(Xi))
    ;XMM8(SUM(Xi^2))

    movdqu oword[final_helper], xmm8 
    mov eax, dword[final_helper]            ;sum(xi)
    mov ebx, dword[final_helper + 4]        ;sum(yi)
    mov ecx, dword[final_helper + 8]        ;sum(xi*yi)
    mov edx, dword[final_helper + 12]       ;sum(xi*xi)

    ;cvtsi2sd xmm4, eax
    ;movsd xmm1, qword[rax] nicetry:)
    ;cvtsi2sd xmm1, dword[final_helper]         ;DUNNO HOW TO CAST BACK TO DOUBLE
    movss xmm1, dword[final_helper]
    movss xmm3, dword[final_helper] 
    movss xmm6, dword[final_helper] 
    movss xmm2, dword[final_helper + 4]
    movss xmm5, dword[final_helper + 8]
    movss xmm8, dword[final_helper + 12]
    ;vpxor xmm4, xmm4   NOPE 
    ;movsd xmm4, xmm15
    mov eax, dword[num_of_elements]
    cvtsi2sd xmm15, eax
    cvtpd2ps xmm15, xmm15

    ;1,3,6,2,5,8,15 cleared!
    ;xmm7 -> xmm14
    ;xmm9 -> xmm13, cuz i copied from up somewhere
    movss xmm14, xmm5
    movss xmm13, xmm2  
    divss xmm13, xmm1 
    mulss xmm13, xmm8 
    subss xmm14, xmm13 ;WE GOT THE FIRST PART OF A

    movss xmm13, xmm1
    movss xmm10, xmm15 
    divss xmm10, xmm1 
    mulss xmm10, xmm8
    subss xmm13, xmm10

    divss xmm14, xmm13 ;b parameter STORED IN XMM14

    movss xmm13, xmm2 
    movss xmm10, xmm15
    mulss xmm10, xmm14
    subss xmm13, xmm10 
    divss xmm13, xmm1 ;a parameter STORED IN XMM13

    ;mov oword[final_helper], xmm13 
    cvtps2pd xmm13, xmm13   ;converted a to double
    cvtps2pd xmm14, xmm14   ;converted b to double
    ;xorps xmm7, xmm7  how to clear a xmm7 register, a xmm9, b xmm7
    xorps xmm7, xmm7 
    xorps xmm9, xmm9 
    movsd xmm9, xmm13   ;moving result to xmm9 because it's easier to call one procedure for two things 
    movsd xmm7, xmm14   ;same reasong as mentioned above
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

    mov rdi, rax ;save file descriptor

    push rdi
    mov rax, 1
    mov rdx, 8                
    mov rsi, rez        ;writting a parameter to output file 
    syscall

    movdqu oword[rez],xmm7  ;b parameter was stored in xmm7

    pop rdi 
    mov rax, 1
    mov rdx, 8
    mov rsi, rez 
    syscall

    call .close_file
    ret 
