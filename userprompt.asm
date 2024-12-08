section .text
global _user_prompt  ; Make the function available for C to call

_user_prompt:

    ;amount of secconds passed in rdi
    ;divide by 64 => approximately get minutes passed, divide by 32 => approximately half hours passed
    ;2^6 & 2^5 => 64 and 32 respectively 5 + 6 = 11
    shr rdi, 11
    push rdi                    ;save the amount of ticks for later


    ;initial user message
    mov rax, 0x2000004          ; syscall number for write
    mov rdi, 1                  ; file descriptor 1 is stdout
    lea rsi, [rel user_input_prompt]      ; address of the string to output
    mov rdx, 37                 ; length
    syscall

    call read_status            ;get pet info from file and save the count of pets into r11

    ;update pet stats
    pop rdi                     ;amount of ticks
    call time_update

    ;load the names of the pets into names_pets
    call names_pets

    ;TODO: check if can be removed should be tbh
    call move_last_pet          ;move pointer to the last part

    call action_selection

    mov rax, r11
    ret


;################################# Time Updates #################################
time_update:
    push r12                ;save initial r12
    push r13                ;save initial r13 value
    push r14                ;save initial r14 value

    mov r13, rdi            ;save the tick amount
    lea r9, [rel pet_status]    ;load pointer to first pet
    mov r14, 0              ;counter for pets


food_update:
    mov r12, 0              ;offset for food
    mov rcx, 2              ;add 2 per tick
    call update

water_update:
    mov r12, 3              ;offset for water
    mov rcx, 4              ;add 4 per tick
    call update

sleep_update:
    mov r12, 6              ;offset for sleep
    mov rcx, 1              ;add 1 per tick
    call update

love_update:
    mov r12, 9               ;offset for love
    mov rcx, -1              ;sub 1 per tick
    call update

toilet_update:
    mov r12, 12             ;offset for toilet
    mov rcx, 1              ;add 1 per tick
    call update


loop_update:
    add r9, 40              ;move to the next pet
    add r14, 1              ;increase counter
    cmp r14, r11            ;check if all pets are updated
    je update_done          ;if all done finish the update
    jmp food_update         ;if some still have to be done go to next

update:
    ;set the amount to update in rcx, set the offset in r12
    mov rax, r13            ;get tick into rax to multiply
    ;don't need to 0 out rdx since overflow will not happen
    mul rcx                 ;multiply

    mov r10, rax            ;add the amount to update
    call add_stats          ;add the stats

    ret



update_done:
    ;restore original values
    pop r12
    pop r13
    pop r14

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

;################################# Actions when Pet is selected #################################

selected_actions:

    mov r8b, [r9 + 3]   ;load the pet status
    cmp r8b, 48         ;check if pet is dead
    je dead_pet

    mov rax, 0x2000004  ;syscall write
    mov rdi, 1          ;stdout
    lea rsi, [rel selected_prompt]  ;start of buffer
    mov rdx, 153        ;length
    syscall

    mov rax, 0x2000003  ;syscall read
    mov rdi, 0          ;stdin
    lea rsi, [rel user_selection]   ;start of buffer
    mov rdx, 100        ;length
    syscall

    mov al, byte [rel user_selection]   ;take user selection into memory

    cmp al, 49
    je feed

    cmp al, 50
    je water

    cmp al, 51
    je play

    cmp al, 52
    je pet

    cmp al, 53
    je bed

    cmp al, 54
    je walk

    cmp al, 55
    je potty

    cmp al, 56
    je remove_pet

    cmp al, 57
    je display_pet

    cmp al, 48
    je go_back

;preserve the r12 register when using it
;add the amounts for stats

feed:
    push r12

    ;food
    mov r10, -30
    mov r12, 0
    call add_stats

    ;love
    mov r10, 3
    mov r12, 9
    call add_stats

    ;tired
    mov r10, 7
    mov r12, 12
    call add_stats

    pop r12
    jmp selected_actions

water:
    push r12

    ;water
    mov r10, -20
    mov r12, 3
    call add_stats

    ;love
    mov r10, 2
    mov r12, 9
    call add_stats

    ;toilet
    mov r10, 10
    mov r12, 12
    call add_stats

    pop r12
    jmp selected_actions

