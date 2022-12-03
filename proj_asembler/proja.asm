SECTION .data 
    error_string db "Something went wrong!", 0
    error_string_length EQU $ - error_string
    temp_value_for_nelems db 14

SECTION .bss
    entry_file_path resq 1
    output_file_path resq 1
    num_of_elements resq 1
    tmp resq 1
    x_values resq 1
    y_values resq 1

SECTION .text
global _start
_start:

    call .clean_registers

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

    mov rdi, 0
    mov rsi, 1         ;allocating 1 byte
    mov rdx, 2         ;prot value, write+read
    mov r10, 22h
    mov r8, -1
    mov r9, 0
    mov rax, 9
    syscall
    mov [tmp], rax 

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
    mov rdx, 500
    syscall

    ;closing entry file, need to allocate memory for other stuff
    mov rax, 3
    syscall


    
    call .clean_registers
    ;we're going to allocate memory for all the x parameters and all the y parameters, cuz it's required 
    ;mov rdi, 0
    ;mov rsi, 5                          ;allocating number_of_elements bytes, 5 for fun to test
    ;mov rdx, 2                          ;prot value, write+read
    ;mov r10, 22h
    ;mov r8, -1
    ;mov r9, 0
    ;mov rax, 9
    ;syscall
    ;mov [x_values], rax 

    call .clean_registers

    ;same code all over again, probably should make a function and put something on stack to pop it back later so I can work around that problem
    ;mov rdi, 0
    ;mov rsi, 5                        ;allocating number_of_elements bytes
    ;mov rdx, 2                        ;prot value, write+read
    ;mov r10, 22h
    ;mov r8, -1
    ;mov r9, 0
    ;mov rax, 9
    ;syscall
    ;mov [y_values], rax 


    pop rax 
    mov [output_file_path], rax
    xor rax, rax 
    mov rax, 2
    mov rdi, [output_file_path]
    mov rsi, 2                     ;read/write flag, only write flag also a viable option
    syscall                         ;open output file

    cmp rax, -1
    je .mistakes_have_been_made 


    mov rdi, rax 
    mov rax, 1
    mov rdx, 1
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

.convert_str_to_int_x:
    


.clean_registers:
    ;clean registers
    xor rax, rax 
    xor rbx, rbx 
    xor rcx, rcx 
    xor rdx, rdx 
    xor rsi, rsi 
    xor rdi, rdi 
    ret 