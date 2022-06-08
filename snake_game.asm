;-------------------------------------------------------------------------------
; FILE: LEDsnake
; AUTH: Ed's Projects
; DATE: 01/09/2016
; DESC: 5x7 LED Dot Matrix Snake Game
;-------------------------------------------------------------------------------
	LIST      	P = 16F887, R=DEC	
	include		<P16F887.inc>		; Define configurations, registers, etc.
 __CONFIG _CONFIG1, _FOSC_XT & _WDTE_OFF & _PWRTE_ON & _MCLRE_OFF & _CP_OFF & _CPD_OFF & _BOREN_ON & _IESO_OFF & _FCMEN_OFF & _LVP_OFF
;-------------------------------------------------------------------------------
;-----------------------------  Port Definitions  ------------------------------
;-------------------------------------------------------------------------------	    
; PortD - Output - RD0 - Pin 19 - Row 1
; PortD - Output - RD1 - Pin 20 - Row 2
; PortD - Output - RD2 - Pin 21 - Row 3
; PortD - Output - RD3 - Pin 22 - Row 4
; PortD - Output - RD4 - Pin 27 - Row 5	
; PortD - Output - RD5 - Pin 28 - Row 6
; PortD - Output - RD6 - Pin 29 - Row 7	
; PortD - Output - RD7 - Pin 30 - Row 7

; PortC - Output - RC0 - Pin 15 - Column 1
; PortC - Output - RC1 - Pin 16 - Column 2
; PortC - Output - RC2 - Pin 17 - Column 3
; PortC - Output - RC3 - Pin 18 - Column 4
; PortC - Output - RC4 - Pin 23 - Column 5
; PortC - Output - RC5 - Pin 24 - Column 6
; PortC - Output - RC6 - Pin 25 - Column 7
; PortC - Output - RC7 - Pin 26 - Column 7
	
; PortB - Input - RB7 - Pin 40 - Button Up
; PortB - Input - RB6 - Pin 39 - Button Down
; PortB - Input - RB5 - Pin 38 - Button Left
; PortB - Input - RB4 - Pin 37 - Button Right	
	
; PortA - Output - RA4 - Pin 3 - Provides pull-up voltage for button resistors		
;-------------------------------------------------------------------------------
;--------------------------------  Variables  ---------------------------------- 
;-------------------------------------------------------------------------------
	    cblock	0x20	    
	    temp
	    temp2
	    temp3
	    temp4
	    temp5
	    C1			;   Column 1 Matrix Display
	    C2
	    C3
	    C4
	    C5			;   Column 5 Matrix Display
	    C6
	    C7
	    C8
	    S1			;   Snake Position Column 1
	    S2			;   Snake Position Column 2
	    S3			;   Snake Position Column 3
	    S4			;   Snake Position Column 4
	    S5			;   Snake Position Column 5
	    S6			;   Snake Position Column 6
	    S7			;   Snake Position Column 7
	    S8			;   Snake Position Column 8
	    Posind		;   Column Indicator, bit4 - 0
	    Posdir		;   Snake Direction 0-up, 1-down, 2-left, 3-right
	    w_save
	    status_save
	    pclath_save
	    snake		;   Snake length
	    colind		;   Collision Indicator
	    apptmr		;   Apple timer
	    T1H			;   Timer1 High
	    endc
;-------------------------------------------------------------------------------
;-----------------------------  Define Symbols  --------------------------------
;-------------------------------------------------------------------------------
	    #define ROW1    PORTD, RD0		
	    #define ROW2    PORTD, RD1
	    #define ROW3    PORTD, RD2
	    #define ROW4    PORTD, RD3
	    #define ROW5    PORTD, RD4
	    #define ROW6    PORTD, RD5
	    #define ROW7    PORTD, RD6
	    #define ROW8    PORTD, RD7
	    #define COL1    PORTC, RC0
	    #define COL2    PORTC, RC1
	    #define COL3    PORTC, RC2
	    #define COL4    PORTC, RC3
	    #define COL5    PORTC, RC4
	    #define COL6    PORTC, RC5
	    #define COL7    PORTC, RC6
	    #define COL8    PORTC, RC7
	    #define LEFT    PORTB, RB4
	    #define RIGHT   PORTB, RB5
	    #define DOWN    PORTB, RB6
	    #define UP	    PORTB, RB7  
