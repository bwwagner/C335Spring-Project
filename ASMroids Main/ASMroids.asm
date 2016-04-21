;ASMroids.asm
;A simple action shooter
;Windows32 Application 
;Author: Branden Wagner

;Include files from Irvine libraries found in the ..\Irvine folder
INCLUDE Irvine32.inc
INCLUDE GraphWin.inc

;==================== DATA =======================
.data
; NULL - Set by Irvine
; Playfield values
LOWXBND	EQU 0
LOWYBND	EQU 0
UPXBND	EQU 800
UPYBND	EQU 600
SSPAWNX	EQU 400
SSPAWNY	EQU 300
MAXSHOTS	EQU 3
MAXASTER	EQU 6
LOOPSSEC	EQU 70
SHOTTIME	EQU 30

; Game data structures
shot		STRUC
	xCoord	DWORD 0		; shot position = ship position at spawn
	yCoord	DWORD 0
	heading	DWORD 0		; shot heading = ship heading at spawn
	accel	DWORD 10		; base acceleration of shot is 10 coords/cycle
	time		DWORD 30		; number of loops active, roughly 1/2 sec
	active	DWORD 0		; 1 = in play, 0 = not in play
	next		DWORD NULL
shot		ENDS

roid		STRUC
	xCoord	DWORD 0		; Roid position assigned randomly at spawn
	yCoord	DWORD 0
	heading	DWORD 0		; Roid heading random at spawn
	accel	DWORD 2		; Base acceleration one less than ship max thrust
	active	DWORD 0		; 1 = in play, 0 = not in play
	next		DWORD NULL
roid		ENDS

ship		STRUC
	xCoord	DWORD SSPAWNX	; Ship starting position roughly middle of playfield
	yCoord	DWORD SSPAWNY	
	heading	DWORD 90		; Ship heading 90 degrees 
	accel	DWORD 0		; Ship starting acceleration 0 = stationary
	next		DWORD NULL
ship		ENDS



; Struc Values
ship1		ship {SSPAWNX,SSPAWNY,90,0,NULL}
shot1		shot {0,0,0,0,0,0,NULL}
roid1		roid {0,0,0,0,0,NULL}
shipString	BYTE "V",0
; roid string [0] = Large, [1] = Medium, [2] = Small  
roidString1	BYTE "FOR (int y = 0, y > y, y++)(while 0 == 0)", "{ int y:= 0", "/n",0
shotString	BYTE ".",0

; Other Values
shotsFired	DWORD 0		; number of shots fired
gameCycles	DWORD 0		; number of loops through main
paused		DWORD 0		; game paused 1 = paused, 0 = not paused

; Player Values
playerScore	DWORD 0		; player score
playerLives	DWORD 3		; player number of lives/tries

; Welcome Message
GreetTitle BYTE "ASMroids",0
GreetText  BYTE "Welcome to ASMroids! "
	       BYTE "Press OK to begin. ",0

; Exit Message
CloseMsg   BYTE "Thank you for playing!",0

; Continue Message
continueF2 BYTE "Press F2 to continue", 0

; Fake errror message strings to display at game end
gameOverMessage BYTE "Warning: Unreachable code detected.", "Error Line A70 - Termination Expected.",
				 "/n is not a recognized character.", 0

; Playtest messages
PopupTitle BYTE "Weapon Fired!",0
PopupText  BYTE "PEW! "
	       BYTE "PEW!",0

;Debug Messages
debugMode DWORD 1		; Debug Mode on = 1, off = 0
shots BYTE "Shots Fired: ",0
xPos BYTE "Ship X Coord: ",0
yPos BYTE "Ship Y Coord: ",0
score BYTE "Player Score: ",0
sAccel BYTE "Ship Acceleration: ",0
pLives BYTE "Player Lives: ",0
sHeading BYTE "Ship heading: ",0
divider BYTE "------------------------",0
displayTimer BYTE "Game time: ",0
shot1X	 BYTE "Shot1 X Coord: ",0
shot1Y	 BYTE "Shot1 Y Coord: ",0
shot1Head	 BYTE "Shot1 Heading: ",0
shot1Time  BYTE "Shot1 Time: ",0

