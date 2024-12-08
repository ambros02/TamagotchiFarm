;NOTE
;This file is not part of the program, but instead is here for informatory purposes
;check the readme for additional information
;if you run this file your gamestate.txt can become inconsistent (SAVE IT BEFORE!)
;##################################


section .text
global _take_user_input  ; Make the function available for C to call

_take_user_input:


    ;open the state file
    mov rax, 0x2000005            ;code to open
    lea rdi, [rel state_file]   ;file path
    mov rsi, 2                  ;write to file
    mov rdx, 0
    syscall

    ;save the file descriptor
    mov r8, rax

    ;mov rax, 0x20000C9          ;syscall ftruncate
    ;mov rdi, r8                 ;file descriptor
    ;mov rdx, 41                 ;length
    ;syscall



    ;close the file
    mov rax, 0x2000006
    mov rdi, r8
    syscall

    mov rax, 0x2000074          ;syscall for gettimeofday
    lea rdi, [rel timeval]      ;address to save the value
    syscall

    mov r11, rax        ;save return value from gettimeofday


_end:
    mov rdx, r11
    lea rax, [rel input]
    ;return to the c function
    ret


section .data
    ;files
    state_file: db "gamestate.txt", 0 ;length 13

section .bss
    input: resb 32       ;32 bytes for the user input
    timeval: resb 16