;-------------------------------------------------------------------------------
;-------------------------------  Program Code  --------------------------------
;-------------------------------------------------------------------------------
            org	        0 
	    goto	Init
;-------------------------------------------------------------------------------
;-----------------------------  Interrupt Vector  ------------------------------
;-------------------------------------------------------------------------------
            org	        04
	    goto	Interrupt
;-------------------------------------------------------------------------------
;--------------------------  Initialisation of Ports  --------------------------
;-------------------------------------------------------------------------------
Init	    ;PORTC and PORTD pins are outputs, PORTB<RB7-RB4> are inputs
	    banksel	TRISB
	    movlw	0xF0
	    movwf	TRISB
	    clrf	TRISC		
	    clrf	TRISD
	    ;all analogue pins to digital
	    banksel	ANSEL
	    clrf	ANSEL
	    clrf	ANSELH
	    ;set PORTB and PORTD pins LOW and PORTC pins HIGH
	    banksel	PORTB
	    clrf	PORTB
	    clrf	PORTC
	    movlw	0xFF
	    movwf	PORTD
	    ;clear variable's registers 	
	    clrf	Posdir
	    clrf	S1
	    clrf	S2
	    clrf	S3
	    clrf	S4
	    clrf	S5
	    clrf	S6
	    clrf	S7
	    clrf	S8
	    clrf	colind
	    clrf	apptmr
	    movlw	d'3'
	    movwf	snake		; Start with 3 snake segments
	    movlw	d'160'
	    movwf	FSR
clrram	    clrf	INDF
	    incf	FSR, f
	    movf	FSR, w
	    xorlw	d'230'
	    btfss	STATUS, Z
	    goto	clrram
	    
;-------------------------------------------------------------------------------
;-----------------------  Interrupt Timer Initialisation  ----------------------
;-------------------------------------------------------------------------------
	    banksel	T1CON
	    movlw	b'00110100'	;Inicialmente inhabilitado, trabajando con clock interno, no sincronizado ,osc LP apagado ,  prescaler 1:8, gate inhabilitado
	    movwf	T1CON
	    movlw	b'00001011'	;0x0B
	    movwf	TMR1H		;0xDB
	    movlw	b'11011011'
	    movwf	TMR1L		; genera interrupciones del timer1 cada 0.25s
	    banksel	PIE1
	    bsf		PIE1, TMR1IE	; Enable Timer 1 Interrupt
	    banksel	PIR1
	    bcf		PIR1, TMR1IF
	    bsf		INTCON, GIE	;Enable Global Interrupts
	    bsf		INTCON, PEIE	;Enable Peripheral Interrupts for TMR1
;-------------------------------------------------------------------------------
;--------------------------------  Game Initialisaton  -------------------------
;-------------------------------------------------------------------------------
	    ;enable pull ups for RB7-RB4
	    banksel	OPTION_REG
	    bcf		OPTION_REG, NOT_RBPU
	    banksel	WPUB
	    movlw	0xF0
	    movwf	WPUB
	    banksel	PORTA
	    movlw	d'2'
	    call	delay1		; Wait 0.5 second
	    ;here we can set where we want the snake to spawn, we decide to spawn in column 4, row 4
	    movlw	b'00000000'
	    movwf	C1
	    movlw	b'00000000'
	    movwf	C2
	    movlw	b'00000000'
	    movwf	C3
	    movlw	b'00001000'
	    movwf	C4
	    movwf	S4
	    movlw	b'00000000'
	    movwf	C5
	    movlw	b'00000000'
	    movwf	C6
	    movlw	b'00000000'
	    movwf	C7
	    movlw	b'00000000'
	    movwf	C8
	    
	    ;indicamos que la columna de inicio es la 4
	    movlw	b'00001000' 
	    movwf	Posind
here	    call	Button		;verifica si se presiona un botón, y en caso afirmativo que la direccion sea válida, si no lo es la corrige 
	    movf	Posdir, W
	    addlw	d'0'
	    btfsc	STATUS, Z	; Cuando se presiona un botón la serpiente comienza moverse
	    goto	here
	    bsf		T1CON, TMR1ON   ; Start timer counting
	    goto	Start
