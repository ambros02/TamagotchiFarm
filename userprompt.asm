section .text
global _user_prompt  ; Make the function available for C to call

_user_prompt:

    ;initial user message
    mov rax, 0x2000004          ; syscall number for write
    mov rdi, 1                  ; file descriptor 1 is stdout
    lea rsi, [rel user_input_prompt]      ; address of the string to output
    mov rdx, 37                 ; length
    syscall

    call read_status            ;get pet info from file and save the count of pets into r11

    call move_last_pet          ;move pointer to the last part

    call action_selection

    mov rax, r11
    ret

;################################# Action Selection #################################
;create, select, list pets

action_selection:

    mov rax, 0x2000004          ;syscall write
    mov rdi, 1                  ;stdout
    lea rsi, [rel pet_list_selection_prompt]    ;prompt for selection
    mov rdx, 117                 ;length
    syscall

    mov rax, 0x2000003          ;syscall for read
    mov rdi, 0                  ;stdin
    lea rsi, [rel user_selection]        ;address of input
    mov rdx, 2                 ;2 bytes to read
    syscall

    mov r9b, [rel user_selection]

    cmp r9b, 49
    je list_pets

    cmp r9b, 51
    je create_new_pet

    cmp r9b, 52
    je end

    jmp bad_selection

;################################# create a new pet #################################
create_new_pet:
    ;check if 100 pets already reached
    cmp r11, 100
    je max_pets_reached

    ;get pointer to the end of pet file into r10
    call move_last_pet

    ;increase pet count by 1
    add r11, 1

    ;prompt for pet type
    mov rax, 0x2000004  ;syscall write
    mov rdi, 1          ;stdout
    lea rsi, [rel pet_type] ;starting address of buffer
    mov rdx, 107        ;length
    syscall

    ;get user input
    mov rax, 0x2000003          ;syscall for read
    mov rdi, 0                  ;stdin
    lea rsi, [rel user_selection]        ;address of input
    mov rdx, 2                 ;2 bytes to read
    syscall
    ;TODO: add error handling

    ;TODO: change this accordingly when creating works
    jmp action_selection



max_pets_reached:
    ;give message that max amount is reached
    mov rax, 0x2000004  ;syscall write
    mov rdi, 1          ;stdout
    lea rsi, [rel max_pets] ;starting buffer address
    mov rdx, 115        ;length
    syscall

    ;go back to action selection
    jmp action_selection

;################################# bad selection of action #################################
bad_selection:

    mov rax, 0x2000004      ;syscall write
    mov rdi, 1              ;stdout
    lea rsi, [rel bad_selection_input]  ;starting address of buffer
    mov rdx, 38             ;length
    syscall

    jmp action_selection    ;back to take input

;################################# List the pets #################################


list_pets:
    ;load the names of the pets
    call names_pets

    ;pet info names
    mov rax, 0x2000004          ; syscall number for write
    mov rdi, 1                  ; file descriptor 1 is stdout
    lea rsi, [rel pet_names_info]    ; address of the string to output
    mov rdx, 16                ; length
    syscall

    ;print names of pets
    mov rax, 0x2000004          ; syscall number for write
    mov rdi, 1                  ; stdout
    lea rsi, [rel pet_names]      ; address of the string to output
    mov rdx, 2501                 ; length
    syscall

    jmp action_selection


;selection:
    ;remove, feed, water, play, toilet, walk, put to bed



;################################# Move to last pet #################################
;saving last pointer in r10

move_last_pet:
    lea r10, [rel pet_status]       ;load initial address

last_pet_loop:
    cmp byte[r10], 0                ;check if 0 terminator is hit
    je last_reached

    add r10, 40                     ;go to next pet
    jmp last_pet_loop               ;loop

last_reached:
    ret

;################################# Get Pet Status #################################
;load the pet statuses into pet_status and get the pet count into r11

read_status:
    ;open the state file
    mov rax, 0x2000005            ;code to open
    lea rdi, [rel state_file]   ;file path
    mov rsi, 0                  ;read from file
    mov rdx, 0
    syscall

    ;save the file descriptor
    mov r10, rax

    ;read the content of the file
    mov rax, 0x2000003
    mov rdi, r10
    lea rsi, [rel pet_status]
    mov rdx, 4001
    syscall

    ;calculate amount of pets: total bytes read / 40 rax already has total amount of bytes
    xor rdx, rdx
    mov rcx, 40
    div rcx

    ;save the amount of bytes in r11
    mov r11, rax


    ;close the file
    mov rax, 0x2000006
    mov rdi, r10
    syscall

    ;load the names of the pets into names_pets
    call names_pets

    ;return to the calling function
    ret

;################################# Get Pet Names #################################

;save pet names in pet_names seperated by newlines
names_pets:
    lea r8, [rel pet_status]    ;pointer to pet status data
    lea r9, [rel pet_names]     ;pointer to pet names


loop_names:
    cmp byte [r8], 0                 ;check if 0 terminator is hit
    je names_done

    mov eax, [r8]               ;take first 4 bytes (number and one additional byte - but we'll overwrite it later)
    mov [r9], eax               ;save first 4 bytes (last one will get overwritten)
    add r8, 4                   ;offset to get names
    add r9, 3                   ;move pointer
    mov byte[r9], 32            ;add a space
    add r9, 1                   ;move pointer


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
    mov byte [r9], 10           ;add the newline
    add r9, 1

    add r8, 16                  ;move to next pet
    jmp loop_names

names_done:
    mov byte[r9], 0             ;0 terminate the finished string
    ret


end:
    ;goodbye message
    mov rax, 0x2000004      ;syscall write
    mov rdi, 1              ;stdout
    lea rsi, [rel exit_message] ;starting address of buffer
    mov rdx, 41             ;length
    syscall

    ;exit the program
    mov rax, 0x2000001  ;syscall for exit code
    mov rdi, 0          ;exit code 0
    syscall



amount_calculated:
    ;save the amount of pets in r10
    mov r10, rcx
    ret


section .data
    state_file: db "gamestate.txt", 0 ;length 13

    ;user promts
    pet_names_info: db "Your pets are: ", 10 ;length 16
    user_input_prompt: db "Hello and Welcome to Tamagotchi Farm", 10 ;length 37
    pet_list_selection_prompt: db 10, "Your possible actions (Select the number):", 10, "(1) List pets", 10, "(2) Select a pet", 10, "(3) Create a new pet", 10, "(4) Exit the program", 10 ;length 117
    bad_selection_input: db "Your input has to be in the range 1-4", 10 ;length 38
    exit_message: db "See you soon and don't forget your pets!", 10 ;length 41
    max_pets: db "Really sorry but your farm only supports 100 pets, if you're ready to pay 10'000 swiss francs we can talk about it", 10 ;length 115

    ;pet creation prompts
    pet_type: db "What would you like your new pet to be?",10,"Please enter the number",10,"(1) Cat",10,"(2) Dog",10,"(3) Rat",10,"(4) Bird",10,"(5) Snake", 10 ;length 107


section .bss
    user_selection: resb 2
    pet_status: resb 4001
    pet_names: resb 2501