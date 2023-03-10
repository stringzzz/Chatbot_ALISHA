 ;   This is the Chatbot ALISHA, written in x86 Assembly
 ;   Copyright (C) 2022 stringzzz, Ghostwarez Co.
 ;
 ;   This program is free software: you can redistribute it and/or modify
 ;   it under the terms of the GNU General Public License as published by
 ;   the Free Software Foundation, either version 3 of the License, or
 ;   (at your option) any later version.
 ;
 ;   This program is distributed in the hope that it will be useful,
 ;   but WITHOUT ANY WARRANTY# without even the implied warranty of
 ;   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 ;   GNU General Public License for more details.
 ;
 ;   You should have received a copy of the GNU General Public License
 ;   along with this program.  If not, see <https://www.gnu.org/licenses/>.

; ChatBot ALISHA (Assembly Language Intelligent Speech Happy Automator)
; Version 0.04
; Completed on 2-08-2022
; By stringzzz
; Ghostwarez Co.

; First the memory files are input into arrays of bytes
; Then the user enters their username
; Before the chat starts, ALISHA finds a random response in memory and displays it
; This officially starts the chat loop:

; Chat loop
; In the chat loop, the user enters their reply
; The reply is checked for a full match with any messages in ALISHA's memory
; If full match, output the response paired with the message
; Else, try to find a partial match, is user reply a substring of memory message?
; If yes, output the response paired with the matching message
; Else, learn new reponse/message pair
; Store ALISHA's previous reply as new message in memory
; Store user's reply as new response in memory
; Then, to keep conversation, output a random response
; Repeat chat loop until user enter's 'quit'

; Once outside chat loop, output byte arrays to memory files


INCLUDE asmlib.inc

CreateFileA Proto,
	fileName: PTR BYTE,
	accessMode: DWORD,
	shareMode : DWORD,
	securityAttrib : DWORD,
	creationDispo : DWORD,
	flagsAndAttrib : DWORD,
	hTemplateFile : DWORD


ReadFile PROTO,		
	hHandle:DWORD ,		
	lpBuffer:PTR BYTE,		
	nNumberOfBytesToRead: DWORD,		
	pNumberOfBytesRead: PTR DWORD,	
	lpOverlapped: PTR DWORD		
	
WriteFile PROTO,
  hHandle : DWORD,
  lpBuffer : PTR BYTE,
  nNumberOfBytesToWrite : DWORD,
  pNumberOfBytesWritten : PTR DWORD,
  lpOverlapped : PTR DWORD

 CloseHandle PROTO, hObject : DWORD

GENERIC_READ     = 80000000h
GENERIC_WRITE    = 40000000h

OPEN_EXISTING      = 3
OPEN_ALWAYS        = 4

FILE_ATTRIBUTE_NORMAL  = 80h

NULL = 0

.data	
	
	;I/O Messages
	inputMessage BYTE "Inputting memory...", 0
	inputCompleteMessage BYTE "Memory input complete.", 0
	outputMessage BYTE "Outputting memory...", 0
	outputCompleteMessage BYTE "Memory output complete.", 0

	; For Message memory input
	fname1 BYTE "MessageMemory.txt", 0
	messageArray BYTE 8192 DUP(0)
	fHandle1 DWORD ?	
	bytesRead1 DWORD 0
	bytesWritten1 DWORD 0

	; For Response memory input
	fname2 BYTE "ResponseMemory.txt", 0
	responseArray BYTE 8192 DUP(0)
	fHandle2 DWORD ?	
	bytesRead2 DWORD 0
	bytesWritten2 DWORD 0

	; Name stuff
	usernameMessage BYTE "Enter your name: ", 0
	username BYTE 64 DUP(0)
	botName BYTE "ALISHA: ", 0

	; Variables for use in dealing with responses/memories
	messageEnd DWORD ?
	responseEnd DWORD ?
	messageNumber DWORD ?
	messagesTotal DWORD ?

	; Message variables
	userMessage BYTE 256 DUP(0)
	botPreviousMessage BYTE 256 DUP(0)

	; For checking if user wants to quit
	quitMessage BYTE "quit", 0
				
