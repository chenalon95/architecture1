
section	.rodata                                                                          ; we define (global) read-only variables in .rodata section
overflow_string: db "Error: Operand Stack Overflow", 10, 0                           ; format string
emptystack_string: db "Error: Insufficient Number of Arguments on Stack", 10, 0      ; format string
input_error_string:db "Error: Input is invalid", 10, 0
positivePowerString: db "wrong Y value", 10, 0
format_string: db "%s",0	; format string
debugString1: db "Number received is: ", 0
newLine: db "",10,0
debugString2: db "Result is: ", 0
debugS: db "-d",0



section	.data
numOfSlots: equ 5
_top: dd 0
num1: db 0                      ; link's data
num2: db 0                      ; link's data
number_of_operations: dd 0
dMode: db 0


section .bss                    ; we define (global) uninitialized variables in .bss section
result: resb 4
reversedResult: resb 4
input: resb 82
operand_stack: resb 4*numOfSlots
topOp: resb 4
input_len: resb 4
firstCopy: resb 4
secondCopy: resb 4


struc node
size_i:
        info: resb  1
        next: resb  4
endstruc

section .text
    align 16
     global main
     extern printf
     extern fflush
     extern malloc
     extern calloc
     extern free
     extern gets
     extern fgets

; %3 - len of string
; %2 - string
; %1 - stdout

%macro myPrint 3
        pushad
        mov  edx, %1
        mov  ecx , %2
        mov  ebx, %3
        mov  eax, 4
        int 0x80
        popad                                                                         ; Transfer control to operating system
%endmacro



; %1 is the pointer to the list
; data of removed link will be in dl
; return value: data of removed link or -1 if list is empty.
;               returned into dl
%macro remove_from_lst 1
        mov eax, [%1]               ; Address of the first element
        cmp eax, 0
        je %%endPop                  ; if list is empty, return -1
        mov dl, byte[eax + info]     ; The information stored in the element
        mov ecx, dword[eax + next]
        mov [%1], ecx               ; list pointer points to next element
        mov ebx, eax

        pushad                    
        push ebx                     ; Free the allocated resources
        call free
        add esp, 4
        popad
        jmp %%done

        %%endPop:
        mov dl,-1

        %%done:
%endmacro

%macro list_Size 2
       
        mov ebx,%1                       ; ebx holds the pointer to the link
        mov ebx, [ebx]                   ; This parameter was the address of the address

 %%start_count:
        cmp dword [ebx + next] , 0       ; when next is null - there is 0 
        je %%found_last                  ; end of count

        inc dword [%2]                   ; counts the size
        mov ebx, [ebx + next]            ; go to the next link

        jmp %%start_count

        %%found_last:
        inc dword [%2]                   

%endmacro



; %1 is the data of the new link
; %2 is the pointer to the list
; changes pointer of list in case of empty list
%macro append 2
        
        push eax                         ; Save the registers
        push ebx
        
        push 5                           ; size of each link
        call malloc                      ; Call the malloc function - 
        add esp, 4                       ; now eax has the address of the allocated memory
        
        mov dl, byte[%1]                     ; dl holds new link's data         
        mov byte [eax + info], dl        ; Add the element to the node data field
        mov dword [eax + next], 0        ; Address of the next element is NULL
        mov ebx, %2                      ; pointer to list
        cmp dword[ebx], 0                ; check if list is empty
        je %%nullPointer
        mov ebx, [ebx]                   ; This parameter was the address of the address
                                         ;  Now it is the address of the first element
        ;find last link
        %%next:
        cmp dword [ebx + next], 0
        je %%found_last
        mov ebx, [ebx + next]
        jmp %%next

        %%found_last:
        mov [ebx + next], eax            ; new link is the last link
        jmp %%goOut
        
        %%nullPointer:
        mov [%2], eax                    ; list points to new (and only) link
              
        
        %%goOut:
        pop ebx                          ; Restore registers after malloc
        pop eax
        

                                                                                       