play:
    push r12

    ;sleep
    mov r10, 20
    mov r12, 6
    call add_stats

    ;love
    mov r10, 7
    mov r12, 9
    call add_stats

    ;toilet
    mov r10, 6
    mov r12, 12
    call add_stats

    ;hunger
    mov r10, 12
    mov r12, 0
    call add_stats

    pop r12
    jmp selected_actions

pet:
    push r12

    ;love
    mov r10, 6
    mov r12, 9
    call add_stats

    pop r12
    jmp selected_actions

bed:
    push r12

    ;sleep
    mov r10, -80
    mov r12, 6
    call add_stats

    ;toilet
    mov r10, 25
    mov r12, 12
    call add_stats

    ;hunger
    mov r10, 20
    mov r12, 0
    call add_stats

    ;thirst
    mov r10, 40
    mov r12, 3
    call add_stats

    pop r12
    jmp selected_actions

walk:
    push r12

    ;love
    mov r10, 12
    mov r12, 9
    call add_stats

    ;thirst
    mov r10, 15
    mov r12, 3
    call add_stats

    ;hunger
    mov r10, 10
    mov r12, 0
    call add_stats

    ;toilet
    mov r10, -20
    mov r12, 12
    call add_stats

    ;tired
    mov r10, 20
    mov r12, 6
    call add_stats

    pop r12
    jmp selected_actions

potty:
    push r12

    ;toilet
    mov r10, -100
    mov r12, 12
    call add_stats

    pop r12
    jmp selected_actions

add_stats:
    ;offset from r12
    ;0 food, 3 water, 6 sleep, 9 love, 12 toilet
    add r9, 24                                  ;move to food
    add r9, r12                                 ;add the offset to the stat
    call convert_ascii_to_int_no_checks         ;get info from stat into rax
    sub r9, 3                                   ;reset to stat

    add rax, r10                                ;add stat
    ;make sure doesn't go below 0
check_bot_stats:
    cmp rax, 0
    jge check_top_stats
    xor rax, rax                                ;if rax goes below 0 make it 0

check_top_stats:
    cmp rax, 100
    jle continue_stats
    mov rax, 100                                ;if rax goes above 100 make it 100

continue_stats:
    mov r8, r9                                  ;move pointer to r8 for function call
    mov r9, rax                                 ;move value to r9 to save it
    call convert_ascii

    mov r9, r8                                  ;move back the pointer to pet to r9

    sub r9, 27                                  ;reset pointer to start of pet
    sub r9, r12                                 ;reset extra stat offset
    ret

go_back:
    jmp action_selection

dead_pet:
    mov rax, 0x2000004      ;syscall for write
    mov rdi, 1              ;stdout
    lea rsi, [rel dead_pet_dispose] ;buffer
    mov rdx, 83             ;length
    syscall

    mov rax, 0x2000003      ;syscall read
    mov rdi, 0              ;stdin
    lea rsi, [rel user_selection]   ;start of buffer
    mov rdx, 100            ;length
    syscall

    mov r8b, [rsi]          ;save the first input
    cmp r8b, 49             ;check for 1
    je remove_pet     ;jump back to action selection

    cmp r8b, 50             ;check for 2
    je action_selection           ;delete the pet

    jmp bad_dead_input

remove_pet:
    ;TODO: add confirmation message
    ;remove the pet pointed to by r9
    ;concatenate the other pets together in memory and update their IDs

    mov rax, 0x2000004
    mov rsi, 1
    lea rdi, [rel pet_status]
    mov rdx, 1000
    syscall

    ;get the pet ID
    call convert_ascii_to_int_no_checks
    sub r9, 3           ;reset pointer to start of pet

    mov rcx, r11        ;total amount of pets
    sub rcx, rax        ;amount of pets after this

    mov rax, rcx        ;move back for addition
    xor rdx, rdx        ;0 out rdx for multiplication
    mov rcx, 5          ;mulitplier
    mul rcx             ;multiply rax by 5 to get amount of quadwords to shift

    mov rcx, rax        ;amount of quadwords to shift

    mov rdi, r9         ;destination address
    mov rsi, r9
    add rsi, 40         ;source address
    rep movsq           ;shift the amount of rcx quadwords from rsi to rdi

    mov byte [rdi], 0        ;terminate with 0 byte

    xor rax, rax

    add rdi, 1          ;increment pointer
    mov rcx, 5          ;5 * 8 = 40
    rep stosq           ;zero out the bytes

    ;0 out the pet names
    lea rdi, [rel pet_names]    ;load address for pet names
    mov rcx, 625                ;4 * 625 = 2500
    rep stosd


    ;setup for ID update
    mov r9, 1          ;init counter to update indices
    lea r8, [rel pet_status]    ;starting address of pet status to save new ID