;-------------------------------------------------------------------------------
;--------------------------------  Delay Loops  --------------------------------
;-------------------------------------------------------------------------------
delay1	    movwf	temp4
loopy2	    movlw	d'100'	    ;mmultiplos ode 2.5ms
	    movwf	temp3
loopy	    movlw	d'250'
	    movwf	temp
initloop    goto	$+1	    ;2us
	    goto	$+1	    ;2us
	    goto	$+1	    ;2us
	    nop			    ;1us
	    decfsz	temp, f	    ;1us
	    goto	initloop    ;2us  
	    decfsz	temp3, f
	    goto	loopy	    ;250ms total
	    decfsz	temp4, f
	    goto	loopy2	    ;multiplos de 250ms
	    return
	    
msdelay	    movlw	d'100'
	    movwf	temp
loop	    goto	$+1	    ;2us
	    goto	$+1	    ;2us
	    goto	$+1	    ;2us
	    nop			    ;1us
	    decfsz	temp, f	    ;1us
	    goto	loop	    ;2us  
	    return	    
;-------------------------------------------------------------------------------
;--------------------------------  Main-----------------------------------------
;-------------------------------------------------------------------------------	
Start	    call	Disp
	    btfss	colind, 0
	    goto	Start
;   GAME OVER
	    bcf		T1CON, TMR1ON   ; frenar la cuenta del timer
	    movlw	d'8'
	    movwf	temp5
gameover    movlw	d'100'		
	    movwf	temp4
	    call	Disp
	    decfsz	temp4, f
	    goto	$-2
	    movlw	d'1'
	    call	delay1		;esperar 250ms
	    decfsz	temp5, f
	    goto	gameover
	    goto	Init		;volver a empezar
;-------------------------------------------------------------------------------
;--------------------------------  Display Cycle  ------------------------------
;-------------------------------------------------------------------------------	    	    
Disp	    movf	C1, w
	    call	PRTLD
	    bsf		COL1
	    call	msdelay
	    bcf		COL1
	    call	Button
	    
	    movf	C2, w
	    call	PRTLD
	    bsf		COL2
	    call	msdelay
	    bcf		COL2
	    call	Button
	    
	    movf	C3, w
	    call	PRTLD
	    bsf		COL3
	    call	msdelay
	    bcf		COL3
	    call	Button
	    
	    movf	C4, w
	    call	PRTLD
	    bsf		COL4
	    call	msdelay
	    bcf		COL4
	    call	Button
	    
	    movf	C5, w
	    call	PRTLD
	    bsf		COL5
	    call	msdelay
	    bcf		COL5
	    call	Button
	    
	    movf	C6, w
	    call	PRTLD
	    bsf		COL6
	    call	msdelay
	    bcf		COL6
	    call	Button
	    
	    movf	C7, w
	    call	PRTLD
	    bsf		COL7
	    call	msdelay
	    bcf		COL7
	    call	Button
	    
	    movf	C8, w
	    call	PRTLD
	    bsf		COL8
	    call	msdelay
	    bcf		COL8
	    call	Button
	    return
	    
PRTLD	    movwf	temp
	    bsf		ROW1
	    bsf		ROW2
	    bsf		ROW3
	    bsf		ROW4
	    bsf		ROW5
	    bsf		ROW6
	    bsf		ROW7
	    bsf		ROW8
	    btfsc	temp, 0
	    bcf		ROW1
	    btfsc	temp, 1
	    bcf		ROW2
	    btfsc	temp, 2
	    bcf		ROW3
	    btfsc	temp, 3
	    bcf		ROW4
	    btfsc	temp, 4
	    bcf		ROW5
	    btfsc	temp, 5
	    bcf		ROW6
	    btfsc	temp, 6
	    bcf		ROW7
	    btfsc	temp, 7
	    bcf		ROW8
	    return
;-------------------------------------------------------------------------------
;--------------------------------  Button Input  -------------------------------
;-------------------------------------------------------------------------------	
Button	    btfss	UP
	    goto	GO_UP
	    btfss	DOWN
	    goto	GO_DOWN
	    btfss	LEFT
	    goto	GO_LEFT
	    btfss	RIGHT
	    goto	GO_RIGHT
	    return	    
