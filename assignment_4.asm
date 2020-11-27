;TITLE Assignment 4    (assignment_4.asm)

; Author: Allison Skinner
; Last Modified: 8/2/2020
; OSU email address: skinneal@oregonstate.edu
; Course number/section: CS271-400
; Assignment Number: #4                Due Date: 8/2/2020
; Description: Get a user request in the range [min=10..max=200].
; Generate request random integers in the range [lo=100..hi=999], store in array.
; Display list of integers before sorting, 10 numbers per line.
; Sort the list in descending order.
; Calculate and display the median value rounded to the nearest integer.
; Display the sorted list, 10 numbers per line.

INCLUDE Irvine32.inc

;Constants
	MIN EQU <10>
	MAX EQU <200>
	LO	EQU <100>
	HI	EQU <999>
	MAX_SIZE EQU <200>	;array size


.data

programTitle	BYTE	"Program Title: Sorting Random Integers (Assignment #4):", 0
programmer		BYTE	"Name: Allison Skinner", 0
instructions	BYTE	"This program generates random numbers in the range [100..999], ", 0
instructions2	BYTE	"displays the original list, sorts the list, and calculates the ", 0
instructions3	BYTE	"median value. Then, it displays the list sorted in descending order. ", 0
prompt			BYTE	"How many numbers do you want to generate? [10-200]: ", 0
validMessage	BYTE	"Good choice.", 0 
errorMessage	BYTE	"Invalid input. Try again. ", 0	
goodbyeMessage	BYTE	"Thank you. Have a nice day! ", 0
EC_2			BYTE	"**EC: Used a recursive sorting algorithm (QuickSort)",0
EC_5			BYTE	"**EC: Changed color scheme to white and red. Go Blazers!", 0

request			DWORD	? ;user input for amount of numbers to generate
leftMost		DWORD	0 ;left most value in array, 0
rightMost		DWORD	? ;right most value in array, request - 1

array			DWORD	MAX	DUP(?)	;unitialized array, capacity 200

sorted			BYTE	"Sorted List: ", 0
unsorted		BYTE	"Unsorted List: ", 0
printMed		BYTE	"Median: ", 0

spacing			BYTE	"     ", 0


.code

main PROC

	;seed random number generator
	call Randomize

	;introduction
	call introduction

	;get data
	push OFFSET request
	call getData

	;get fill array
	push OFFSET array
	push request
	call fillArray

	;calculate the right most value's index in the array using user input, request (rightMost = request -1) 
	mov		eax, request
	dec		eax
	mov		rightMost, eax
	mov		eax, rightMost
	call	WriteDec	
	call	Crlf

	;display unsorted list
	push OFFSET unsorted
	push OFFSET array
	push request
	call displayList

	;sort list
	push	rightMost
	push	leftMost
	push	OFFSET array
	call	sortList
	push	rightMost
	push	OFFSET array
	call	reverse

	;display median
	push	OFFSET printMed
	push	request
	push	OFFSET array
	call	displayMedian

	;display sorted list
	push	OFFSET sorted
	push	OFFSET array
	push	request
	call	displayList

	;display goodbye message
	push OFFSET goodbyeMessage
	call goodbye

	exit	; exit to operating system

main ENDP

introduction PROC

	;Display program title
		mov edx, OFFSET programTitle
		call WriteString
		call Crlf
		call Crlf

	;Display programmer
		mov edx, OFFSET programmer
		call WriteString
		call Crlf

	;Display instructions
		mov edx, OFFSET instructions
		call WriteString
		call Crlf
		mov edx, OFFSET instructions2
		call WriteString
		call Crlf
		mov edx, OFFSET instructions3
		call WriteString
		call Crlf
		call Crlf

	;Display extra credit
		call	CrLf
		mov		edx, OFFSET EC_2
		call	WriteString				
		call	CrLf
		mov		edx, OFFSET EC_5	
		call	WriteString				
		call	CrLf
		call	CrLf

		mov eax, white+(red*16)
		call	SetTextColor	;set to Blazers color scheme

	ret

introduction ENDP

getData PROC

	push ebp	;push old ebp+4
	mov ebp, esp	;set stack frame pointer
	mov ebx, [ebp + 8]	;location of request's address+4 in ebx, ebx points to it

	;Ask user for number
		validationLoop:
			mov edx, OFFSET prompt
			call WriteString
			call ReadInt
			mov [ebx], eax	;store user input at address in ebx

			cmp eax, MIN	;check condition 1
			jl falseBlock	;number < lower limit
			cmp eax, MAX	;check condition 2
			jg falseBlock	;number > upper limit

		;trueBlock:
			mov edx, OFFSET validMessage ;"Good choice"
			call WriteString
			call Crlf
			jmp endBlock

		falseBlock:
			mov	edx, OFFSET errorMessage ;"Invalid input. Try again."
			call WriteString
			call CrLf

			jmp validationLoop

		endBlock:
			pop ebp		;restore stack
			ret 4	; return bytes pushed before the call