loop_id_update:
    call convert_ascii

    add r9, 1       ;increment count
    add r8, 37      ;move to the starting point of next pet

    cmp r9, r11
    jl loop_id_update

    sub r11, 1          ;one less pet

    jmp action_selection

bad_dead_input:
    ;message for bad selection
    mov rax, 0x2000004      ;syscall write
    mov rdi, 1              ;stdout
    lea rsi, [rel dead_pet_bad_input]   ;start of buffer
    mov rdx, 86
    syscall

    jmp dead_pet

;################################# Display Pet Status #################################

display_pet:
    ;pet pointed to by r9
    ;print out the status information for the pet

    lea r8, [rel pet_display]   ;pointer to buffer for adding info
    add r9, 3                   ;move pointer by 3 to get type

    xor rax, rax                ;clear rax
    mov al, [r9]                ;get the pet type
    sub al, 48                  ;go from ascii to int
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

    call string_type            ;get the type of pet

    call pet_needs              ;get the needs of the pet (r8 is already in position)

    ;display pet information
    mov rax, 0x2000004          ;write syscall
    mov rdi, 1                  ;stdout
    lea rsi, [rel pet_display]  ;information
    mov rdx, 184                ;length
    syscall

    sub r9, 39                 ;reset counter to the pet

    jmp selected_actions

pet_needs:
    ;add the needs of the pet to the memory buffer to display it to the user
    ;since the needs are next to each other in memory and all are 8 bytes long we can offset again
    ;(r8 is the pointer to the memory info being written to then display)
    push r12        ;save r12 to use as a counter
    mov r12, 5      ;initialize counter
    lea rdi, [rel hunger]   ;starting address for needs text

loop_needs:
    ;save the int from the 3 ascii characters coming from r8 into rax (level of needs)
    call convert_ascii_to_int_no_checks

    mov rcx, [rdi]      ;get the 8 bytes text for need
    mov [r8], rcx       ;save 8 bytes to the memory buffer
    add r8, 8           ;increase pointer
    mov byte [r8], 91   ;add a [
    add r8, 1           ;increase pointer
    mov rcx, 20         ;counter to keep track of how many are filled

loop_display:
    ;idea show up to 20 # to show a filled bar 0 => (0-4), 20 => 100
    sub rax, 5         ;decrease need by 5

    cmp rax, 0          ;if need is below 0 pad the rest
    jl pad_display

    mov byte [r8], 35   ;add a #
    add r8, 1           ;increase pointer
    sub rcx, 1         ;decrease counter

    jmp loop_display    ;loop again



pad_display:
    ;for the values remainging in rcx add a space
    cmp rcx, 0          ;if all the values are done end the string
    je display_done

    mov byte [r8], 32   ;add a space
    add r8, 1           ;increase pointer
    sub rcx, 1         ;decrease counter

    jmp pad_display

display_done:
    mov word [r8], 0x0A5D    ;add ]\n to the end
    add r8, 2                ;increment pointer
    add rdi, 8          ;go to the next need text
    ;note r8 updates automatically from the function
    sub r12, 1         ;decrement overall counter
    cmp r12, 0
    je needs_done       ;if all needs are in memory return

    jmp loop_needs

needs_done:

    pop r12             ;restore r12
    ret


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

    mov byte [r8], 10               ;add a newline
    add r8, 1                       ;move pointer

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
    sub rax, 1         ;go one back => pets before the pet
    mov rdx, 40         ;40 bytes per pet

    mul rdx             ;get total byte count


    lea r9, [rel pet_status]        ;load initial address of pet status
    add r9, rax                      ;add the offset to get to start of the pet

    mov rsi, r9                   ; address of the string to output
    mov rax, 0x2000004          ; syscall number for write
    mov rdi, 1                  ; file descriptor 1 is stdout
    mov rdx, 40                 ; length
    syscall

    jmp display_pet


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

