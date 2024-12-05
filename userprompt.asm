section .text
global _user_prompt  ; Make the function available for C to call

_user_prompt:

    ;initial user message
    mov rax, 0x2000004          ; syscall number for write
    mov rdi, 1                  ; file descriptor 1 is stdout
    lea rsi, [rel user_input_prompt]      ; address of the string to output
    mov rdx, 37                 ; length
    syscall


;################################# Get Pet Status #################################
read_status:
    ;open the state file
    mov rax, 0x2000005            ;code to open
    lea rdi, [rel state_file]   ;file path
    mov rsi, 0                  ;read from file
    mov rdx, 0
    syscall

    ;save the file descriptor
    mov r11, rax

    ;read the content of the file
    mov rax, 0x2000003
    mov rdi, r11
    lea rsi, [rel pet_status]
    mov rdx, 4001
    syscall

    ;close the file
    mov rax, 0x2000006
    mov rdi, r11
    syscall

    call amount_pets    ;calculate the number of pets


    call names_pets

    ;pet info names
    mov rax, 0x2000004          ; syscall number for write
    mov rdi, 1                  ; file descriptor 1 is stdout
    lea rsi, [rel pet_names_info]    ; address of the string to output
    mov rdx, 17                ; length
    syscall
    ;pet names
    mov rax, 0x2000004          ; syscall number for write
    mov rdi, 1                  ; file descriptor 1 is stdout
    lea rsi, [rel pet_names]    ; address of the string to output
    mov rdx, 211                ; length
    syscall

    ;return to the c function
    mov rax, r10
    ret

;################################# Get Pet Names #################################

;save pet names in pet_names seperated by newlines
names_pets:
    lea r8, [rel pet_status]    ;pointer to pet status data

    lea r9, [rel pet_names]     ;pointer to pet names

    add r8, 4                   ;offset to get names


loop_names:
    cmp byte [r8], 0                 ;check if 0 terminator is hit
    je names_done

    mov rcx, 20                 ;bytes to skip

    mov rax, [r8]               ;load first 8 bytes
    mov [r9], rax               ;move first 8 bytes

    add r8, 8                   ;move by 8 bytes
    add r9, 8                   ;move by 8 bytes
    mov rax, [r8]               ;load next 8 bytes
    mov [r9], rax               ;move next 8 bytes

    add r8, 8                   ;move by 8 bytes
    add r9, 8                   ;move by 8 bytes
    mov eax, [r8]               ;load last 4 bytes (8 + 8 + 4 = 20)
    mov [r9], eax               ;move last 4 bytes

    add r8, 4                   ;move 4 bytes
    add r9, 4                   ;move 4 bytes

    add r9, 1                   ;go to the next byte
    mov byte [r9], 10                ;add the newline
    add r9, 1

    add r8, 20                  ;move to next pet
    jmp loop_names

names_done:
    ret



;################################# Pet Count #################################

;caluclate amount of pets and save into r10
amount_pets:
    mov rcx, 0                  ;counter for amount of pets
    lea r8, [rel pet_status]    ;get the status info
    add r8, 1                   ;offset by 1 to land in the 0 byte

loop_amount:
    cmp byte [r8], 0            ;compare to check if last byte is reached
    je amount_calculated        ;finish if the last is reached

    inc rcx                     ;increment counter by one
    add r8, 40                  ;move to the next pet

    jmp loop_amount

amount_calculated:
    ;save the amount of pets in r10
    mov r10, rcx
    ret


section .data
    state_file: db "gamestate.txt", 0 ;length 13

    ;user promts
    pet_names_info: db "Your pets are: ", 10 ;length 16

    user_input_prompt: db "Hello and Welcome to Tamagotchi Farm", 10 ;lenght 37



section .bss
    pet_status: resb 4001
    pet_names: resb 211