.code

inputMessages PROC
	; Input MessageMemory.txt into messageArray

	mov eax, 0
	mov edx, OFFSET fname1									; Load offset of filename
	INVOKE  CreateFileA, edx, GENERIC_READ, NULL, NULL,		; Open an exisiting file
		OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL

	mov fHandle1, eax										; Store Off the Handle
	mov eax, 0
	INVOKE  ReadFile, fHandle1, ADDR messageArray, 8192, ADDR bytesRead1, NULL ;Read a maximum of 100 bytes
	INVOKE  CloseHandle, fHandle1				; Close the file

	ret
inputMessages ENDP

outputMessages PROC
	; Output messageArray into MessageMemory.txt

	mov eax, 0						
	mov edx, OFFSET fname1
	INVOKE  CreateFileA, edx, GENERIC_WRITE, NULL, NULL,	; Create the file for writing
		OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
	
	mov fHandle1, eax					; File handle returned in eax
	   	
	INVOKE WriteFile, fHandle1, ADDR messageArray, SIZEOF messageArray, ADDR bytesWritten1, NULL ;write text to file
		
	INVOKE closeHandle, fHandle1				; Close file
	ret
outputMessages ENDP

inputResponses PROC
	; Input ResponseMemory.txt into responseArray

	mov eax, 0
	mov edx, OFFSET fname2									; Load offset of filename into edx
	INVOKE  CreateFileA, edx, GENERIC_READ, NULL, NULL,		; Open an exisiting file with fname2 filename
		OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL

	mov fHandle2, eax										; Store Off the Handle in a variable fHandle2
	mov eax, 0
	INVOKE  ReadFile, fHandle2, ADDR responseArray, 8192, ADDR bytesRead2, NULL ;Read a maximum of 100 bytes
	INVOKE  CloseHandle, fHandle2				; Close the file

	ret
inputResponses ENDP

outputResponses PROC
	; Output responseArray into ResponseMemory.txt

	mov eax, 0						;Clear eax
	mov edx, OFFSET fname2
	INVOKE  CreateFileA, edx, GENERIC_WRITE, NULL, NULL,	;Create the file for writing
		OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
	
	mov fHandle2, eax					;File handle returned in eax
	   	
	INVOKE WriteFile, fHandle2, ADDR responseArray, SIZEOF responseArray, ADDR bytesWritten1, NULL ;write text to file
		
	INVOKE closeHandle, fHandle2			; Close file
	ret
outputResponses ENDP

getUsername PROC
	; Prompt for username and input it

	mov edx, OFFSET usernameMessage					; Move usernameMessage prompt into edx
	call writeString								; output the prompt to console
	mov edx, OFFSET username						; Move username offset into edx for input
	call readLine									; get the username from user input

	incLoop1:										; Increment loop
	inc edx											; Iterate bytes in edx until at NULL
	mov cl, [edx]
	cmp cl, 0
	jne incLoop1									; Exit the loop if current byte is NULL

	mov cl, 3ah										; Add a ':' to the end of the username string
	mov [edx], cl
	inc edx
	mov cl, 20h										; Add a space to the end of the username string
	mov [edx], cl

	ret
getUsername ENDP

seekEnd PROC
	; eax contains byte array
	; ecx contains byte end counter

	mov ecx, 0										; Start the end count at zero

	incLoop2:										; Loop through the bytes of eax until NULL is found
	inc eax
	inc ecx
	mov dh, [eax]
	cmp dh, 0
	jne incLoop2									; Exit loop if NULL is reached

	inc eax											; Increment eax once more to get next byte
	inc ecx
	mov dh, [eax]
	cmp dh, 0										; If next byte is also NULL, this is the end of the data in eax
	jne incLoop2
													; ecx now holds the end position of the byte array
													; This is then used to add new messages or responses to the respective byte arrays
	ret
seekEnd ENDP

