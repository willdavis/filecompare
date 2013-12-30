FileCompare:fcomp.o hexdump.o treewalker.o
	gcc -m32 fcomp.o treewalker.o  hexdump.o -o FileCompare
fcomp.o:fcomp.asm
	nasm -f elf -g -F stabs fcomp.asm -o fcomp.o
hexdump.o:hexdump.asm
	nasm -f elf -g -F stabs hexdump.asm -o hexdump.o
treewalker.o:treewalker.asm
	nasm -f elf -g -F stabs treewalker.asm -o treewalker.o