%endmacro


%macro addition 0

        section .data
                %%size1: dd 0                              ; firstNum's size
                %%size2: dd 0                              ; secondNum's size
                %%lst_greater: dd 2                        ; holds the num of the linked list with more elements (by default, secondNum)
                %%loopIndex: dd 0                          ; counts (backwards) number of links already added
                %%diff: dd 0                               ; difference between size1, size2
                %%carry: db 0
        section .bss
                %%firstNum: resb 4                         ; pointer to first num's linked list
                %%secondNum: resb 4                        ; pointer to second num's linked list
                %%sumList: resb 4                          ; pointer to sum of numbers' linked list


        section .text
        
        %%startAdd:
        ; init variables
        mov dword[%%carry], 0                      ; init carry from the last addition
        mov dword[%%sumList], 0
        mov dword[%%size1], 0
        mov dword[%%size2], 0
        mov dword[%%lst_greater],2                 ; assume lst2 > lst1
        mov dword[%%diff], 0
        
        myPop                                    ; macro. topOp now holds a pointer to the first linked list
        mov ecx, dword[topOp]
        mov dword [%%firstNum], ecx

        myPop                                    ; topOp now holds a pointer to the second linked list
        mov ecx, dword[topOp]
        mov dword [%%secondNum], ecx

        %%length_of_lists:

        list_Size %%firstNum, %%size1                ; check the list size
        list_Size %%secondNum, %%size2
        
        %%sizes:
        mov ebx, [%%size1]                         ; assume size1<size2
        mov dword [%%loopIndex], ebx
        mov dword [%%lst_greater], 2               ; if 1 - then list 1 is greater. 2 - list2 is greater

        mov ebx, [%%size1]
        mov ecx, [%%size2]
        sub ecx, ebx
        mov dword [%%diff], ecx                    ; diff is the difference between size1 and size2

        mov edx,dword[%%size2]                     ; can't compare memory with memory

        cmp dword [%%size1], edx
        jng %%addLoop

        mov ebx, [%%size2]
        mov dword [%%loopIndex],ebx
        mov dword [%%lst_greater], 1               ; list1 is greater

        mov ebx, [%%size2]                         ; diff is negative, change sign
        mov ecx, [%%size1]
        sub ecx, ebx
        mov dword [%%diff], ecx



        %%addLoop:
        mov byte[num1],0                    ; init
        mov byte[num2], 0                   ; init
        mov ebx, dword [%%loopIndex]
        cmp dword [%%loopIndex], 0
        je %%add_diff_label
        ; first num's byte to add
        remove_from_lst %%firstNum              ; node's data into dl
        mov byte [num1], dl                   ; save the first number
        
        ; second num's byte to add
        remove_from_lst %%secondNum             ; node's data into dl

        %%add: 
        mov eax, 0                            ; init
        add dl,[num1]                         ; add the 2 numbers
        add dl, byte[%%carry]                 ; add carry
        mov al, dl                            ; sum into eax
        mov edx,0                             ; remainder of division, sum of addition (in dl)!
        mov ebx,10H                           ; 16,the divisor
	div ebx                               ; eax gets eax/16 - > carry!
        mov byte [%%carry], al
        mov byte [num1], dl
        append num1,%%sumList
        dec dword [%%loopIndex]
        jmp %%addLoop


        %%add_diff_label:
        section .bss
                %%carryF: resb 1
        section .text
        
        mov al, byte [%%carry]
        mov byte [%%carryF], al             ; val for first loop
        cmp dword [%%lst_greater], 2
        je %%secondIsLonger                 ; skip "firstIsLonger"
        

        %%firstIsLonger:
        cmp dword [%%diff], 0             ; is end of list?
        je %%jumpToEnd
        remove_from_lst %%firstNum
        mov al, dl                       ; al, dl hold curr byte
        cmp dl, 0xF                      ; if dl = 0xF, next loop's carry = current carry  
        jne %%notF1
        mov al, byte[%%carryF]           ; f + carryF = 0 (and new carry=1) if carryF=1
        cmp al, 0                        ; f + carryF = f (and new carry=0) if carryF=0          
        je %%appendToSum1
        mov dl, 0                        ; carryF = 1
        jmp %%appendToSum1
        %%notF1:
        add dl, byte[%%carryF]
        mov byte[%%carryF], 0            ; carryF = 1
        %%appendToSum1:
        mov byte [num1], dl              
        append num1, %%sumList           ; next carryF will also be 0
        dec dword[%%diff]
        jmp %%firstIsLonger
        
        

        %%secondIsLonger:
        cmp dword [%%diff], 0              ; is end of list?
        je %%jumpToEnd
        remove_from_lst %%secondNum
        mov al, dl                       ; al, dl hold curr byte
        cmp dl, 0xF                      ; if dl = 0xF, next loop's carry = current carry  
        jne %%notF
        mov al, byte[%%carryF]           ; f + carryF = 0 (and new carry=1) if carryF=1
        cmp al, 0                        ; f + carryF = f (and new carry=0) if carryF=0          
        je %%appendToSum2
        mov dl, 0                        ; carryF = 1
        jmp %%appendToSum2
        %%notF:
        add dl, byte[%%carryF]
        mov byte[%%carryF], 0
        %%appendToSum2:
        mov byte [num1], dl              
        append num1, %%sumList             ; next carryF will also be 0
        dec dword[%%diff]
        jmp %%secondIsLonger
        

        %%jumpToEnd:
        mov al, byte [%%carryF]            ; copy carryF to carry for the check in endAdd
        mov byte [%%carry], al          
        jmp %%endAdd      
        %%endAdd:
        cmp dword[%%carry], 0              ; check if there's a carry
        je %%pushAddList
        append %%carry, %%sumList
        %%pushAddList:
        myPush %%sumList
        