nullFill PROC
	; Eax contains byte array to fill with NULLS
	; This is used to reset the data for recieving new input

	incLoop3:
	mov dh, 0
	mov [eax], dh
	inc eax
	mov dh, [eax]
	cmp dh, 0
	jne incLoop3

	inc eax
	mov dh, [eax]
	cmp dh, 0
	jne incLoop3

	ret
nullFill ENDP

printUsername PROC
	; Output username

	mov edx, OFFSET username
	call writeString

	ret
printUsername ENDP

getUserMessage PROC
	; Input user reply

	mov eax, OFFSET userMessage
	call nullFill
	call printUsername
	mov edx, OFFSET userMessage			
	call readLine						

	ret
getUserMessage ENDP

moveToMessageNumber PROC
	; eax byte array
	; ecx message number
	; Moves to ecx message number position in byte array

	mov ebx, 0
	incLoop3:
	cmp ebx, ecx
	je outsideIncLoop3
	inc eax
	mov dh, [eax]
	cmp dh, 0
	jne incLoop3
	inc eax
	inc ebx
	jmp incLoop3

	outsideIncLoop3:
	ret

moveToMessageNumber ENDP

countMessages PROC
	; eax byte array
	; ebx message count
	; Gets the number of message strings in eax

	mov ebx, 0
	countLoop:

	inc eax
	mov dh, [eax]
	cmp dh, 0
	jne countLoop
	inc eax
	mov dh, [eax]
	cmp dh, 0
	je outsideCountLoop
	inc ebx
	jmp countLoop

	outsideCountLoop:
	ret

countMessages ENDP

getBotPreviousMessage PROC
	; ecx contains messageNumber

	; Clear botPreviousMessage
	mov eax, OFFSET botPreviousMessage
	call nullFill

	; Move to messageNumber in ecx
	mov eax, OFFSET responseArray	
	call moveToMessageNumber
	mov ebx, OFFSET botPreviousMessage			

	; Copy current responseArray message into botPreviousMessage
	moveLoop:						
	mov dh, [eax]					
	mov [ebx], dh					
	inc eax							
	inc ebx							
	mov dh, [eax]
	cmp dh, 0
	jne moveLoop

	ret
getBotPreviousMessage ENDP

fullMatch PROC

	; Checks if the string in eax matches the string in ebx exactly

	;'Input':
	; Before calling this procedure:
	; move the 1st string to match into eax with its OFFSET
	; Example: mov eax, OFFSET textString1
	; move the 2nd string to match to into ebx with its OFFSET
	; Example: mov ebx, OFFSET textString2

	; 'Output':
	; If Full match found: Moves 1 into ecx
	; Else: moves 0 into ecx

	; Main match loop:
	fullMatchLoop:
	mov cl, [eax]									; Move the current byte of eax into cl
	cmp cl, [ebx]									; Compare contents of cl with the current byte of ebx
	jne noFullMatch									; If 2 bytes don't match, jump to noFullMatch, because full match is not found
	mov dh, [eax]									; Else, move current eax byte into dh
	cmp dh, 0										; Compare dh with null
	je yesFullMatch									; If dh is null, jump to yesFullMatch, because full match is found
	inc eax											; Increment eax to get next byte of string
	inc ebx											; Same as above, but for ebx
	jmp fullMatchLoop								; Repeat main match loop

	noFullMatch:									; If full match not found
	mov ecx, 0										; Move 0 into ecx, full match not found
	jmp exitFullMatch								; Jump to end of fullMatch procedure

	yesFullMatch:									; If full match found
	mov ecx, 1										; move 1 into ecx, full match found

	exitFullMatch:									; Go here if procedure complete
	ret												; Return from procedure
fullMatch ENDP

