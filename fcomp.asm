; Description: recursively hexdump and compare two files (all sub-files also)
; Author: Bill Davis
; Command Args: ./FileCompare <File1> <File2> <OutputFile>
	
[SECTION .bss]
fSrcPtr:	resd 1		;pointer to source file
fDestPtr:	resd 1		;pointer to destination file
OutFilePtr:	resd 1		;output file pointer

	
[SECTION .data]
; Error strings
missingArgError: db "ERROR: unable to parse command line arguments.  Argument(s) missing.",10,"[Correct Version]: ./FileCompare [FilePath1] [FilePath2] (OutputFile)",10,0
fileCompError:	db "ERROR: unable to compare files",10,0
openFileError:	db "ERROR: unable to open file stream",10,0

; Debug strings
debug_current_cmd_args:	db "SUCCESS: parsed command line arguments...",10,"Source path:%s",10,"Target path:%s",10,"Output path:%s",10,0
debug_print_returned_list: db "DEBUG: treewalker returned file list pointer: %x",10,0
debug_print_file_list_item: db "DEBUG: path => '%s' type => %i",10,0

; File IO mode strings
FileRead:	db "r",0
FileWrite:	db "w",0

[SECTION .text]
extern printf
extern fopen
extern fclose

extern hexdump
extern TreeWalker
	
global main

main:
	push ebp
	mov ebp,esp		; setup stackframe for main program

	;; Check if command line args are valid
	mov eax,[ebp+12]	;store arg table pointer in eax
	mov ecx,[ebp+8]		;store arg count in ecx
	cmp ecx,3		;check if there are at least 3 arguments
	jge .argsOK

	push missingArgError
	call PrintError		;Invalid args, print error and exit program
	add esp,4
	jmp .exit

; Command line arguments are valid. Parse them!
.argsOK:
	call ParseCmdArgs

	;; debug
	push dword [OutFilePtr]
	push edi
	push esi
	push debug_current_cmd_args
	call printf
	add esp,16
	;; end debug

; Open file streams.  Do not cross them!
	call OpenFiles
	cmp eax,0		;check error flag
	jz .compare		;no errors, start comparing the files

	push openFileError
	call PrintError		;print the error and exit
	add esp,4
	jmp .close

; Run the comparison test
.compare:
	push esi
	call TreeWalker
	add esp,4
	
	push eax
	call PrintFileList
	add esp,4
	
	xor eax,eax		;clear eax
	
	push edi
	call TreeWalker
	add esp,4
	
	push eax
	call PrintFileList
	add esp,4

	;; int hexdump(file* src, file* dest, file* output)
	;push dword [OutFilePtr]
	;push dword [fDestPtr]
	;push dword [fSrcPtr]
	;call hexdump
	;add esp,12
	;cmp eax,0		;check for fatal errors in hexdump

.close:
	call CloseFiles

.exit:
	leave
	ret
	
; void PrintFileList(file_list* start_node)
PrintFileList:
	push ebp
	mov ebp,esp
	
	mov eax, dword [ebp+8]
.print_file_list_loop:
	push eax			;store EAX so printf() doesn't destroy it
	
	cmp dword [eax+8],1	;check if the current typeflag is a directory (1)
	je .print_file_list_check_next_node	;don't include directories
	
	; print the current file_list* node
	push dword [eax+8]
	push dword [eax+4]
	push debug_print_file_list_item
	call printf
	add esp,12
	
.print_file_list_check_next_node:
	pop eax				;restore EAX
	cmp dword [eax], 0	;check if the next node is NULL
	je .print_file_list_exit
	
	;not a leaf node.  we must go deeper!
	mov ebx, dword [eax]	;store node->next in EBX
	mov eax, ebx			;set EAX to node->next for the next loop
	jmp .print_file_list_loop
	
.print_file_list_exit:
	leave
	ret

; void PrintError(string* str)
PrintError:
	push ebp
	mov ebp,esp
	
	push dword [ebp+8]		;push string* paramater
	call printf
	add esp,4
	
	leave
	ret

ParseCmdArgs:
	mov edx,1		;setup index for command line args (arg(0)=filename)
.start:
	push eax		
	push ecx
	push edx		;save the registers currently in use

	mov ebx, [eax+edx*4]
	cmp edx,1		;check for the 2nd command line arg
	jnz .checkArg3

	mov esi,ebx 		;store 2nd argument pointer in esi
	jmp .continue

.checkArg3:
	cmp edx,2		;check for the 3rd command line arg
	jnz .checkArg4

	mov edi,ebx 		;store 3rd argument pointer in edi
	jmp .continue

.checkArg4:
	cmp edx,3		;check for output file
	jnz .continue

	mov dword [OutFilePtr],ebx

.continue:
	pop edx
	pop ecx
	pop eax			;restore the registers
	
	inc edx
	loop .start
	ret

; Returns 0 or 1 in eax
; 1 = errors, 0 = no errors
OpenFiles:
	push FileRead
	push esi
	call fopen
	add esp,8
	cmp eax,0
	jz .error
	mov dword [fSrcPtr],eax

	push FileRead
	push edi
	call fopen
	add esp,8
	cmp eax,0
	jz .error
	mov dword [fDestPtr],eax

.exit:
	mov eax,0
	ret

.error:
	mov eax,1
	ret

CloseFiles:
	push dword [fSrcPtr]
	call fclose
	add esp,4

	push dword [fDestPtr]
	call fclose
	add esp,4

	ret