getData ENDP

fillArray PROC

	push ebp	;set stack frame
	mov ebp, esp	
	mov edi, [ebp+12]	;address of beginning of array in edi
	mov ecx, [ebp+8]	;request as count in ecx
	
		again:	;loop for adding random numbers to array
			mov		eax, HI					;999				
			sub		eax, LO					;999 - 100 = 899
			inc		eax						;900
			call	RandomRange				;eax is [0, 900 - 1] => [0, 899]
			add		eax, LO					;eax is [100, 999]

			;add random number to array
			mov		[edi], eax
			add		edi, 4
			loop	again

	pop ebp	;restore stack
	ret 8	;return bytes pushed before the call

fillArray ENDP

sortList PROC

	pushad
	mov ebp, esp

	sub esp, 12
	i_local	EQU	DWORD PTR [ebp-4]
	j_local	EQU	DWORD PTR [ebp-8]
	pivot_local	EQU	DWORD PTR [ebp-12]

	mov edx, [ebp+44]	;rightmost index in edx
	mov ecx, [ebp+40]	;leftmost index in ecx
	mov esi, [ebp+36]	;address to array in esi

	;set up i and j
	mov i_local, ecx	;i = initial low index of array
	mov j_local, edx	;j = initial high index of array

	;set pivot as midpoint of array
	mov eax, ecx	;eax = i
	add eax, edx	;eax = i = i + j
	cdq				;edx = 0
	mov ebx, 2		;ebx = 2
	div ebx			;eax/ebx => quotient in eax, remainder in edx
	mov ecx, [esi+eax*4]
	mov pivot_local, ecx

	L1: ;while(i <= j), leftMost is less than or equal to rightMost
		mov eax, i_local
		cmp eax, j_local
		jg endL1				;jump if greater (leftOp > rightOp)

	L2: ;while(array[i] < pivot) => increment i
		mov ecx, i_local
		mov eax, [esi+ecx*4]	;move value of array[i] into eax
		cmp eax, pivot_local
		jge endL2				;jump is greater than or equal
		inc i_local
		jmp L2					;continue loop
	endL2:

	L3:	;while(array[j] > array[pivot]) => decrement j
		mov ecx, j_local
		mov eax, [esi+ecx*4]	;move value of array[j] into eax
		cmp eax, pivot_local
		jle endL3				;jump is less than or equal
		dec j_local
		jmp L3					;continue loop
	endL3:

	;compare i and j
	mov ecx, i_local
	mov ebx, j_local
	cmp ecx, ebx
	jg endCompare

	;swap array[i] and array[j] elements as i is less than or equal to j, then inc i and dec j
	mov ecx, i_local
	mov ebx, j_local
	mov esi, [ebp+36]			;address of array in esi
	lea edi, [esi+ecx*4]		;load address of array[i] in edi
	push edi
	lea edi, [esi+ebx*4]		;load address of array[j] in edi
	push edi
	call swap
	inc i_local
	dec j_local

	endCompare:
		jmp L1

	endL1: ;quicksort is recursive, here is the recursion component of the algorithm
		mov eax, [ebp+40]		;move leftMost into eax
		cmp eax, j_local
		jge byPass				;leftMost is greater than or equal to rightMost
		mov ebx, j_local
		push ebx				;push rightMost j index
		push eax				;push leftMost i index
		push esi				;push address of array
		call sortList

	byPass:
		mov eax, [ebp+44]		;move rightMost ino eax
		cmp i_local, eax
		jge endQuickSort
		mov ebx, i_local
		push eax
		push ebx
		push esi
		call sortList

	endQuickSort:
		mov esp, ebp			;clear local variables from stack
		popad					;restore general purpose registers
		ret 12

sortList ENDP

swap PROC

	push ebp	;set up stack frame
	mov ebp, esp
	pushad	;save general purpose registers

	;set up array registers for swap
	mov esi, [ebp+8]	;address of specific source array element 
	mov edi, [ebp+12]	;address of specific destination array element

	;perform swap
	mov eax, [esi]	;eax now has source array element value
	mov ebx, [edi]	;ebx now has destination array element value
	mov [esi], ebx	;destination value, ebx ---> replaces source value [esi]
	mov [edi], eax	;source value, eax ---> replaces destination value [edi]

	popad	;restore general purpose registers
	pop ebp
	ret 8

swap ENDP