%endmacro

; duplicates the element at the top of the stack into firstsCopy
; pushed original back
%macro duplication 0
       
      
        mov dword[firstCopy], 0          ; init pointer to first duplicate
        cmp dword [_top], 0              ; check if the stack is empty
        jbe stack_empty
        myPop                            ; top number is now in topOp
        mov ebx, dword[topOp]            ; ebx holds the pointer to the first link
        
        %%createCopies:
        mov dl, byte[ebx+info]
        mov byte[num1], dl
        push ebx
        append num1, firstCopy
        pop ebx

        mov ebx, [ebx + next]            ; continuen - next link
        cmp dword ebx , 0                ; when next is null - there is 0 
        je %%endCopy                     ; end of count
  
        jmp %%createCopies

        %%endCopy:
        myPush topOp
%endmacro

%macro myPush 1
        cmp dword [_top], numOfSlots               ; did we exceed stack size
        jne %%pushTheList
        mov ebx, dword[%1]
        mov dword[topOp], ebx
        call freeNum
        jmp stack_empty
        %%pushTheList:
        mov eax, dword [_top]
        mov edx, dword[%1]
        mov dword [operand_stack+eax*4], edx    ; write the value to stack
        inc dword [_top]                        ; update the last element position

%endmacro

%macro myPop 0
        mov dword[topOp], 0                      ; init
        cmp dword [_top], 0                      ; is stack empty
        jbe stack_empty
                                                 ; position of last element: _top-1
        dec dword [_top]                         ; decrease last element position
        mov eax, dword [_top]
        mov ebx, dword [operand_stack+eax*4]
        mov dword [topOp], ebx                   ; save the operand on the top
        mov dword [operand_stack+eax*4], 0       ; clear stack value at last position
%endmacro

