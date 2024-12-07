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

    mov rax, r9
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
    mov rdx, 100                 ;2 bytes to read but read 100 to prevent overflow
    syscall

    mov r9b, [rel user_selection]

    cmp r9b, 49         ;check for ascii 1
    je list_pets

    cmp r9b, 50         ;check for ascii 2
    je select_pet

    cmp r9b, 51         ;check for ascii 3
    je create_new_pet

    cmp r9b, 52         ;check for ascii 4
    je end

    jmp bad_selection

;################################# Display Pet Status #################################

display_pet:
    ;pet pointed to by r9
    ;print out the status information for the pet

    lea r8, [rel pet_display]   ;pointer to buffer for adding info
    add r9, 3                   ;move pointer by 3 to get type

    xor rax, rax                ;clear rax
    mov al, [r9]                ;get the pet type
    add r9, 1                   ;move pointer by 1

    mov rdx, [r9]               ;get first 8 bytes of the name
    mov [r8], rdx               ;save first 8 bytes of the name

    add r9, 8                   ;move pointer
    add r8, 8                   ;move pointer

    mov rdx, [r9]               ;get first 8 bytes of the name
    mov [r8], rdx               ;save first 8 bytes of the name

    add r9, 8                   ;move pointer
    add r8, 8                   ;move pointer

    mov edx, [r9]               ;get last 4 bytes of the name
    mov [r8], edx               ;save last 4 bytes

    add r9, 4                   ;move pointer
    add r8, 4                   ;move pointer

    ;call string_type

    mov rax, 0x2000004
    mov rdi, 1
    lea rsi, [rel pet_display]
    mov rdx, 28
    syscall

    ;TODO: adapt this when done
    jmp action_selection


string_type:
    ;get the string for the type since they're next to each other and 8 bytes long we can offset based on the number
    ;multiply rax with pet type by 8 to get the byte offset
    mov rdx, 8
    mul rdx

    lea rdx, [rel dead]             ;get initial address
    add rdx, rax                    ;add the offset

    mov rcx, [rdx]                  ;move the pet type into rax (8 bytes)
    mov [r8], rcx                   ;save pet type into buffer
    add r8, 8                       ;increase pointer

    ret

;################################# Select a Pet and give new Actions #################################

select_pet:
    mov rax, 0x2000004      ;syscall write
    mov rdi, 1              ;stdout
    lea rsi, [rel pet_id_selection] ;starting address of buffer
    mov rdx, 47             ;length
    syscall

    ;take user input
    mov rax, 0x2000003      ;syscall read
    mov rdi, 0              ;stdin
    lea rsi, [rel user_selection] ;starting address of buffer
    mov rdx, 100             ;length
    syscall


    ;setup address for conversion
    mov r8, rsi
    call convert_ascii_to_int

    ;return for 0
    cmp r9, 0
    je action_selection

    ;if number higher than 100 give message that id is bad
    cmp r9, 100
    jg bad_id_selection

    ;check if an index larger than amount of existing pets is accessed
    cmp r9, r11
    jg pet_not_exist

    ;calculate the position of the pet in memory
    mov rax, r9         ;number of pet
    add rax, -1         ;go one back => pets before the pet
    mov rdx, 40         ;40 bytes per pet

    mul rdx             ;get total byte count


    lea r9, [rel pet_status]        ;load initial address of pet status
    add r9, rax                      ;add the offset to get to start of the pet

    mov rsi, r9                   ; address of the string to output
    mov rax, 0x2000004          ; syscall number for write
    mov rdi, 1                  ; file descriptor 1 is stdout
    mov rdx, 40                 ; length
    syscall

    lea rsi, [rel user_input_prompt]      ; address of the string to output
    mov rax, 0x2000004          ; syscall number for write
    mov rdi, 1                  ; file descriptor 1 is stdout
    mov rdx, 37                 ; length
    syscall

    call display_pet


convert_ascii_to_int:
    ;take up to 3 ascii characters from memory starting at address r8
    ;calculate the int value and save it into r9
    mov rax, 0       ;setup rax
    mov rcx, 3       ;setup counter
    xor rdx, rdx     ;0 out rdx

