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
	
	push edi
	call TreeWalker
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