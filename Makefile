main: main.o coroutine.o
	ld -o main main.o coroutine.o /usr/lib/x86_64-linux-gnu/crt1.o -lc -dynamic-linker /lib64/ld-linux-x86-64.so.2

coroutine.o: coroutine.asm
	/home/linuxfish/bin/fasm coroutine.asm

main_new: main_new.c coroutine_new.o
	gcc -Wall -Wextra -ggdb -o main_new main_new.c coroutine_new.o

coroutine_new.o: coroutine_new.asm
	/home/linuxfish/bin/fasm coroutine_new.asm

# prove of concept of the coroutine idea in assembly
poc: poc.asm
	/home/linuxfish/bin/fasm poc.asm && ./poc