GO_UP	    btfsc	Posdir, 1	; Make sure we can't go back on ourself
	    goto	GO_DOWN	
	    movlw	b'00000001'
	    movwf	Posdir
	    return
GO_DOWN	    btfsc	Posdir, 0
	    goto	GO_UP
	    movlw	b'00000010'
	    movwf	Posdir
	    return
GO_LEFT	    btfsc	Posdir, 3
	    goto	GO_RIGHT
	    movlw	b'00000100'
	    movwf	Posdir
	    return
GO_RIGHT    btfsc	Posdir, 2
	    goto	GO_LEFT
	    movlw	b'00001000'
	    movwf	Posdir
	    return	    
;-------------------------------------------------------------------------------
;-----------------------------  Interrupt Program  -----------------------------
;-------------------------------------------------------------------------------	    
Interrupt   bcf		PIR1, TMR1IF	;clear flag 
	    movwf	w_save		;start of context saving
	    movf	STATUS, w
	    clrf	STATUS
	    movwf	status_save
	    movf	PCLATH, w
	    movwf	pclath_save	;end of context saving
	    
	    bcf		T1CON, TMR1ON   ; Stop timer counting
	    movf	T1H, w
	    movwf	TMR1H
	    movlw	b'11011011'
	    movwf	TMR1L		; Half a second
	    bsf		T1CON, TMR1ON   ; Start timer counting
	    
	    btfsc	apptmr, 7	; Bit 7 indicates if there is an aplle still not eaten in de board
	    goto	skip		;skip count, if there is an apple in the board, don't increment the "apple placement" counter
	    incf	apptmr, f	;if there is no apple in the board, increase the count of timer interruptions, and when it goes to 10 go place a new apple in the board
	    movf	apptmr, w
	    xorlw	d'10'
	    btfsc	STATUS, Z
	    call	Apple
skip	    ;depending in wich column was the snake´s head when the interruption ocurred, 
	    btfsc	Posind, 7   ; Are we column 8?
	    goto	Col8
	    btfsc	Posind, 6   ; Are we column 7?
	    goto	Col7
	    btfsc	Posind, 5   ; Are we column 6?
	    goto	Col6
	    btfsc	Posind, 4   ; Are we column 5?
	    goto	Col5
	    btfsc	Posind, 3   ; Are we column 4?
	    goto	Col4
	    btfsc	Posind, 2   ; Are we column 3?
	    goto	Col3
	    btfsc	Posind, 1   ; Are we column 2?
	    goto	Col2
				    ; Then we can only be at column 1	    
Col1	    movf	S1, w
	    call	Checkdir
	    call	Placecont
	    goto	LoadDisp
Col2	    movf	S2, w
	    call	Checkdir
	    call	Placecont
	    goto	LoadDisp
Col3	    movf	S3, w
	    call	Checkdir
	    call	Placecont
	    goto	LoadDisp
Col4	    movf	S4, w
	    call	Checkdir
	    call	Placecont
	    goto	LoadDisp	    
Col5	    movf	S5, w
	    call	Checkdir
	    call	Placecont
	    goto	LoadDisp
Col6	    movf	S6, w
	    call	Checkdir
	    call	Placecont
	    goto	LoadDisp
Col7	    movf	S7, w
	    call	Checkdir
	    call	Placecont
	    goto	LoadDisp
Col8	    movf	S8, w
	    call	Checkdir
	    call	Placecont
	    goto	LoadDisp
	    				    
Placecont   clrf	S8
	    clrf	S7
	    clrf	S6
	    clrf	S5
	    clrf	S4
	    clrf	S3
	    clrf	S2
	    clrf	S1
	    
	    btfsc	Posind, 7   ; Are we to place contents in column 8?
	    goto	PlacA
	    btfsc	Posind, 6   ; Are we to place contents in column 7?
	    goto	PlacB
	    btfsc	Posind, 5   ; Are we to place contents in column 6?
	    goto	PlacC
	    btfsc	Posind, 4   ; Are we to place contents in column 5?
	    goto	PlacD
	    btfsc	Posind, 3   ; Are we to place contents in column 4?
	    goto	PlacE
	    btfsc	Posind, 2   ; Are we to place contents in column 3?
	    goto	PlacF
	    btfsc	Posind, 1   ; Are we to place contents in column 2?
	    goto	PlacG		 
	    
	    movwf	S1	    ; Then we must place them in column 1
	    movwf	temp3
	    clrw
	    call	plcdot	    ; Place dot in counter
	    return
	    
