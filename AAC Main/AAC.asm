;AAC.asm
;A simple action shooter
;Windows32 Application 

;Include files from Irvine libraries found in the ..\Irvine folder
INCLUDE Irvine32.inc
INCLUDE GraphWin.inc

doPaint proto c		; stdcall proto

;==================== DATA =======================
.data
; Playfield values
LOWXBND EQU 0
LOWYBND EQU 0
UPXBND EQU 800
UPYBND EQU 600
shipLocX DWORD 50		; X coordinate of the ship
shipLocY DWORD 50		; Y coordinate of the ship
shipHeading DWORD 90	; Heading of the ship
shipAccel DWORD 0		; acceleration of the ship due to thrust
shotsFired DWORD 0		; number of shots fired
gameTimer DWORD 0			; game timer
shipPlaceholder BYTE "V",0
errorRoid BYTE "FOR (int y = 0, y > y, y++)(while 0 == 0)", "{ int y:= 0", "/n",0

; Player Values
playerScore DWORD 0		; player score
playerLives DWORD 0		; player number of lives/tries

; Welcome Message
GreetTitle BYTE "ErrorRoids!",0
GreetText  BYTE "Welcome to AAC! "
	       BYTE "Press OK to begin. ",0

; Exit Message
CloseMsg   BYTE "Thank you for playing!",0

; Fake errror message strings to display at game end
gameOverMessage BYTE "Syntax Error Line A70 - Termination Expected",
				 "Error: Unable to Open File - File not found", 0

; Playtest messages
PopupTitle BYTE "Weapon Fired!",0
PopupText  BYTE "PEW! "
	       BYTE "PEW!",0

;Debug Messages
shots BYTE "Shots Fired: ",0
xPos BYTE "Ship X Coord: ",0
yPos BYTE "Ship Y Coord: ",0
score BYTE "Player Score: ",0
sAccel BYTE "Ship Acceleration: ",0
pLives BYTE "Player Lives: ",0
sHeading BYTE "Ship heading: ",0
displayTimer BYTE "Game time: ",0

; Window Pane Strings
ErrorTitle  BYTE "Error",0
WindowName  BYTE "ErrorRoids!",0
className   BYTE "ErrorRoids ASMWin",0

; Define the Application's Window class structure.
MainWin WNDCLASS <NULL,WinProc,NULL,NULL,NULL,NULL,NULL, \
	COLOR_WINDOW,NULL,className>

msg	      MSGStruct <>
winRect   RECT <>
hMainWnd  DWORD ?
hInstance DWORD ?

;WM_PAINT PROTO hwnd:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD

;=================== MACROS =========================

;-----------------------------------------------------
ConsoleMessage MACRO N
; Macro which writes a complete string to console.
;-----------------------------------------------------
local L

	ifb <&N>
	  exitm
	endif

	push edx
	xor edx,edx
	mov edx, offset &N
	call WriteString
	call CRLF
	pop edx

endm



;=================== CODE =========================
.code
;-----------------------------------------------------
Paint PROC,
	hWnd:DWORD, localMsg:DWORD, wParam:DWORD, lParam:DWORD
; The application's paint handler.
;-----------------------------------------------------
     ; TODO: Paint handler
	push hWnd
	pop hWnd
	push localMsg
	pop localMsg
	push wParam
	pop wParam
	push lParam
	pop lParam

	ret
Paint endP

;-----------------------------------------------------
checkX PROC
; Check X is within window bounds, if not wrap on border
;-----------------------------------------------------
	pushf
	cmp eax,LOWXBND  ; Check for leaving X lower bound
	jle LowX
	cmp eax,UPXBND   ; Check for leaving X upper bound
	jae HighX
	jmp FinXCheck

	LowX:
	mov eax,UPXBND   ; Wrap on X border
	jmp FinXCheck

	HighX:
	mov eax,LOWXBND  ; Wrap on X border

	FinXCheck:
	popf
	ret
checkX endp

;-----------------------------------------------------
checkY PROC
; Check Y is within window bounds, if not wrap on border
;-----------------------------------------------------
	pushf
	cmp eax,LOWYBND  ; Check for leaving Y lower bound
	jle LowY
	cmp eax,UPYBND   ; Check for leaving Y upper bound
	jae HighY
	jmp FinYCheck

	LowY:
	mov eax,UPYBND   ; Wrap on Y border
	jmp FinYCheck

	HighY:
	mov eax,LOWYBND  ; Wrap on Y border

	FinYCheck:
	popf
	ret