; Window Pane Strings
ErrorTitle  BYTE "Error",0
WindowName  BYTE "ASMroids",0
className   BYTE "ASMroids ASMWin",0

; Define the Application's Window class structure.
MainWin WNDCLASS <NULL,WinProc,NULL,NULL,NULL,NULL,NULL, \
	COLOR_WINDOW,NULL,className>

msg	      MSGStruct <>
winRect   RECT <>
hMainWnd  DWORD ?
hInstance DWORD ?


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
	cmp eax,0		 ; Check lower than 0 Degrees
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

;-----------------------------------------------------
doAccel PROC N : near ptr ship 
; Pass location and accel by reference and add them
;-----------------------------------------------------
	mov ebx,N
	cmp ebx,NULL
	je NoAccel

	mov eax,N.ship.xcoord
	mov ebx,N.ship.accel
	add eax,ebx

    NoAccel:
     ret
doAccel endp

;-----------------------------------------------------
WinMain PROC
; Get a handle to the current process.
;-----------------------------------------------------
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

	cmp paused,1
	je MessageCheck

	; TODO: Fully Implement Clean up objects
	
	;Check Shot Time left
	mov eax,shot1.time
	cmp eax,0
	je DecelShip
	dec eax
	mov shot1.time,eax
	cmp eax,0
	jnz DecelShip
	mov shot1.active,eax

	DecelShip:
	cmp ship1.accel,0
	je NoDecel
	dec ship1.accel

	NoDecel:

	; TODO: Implement Roid Spawning

	; TODO: Implement Draw Playfield
	ConsoleMessage shipString
	ConsoleMessage shotString
	ConsoleMessage roidString1


	;-------ACCEL-----------------
	; TODO: Test/Fix ship acceleration
	push eax
	push ebx
	mov eax,ship1.xcoord
	mov ebx,ship1.accel
	add eax,ebx
	mov ship1.xcoord,eax

	mov eax,shot1.time
	cmp eax,0
	jle EndShotAccel
	mov eax,shot1.xcoord
	mov ebx,shot1.accel
	add eax,ebx
	mov shot1.xcoord,eax

	EndShotAccel:
	pop eax
	pop ebx

	;-------/ACCEL----------------
    
    ;-----BOUNDS------------------
    ; TODO: Collision Detection, bounds checking & wrapping for other objects

    ; Ship bounds checking
    push eax
    mov eax,ship1.xcoord
    call checkX
    mov ship1.xcoord,eax
    mov eax,ship1.ycoord
    call checkY
    mov ship1.ycoord,eax
    mov eax,ship1.heading
    call checkHeading
    mov ship1.heading,eax

    mov eax,shot1.xcoord
    call checkX
    mov shot1.xcoord,eax
    mov eax,shot1.ycoord
    call checkY
    mov shot1.ycoord,eax
    mov eax,shot1.heading
    call checkHeading
    mov shot1.heading,eax

    mov eax,shot1.active
    mov shotsFired,eax

    mov eax,roid1.xcoord
    call checkX
    mov roid1.xcoord,eax
    mov eax,roid1.ycoord
    call checkY
    mov roid1.ycoord,eax
    mov eax,roid1.heading
    call checkHeading
    mov roid1.heading,eax


    pop eax
  
    ;-----/BOUNDS-----------------

     inc gameCycles;
	push eax
	push ebx
	push edx
	mov ebx,LOOPSSEC
	xor edx,edx
	mov eax,gameCycles
	div ebx
	cmp edx,0
	jne NotSecond
	add playerScore,5        ; Increase score 5 roughly once every second
	NotSecond:
	pop edx
	pop ebx
	pop eax
	
	;-----Game Over-----------------
	; Check Game Over
	cmp playerLives,0
	jne MessageCheck
	ConsoleMessage gameOverMessage
	call CRLF
	ConsoleMessage score
	  MOV eax, playerScore
	  call WriteDec
	  call CRLF
	ConsoleMessage continueF2
	mov paused,1		; Pause after game over
	mov playerLives,3
	mov playerScore,0
	;-----/Game Over-----------------

     MessageCheck:
	; Relay the message to the program's WinProc.
	INVOKE DispatchMessage, ADDR msg
	jmp Main_Loop


