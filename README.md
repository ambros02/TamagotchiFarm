# TamagotchiFarm

A game which extends tamagotchi to multiple pets, written in assembly (Nasm x86_64 for ARM system) and some C


## Setup

### Hardware
To run this software you need a device with arm syscall architecture

### Software
- nasm
- a linker / compiler for C
  - in this project clang is used

### Run the Game
- Clone the Github repository
- From the project folder run the following to assemble and compile/link the project into an executable

```shell
nasm -f macho64 syscall_examples.asm && nasm -f macho64 userprompt.asm && clang -arch x86_64 main.c syscall_examples.o userprompt.o -o program
 ```
- To run the program then run

```shell
./program
```