checkY endp

;-----------------------------------------------------
checkHeading PROC
; Check H is within 0-360 degrees, if not translate rotation
;-----------------------------------------------------
	pushf
	cmp eax,360     ; Check greater than 360 Degrees
	jge OverH
	cmp eax,0	    ; Check lower than 0 Degrees
	jl UnderH
	jmp FinHCheck

	OverH:
	sub eax,360		; Minus one rotation
	jmp FinHCheck

	UnderH:
	add eax,360		; Plus one rotation

    FinHCheck:
     popf
     ret
checkHeading endp

WinMain PROC
; Get a handle to the current process.
	INVOKE GetModuleHandle, NULL
	mov hInstance, eax
	mov MainWin.hInstance, eax

; Load the program's icon and cursor.
	INVOKE LoadIcon, NULL, IDI_APPLICATION
	mov MainWin.hIcon, eax
	INVOKE LoadCursor, NULL, IDC_ARROW
	mov MainWin.hCursor, eax

; Register the window class.
	INVOKE RegisterClass, ADDR MainWin
	.IF eax == 0
	  call ErrorHandler
	  jmp Exit_Program
	.ENDIF

; Create the application's main window.
; Returns a handle to the main window in EAX.
	INVOKE CreateWindowEx, 0, ADDR className,
	  ADDR WindowName,MAIN_WINDOW_STYLE,
	  CW_USEDEFAULT,CW_USEDEFAULT,CW_USEDEFAULT,
	  CW_USEDEFAULT,NULL,NULL,hInstance,NULL
	mov hMainWnd,eax

; If CreateWindowEx failed, display a message & exit.
	.IF eax == 0
	  call ErrorHandler
	  jmp  Exit_Program
	.ENDIF

; Show and draw the window.
	;Invoke Paint,hWnd,localMsg,wParam,lParam
	INVOKE ShowWindow, hMainWnd, SW_SHOW	
	INVOKE UpdateWindow, hMainWnd

; Display a greeting message.
	INVOKE MessageBox, hMainWnd, ADDR GreetText,
	  ADDR GreetTitle, MB_OK

; Begin the program's message-handling loop.
Main_Loop:
     ; Get next message from the queue.
	INVOKE GetMessage, ADDR msg, NULL,NULL,NULL

	; Quit if no more messages.
	.IF eax == 0
	  jmp Exit_Program
	.ENDIF

	; TODO: Implement Draw Playfield, probably with a C callback program
	

	; TODO: Implement Decrease object acceleration due to inertia

	;-------ACCEL-----------------
	; TODO: Test/Fix ship acceleration
	cmp shipAccel,1
	je AccelTrue
	AccelDone:
	;-------/ACCEL----------------
    
    ;-----BOUNDS------------------
    ; TODO: bounds checking & wrapping for other objects

    ; Ship bounds checking
    push eax
    mov eax,shipLocX
    call checkX
    mov shipLocX,eax
    mov eax,shipLocY
    call checkY
    mov shipLocY,eax
    mov eax,shipHeading
    call checkHeading
    mov shipHeading,eax
    pop eax
  
    ;-----/BOUNDS-----------------

     inc gameTimer;
	push eax
	push ebx
	push edx
	mov ebx,100
	xor edx,edx
	mov eax,gameTimer
	div ebx
	cmp edx,0
	jne NotSecond
	add playerScore,5
	NotSecond:
	pop edx
	pop ebx
	pop eax
	nop
	nop



     MessageCheck:
	; Relay the message to the program's WinProc.
	INVOKE DispatchMessage, ADDR msg
	jmp Main_Loop

    AccelTrue:
     ; TODO: Change to Procedure and add Ship Acceleration with respect to heading
	inc shipLocX
     jmp AccelDone