; current result is first in stack
; check debug mode, it is on, duplicate last result, call pop and print
%macro printResultForDebug 0
        cmp byte[dMode], 0
        je %%dontPrint
        myPrint 11, debugString2, 1
        duplication
        myPush firstCopy
        jmp pop_and_print
        %%dontPrint:
        
%endmacro

; will build linked list from input string and push to opernad_stack
%macro buildAList 0

        %%build:
        mov eax, [input_len]            ; check if we've finished interating through input_num
        cmp eax, -1
        je %%pushList  
     
        mov ebx, [input_len]
        mov dl, byte[input + ebx]       ; data of new link to be appended to list
        
        %%beforeAdd:   
        cmp dl, 64                      ; check if char or number
        jg %%char
        sub dl,30H                      ; from string to int (ASCII)
        jmp %%appendByte
        %%char:
        sub dl, 37H
       
        %%appendByte:
        mov byte[data], dl
        append data, pointerToList      ; call macro - append a new link
        dec dword [input_len]
        jmp %%build                   

        %%pushList:
        myPush  pointerToList                 ; push linked list to op stack
       
%endmacro

main:
   
mov byte[dMode], 0
mov ecx, dword [esp+4]	; get argc
cmp ecx, 1      ; check if argdc >1
jng callCalc
mov byte[dMode], 1

callCalc:
call myCalc
call releaseRemainingNumbers            ; release memory
mov eax, dword[number_of_operations]
mov dword[reversedResult], 0
mov dword[result], 0

mov ecx, 0
ResultToString:                          ; convert to Hex string 
        mov edx,0x0                      ; remainder of division
        mov ebx,0x10                     ; the diviser
	div ebx                          ; eax gets eax/16
        add edx,0x30                     ; convert to string
	mov [reversedResult+ecx], edx      ; insert char to string array
	inc ecx                          ; counter of length
	cmp eax ,0
	jne ResultToString

        mov ebx,0                        ; an index
        mov dword [input_len], ecx
        mov dword [result], 0             ; init
        reverseResult:
        dec ecx
        mov al, [reversedResult+ecx]
        mov [result+ebx], al
        inc ebx
        cmp ecx, 0
        je printRes
        jmp reverseResult

        printRes:
        myPrint [input_len], result, 1 
        myPrint 1, newLine, 1
        ret




myCalc:

        mov eax, 3                            ; system call number (sys_read)
        mov ebx, 0                            ; file descriptor (stdin)
        mov ecx, input                        ; buffer to keep the read data
        mov edx, 82                           ; bytes to read, include \n
        int 0x80                              ; call kernel
  
        mov  dword [input_len], eax           ; save the length of the input
        dec dword [input_len]

        cmp byte [input], 0x71                ; while input is not q
        jne dontQuit
         sss:
        ret
        dontQuit:
        cmp byte [input], 0x2b                ; if input is +
        je add_numbers

        cmp byte [input], 0x70                ; if input is 'p' - pop and print
        je pop_and_print

        cmp byte [input], 0x64                ; if input is 'd' - duplicate
        je duplicate

        cmp byte [input], 0x5e                ; if input is '^' - X*2^Y
        je positive_power

        cmp byte [input], 0x76                ; if input is 'v' 0 X*2^(-Y)
        je negative_power

        cmp byte [input], 0x6e                ; if input is 'n' - count number of '1'
        je count_ones

        cmp byte [input], 0x73                ; if first letter of input is 's'
        jne input_number                      ; my push is a macro with 1 argument - case of a number
        cmp byte [input + 1], 0x72            ; if second letter of input is 'r'
        jne input_error
        jmp sqr_root


input_number:
section .bss
  pointerToList: resb 4
  data: resb 1
section .text
        
        mov dword [pointerToList], 0
        mov dword [pointerToList+1], 0
        mov dword [pointerToList+2], 0
        mov dword [pointerToList+3], 0
        mov byte  [data], 0
        dec dword [input_len]
        
        debugPrint:
        cmp byte[dMode], 0
        je startBuild
        myPrint 20, debugString1, 1
        inc dword [input_len]
        myPrint [input_len], input, 1
        dec dword [input_len]
        myPrint 1, newLine, 1
        
        startBuild:
        buildAList                        ; call macro                          
        jmp myCalc                        ; return to main loop, receive new input



