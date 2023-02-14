#!/bin/bash

nasm -f elf64 -g projataketwoYMM2.asm 
ld -o projataketwoYMM2 projataketwoYMM2.o

nasm -f elf64 -g projataketwoYMMP.asm 
ld -o projataketwoYMMP projataketwoYMMP.o

gcc gen2.c
./a.out

gcc -o mainDouble mainDouble.c

gcc -O0 -o mainO0 mainDouble.c
gcc -O1 -o mainO1 mainDouble.c
gcc -O2 -o mainO2 mainDouble.c
gcc -O3 -o mainO3 mainDouble.c
gcc -Ofast -o mainOfast mainDouble.c
gcc -ofastmavx -o mainOfastmavx mainDouble.c