partialMatch PROC

	; Checks if the string in eax is found within the string in ebx

	; 'Input':
	; Before calling this procedure:
	; move the 1st string (substring) at its OFFSET to into eax
	; Example: mov eax, OFFSET subText
	; move the 2nd string's OFFSET to match to into ebx
	; Example: mov ebx, OFFSET biggerText

	; 'Output':
	; If partial match found: Moves 1 into ecx
	; Else: moves 0 into ecx

	; Store eax (substring to match) into edx for use in resetting during loop
	mov edx, eax

	; Main partial match loop
	partialMatchLoop:
	mov cl, [eax]									; Move current byte of eax into cl
	cmp cl, [ebx]									; Compare cl with current byte of ebx
	jne partialMatchReset							; If: cl not equal to current byte of ebx, jump to partialMatchReset
	inc eax											; Else: Increment eax to get next byte of 'text'
	inc ebx											; Increment ebx to get next byte of 'toMatch'
	mov cl, [eax]									; Move current byte of eax into ch
	cmp cl, 0										; Compare ch with null
	je yesPartialMatch								; If: ch == null, jump to yesPartialMatch, because partial match is found
	mov ch, [ebx]									; Else: Move current byte of ebx into ch
	cmp ch, 0										; Compare ch with null
	je noPartialMatchFound							; If: ch == null, jump to noPartialMatchFound, because the end of 'toMatch' string is reached
	jmp partialMatchLoop							; Else: Jump back to main partial match loop

	partialMatchReset:								; Go here if end of 'text' string has been reached
	mov ch, [ebx]
	inc ebx
	cmp ch, 0
	je noPartialMatchFound
	mov ch, [ebx]
	cmp ch, 0
	je noPartialMatchFound
	mov eax, edx									; Move text stored in edx into eax again, to reset from beginning
	jmp partialMatchLoop							; Jump back to top of main partial match loop

	yesPartialMatch:								; Go here if partial match was found
	mov ecx, 1										; Move 1 into ecx, signaling partial match found
	jmp exitPartialMatch							; Jump to end of procedure

	noPartialMatchFound:							; Go here if end of 'toMatch' string was reached without partial match found
	mov ecx, 0										; Move 0 into ecx, signaling partial match not found

	exitPartialMatch:								; Exit from the procedure

	ret
partialMatch ENDP

printBotResponse PROC
	; Output bot name and response

	mov edx, OFFSET botName
	call writeString
	mov edx, OFFSET botPreviousMessage
	call writeLine

	ret
printBotResponse ENDP

checkFullMatch PROC
	; ecx = 1 if full match found
	; messageNumber contains the number of which string in messageArray matches

	mov messageNumber, 0

	fullMatchSearch:
	mov eax, OFFSET messageArray
	mov ecx, messageNumber
	call moveToMessageNumber
	mov ebx, eax
	mov eax, OFFSET userMessage
	call fullMatch
	cmp ecx, 1
	je outsideFullMatchSearch

	mov edx, messageNumber
	inc edx
	mov messageNumber, edx
	inc ebx
	mov dh, [ebx]
	cmp dh, 0
	je noFullMatch
	jmp fullMatchSearch

	noFullMatch:
	mov ecx, 0

	outsideFullMatchSearch:

	ret
checkFullMatch ENDP

checkPartialMatch PROC
	; ecx = 1 if partial match found
	; messageNumber contains the number of which string in messageArray matches

	mov messageNumber, 0

	partialMatchSearch:
	mov eax, OFFSET messageArray
	mov ecx, messageNumber
	call moveToMessageNumber
	mov ebx, eax
	mov eax, OFFSET userMessage
	call partialMatch

	cmp ecx, 1
	je outsidePartialMatchSearch
	mov edx, messageNumber
	inc edx
	mov messageNumber, edx
	inc ebx
	mov dh, [ebx]
	cmp dh, 0
	je noPartialMatch
	jmp partialMatchSearch

	noPartialMatch:
	mov ecx, 0

	outsidePartialMatchSearch:

	ret
checkPartialMatch ENDP

learnMessage PROC
	; Learn new message from botPreviousMessage and copy into messageArray

	mov eax, messagesTotal
	inc eax
	mov messagesTotal, eax

	mov eax, OFFSET botPreviousMessage
	mov ebx, OFFSET messageArray
	add ebx, messageEnd							; Adding messageEnd to ebx gets the end of messageArray,
												; so a new message can be copied into the end
	mov ecx, messageEnd

	; Copy from eax into ebx
	moveLoop2:						
	mov dh, [eax]					
	mov [ebx], dh					
	inc eax							
	inc ebx	
	inc ecx							
	mov dh, [eax]
	cmp dh, 0
	jne moveLoop2

	inc ecx
	mov messageEnd, ecx

	ret