duplicate:
        inc dword [number_of_operations]
        duplication                      ; call macro
        myPush firstCopy
        jmp myCalc



; pop the operand on the top and print it
pop_and_print:
        section .bss
                revNum: resb 4
                printByte: resb 1
                isNumZero: resb 1
            
        section .text
        
        inc dword [number_of_operations]
        mov byte[isNumZero], 0          ; boolean
        mov byte [printByte], 0         ; each link's data
        mov dword [revNum], 0      ; init pointer to reversed num's list
        mov dword [topOp], 0
        myPop                           ; remove the list from the stack into topOp
        
        ; create a reversed num
        mov ebx, dword[topOp]
        mov ecx, [ebx+next]
        mov dword[ebx+next], 0
        cmp ecx, 0
        je prepPrint                    ; only one link
        revLoop:                        ; reverse all pointers
        mov edx, [ecx+next]
        mov dword[ecx+next], ebx
        mov ebx, ecx
        cmp edx, 0
        je prepPrint
        mov ecx, edx
        jmp revLoop

        prepPrint:
        mov dword[revNum], ebx
        
        eliminateLeadingZeroes:                   
        remove_from_lst revNum
        cmp dl, 0 
        je eliminateLeadingZeroes
        cmp dl, -1
        je numIsZero
        jmp firstLoopStartsHere         ; skip remove_from_lst in first iteration

        printLoop:                      ; print the reversed list
        remove_from_lst revNum
        firstLoopStartsHere:
        cmp dl, -1
        je endPrint
        cmp dl, 9                       ; check if A-F
        jg isADigit
        add dl,48                       ; is number
        mov byte[printByte],dl        
        jmp printTheByte
        isADigit:
        add dl, 55
        mov byte[printByte],dl

        printTheByte:
        pushad
        push printByte			; call printf with 2 arguments -  
	push format_string	        ; pointer to str and pointer to format string
	call printf
	add esp, 8		        ; clean up stack after call
        popad     

        jne printLoop                     

        endPrint:
        cmp byte[isNumZero], 0
        jne numPrinted
     
        numPrinted:
        mov dl, 0xA                     ; \n
        mov byte[printByte],dl
       
        pushad                          ; print '\n'
        push printByte			; call printf with 2 arguments -  
	push format_string	        ; pointer to str and pointer to format string
	call printf
	add esp, 8		        ; clean up stack after call
        popad   
        jmp myCalc

  
        numIsZero:
        mov dl, 0x30                     
        mov byte[printByte],dl
        pushad                          ; print '\n'
        push printByte			; call printf with 2 arguments -  
	push format_string	        ; pointer to str and pointer to format string
	call printf
	add esp, 8		        ; clean up stack after call
        popad   
        jmp numPrinted



add_numbers:

        inc dword [number_of_operations]
        mov ebx, dword[_top]
        cmp ebx, 1                      ; stack must have at least two nums
        jng stack_empty
        addition        ; call macro
        printResultForDebug
        jmp myCalc

