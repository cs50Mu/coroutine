main: main.c coroutine.o
	gcc -Wall -Wextra -o main main.c coroutine.o

coroutine.o: coroutine.c
	gcc -Wall -Wextra -c coroutine.c

# prove of concept of the coroutine idea in assembly
poc: poc.asm
	/home/linuxfish/bin/fasm poc.asm && ./poc