int_convert_loop:
    mov dl, [r8]        ;take the first byte

    ;if newline is hit terminate early
    cmp dl, 10
    je convert_done

    ;save the rdx register so it does not get lost because of the multiplication
    push rdx
    ;multiply previous value by 10 and get the next ascii
    mov rsi, 10
    mul rsi          ;multiply rax by 10
    pop rdx   ;get the rdx register value back

    ;check if dl lower than 0 in ascii
    cmp dl, 48
    jl bad_id_selection
    ;check if dl higher than 9 in ascii
    cmp dl, 57
    jg bad_id_selection

    add dl, -48          ;subtract ascii to get int value
    add rax, rdx          ;add the int value to rax

    ;if counter hits 0 conversion is done
    add rcx, -1         ;decrement counter
    cmp rcx, 0
    je convert_done

    add r8, 1        ;move to the next byte
    jmp int_convert_loop    ;continue loop

bad_id_selection:

    mov rax, 0x2000004      ;syscall write
    mov rdi, 1              ;stdout
    lea rsi, [rel bad_id]   ;start buffer message
    mov rdx, 40             ;length
    syscall

    jmp select_pet

pet_not_exist:
    mov rax, 0x2000004      ;syscall write
    mov rdi, 1              ;stdout
    lea rsi, [rel non_existing_id]   ;start buffer message
    mov rdx, 107             ;length
    syscall

    jmp select_pet

convert_done:
    ;save the calculated value to r9
    mov r9, rax
    ret

;################################# create a new pet #################################
create_new_pet:
    ;check if 100 pets already reached
    cmp r11, 100
    je max_pets_reached

    ;get pointer to the end of pet status into r10
    call move_last_pet

type_prompt:
    ;prompt for pet type
    mov rax, 0x2000004  ;syscall write
    mov rdi, 1          ;stdout
    lea rsi, [rel pet_type] ;starting address of buffer
    mov rdx, 118        ;length
    syscall

    ;get user input
    mov rax, 0x2000003          ;syscall for read
    mov rdi, 0                  ;stdin
    lea rsi, [rel user_selection]        ;address of input
    mov rdx, 100                 ;2 bytes to read
    syscall

    mov al, byte [rel user_selection]   ;take user selection into memory

    ;check for values which are too low
    cmp al, 49                      ;ascii for 1
    jl bad_type                     ;too low give message

    ;check for values which are too high
    cmp al, 54                      ;ascii for 6
    jg bad_type                     ;too high give message
    je action_selection             ;if value is 6 return to actions

    ;save the pet ID first
    mov r9, r11
    add r9, 1
    mov r8, r10

    call convert_ascii

    mov byte [r8], al               ;save the user selection into memory
    add r8, 1                       ;move pointer by 1
    mov r10, r8                     ;move updated pointer back to r10

name_prompt:

    ;prompt for pet type
    mov rax, 0x2000004  ;syscall write
    mov rdi, 1          ;stdout
    lea rsi, [rel pet_name_prompt] ;starting address of buffer
    mov rdx, 78        ;length
    syscall


    ;get user input
    mov rax, 0x2000003          ;syscall for read
    mov rdi, 0                  ;stdin
    lea rsi, [rel user_selection]        ;address of input
    mov rdx, 100                 ;2 bytes to read
    syscall

    ;pad the name in the end with spaces
    call pad_name_input

    mov rax, [rsi]      ;first 8 bytes into register
    add rsi, 8          ;go to next bytes
    mov rdi, [rsi]      ;next 8 bytes
    add rsi, 8          ;go to next bytes
    mov esi, [rsi]      ;last 4 bytes (8 + 8 + 4 = 20)

    mov [r10], rax      ;save first 8 bytes
    add r10, 8          ;increment pointer by 8
    mov [r10], rdi      ;store next 8 bytes
    add r10, 8          ;increment pointer by 8
    mov [r10], esi      ;save last 4 bytes
    add r10, 4          ;increment pointer by 8


fill_status:
    ;for the stats set all to 0 and add a newline in the end
    mov cl, 15          ;need to set 15 0 for 5 stats 3 zeros

loop_fill:
    mov byte [r10], 48  ;save a 0 (ascii)
    add r10, 1          ;increment pointer by 1
    add cl, -1          ;decrease counter

    cmp cl, 0
    je save_pet

    jmp loop_fill