positive_power:
 section .data
        Xpointer: dd 0                              
        Ypointer: dd 0                              
        nodeToSave: db 4                        
        numY: db 4
        section .text

        inc dword [number_of_operations]
        mov eax, 0
        mov ebx, dword[_top]
        cmp ebx, 1                      ; stack must have at least two nums
        jg enoughEle
        jmp stack_empty

        enoughEle:
        ; y is the second operand so we need to pop x then pop y and push back x
        ; make sure stack remains unchanged in case of wrong y value
        myPop                           ; pop x
        mov ebx, dword[topOp]
        mov dword [Xpointer], ebx
        duplication                     ; y backup into firstCopy
        mov ebx, dword[firstCopy]                          
        mov dword [Ypointer], ebx              
        mov dword[firstCopy], 0
        myPush Xpointer
        duplication                     ; x backup into firstCopy
        mov ebx, dword[firstCopy]
        mov dword [Xpointer], ebx
        ; ------------  stack is unchanged ! (in case of wrong y input)
        remove_from_lst Ypointer        ; data into dl
        mov cl, dl

        cmp dl, -1                      ;first node isn't supposed to be empty
        jne okIn
        mov ebx, dword[Xpointer]
        mov dword [topOp], ebx
        call freeNum                         ; free memory
        call wrongInput                 ; print error string
        jmp myCalc
        okIn:

        push ecx
        remove_from_lst Ypointer        ; into dl
        pop ecx
        cmp dl, -1                      
        jne skip
        mov dl, 0
        skip:
        mov bl, 10H
        mov al, dl
        mul bl                          ; al hold dl in HEXA
        add cl, al                      
        mov al, cl                      ; al - number of loops - Y    
        push eax
        remove_from_lst Ypointer        ; into dl
        pop eax                         ; al hold Y
        cmp dl, -1                      ; not possible, y is less then 200 
        je checkY
        mov ebx, dword[Xpointer]
        mov dword [topOp], ebx
        call freeNum                         ; free memory
        mov ebx, dword[Ypointer]
        mov dword [topOp], ebx
        call freeNum                         ; free memory
        call wrongInput
        jmp myCalc
        

        checkY:
        mov ebx, 0
        mov bl, al
        cmp ebx, 0xC8
        jng inputLegal
        mov ebx, dword[Xpointer]
        mov dword [topOp], ebx
        call freeNum                         ; free memory
        mov ebx, dword[Ypointer]
        mov dword [topOp], ebx
        call freeNum                         ; free memory
        call wrongInput                 ; print error string
        jmp myCalc
        
        inputLegal:
        pushad
        myPop                           ; copies of x,y are in the stack
        call freeNum                    ; free momery
        myPop
        call freeNum                    ; free memory
        myPush Xpointer                 ; push back x
        popad
        
        loopY:
        cmp ebx, 0                       ; al has Y - we loop Y times
        je endOfLoopY
       ; mov dword[numY], ebx
        push ebx
        dupX:
        duplication                     ; call macro, top two nums in stack are x
        myPush firstCopy                ; top of stack holds two copies of current result
        addDups:

        addition                        ; call macro, add X and X which is 2*X
        pop ebx
        t:;mov ebx, dword[numY]
        dec ebx                        ; do it Y times 
        jmp loopY
       
        endOfLoopY:
        printResultForDebug
        jmp myCalc