PlacA	    movwf	S8
	    movwf	temp3	    ; Save column offset	    
	    movlw	d'7'	    ; Tells next program what column we're in
	    call	plcdot	    ; Place dot in counter
	    return	
PlacB	    movwf	S7
	    movwf	temp3	    ; Save column offset	    
	    movlw	d'6'	    ; Tells next program what column we're in
	    call	plcdot	    ; Place dot in counter
	    return	
PlacC	    movwf	S6
	    movwf	temp3	    ; Save column offset	    
	    movlw	d'5'	    ; Tells next program what column we're in
	    call	plcdot	    ; Place dot in counter
	    return	
PlacD	    movwf	S5
	    movwf	temp3	    ; Save column offset	    
	    movlw	d'4'	    ; Tells next program what column we're in
	    call	plcdot	    ; Place dot in counter
	    return	    
PlacE	    movwf	S4
	    movwf	temp3	    ; Save column offset 
	    movlw	d'3'	    ; Tells next program what column we're in
	    call	plcdot	    ; Place dot in counter
	    return				    		
PlacF	    movwf	S3
	    movwf	temp3	    ; Save column offset	    
	    movlw	d'2'	    ; Tells next program what column we're in
	    call	plcdot	    ; Place dot in counter
	    return
PlacG	    movwf	S2
	    movwf	temp3	    ; Save column offset    
	    movlw	d'1'	    ; Tells next program what column we're in
	    call	plcdot	    ; Place dot in counter
	    return	    
	    
Checkdir    btfsc	Posdir, 0   ; Going up?
	    goto	DirectU
	    btfsc	Posdir, 1   ; Going down?
	    goto	DirectD
	    btfsc	Posdir, 2   ; Going left?
	    goto	DirectL
	    goto	DirectR    ; Going right then
	    
DirectU	    movwf	temp5
	    rrf		temp5, f
	    btfsc	STATUS, C
	    bsf		temp5, 7
	    movf	temp5, w
	    return
					
DirectD	    movwf	temp5
	    rlf		temp5, f
	    btfsc	STATUS, C
	    call	DirectDa
	    movf	temp5, w
	    return
DirectDa    clrf	temp5
	    bsf		temp5, 0
	    return
	    	    
DirectL	    movwf	temp5
	    rrf		Posind, f
	    btfsc	STATUS, C   ; verifie if active column is the most left (column 0)
	    bsf		Posind, 7
	    movf	temp5, w
	    return

DirectR	    movwf	temp5
	    rlf		Posind, f
	    btfsc	STATUS, C  ; verify if active column is the most left (column 4)
	    call	DirectRa
	    movf	temp5, w
	    return
DirectRa    clrf	Posind
	    bsf		Posind, 0
	    return	    
	    	    
LoadDisp    call	Decdot
	    movf	S1, w
	    iorwf	C1, f
	    movf	S2, w
	    iorwf	C2, f
	    movf	S3, w
	    iorwf	C3, f
	    movf	S4, w
	    iorwf	C4, f
	    movf	S5, w
	    iorwf	C5, f 
	    movf	S6, w
	    iorwf	C6, w
	    movf	S7, w
	    iorwf	C7, w
	    movf	S8, w
	    iorwf	C8, w
	    
	    movf	pclath_save, w
	    movwf	PCLATH
	    movf	status_save, w
	    movwf	STATUS
	    swapf	w_save, f
	    swapf	w_save, w
	    retfie
;-------------------------------------------------------------------------------
;----------------------------  Dot Counter Decrement  --------------------------
;-------------------------------------------------------------------------------	    
Decdot	    movlw	d'160'
	    movwf	temp2
	    clrf	temp3
