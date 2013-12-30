[SECTION .data]
debug:	db "hexdump finished! %i missmatches found",10,0
MissmatchWarning:	db "Src:%x Dest:%x",10,0

[SECTION .txt]
extern printf
extern fgetc
extern feof
	
global hexdump

; int hexdump(file* src, file* dest, file* output)
hexdump:
	push ebp
	mov ebp, esp		;setup stack frame for this function
	sub esp,4		;local var: inconsistency counter

	push esi
	push edi

	mov dword [ebp-4],0	;initialize counter to zero

	;; while(A && B != EOF){
	;; 	if(A[i] != B[i])
	;; 	{
	;; 		misses++
	;; 		printf(MissmatchWarning)
	;; 	}
	;; }
.start:
	;; Check for EOF marker in the two files
	push dword [ebp+12]	;check for source EOF
	call feof
	add esp,4
	cmp eax,0
	jnz .eof

	push dword [ebp+8]	;check for destination EOF
	call feof
	add esp,4
	cmp eax,0
	jnz .eof
	
	;; Grab a character from each file and compare them
	push dword [ebp+12]
	call fgetc		;get a character from the Destination file
	add esp, 4
	mov edi, eax
	
	push dword [ebp+8]
	call fgetc		;get a character from the Source file
	add esp, 4
	mov esi, eax

	cmp esi,edi		;check if both characters are equivalent
	jnz .printErr
	jmp .start

.printErr:
	inc dword [ebp-4]	;inc the missmatch counter

	call PrintMissmatch	;print a warning
	jmp .start

.eof:
	push dword [ebp-4]	;display missmatch counter
	push debug
	call printf
	add esp,4

	mov eax,0		;set return code (no errors), and exit
	jmp .exit

.fatalError:
	mov eax,1		;set return code (error), and exit

.exit:
	pop edi
	pop esi

	leave
	ret

PrintMissmatch:
	pushad
	push edi
	push esi
	push MissmatchWarning
	call printf
	add esp,12
	popad
	ret