;################################# Convert 3 ASCII to int #################################
convert_ascii_to_int_no_checks:
    ;take 3 ascii characters from memory starting at address r9 without checks
    ;calculate the int value and save it into rax
    mov rax, 0       ;setup rax
    mov rcx, 3       ;setup counter
    xor rdx, rdx     ;0 out rdx

int_convert_loop_no_check:
    mov rsi, 10
    mul rsi          ;multiply rax by 10

    mov dl, [r9]     ;take the first byte
    add r9, 1        ;move to the next byte

    sub dl, 48          ;subtract ascii to get int value
    add rax, rdx         ;add the int value to rax

    ;if counter hits 0 conversion is done
    sub rcx, 1         ;decrement counter
    cmp rcx, 0
    je convert_done_no_check

    jmp int_convert_loop_no_check    ;continue loop

convert_done_no_check:
    ret

convert_ascii_to_int:
    ;use this for inputs, it terminates early when a newline is hit and checks if the nubmers are digits
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

    sub dl, 48          ;subtract ascii to get int value
    add rax, rdx          ;add the int value to rax

    ;if counter hits 0 conversion is done
    sub rcx, 1         ;decrement counter
    cmp rcx, 0
    je convert_done

    add r8, 1        ;move to the next byte
    jmp int_convert_loop    ;continue loop

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

    push rax                        ;save rax to hold pet type
    call convert_ascii              ;convert the input to ascii
    pop rax                         ;get rax back

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
    sub cl, 1          ;decrease counter

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
    sub cl, 1              ;decreasse counter
    cmp cl, 0               ;if counter done break
    je name_done            ;break if name is 20 char

    jmp pad_name_loop       ;go to the next char

pad:
    ;pad until the end
    mov byte [r9], 32    ;save a space
    add r9, 1       ;increase pointer
    sub cl, 1      ;decrease counter

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

    mov rax, 0x2000005            ;code to open
    lea rdi, [rel state_file]   ;file path
    mov rsi, 2                  ;write to file
    mov rdx, 0
    syscall

    ;save the file descriptor
    mov r8, rax


    mov rax, r11            ;amount of pets
    mov rdx, 40             ;amount bytes per pet
    mul rdx                 ;multiply rax by 40
    add rax, 1              ;add 1 for the nul terminator

    mov rdx, rax                ;length
    mov rax, 0x2000004          ;syscall write
    mov rdi, r8                 ;file descriptor
    lea rsi, [rel pet_status]   ;start of the buffer
    syscall

    ;same system call as in testa.asm but different behavior somehow
    ;mov rax, 0x20000C9          ;syscall ftruncate
    ;mov rdi, r8                 ;file descriptor
    ;mov rdx, 500
    ;syscall

    ;close the file
    mov rax, 0x2000006
    mov rdi, r8
    syscall


    ;goodbye message
    mov rax, 0x2000004      ;syscall write
    mov rdi, 1              ;stdout
    lea rsi, [rel exit_message] ;starting address of buffer
    mov rdx, 41             ;length
    syscall

    ;exit the program
    mov rax, r11
    ret


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

    ;selected pet actions
    selected_prompt: db "What would you like to do with your pet?",10,"(1) Feed",10,"(2) Water",10,"(3) Play",10,"(4) Pet",10,"(5) Put to bed",10,"(6) Walk",10,"(7) Potty",10,"(8) Dispose",10,"(9) Display status",10,"(0) Return",10 ;length 153
    dead_pet_dispose: db "Unfortunately your pet has died do you want to dispose of it?",10,"(1) Dispose",10,"(2) Keep",10 ;length 83
    dead_pet_bad_input: db "You need to either dispose of the dead pet or keep it (but that would be kinda cruel)", 10 ;length 86

    ;pet types all padded to length 8
    dead: db " (Dead) "
    cat: db " (Cat)  "
    dog: db " (Dog)  "
    rat: db " (Rat)  "
    bird: db " (Bird) "
    snake: db " (Snake)"

    ;pet needs all padded to length 8
    hunger: db "Hunger: "
    thirst: db "Thirst: "
    sleep: db "Sleep:  "
    love: db "Love:   "
    toilet: db "Toilet: "

section .bss
    pet_status: resb 4001
    pet_names: resb 2501

    ;user inputs
    user_selection: resb 100

    ;display pet
    pet_display: resb 184

