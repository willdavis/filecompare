; Description: recursively hexdump and compare two files (all sub-files also)
; Author: Bill Davis
; Prototype: int hexdump(file* source, file* target, file* output)
; Returns:
;	 0 = complete, no errors.
;	-1 = failed.

[SECTION .data]
debug_show_start_hexdump : db "Starting comparison for files: %x -> %x",10,0
debug_show_final_count:	db "Comparison finished! %i missmatches found",10,0
MissmatchWarning:	db "WARNING: missmatch found (source:'%x' and target:'%x')",10,0

[SECTION .txt]
extern printf
extern fgetc
extern feof
	
global hexdump

; int hexdump(file* src, file* dest, file* output)
hexdump:
	push ebp
	mov ebp, esp	;setup stack frame for this function

	sub esp,4		;local variable: inconsistency counter

	push esi
	push edi

	mov dword [ebp-4],0	;initialize counter to zero

	push edi
	push esi
	push debug_show_start_hexdump
	call printf
	add esp,12

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
	push debug_show_final_count
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