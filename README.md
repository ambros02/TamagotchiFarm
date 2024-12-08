# Tamagotchi Farm

A game which extends tamagotchi to multiple pets, written in assembly (Nasm x86_64 for ARM system) and some C

## For Users
- See how to play the game [here](#run-the-game)
- Make sure to always terminate the game properly over the console, or your progress will not get saved
- Do not touch the gamestate.txt or gametime.txt file if you do not know what you are doing or you risk the game breaking
- Only input ASCII character
- Do not input more than 100 characters at a time

### Overview

This game is all about you and your beloved animals. You can create new animals name and nurture them. Up to 100 animals
can make your farm an amazing place. But be careful to not overdo it or your animals might suffer a fatal death due to a
lack of food, water, sleep, love or possibilities to relieve themselves.

### Setup

#### Hardware
To run this software you need a device with arm architecture (or equivalent vm which has the same syscall convention/codes)

#### Software
- nasm
- a linker / compiler for C
  - in this project clang is used

#### Run the Game
- Clone the Github repository
- From the project folder run the following to assemble and compile/link the project into an executable
  - note that clang is used, if you use another compiler/linker change it accordingly

```shell
nasm -f macho64 syscall_examples.asm && nasm -f macho64 userprompt.asm && clang -arch x86_64 main.c syscall_examples.o userprompt.o -o program
 ```
- To run the program then run

```shell
./program
```

## For Developers

Please read this guide and make sure that you have a debugger if you are coding in assembly.

### Overview
The game is developed in nasm x86_64 syntax for arm architecture to allow easier transition between arm and x86 systems. The Idea was, that arm 
has emulators (such as rosetta 2 for macos) which allow to run x86 architecture software. In theory only the system call 
numbers would need to be adapted to the kernel to run on a native x86 system, however depending on the implementation parameters 
and return values are stored at different locations. Therefore if you want to adapt the implementation for another architecture 
make sure to understand the differences first.

### Implementation
Generally mostly simple instructions were used. The conventions for register usage was purposefully broken. Specifically 
register r8-r11 are being used by functions to pass specific parameters. The idea was to remove unnecessary overhead and confusing mov 
instructions, but in hindsight as the code grew this was probably a bad idea, because of the growing complexity, since the overhead 
becomes negligible, but the time to learn the conventions and the possibilities to make mistakes increase significantly. (Patterns 
do exist for a reason it seems) Additionally the sizes for the strings are hardcoded, meaning if a string in the .data section 
is adapted, also the write calls using it have to be adapted for the new size. This allows to save a memory access when using the write syscall resulting 
in slightly better performance. Lastly some ascii art was used, even though this introduces overhead in performance and size.
(In the end I just could not resist and it makes it look nicer)

### Why the C file
The C file is crucial for handling the timestamp and the truncation of the file. Since the system calls for this did not 
work for the arm architecture. For illustration purposes the [syscall_examples](syscall_examples.asm) file was left in the 
repository. Feel free to uncomment the call to take_user_input in the [main.c](main.c) file to test it. the syscall_examples 
also features a system call to gettimeofday which did not work either. If you manage to get it to work please contact me 
so I can learn where I went wrong.

My current theory why the syscalls are not working is because of rosetta 2 which can not properly map the syscalls to the 
arm architecture. I tripple checked the syscall numbers and parameters. Furthermore the ftruncation system call behaves differently 
when called from [syscall_examples](syscall_examples.asm) or [userprompt.asm](userprompt.asm). It even behaves differently in 
syscall_examples when the file is opened in write mode or in read/write mode. To find the syscall in userprompt.asm search for 
0x20000C9 (syscall code for ftruncate).

If you would like to debug this and need information about the different behaviors please do not hesitate to contact me.

#### main.c

The entry point is in the [main file](main.c). The function also fetches the time from the [time file](gametime.txt) 
and compares it to a current timestamp. Based on this time the pet stats get updated. Furthermore it also truncates 
the content of the [gamestate file](gamestate.txt) where the information about the pets is persisted.

#### userprompt.asm

This file is the core heart. It contains all the logic to run the game. It prompts the user for inputs and processes it 
accordingly. Furthermore it updates the status of the pets. This is achieved by loading the state of the pets from the 
[gamestate file](gamestate.txt) into memory at the start. From there all the updates are done in memory and when the program is exited 
the information gets written back to the file. (This means if the program is interrupted by the user all changes get lost). 
However this should normally not pose a problem, since the program only allows to terminate by exiting properly. 
Obviously the user can still force quit the terminal but this is in the users responsibility. Handling of inconsistent 
states in [gamestate](gamestate.txt) and [gametime](gametime.txt) is not implemented, but could be done in the future. 

#### gamestate.txt

In this file the state of the pets is persisted. It follows a convention where each pet occupies one line which takes 
exactly 40 bytes. This allows to find the pets in the memory and also in the file by a fixed offset. This is nice for 
assembly and speed, but introduces limitations such as on the number of pets and stats and name length. As of now 100 
pets are allowed but this could easily be extended to 999, crossing a mark which requires more bytes would require greater 
effort. The information is stored as follows (in order, the list shows size, type and value range):
- 3 bytes: PetID (1-100)
- 1 byte: Pet type (0-5)
  - 0: dead
  - 1: cat
  - 2: dog
  - 3: rat
  - 4: bird
  - 5: snake
- 20 bytes: Pet name (any Ascii character)
- 3 bytes: Hunger level (0-200)
- 3 bytes: Thirst level (0-200)
- 3 bytes: Sleep level (0-200)
- 3 bytes: Love level (0-200)
- 3 bytes: Toilet level (0-200)

**important**: in the end after all pets there is a 0 terminator which is needed to find the end

#### gametime.txt
This file simply holds a time stamp of when the game was last opened to adapt the stats of the pets when you are gone. 
In the future this could be changed that it saves the timestamp when the application is exited (would be more logical).

## Acknowledgements
- Thanks to my fellow student for his assignment which taught me key aspects, without which I could have not realized this project
- Thanks to my sister for testing my game
- Thanks to the awesome people doing [ASCII art](https://www.asciiart.eu) and providing it
- Big Thanks to all the people who implemented the [lldb](https://lldb.llvm.org) debugger, you saved me a great deal of time and sanity