reverse PROC

	push ebp
	mov ebp, esp

	;Create space for 2 local variable, i, j.
	;Where i and j are the left and right indexes of the array, respectively
	sub esp, 8
	i_local	EQU DWORD PTR [ebp-4]
	j_local	EQU DWORD PTR [ebp-8]

	mov esi, [ebp+8]	;address of array is in esi
	mov ecx, 0	;left most array index is in ecx
	mov ebx, [ebp+12]	;right most array index is in ebx

	;set up i and j with their values
	mov i_local, ecx	;i = initial low index of array, leftMost
	mov j_local, ebx	;j = initial high index of array, rightMost

	;check if the rightMost index is even
	mov ecx, [ebp+12]	;request (size of array) in ecx

	;check if right most array index is odd
	mov eax, ebx	;rightMost index is in now eax
	cdq
	mov ebx, 2
	div ebx	;eax/ebx => quotient in eax, remainder in edx, no change ebx
	cmp edx, 1	;compare the remainder with 1. 1 means the right most array index is odd
	jne oddReversal	;right most index is even, there is an odd number of elements in the array

	evenReversal: ;there is an even number of elements in the array 
		mov ecx, i_local
		mov ebx, j_local
		lea edi, [esi+ecx*4]	;load address of array[i] in edi
		push edi
		lea edi, [esi+ebx*4]	;load address of array[j] in edi
		push edi
		call swap

		inc i_local				;increment i (left index)
		dec j_local				;decrement j (left index)
		mov ecx, i_local
		mov ebx, j_local

		;check if the swap has reached the two middle values
		inc ecx
		cmp ecx, ebx
		jl evenReversal

		;swap the remaining two middle values
		mov ecx, i_local
		mov ebx, j_local
		inc ecx
		dec ebx
		lea edi, [esi+ecx*4]	;load address of array[i] in edi
		push edi
		lea edi, [esi+ebx*4]	;load address of array[j] in edi
		push edi
		call swap

		jmp endReversal

	oddReversal: ;there is an odd number of elements in the array 
		mov ecx, i_local
		mov ebx, j_local
		lea edi, [esi+ecx*4]	;load address of array[i] in edi
		push edi
		lea edi, [esi+ebx*4]	;load address of array[j] in edi
		push edi
		call swap

		inc i_local				;increment i (left index)
		dec j_local				;decrement j (left index)
		mov ecx, i_local
		mov ebx, j_local
		cmp ecx, ebx			;check if the swap has reached the absolute middle
		jne oddReversal

	endReversal:
		mov esp, ebp			;clear local variables from stack
		pop ebp
		ret 12

reverse ENDP

displayMedian PROC
	push ebp
	mov ebp, esp	;set up stack frame

	;print list tile
	call Crlf
	mov edx, [ebp+16]	;address of sorted is in edx
	call WriteString
	call Crlf

	mov esi, [ebp+8]	;(starting) address of array in esi
	mov ecx, [ebp+12]	;request (size of array) in ecx

	;check if the number of elements in the array is odd
	mov eax, ecx
	cdq
	mov ebx, 2
	div ebx	;eax/ebx => quotient in eax, remainder in edx, no change ebx
	cmp edx, 1 ;compare the remainder with 1. 1 = odd
	je oddArray	;median will by the middle number of the array
	
	;else the number of elements is even
	mov ebx, eax
	dec ebx	;the median is now between ebx and eax
	mov ecx, [esi+ecx*4]	;put the right median value in ecx
	mov edx, [esi+ebx*4]	;put the left median value in edx
	add ecx, edx	;the sum of the two values is now in ecx

	;calculate and display median to the nearest integer for an even number of elements
	mov eax, ecx
	cdq
	mov ebx, 2
	div ebx
	div ebx	;eax/ebx => quotient in eax, remainder in edx, no change ebx
	call WriteDec

	jmp endDisplayMedian

	;display the median for an odd number off elements
	oddArray:			;middle array index is in eax
		mov ebx, eax	;move the middle array index into ebx
		mov eax, [esi+ebx*4]
		call WriteDec

	endDisplayMedian:
		call Crlf
		pop ebp
		ret 12

displayMedian ENDP

displayList PROC

	push ebp
	mov ebp, esp	;set up stack frame

	;print the list title
	call Crlf
	mov edx, [ebp+16]	;address of unsorted is in edx
	call WriteString
	call Crlf

	;set up other parameters
	mov esi, [ebp+12]	;(starting) address of array in esi
	mov ecx, [ebp+8]	;address of request (size, count) in ecx
	mov ebx, 0	;terms per line counter

	more:
		mov eax, [esi]			;get current element
		call WriteDec
		mov edx, OFFSET spacing	;puts spaces between terms
		call WriteString
		add esi, 4				;next element
	
		;manage terms per line
		inc ebx
		cmp ebx, 10
		je newLine
		jmp resume

	newLine:
		call Crlf
		mov ebx, 0

	resume:
		loop more

	endMore:
		pop ebp
		ret 12

displayList ENDP

goodbye PROC
	push ebp
	mov ebp, esp	;set up stack frame

	;print goodbye message
	call Crlf
	call Crlf
	mov edx, [ebp+12]	;address of goodbye message is in edx
	call WriteString
	call Crlf

	call Crlf
	mov edx, [ebp+8]	;address of goodbye message is in edx
	call WriteString
	call Crlf

	pop ebp
	ret 8

goodbye ENDP

END main
