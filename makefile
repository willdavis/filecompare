MAKE_X32=-m32
NASM_FLAGS=-f elf -g -F stabs

all:fcomp.o hexdump.o treewalker.o
	gcc $(MAKE_X32) fcomp.o treewalker.o  hexdump.o -o FileCompare
fcomp.o:fcomp.asm
	nasm $(NASM_FLAGS) fcomp.asm -o fcomp.o
hexdump.o:hexdump.asm
	nasm $(NASM_FLAGS) hexdump.asm -o hexdump.o
treewalker.o:treewalker.asm
	nasm $(NASM_FLAGS) treewalker.asm -o treewalker.o
clean:
	rm -rf *o FileCompare