negative_power:
       section .data
        XpointerNeg: dd 0                              
        YpointerNeg: dd 0                              
        numYneg: dd 4                        
        divitionCarry: db 0
        section .text
  
        inc dword [number_of_operations]
        mov ebx, dword[_top]
        cmp ebx, 1                      ; stack must have at least two nums
        jg enoughElem
        jmp stack_empty

        enoughElem:
        ; y is the second operand so we need to pop x then pop y and push x back
        ; make sure stack remains unchanged in case of wrong y value
   
        myPop                           ; pop x
        mov ebx, dword[topOp]
        mov dword [XpointerNeg], ebx
        duplication                     ; y backup into firstCopy
        mov ebx, dword[firstCopy]                          
        mov dword [YpointerNeg], ebx              
        mov dword[firstCopy], 0
        myPush XpointerNeg
        duplication                     ; x backup into firstCopy
        mov ebx, dword[firstCopy]
        mov dword [XpointerNeg], ebx

        ; ------------  stack is unchanged ! (in case of wrong y input)
     
        remove_from_lst YpointerNeg              ; data into dl
        mov cl, dl
        cmp dl, -1                      ;first node isn't supposed to be empty
        jne yNotEmpty
        mov ebx, dword[XpointerNeg]
        mov dword [topOp], ebx
        call freeNum                         ; free memory
        call wrongInput                 ; print error string
        jmp myCalc
        
        yNotEmpty:
        push ecx
        remove_from_lst YpointerNeg        ; into dl
        pop ecx
        cmp dl, -1                      
        jne skipNeg
        mov dl, 0
        
        skipNeg:
        mov bl, 10H
        mov al, dl
        mul bl                          ; al hold dl in HEXA
        add cl, al                      
        mov al, cl                      ; al - number of loops - Y
        push eax
        remove_from_lst YpointerNeg     ; into dl
        pop eax 
        cmp dl, -1                      ; not possible, y is less then 200 
        je checkYNeg
        mov ebx, dword[XpointerNeg]
        mov dword [topOp], ebx
        call freeNum                         ; free memory
        mov ebx, dword[YpointerNeg]
        mov dword [topOp], ebx
        call freeNum                         ; free memory
        call wrongInput                 ; print error string
        jmp myCalc
       
        
        checkYNeg:                      ; al holds Y
        mov ebx, 0
        mov bl, al
        cmp ebx, 0xC8
        jng rightInp

        call wrongInput                 ; print error string
        jmp myCalc
        mov ebx, dword[XpointerNeg]
        mov dword [topOp], ebx
        call freeNum                         ; free memory
        mov ebx, dword[YpointerNeg]
        mov dword [topOp], ebx
        call freeNum                         ; free memory
        
        rightInp:  
        pushad 
        myPop                           ; copies of x,y are in the stack
        call freeNum                    ; free memory
        myPop    
        call freeNum                    ; free memory
        myPush XpointerNeg              ; x is FO in LIFO stack
        popad

        loopYneg:
        cmp ebx, 4                       ; devide by 16 = 2^4 if Y => 4
        jl smallerThan4
        push ebx
        myPop                           ; x into topOp
        remove_from_lst topOp           ; devide by 16  (shl)
        cmp dl, -1             ; if the list is of size 0 (num is zero)
        jne xIsntZero                    ; skip handling x=0
        xIsZero:
        pop ebx       
        mov byte[num1], 0
        append num1, topOp              ; create list representing the number 0
        myPush topOp
        jmp endOfLoopNeg
        
        xIsntZero:
        myPush topOp                    ; push back list afte shl
        pop ebx       
        add ebx, -4
        jmp loopYneg

        smallerThan4: 
        cmp bl, 0
        je endOfLoopNeg
        dec bl
        mov byte[numYneg], bl
        myPop                           ; into topOp      
        mov dword[divitionCarry], 0     ; init carry to zero
        
        
        ; create a reversed num
        mov eax, dword[topOp]
        cmp eax, 0
        je xIsZero
        mov ecx, [eax+next]
        mov dword[eax+next], 0
        cmp ecx, 0
        je prepIt                    ; only one link
        revIt:                          ; reverse all pointers
        mov edx, [ecx+next]
        mov dword[ecx+next], eax
        mov eax, ecx
        cmp edx, 0
        je prepIt
        mov ecx, edx
        jmp revIt

        prepIt:
        mov ecx, eax 
        mov dword[topOp], eax         
        
        divideByTwo:
        mov ax,0
        mov al, byte[ecx+info]          ; hold current data
        mov dl, byte[divitionCarry]
        cmp dl, 0
        je noCarry
        add al, 0x10                    ; add 16 if there's a carry from last divition
        noCarry:
        mov bl, 0x2
        div bl                          ; result into al, carry into ah    
        mov byte[ecx+info], al          ; update new value 
        mov byte[divitionCarry], ah
        mov byte[ecx+info], al          ; update value 
        mov ecx, [ecx + next]           ; continuen - next link
        cmp dword ecx , 0               ; when next is null - there is 0 
        jne divideByTwo

 
        ; reverse back
        mov eax, dword[topOp]
        mov ecx, [eax+next]
        mov dword[eax+next], 0
        cmp ecx, 0
        je endR                    ; only one link
        revBack:                        ; reverse all pointers
        mov edx, [ecx+next]
        mov dword[ecx+next], eax
        mov eax, ecx
        cmp edx, 0
        je endR
        mov ecx, edx
        jmp revBack
        
        endR:
        mov dword[topOp], eax
        myPush topOp
        mov bl, byte[numYneg]
        jne smallerThan4                 ; end of divition, again with y-1

        endOfLoopNeg:
        printResultForDebug
        jmp myCalc