save_pet:
    mov byte [r10], 10  ;add a newline after the pet
    add r10, 1          ;increment pointer by 1

    ;amount of bytes 40(bytes per pet) * amount pets + 1 for 0 in the end + 40 for new pet
    ;to get 40 * amount we can do 32 * amount + 8 * amount
    mov r8, 41           ;setup r8 to hold amount of bytes to read
    mov rax, r11        ;amount of pets
    shl rax, 3          ;shift rax left by 3
    add r8, rax
    shl rax, 2          ;shift rax left by 2 => 3 + 2 = 5 (2^5 = 32)
    add r8, rax

    mov r9, 40          ;byte amount per pet
    mul r9              ;multiply by 40

    ;open the file to save the pet
    mov rax, 0x2000005            ;code to open
    lea rdi, [rel state_file]   ;file path
    mov rsi, 1                  ;read from file
    mov rdx, 0
    syscall

    mov r9, rax                 ;save the file descriptor

    ;write the new pet to the file
    mov rax, 0x2000004          ;syscall write
    mov rdi, r9                 ;file descriptor
    lea rsi, [rel pet_status]                ;start of pet buffer
    mov rdx, r8                 ;length of pets
    syscall


    add r10, 40                 ;reset pointer to end

    ;close the file
    mov rax, 0x2000006          ;syscall close
    mov rdi, r9                 ;file descriptor
    syscall

    ;increase pet count by 1
    add r11, 1

    jmp action_selection

pad_name_input:
    ;find newline and from there pad with spaces
    mov cl, 20     ;counter for 20 bytes
    lea r9, [rel user_selection]    ;starting address for the name input

pad_name_loop:
    cmp byte[r9], 10        ;check for newline
    je pad                  ;if found start padding

    add r9, 1               ;increase pointer
    add cl, -1              ;decreasse counter
    cmp cl, 0               ;if counter done break
    je name_done            ;break if name is 20 char

    jmp pad_name_loop       ;go to the next char

pad:
    ;pad until the end
    mov byte [r9], 32    ;save a space
    add r9, 1       ;increase pointer
    add cl, -1      ;decrease counter

    cmp cl, 0       ;check if all 20 bytes done
    je name_done    ;if all padded go back

    jmp pad         ;go to the next char

name_done:
    ret

bad_type:
    ;prompt message
    mov rax, 0x2000004          ; syscall number for write
    mov rdi, 1                  ; file descriptor 1 is stdout
    lea rsi, [rel bad_type_selection]      ; address of the string to output
    mov rdx, 40                 ; length
    syscall

    ;go back to selection
    jmp type_prompt


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

;################################# Exit the program #################################


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


;################################# Convert Int Ascii #################################
;convert a maximum of 3 digit int (1 - 999) to ascii
;the integer is given in r9, the ascii saved the memory starting at r8
convert_ascii:
    ;get the first character
    mov rax, r9         ;take r9 into rax
    xor rdx, rdx        ;clear rdx for division
    mov rcx, 100        ;divisor
    div rcx             ;quotient in rax, remainder in rdx

    add al, 48          ;convert to ascii
    mov [r8], al        ;save into address at r8

    add r8, 1           ;increase pointer by 1

    ;get the second character
    mov rax, rdx        ;move remainder to rax
    xor rdx, rdx        ;clear rdx for division
    mov rcx, 10         ;divisor
    div rcx             ;quotient in rax, remainder in rdx

    add al, 48          ;convert to ascii
    mov [r8], al        ;save the character
    add r8, 1           ;increase pointer by 1

    add rdx, 48         ;convert remainder to ascii
    mov [r8], dl        ;save the character
    add r8, 1           ;increase pointer by 1

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
    pet_type: db "What would you like your new pet to be?",10,"Please enter the number",10,"(1) Cat",10,"(2) Dog",10,"(3) Rat",10,"(4) Bird",10,"(5) Snake",10,"(6) Return",10 ;length 118
    bad_type_selection: db "You need to enter a number between 1-6", 10, 10 ;lenght 40
    pet_name_prompt: db "Please enter a name for your pet, maximum of 20 characters (rest will be cut)", 10 ;length 78

    ;pet selection prompts
    pet_id_selection: db "Please enter the id of your pet: (0) to return", 10 ;lenght 47
    bad_id: db "ID of your pet has to be in range 1-100", 10 ;length 40
    non_existing_id: db "You don't have a pet with the ID you're trying to access, try listing your pets to see which are available", 10 ;length 107

    ;pet types all padded to length 8
    dead: db " (Dead) "
    cat: db " (Cat)  "
    dog: db " (Dog)  "
    rat: db " (Rat)  "
    bird: db " (Bird) "
    snake: db " (Snake)"

section .bss
    pet_status: resb 4001
    pet_names: resb 2501

    ;user inputs
    user_selection: resb 100

    ;display pet
    pet_display: resb 190

