SECTION .data 
    error_string db "Something went wrong!", 0
    error_string_length EQU $ - error_string
    tmp1 dq 1.2
    tmp2 dq 1.3

;align 32 
SECTION .bss
    entry_file_path resq 1
    output_file_path resq 1
    num_of_elements resq 1
    x_values resq 10
    y_values resq 10
    rez resq 1
    

SECTION .text
global _start
_start:

    call .clean_registers

    ;allocate 4 bytes so we know num of elements we're working with
    mov rdi, 0
    mov rsi, 4         ;allocating 4 bytes, which represents an integer so I could store number of things I should process
    mov rdx, 2         ;prot value, write+read
    mov r10, 22h
    mov r8, -1
    mov r9, 0
    mov rax, 9
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
    mov rdi, 0      
    mov rsi, rax                         ;rax should have num of elements placed inside times double data for example 5 values of x * 8 = 40
    mov rdx, 2                          ;prot value, write+read
    mov r10, 22h
    mov r8, -1
    mov r9, 0
    mov rax, 9
    syscall
    mov [x_values], rax                 ;memory allocated in rax

    call .num_elements_to_rax

    ;allocating space for y values
    mov rdi, 0                          
    mov rsi, rax                        ;allocating number_of_elements bytes for y array, it was rax before, now just testing
    mov rdx, 2                           ;prot value, write+read
    mov r10, 22h
    mov r8, -1
    mov r9, 0
    mov rax, 9
    syscall
    mov [y_values], rax

    call .num_elements_to_rax 

    pop rdi  ;file descriptor was on stack, poping it back so I can work with files
    push rdi 
    ;mov rdi, rcx ;TEST
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
    mov rax, 3
    syscall

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

;    mov rax, 2
;    mov rdi, [output_file_path]
;    mov rsi, 1                   ;read/write flag, only write flag (2) also a viable option
;    syscall                         ;open output file

;    cmp rax, 0
;    jbe .mistakes_have_been_made 

;    mov rdi, rax ;save file descriptor

    ;why am i writting this into file? so i can understand what's happening a little bit better
;    push rdi
;    mov rax, 1
;    mov rdx, 4                  ;this one is valid, I suppose that num of elements is going to be an integer
;    mov rsi, num_of_elements
;    syscall

 ;   call .num_elements_to_rax

;    pop rdi 
;    push rdi
;    mov rdx, rax                 ;only testing because I know that there are 5 x elements in a file, was 40
;    xor rax, rax 
;    mov rax, 1
;    mov rsi, x_values
;    syscall


;    call .num_elements_to_rax
;    pop rdi 
;    push rdi
    ;mov rdx, rax
;    mov rdx, rax
;    xor rax, rax  
;    mov rax, 1
;    mov rsi, y_values 
;    syscall

;    mov rax, 3
;    syscall

;    pop rdi         ;didn't have to do the last push, whatever
    call .clean_registers

    ;DIDN'T HAVE TO DO EVERYTHING BEFORE, BUT I'VE DONE IT JUST TO UNDERSTAND FILES A LITTLE BIT
    ;WRITTING AND READING FROM FILES WORKS, NEXT STOP => IMPLEMENT LINEAR REGRESSION  

    mov ecx, dword[num_of_elements]      ;how many times it's going to loop
    mov rsi, 0                          
    .sumX:  
        movsd xmm1, qword[x_values + rsi * 8]
        addsd xmm3, xmm1                        ;IN XMM3 IS PLACED SUM(Xi) i = 1,...,num_of_elements
        add rsi, 1 
        loop .sumX

    mov cl, byte[num_of_elements]
    mov rsi, 0
    .sumY:
        movsd xmm1, qword[y_values + rsi * 8]
        addsd xmm2, xmm1                        ;IN XMM2 IS PLACED SUM(Yi) i = 1,...,num_of_elements
        inc rsi 
        loop .sumY

    mov cl, byte[num_of_elements]
    mov rsi, 0
    .sumXMultiplY: 
        movsd xmm1, qword[x_values + rsi * 8]
        movsd xmm4, qword[y_values + rsi * 8]
        mulsd xmm1, xmm4    ;Xi*Yi
        addsd xmm5, xmm1 ;Sum(Xi*Yi)             ;PLACED IN XMM5 (COMMENTING BECAUSE IT'S EASIER FOR ME)
        inc rsi 
        loop .sumXMultiplY

    mov cl, byte[num_of_elements]
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


    ;BEFORE PLACING VALUES INTO OUTPUT_FILE, CALCULATE THE FORMULA!
    ;NEED TO FINISH PLACING VALUES INTO OUTPUT_FILE

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

    mov rax, 3
    syscall

    ;PARAMETRI USPJESNO UPISANI U MEMORIJU

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
    mov al, byte[num_of_elements]
    mov rbx, 8                      ;each number is double, which should be 8 bytes, so multiplying with that
    mul rbx  
    ret 