learnMessage ENDP

learnResponse PROC
	; Learn new response from userMessage and copy into responseArray

	mov eax, OFFSET userMessage
	mov ebx, OFFSET responseArray
	add ebx, responseEnd						; Adding messageEnd to ebx gets the end of responseArray,
												; so a new message can be copied into the end
	mov ecx, responseEnd

	; copy from eax into ebx
	moveLoop3:						
	mov dh, [eax]					
	mov [ebx], dh					
	inc eax							
	inc ebx	
	inc ecx							
	mov dh, [eax]
	cmp dh, 0
	jne moveLoop3

	inc ecx
	mov responseEnd, ecx

	ret
learnResponse ENDP

main PROC		
	call randSeed								; Set the random seed, needed for getting random responses

	; Input memory from files
	mov edx, OFFSET inputMessage				; Inputting message
	call writeLine

	call inputMessages							; Input data from MessageMemory.txt file into messageArray
	mov eax, OFFSET messageArray
	call seekEnd								; Find the end of the data in messageMemory
	mov messageEnd, ecx							; Copy the data end number into messageEnd
	mov eax, OFFSET messageArray
	call countMessages							; Count the total number of NULL separated strings in messageArray
	mov messagesTotal, ebx

	call inputResponses							; Same as above, but for ResponseMemory.txt and responseArray
	mov eax, OFFSET responseArray
	call seekEnd
	mov responseEnd, ecx

	mov edx, OFFSET inputCompleteMessage		; Input is complete, output message stating this
	call writeLine
	endl

	; Prompt and input username
	call getUsername
	endl

	; Output random response for start
	mov eax, messagesTotal
	call randRange								; Generates a number from zero to messagesTotal
	mov ecx, eax
	call getBotPreviousMessage					; Get the random message and place it into botPreviousMessage for output
	call printBotResponse

	; Main chat loop
	chatLoop:
	call getUserMessage							; Input the user's reply message

	; Check if user entered 'quit'
	mov eax, OFFSET userMessage
	mov ebx, OFFSET quitMessage
	call fullMatch
	cmp ecx, 1
	je endOfChat								; If user message matches 'quit', exit the chat loop

	; Try Full match
	call checkFullMatch							; Check for full match between userMessage and messageArray strings
	cmp ecx, 1
	je MatchSuccess								; Jump to MatchSuccess if ecx is 1: Full match found

	; Try Partial match
	call checkPartialMatch						; Check if userMessage string is a substring of any messageArray strings
	cmp ecx, 1
	je MatchSuccess								; Jump to MatchSuccess if ecx is 1: Partial match found

	; No match
	; Learn new message/response pair
	; Increment messagesTotal in learnMessage
	call learnMessage							; Adds botPreviousMessage to end of messageArray
	call learnResponse							; Adds userMessage to end of responseArray

	; Output random response
	mov eax, messagesTotal
	call randRange
	mov ecx, eax
	call getBotPreviousMessage
	call printBotResponse

	jmp chatLoop

	; If full or partial match found
	MatchSuccess:
	mov ecx, messageNumber
	call getBotPreviousMessage					; Get the responseArray string corresponding to the messageNumber
												; obtained in fullMatch or partialMatch
	call printBotResponse

	jmp chatLoop								; If at this point, jump to the beginning of the chat loop
	
	endOfChat:

	; Output memory
	; 'quit' entered to reach here
	endl
	mov edx, OFFSET outputMessage
	call writeLine

	call outputMessages							; Output messageArray into MessageMemory.txt as is
	call outputResponses						; Output responseArray into ResponseMemory.txt as is

	mov edx, OFFSET outputCompleteMessage
	call writeLine
	endl

  	exit      
main ENDP 
END main