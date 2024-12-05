section .text
global _take_user_input  ; Make the function available for C to call

_take_user_input:


    ;take user input
    mov rax, 0x2000003          ;syscall for read
    mov rdi, 0                  ;stdin
    lea rsi, [rel input]        ;address of input
    mov rdx, 32                 ;32 bytes to read
    syscall


    ;open the state file
    mov rax, 0x2000005            ;code to open
    lea rdi, [rel state_file]   ;file path
    mov rsi, 1                  ;write to file
    mov rdx, 0
    syscall

    ;save the file descriptor
    mov r8, rax


    mov rdi, r8                 ; file descriptor for the file
    mov rax, 0x2000004          ; syscall number for write
    lea rsi, [rel state]        ; address of the string to output
    mov rdx, 201                ; length
    syscall

    ;close the file
    mov rax, 0x2000006
    mov rdi, r8
    syscall



_end:

    mov rdx, rax
    lea rax, [rel input]
    ;return to the c function
    ret





section .data

    ;user promts
    state: db "0010charlie johnny      050100022099055", 10, "0020abcdefghijklmnopqrst050100022099055", 10, "0030abcdefghijklmnopqrst050100022099055", 10, "0040abcdefghijklmnopqrst050100022099055", 10, "0050abcdefghijklmnopqrst050100022099055", 10, 0

    ;files
    state_file: db "gamestate.txt", 0 ;length 13



section .bss
    input: resb 32       ;32 bytes for the user input
    game_state: resb 80