Exit_Program:
	  ;-----------------------------
       ; Debug Messages to Console
	  ConsoleMessage xPos
       mov eax,shipLocX
	  Call WriteDec
	  Call CRLF

	  ConsoleMessage yPos
	  MOV eax,shipLocY
	  Call WriteDec
	  Call CRLF

	  ConsoleMessage shots
	  MOV eax,shotsFired
	  call WriteDec
	  call CRLF

	  ConsoleMessage sAccel
	  MOV eax,shipAccel
	  call WriteDec
	  call CRLF

	  ConsoleMessage sHeading
	  MOV eax,shipHeading
	  call WriteInt
	  call CRLF

	  ConsoleMessage score
	  MOV eax, playerScore
	  call WriteDec
	  call CRLF

	  ConsoleMessage displayTimer
	  MOV eax, gameTimer
	  call WriteDec
	  call CRLF

	  ConsoleMessage gameOverMessage
	  call CRLF
	  ;-----------------------------

	  INVOKE ExitProcess,0
WinMain ENDP

;-----------------------------------------------------
WinProc PROC,
	hWnd:DWORD, localMsg:DWORD, wParam:DWORD, lParam:DWORD
; The application's message handler, which handles
; application-specific messages. All other messages
; are forwarded to the default Windows message
; handler.
;-----------------------------------------------------

	mov eax, localMsg

	.IF eax == WM_LBUTTONDOWN		; mouse button?
	  INVOKE MessageBox, hWnd, ADDR PopupText,
	    ADDR PopupTitle, MB_OK
	  inc shotsFired			; increase shots fired
	  jmp WinProcExit
	.ELSEIF eax == WM_CREATE		; create window?	  
	  jmp WinProcExit
	.ELSEIF eax == WM_CLOSE		; close window?
	  INVOKE MessageBox, hWnd, ADDR CloseMsg,
	    ADDR WindowName, MB_OK
	  INVOKE PostQuitMessage,0
	  jmp WinProcExit
	.ELSEIF eax == WM_KEYDOWN     ; TODO: Test keyboard controls
	  ;jump table to find virtual key from wparam
	  mov eax,wparam
	  cmp eax,VK_UP			; up arrow
	  je UpKey
	  cmp eax,VK_DOWN			; down arrow
	  je DownKey
	  cmp eax,VK_LEFT			; left arrow
	  je LeftKey
	  cmp eax,VK_RIGHT			; right arrow
	  je RightKey
	  cmp eax,VK_SPACE            ; space bar - toggles thrusters
	  je SpaceKey
	  jmp Default
	  ; Ship movement - 3 pixels per press
	  ; Upper left corner of window is (0,0) Starting point of the ship is (50,50)
	  UpKey:
	    mov shipAccel,1		; fire thrusters
	    endUp:
	    jmp keydownExit
       DownKey:
	    mov shipAccel,0		; turn off thrusters
	    jmp keydownExit
	  LeftKey:
	    sub shipHeading,45	; Decrease Heading by 45 degrees
	    jmp keydownExit
	  RightKey:
	    add shipHeading,45	; Increase Heading by 45 degrees
	    jmp keydownExit
	  SpaceKey:
	    XOR shipAccel,1		; Toggle thrusters
	    jmp keydownExit
       Default:
      keydownExit:
	 jmp WinProcExit
	;.ELSEIF eax == WM_PAINT
	;  jmp WinProcExit
	.ELSE		; other message?
	  INVOKE DefWindowProc, hWnd, localMsg, wParam, lParam
	  jmp WinProcExit
	.ENDIF

WinProcExit:
	ret

WinProc ENDP

;---------------------------------------------------
ErrorHandler PROC
; Display the appropriate system error message.
; Used for real errors.
;---------------------------------------------------
.data
pErrorMsg  DWORD ?		; ptr to error message
messageID  DWORD ?
.code
	INVOKE GetLastError	; Returns message ID in EAX
	mov messageID,eax

	; Get the corresponding message string.
	INVOKE FormatMessage, FORMAT_MESSAGE_ALLOCATE_BUFFER + \
	  FORMAT_MESSAGE_FROM_SYSTEM,NULL,messageID,NULL,
	  ADDR pErrorMsg,NULL,NULL

	; Display the error message.
	INVOKE MessageBox,NULL, pErrorMsg, ADDR ErrorTitle,
	  MB_ICONERROR+MB_OK

	; Free the error message string.
	INVOKE LocalFree, pErrorMsg
	ret
ErrorHandler ENDP

END WinMain