dotdecloop  movf	temp2, w
	    movwf	FSR
	    movlw	d'1'
	    subwf	INDF, f
	    btfss	STATUS, C
	    clrf	INDF
	    movf	INDF, w
	    addlw	d'0'
	    btfsc	STATUS, Z  
	    call	delum		; Deluminate LED's if RAM empty
	    incf	temp3, f
	    incf	temp3, f
	    incf	temp2, f
	    movf	temp2, w
	    xorlw	d'223'
	    btfss	STATUS, Z
	    goto	dotdecloop
	    movf	temp4, w
	    movwf	FSR
	    movlw	d'0'
	    addwf	INDF, w
	    btfss	STATUS, Z
	    call	colapp
	    movf	snake, w
	    movwf	INDF
	    return
colapp	    btfsc	INDF, 7		; Bit 7 set indicates apple
	    goto	apcl
	    bsf		colind, 0
	    return
apcl	    clrf	apptmr
	    incf	snake, f
	    return	    

delum	    movlw	LOW table      ; Deluminate chosen LED
	    addwf	temp3,  w     
	    movlw	HIGH table    
	    btfsc	STATUS, C       
	    addlw	1              
	    movwf	PCLATH          
	    movlw	LOW table     
	    addwf	temp3, w       
	    movwf	PCL             	    
table	    bcf		C1, 0	
	    return
	    bcf		C2, 0	
	    return
	    bcf		C3, 0	
	    return
	    bcf		C4, 0	
	    return
	    bcf		C5, 0	
	    return
	    bcf		C6, 0	
	    return
	    bcf		C7, 0	
	    return
	    bcf		C8, 0	
	    return
	    bcf		C1, 1	
	    return
	    bcf		C2, 1
	    return
	    bcf		C3, 1	
	    return
	    bcf		C4, 1	
	    return
	    bcf		C5, 1	
	    return
	    bcf		C6, 1	
	    return
	    bcf		C7, 1	
	    return
	    bcf		C8, 1	
	    return
	    bcf		C1, 2	
	    return
	    bcf		C2, 2	
	    return
	    bcf		C3, 2	
	    return
	    bcf		C4, 2	
	    return
	    bcf		C5, 2	
	    return
	    bcf		C6, 2
	    return
	    bcf		C7, 2	
	    return
	    bcf		C8, 2	
	    return
	    bcf		C1, 3	
	    return
	    bcf		C2, 3	
	    return
	    bcf		C3, 3	
	    return
	    bcf		C4, 3	
	    return
	    bcf		C5, 3	
	    return
	    bcf		C6, 3	
	    return
	    bcf		C7, 3	
	    return
	    bcf		C8, 3	
	    return
	    bcf		C1, 4	
	    return
	    bcf		C2, 4	
	    return
	    bcf		C3, 4
	    return
	    bcf		C4, 4
	    return
	    bcf		C5, 4
	    return
	    bcf		C6, 4	
	    return
	    bcf		C7, 4
	    return
	    bcf		C8, 4
	    return
	    bcf		C1, 5	
	    return
	    bcf		C2, 5
	    return
	    bcf		C3, 5	
	    return
	    bcf		C4, 5	
	    return
	    bcf		C5, 5	
	    return
	    bcf		C6, 5	
	    return
	    bcf		C7, 5	
	    return
	    bcf		C8, 5	
	    return
	    bcf		C1, 6	
	    return
	    bcf		C2, 6	
	    return
	    bcf		C3, 6	
	    return
	    bcf		C4, 6	
	    return
	    bcf		C5, 6	
	    return
	    bcf		C6, 6	
	    return
	    bcf		C7, 6	
	    return
	    bcf		C8, 6	
	    return
	    bcf		C1, 7	
	    return
	    bcf		C2, 7	
	    return
	    bcf		C3, 7	
	    return
	    bcf		C4, 7	
	    return
	    bcf		C5, 7	
	    return
	    bcf		C6, 7	
	    return
	    bcf		C7, 7	
	    return
	    bcf		C8, 7	
	    return