Exit_Program:
	  ;-----------------------------
	  ; Debug Messages to Console
	  cmp debugMode,1
	  jne NoDebug		; Skip if debugMode = 0
       
	  ConsoleMessage divider
	  Call CRLF

	  ConsoleMessage xPos
       mov eax,ship1.xcoord
	  Call WriteDec
	  Call CRLF

	  ConsoleMessage yPos
	  MOV eax,ship1.ycoord
	  Call WriteDec
	  Call CRLF

	  ConsoleMessage shots
	  MOV eax,shotsFired
	  call WriteDec
	  call CRLF

	  ConsoleMessage sAccel
	  MOV eax,ship1.accel
	  call WriteDec
	  call CRLF

	  ConsoleMessage sHeading
	  MOV eax,ship1.heading
	  call WriteInt
	  call CRLF

	  ConsoleMessage divider
	  call CRLF

	  ConsoleMessage shot1X
	  MOV eax,shot1.xcoord
	  call WriteInt
	  call CRLF

	  ConsoleMessage shot1Y
	  MOV eax,shot1.ycoord
	  call WriteInt
	  call CRLF

	  ConsoleMessage shot1Head
	  MOV eax,shot1.heading
	  call WriteInt
	  call CRLF

	  ConsoleMessage shot1Time
	  MOV eax,shot1.time
	  call WriteInt
	  call CRLF

	  ConsoleMessage divider
	  Call CRLF

	  ConsoleMessage score
	  MOV eax, playerScore
	  call WriteDec
	  call CRLF

	  ConsoleMessage displayTimer
	  MOV eax, gameCycles
	  call WriteDec
	  call CRLF

	  ;-----------------------------
	  NoDebug:
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
	  ; TODO: Check against max number of shots
	  inc shotsFired			; increase shots fired
	  cmp shotsFired,MAXSHOTS
	  ja NoShotLeft
	  push eax
	  mov eax,shot1.time
	  add eax,SHOTTIME
	  mov shot1.time,eax
	  mov shot1.active,1
	  pop eax

	  NoShotLeft:
	  jmp WinProcExit
	.ELSEIF eax == WM_CREATE		; create window?	  
	  jmp WinProcExit
	.ELSEIF eax == WM_CLOSE		; close window?
	  INVOKE MessageBox, hWnd, ADDR CloseMsg,
	    ADDR WindowName, MB_OK
	  INVOKE PostQuitMessage,0
	  jmp WinProcExit
	.ELSEIF eax == WM_KEYDOWN     ; Done: Test keyboard controls
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
	  cmp eax,VK_F1			; F1 - toggles debug
	  je F1Key
	  cmp eax,VK_F2			; F2 - toggles pause
	  je F2Key
	  cmp eax,VK_F4			; F4 - Auto Game Over
	  je F4Key
	  jmp Default
	  ; Ship movement - 3 coords max, 1 coord min
	  ; Upper left corner of window is (0,0) Starting point of the ship is (SSPAWNX,SSPAWNY)
	  UpKey:
	    add ship1.accel,3		; fire thrusters (max)
	    endUp:
	    jmp keydownExit
       DownKey:
	    mov ship1.accel,0		; turn off thrusters
	    jmp keydownExit
	  LeftKey:
	    sub ship1.heading,45		; Decrease Heading by 45 degrees
	    jmp keydownExit
	  RightKey:
	    add ship1.heading,45		; Increase Heading by 45 degrees
	    jmp keydownExit
	  SpaceKey:
	    XOR ship1.accel,1		; Toggle thrusters (min)
	    jmp keydownExit
	  F1Key:
	    XOR debugMode,1			; Toggle Debug Mode
	    jmp keydownExit
	  F2Key:
	    XOR paused,1			; Pause game
	    ConsoleMessage continueF2
	    jmp keydownExit
	  F4Key:					
	    mov playerLives,0		; Test Game Over
	    jmp keydownExit
       Default:
      keydownExit:
	 jmp WinProcExit
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