count_ones:

section .bss
reverseInput: resb 4
section .text
        
        inc dword [number_of_operations]
        mov dword [reverseInput],0      ; init
        myPop                           ; macro. topOp now holds a pointer to the first linked list
        mov eax, 0                      ; counter of ones
        
        count1:
        push eax                        ; backup
        remove_from_lst topOp           ; first node's data into dl  
        pop eax                         ; restore      
        cmp dl,-1                       ; check if end of list
        
        je intToString
        mov ebx,0
        cmp dl, 1
        je addOneToCounter
        cmp dl, 2
        je addOneToCounter
        cmp dl, 4
        je addOneToCounter
        cmp dl, 8
        je addOneToCounter
        cmp dl, 3
        je addTwoToCounter
        cmp dl, 5
        je addTwoToCounter
        cmp dl, 6
        je addTwoToCounter
        cmp dl, 9
        je addTwoToCounter
        cmp dl, 10
        je addTwoToCounter       
        cmp dl, 12
        je addTwoToCounter
        cmp dl, 7
        je addThreeToCounter
        cmp dl, 11
        je addThreeToCounter
        cmp dl, 13
        je addThreeToCounter
        cmp dl, 14
        je addThreeToCounter
        cmp dl, 15
        je addFourToCounter
        jmp count1                       ; digit is zero

        addOneToCounter:
        add eax, 1
        jmp count1

        addTwoToCounter:
        add eax, 2
        jmp count1

        addThreeToCounter:
        add eax, 3
        jmp count1
        addFourToCounter:
        add eax, 4
        jmp count1

        intToString:                     ; convert to string 
        mov edx,0x0                      ; remainder of division
        mov ebx,0x10                     ; the diviser
	div ebx                          ; eax gets eax/10 
        add edx,0x30                     ; convert to string
	mov [reverseInput+ecx], edx      ; insert char to string array
	inc ecx                          ; counter of length
	cmp eax ,0
	jne  intToString

        mov ebx,0                        ; an index
        mov dword [input_len], ecx
        mov dword [input], 0             ; init
        reverseTheString:
        dec ecx
        mov al , [reverseInput+ecx]
        mov [input+ebx], al
        inc ebx
       
        cmp ecx, 0
        je pushToStack
        jmp reverseTheString


        pushToStack:
        mov dword [pointerToList], 0
        dec dword [input_len]
        
        
        buildAList                 ; will create list from input and push to the OP-stack
        printResultForDebug
        jmp myCalc




sqr_root:
        
        
        
        inc dword [number_of_operations]
        printResultForDebug
        jmp myCalc

stack_full:

        myPrint 30, overflow_string, 1
        jmp myCalc


stack_empty:
        myPrint 50, emptystack_string, 1
        jmp myCalc

input_error:
        myPrint 24, input_error_string, 1
        jmp myCalc

 wrongInput:
        myPrint 14, positivePowerString, 1
        ret


; free all memory in list topOp
freeNum:

        freeLoop:              
        remove_from_lst topOp
        cmp dl, -1
        jne freeLoop
        ret

releaseRemainingNumbers:

        freeStack:
        cmp dword[_top],0
        jne notDone
        ret
        notDone:
        myPop
        call freeNum
        jmp releaseRemainingNumbers