;-------------------------------------------------------------------------------
;----------------------------  Dot Counter Increment  --------------------------
;-------------------------------------------------------------------------------	    
plcdot	    addlw	d'160'	    ;A0 -> fila 0 por defecto
	    btfsc	temp3, 7    ;fila 8?
	    addlw	d'56'	    ;D8
	    btfsc	temp3, 6    ;fila 7?
	    addlw	d'48'	    ;D0
	    btfsc	temp3, 5    ;fila 6?
	    addlw	d'40'	    ;C8
	    btfsc	temp3, 4    ;fila 5?
	    addlw	d'32'	    ;C8
	    btfsc	temp3, 3    ;fila 4?
	    addlw	d'24'	    ;B8
	    btfsc	temp3, 2    ;fila 3?
	    addlw	d'16'	    ;B0
	    btfsc	temp3, 1    ;fila 2?
	    addlw	d'8'	    ;A8
	    movwf	temp4
Ilum	    movlw	d'127'
	    movwf	C1
	    movwf	C2
	    movwf	C3
	    movwf	C4
	    movwf	C5
	    movwf	C6
	    movwf	C7
	    movwf	C8
	    return
;-------------------------------------------------------------------------------
;---------------------------  Random Apple Generator  --------------------------
;-------------------------------------------------------------------------------	    
Apple	    movlw	b'10000000'
	    movwf	apptmr		; Clear count of 10 timer interrupts and states that an apple is present
	    call	Random		; Fetch a "sort of" random number
	    addlw	d'159'		
	    movwf	FSR
notclr	    incf	FSR, f
	    movf	INDF, w
	    addlw	d'0'
	    btfsc	STATUS, Z
	    goto	addapple
	    movf	FSR, w
	    addlw	d'33'		;aseguramos que no sea mayor a 223
	    btfss	STATUS, C
	    goto	notclr		; Location not clear, try again.
	    movlw	d'159'
	    movwf	FSR
	    goto	notclr		; Location not clear, try again.
	    
addapple    movlw	d'255'
	    movwf	INDF		; Seventh bit indicates apple to collision			
	    movlw	d'7'		; program.
	    addwf	T1H, f		; Increase snake speed.		    
	    return			
;-------------------------------------------------------------------------------
;----------------------------  Random Number Routine  --------------------------
;-------------------------------------------------------------------------------	    
Random	    movf	snake, w
	    movwf	temp3
	    movlw	LOW Rantbl      
	    addwf	temp3,  w     
	    movlw	HIGH Rantbl    
	    btfsc	STATUS, C       
	    addlw	1              
	    movwf	PCLATH          
	    movlw	LOW Rantbl     
	    addwf	temp3, w       
	    movwf	PCL             	    
Rantbl	    retlw	d'2'
	    retlw	d'49'
	    retlw	d'7'
	    retlw	d'62'
	    retlw	d'11'
	    retlw	d'42'
	    retlw	d'50'
	    retlw	d'37'
	    retlw	d'54'
	    retlw	d'47'
	    retlw	d'3'
	    retlw	d'59'
	    retlw	d'61'
	    retlw	d'21'
	    retlw	d'6'
	    retlw	d'40'
	    retlw	d'19'
	    retlw	d'34'
	    retlw	d'10'
	    retlw	d'8'
	    retlw	d'41'
	    retlw	d'58'
	    retlw	d'18'
	    retlw	d'46'
	    retlw	d'53'
	    retlw	d'26'
	    retlw	d'51'
	    retlw	d'25'
	    retlw	d'33'
	    retlw	d'1'
	    retlw	d'45'
	    retlw	d'9'
	    retlw	d'0'
	    retlw	d'57'
	    retlw	d'35'
	    retlw	d'32'
	    retlw	d'52'
	    retlw	d'17'
	    retlw	d'4'
	    retlw	d'22'
	    retlw	d'43'
	    retlw	d'55'
	    retlw	d'5'
	    retlw	d'12'
	    retlw	d'60'
	    retlw	d'16'
	    retlw	d'20'
	    retlw	d'30'
	    retlw	d'39'
	    retlw	d'63'
	    retlw	d'24'
	    retlw	d'31'
	    retlw	d'56'
	    retlw	d'36'
	    retlw	d'48'
	    retlw	d'13'
	    retlw	d'27'
	    retlw	d'15'
	    retlw	d'23'
	    retlw	d'38'
	    retlw	d'44'
	    retlw	d'28'
	    retlw	d'14'
	    retlw	d'29'
	end