SECTION .data 
    error_string db "Something went wrong!", 0
    error_string_length EQU $ - error_string

SECTION .bss
    entry_file_path resq 1
    output_file_path resq 1
    num_of_elements resb 1
    x_values resq 1
    y_values resq 1

SECTION .text
global _start
_start:

    ;start test
    ;mov rax, 4

    ;clean registers
    xor rax, rax 
    xor rbx, rbx 
    xor rcx, rcx 
    xor rdx, rdx 
    xor rsi, rsi 
    xor rdi, rdi 

    ;allocate 1 byte so we know num of elements we're working with
    mov rdi, 0
    mov rsi, 1         ;allocating 1 byte
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
    cmp rax, 3
    jne .mistakes_have_been_made

    ;next argument not needed
    pop rax 
    
    xor rax, rax                        ;clear rax 
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
    mov rdi, rax
    mov rax, 0                          ;read from file
    mov rsi, [num_of_elements]
    mov rdx, 100
    syscall


    ;closing entry file
    mov rax, 3
    syscall

    xor rax, rax
    pop rax 
    mov [output_file_path], rax
    xor rax, rax 
    mov rax, 2
    mov rdi, [output_file_path]
    mov rsi, 2                      ;read/write flag, only write flag also a viable option
    syscall                         ;open output file

    cmp rax, -1
    je .mistakes_have_been_made 


    mov rdi, rax 
    mov rax, 1
    mov rsi, [num_of_elements]
    mov rdx, 1
    syscall

    mov rax, 3
    syscall

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