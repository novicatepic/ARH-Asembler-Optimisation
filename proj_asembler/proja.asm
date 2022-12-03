SECTION .data 
    error_string db "Something went wrong!", 0
    error_string_length EQU $ - error_string

SECTION .bss
    entry_file_path resq 1
    output_file_path resq 1
    num_of_elements resq 1
    x_values resq 1
    y_values resq 1

SECTION .text
global _start
_start:

    call .clean_registers

    ;allocate 4 bytes so we know num of elements we're working with
    mov rdi, 0
    mov rsi, 4         ;allocating 4 bytes, which represents an integer so I could store number of things I should proceed
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
    mov rdx, 4                          ;reading 4 bytes => integer
    push rdi                            ;gonna need rdi later 
    syscall

    mov rdi, 0
    mov rsi, [num_of_elements]          ;allocating number_of_elements bytes for x array
    mov rdx, 2                          ;prot value, write+read
    mov r10, 22h
    mov r8, -1
    mov r9, 0
    mov rax, 9
    syscall
    mov [x_values], rax 

    mov rdi, 0
    mov rsi, [num_of_elements]           ;allocating number_of_elements bytes for y array
    mov rdx, 2                           ;prot value, write+read
    mov r10, 22h
    mov r8, -1
    mov r9, 0
    mov rax, 9
    syscall
    mov [y_values], rax

    xor rbx, rbx
    mov rbx, 8                            ;each element of x or y is "double"
    imul rbx, [num_of_elements]           ;8*num_of_elements = allocated space for num_of_element elements

    pop rdi
    mov rax, 0
    mov rsi, [x_values]
    mov rdx, rbx 
    push rdi
    syscall

    pop rdi 
    mov rax, 0
    mov rsi, [y_values]
    mov rdx, rbx 
    ;push rdi 
    syscall

    ;closing entry file
    mov rax, 3
    syscall
    
    call .clean_registers

    pop rax 
    mov [output_file_path], rax
    xor rax, rax 

    mov rax, 85
    mov rdi, [output_file_path]
    mov rsi, 1ffh
    syscall

    mov rax, 2
    mov rdi, [output_file_path]
    mov rsi, 1                   ;read/write flag, only write flag also a viable option
    syscall                         ;open output file

    cmp rax, 0
    jbe .mistakes_have_been_made 


    mov rdi, rax 

    ;double check
    cmp rdi, 0
    jbe .mistakes_have_been_made

    mov rax, 1
    mov rdx, 4
    mov rsi, [num_of_elements] 
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

.clean_registers:
    xor rax, rax 
    xor rbx, rbx 
    xor rcx, rcx 
    xor rdx, rdx 
    xor rsi, rsi 
    xor rdi, rdi 
    ret 