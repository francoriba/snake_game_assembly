;****************************************************************************************************************************************************
;****************************************************************************************************************************************************
; AUTORES: Franco Riba y Kevil Walter Reynoso Choque 
; FECHA: 08/06/2022
; HARDWARE: PIC16F887
; DESCRIPCIÓN: Videojuego Snake con display en matriz 8x8, programado en lenguaje ensamblador
; CONTEXTO: Este es el proyecto integrador de fin de curso de la asignatura Electrónica Digital 2, de la FCEFyN, Universidad Nacional de Córdoba, UNC
;*****************************************************************************************************************************************************
;*****************************************************************************************************************************************************
;-------------------------------------------------------------------------------
;-----------------------------  Precompilación  --------------------------------
;-------------------------------------------------------------------------------
	LIST      	P = 16F887, R=DEC	
	include		<P16F887.inc>		
 __CONFIG _CONFIG1, _INTOSC & _WDTE_OFF & _PWRTE_ON & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_OFF & _IESO_OFF & _FCMEN_OFF & _LVP_OFF
 __CONFIG _CONFIG2, _BOR4V_BOR40V & _WRT_OFF
;-------------------------------------------------------------------------------
;-----------------------------  Descripción de Puertos en Hardware  ------------
;-------------------------------------------------------------------------------	    
; PORTD - Salida - RD0 - Pin 19 - Row 1
; PORTD - Salida - RD1 - Pin 20 - Row 2
; PORTD - Salida - RD2 - Pin 21 - Row 3
; PORTD - Salida - RD3 - Pin 22 - Row 4
; PORTD - Salida - RD4 - Pin 27 - Row 5	
; PORTD - Salida - RD5 - Pin 28 - Row 6
; PORTD - Salida - RD6 - Pin 29 - Row 7	
; PORTD - Salida - RD7 - Pin 30 - Row 7

; PORTC - Salida - RC0 - Pin 15 - Column 1
; PORTC - Salida - RC1 - Pin 16 - Column 2
; PORTC - Salida - RC2 - Pin 17 - Column 3
; PORTC - Salida - RC3 - Pin 18 - Column 4
; PORTC - Salida - RC4 - Pin 23 - Column 5
; PORTC - Salida - RC5 - Pin 24 - Column 6
; PORTC - Salida - RB2 - Pin 25 - Column 7
; PORTC - Salida - RB3 - Pin 26 - Column 8
	
; PORTB - Entrada - RB7 - Pin 40 - Botón DOWN
; PORTB - Entrada - RB6 - Pin 39 - Botón UP
; PORTB - Entrada - RB5 - Pin 38 - Botón LEFT
; PORTB - Entrada - RB4 - Pin 37 - Botón RIGHT
		
;-------------------------------------------------------------------------------
;--------------------------------  Variables  ---------------------------------- 
;-------------------------------------------------------------------------------
	    cblock	0x20	    
	    temp
	    temp2
	    temp3
	    temp4
	    temp5
	    C1			;   Columna 1 de display de matriz
	    C2			;   Columna 2 de display de matriz
	    C3			;   Columna 3 de display de matriz
	    C4			;   Columna 4 de display de matriz
	    C5			;   Columna 5 de display de matriz
	    C6			;   Columna 6 de display de matriz
	    C7			;   Columna 7 de display de matriz
	    C8			;   Columna 8 de display de matriz
	    S1			;   Posición del snake en la columna 1 
	    S2			;   Posición del snake en la columna 2 
	    S3			;   Posición del snake en la columna 3 
	    S4			;   Posición del snake en la columna 4 
	    S5			;   Posición del snake en la columna 5 
	    S6			;   Posición del snake en la columna 6 
	    S7			;   Posición del snake en la columna 7 
	    S8			;   Posición del snake en la columna 8 
	    Posind		;   Indicador de columna, bits 4-0
	    Posdir		;   Dirección del snake 0-up, 1-down, 2-left, 3-right
	    w_save
	    status_save
	    pclath_save
	    snake		;   Tamaño del snake (cant de segmentos)
	    colind		;   Indicador de colisión
	    rattmr		;   Indica si ocurrieron las suficientes interrupciones del timer para agregar una nueva rata 
	    T1H			;   Timer1 High
	    endc
;-------------------------------------------------------------------------------
;-----------------------------  Simbolos  --------------------------------------
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
	    #define COL7    PORTB, RB2
	    #define COL8    PORTB, RB3
	    #define LEFT    PORTB, RB5
	    #define RIGHT   PORTB, RB4
	    #define DOWN    PORTB, RB6
	    #define UP	    PORTB, RB7  

            org	        0 
	    goto	Init
;-------------------------------------------------------------------------------
;-----------------------------  Vector de interrupción  ------------------------
;-------------------------------------------------------------------------------
            org	        04
	    goto	ISR
;-------------------------------------------------------------------------------
;--------------------------  Inicializacion de Puertos  ------------------------
;-------------------------------------------------------------------------------
Init	    
	    ;PORTC y PORTD salidas, PORTB<RB7-RB4> entradas
	    banksel	TRISB
	    movlw	0xF0
	    movwf	TRISB
	    clrf	TRISC		
	    clrf	TRISD
	    ;todos los pines analogicos los hacemos digitales
	    banksel	ANSEL
	    clrf	ANSEL
	    clrf	ANSELH
	    ;comenzamos con pines de PORTB y PORTD seteados en bajo, y pines de PORTC seteados en alto
	    banksel	PORTB
	    clrf	PORTB
	    clrf	PORTC
	    movlw	0xFF
	    movwf	PORTD
	    ;limpiamos los registros de variables para la lógica	
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
	    clrf	rattmr
	    movlw	d'1'
	    movwf	snake		; El snake empieza con un tamaño de 1 segmento
	    movlw	d'160'
	    movwf	FSR
clrram	    clrf	INDF
	    incf	FSR, f
	    movf	FSR, w
	    xorlw	d'230'
	    btfss	STATUS, Z
	    goto	clrram
	    ;configuración de interrupciones para comunicación serie (recepción) 
	    banksel	PIE1
	    bsf		PIE1, RCIE ;habilta interrupciones para recepción serie
	    bsf		PIE1, TXIE ;habilta interrupciones para transmisión serie
	    banksel	PIR1
	    bcf		PIR1, RCIF ;comienza con el flag de recepción bajo
	    bcf		PIR1, TXIF ;comienza con el flag de transmisión bajo
	    ;confgiración del registro de estado y control de recepción 
	    banksel	RCSTA
	    bsf		RCSTA, CREN ;habilita la recepción continua da datos
	    bsf		RCSTA, SPEN ;habilita el puerto serie
	    banksel	SPBRG
	    movlw	.29
	    movwf	SPBRG
	    ;configuración para la comunicación serie (transmisión)
	    banksel	TXSTA
	    bsf		TXSTA, TXEN ; Habilitación de transmisión 
	    bsf		TXSTA, BRGH ; Alta velocidad de baudrate activada
	    bcf		TXSTA, SYNC ; modo asincrono
	    
;-------------------------------------------------------------------------------
;-----------------------  Inicialización de la int del TMR0  -------------------
;-------------------------------------------------------------------------------
	    banksel	T1CON
	    movlw	b'00110100'	;Inicialmente inhabilitado, trabajando con clock interno, no sincronizado ,osc LP apagado ,  prescaler 1:8, gate inhabilitado
	    movwf	T1CON
	    movlw	b'00001011'	;0x0B
	    movwf	TMR1H		;0xDB
	    movlw	b'11011011'
	    movwf	TMR1L		; genera interrupciones del timer1 cada 0.25s
	    banksel	PIE1
	    bsf		PIE1, TMR1IE	;Habilitación de interrupciones por TMR1
	    banksel	PIR1
	    bcf		PIR1, TMR1IF
	    bsf		INTCON, GIE	;Interrupciones Globales Habilitadas
	    bsf		INTCON, PEIE	;Habilitación por periféricos habilitada (para el TMR1)
;-------------------------------------------------------------------------------
;--------------------------------  Inicialización del Juego  -------------------
;-------------------------------------------------------------------------------
	    ;habilitamos pull-ups para RB7-RB4
	    banksel	OPTION_REG
	    bcf		OPTION_REG, NOT_RBPU
	    banksel	WPUB
	    movlw	0xF0
	    movwf	WPUB
	    banksel	PORTA
	    movlw	d'2'		;cargamos variable para retardo por software 
	    call	delay1		; Demora de 0.5s
	    ;definimos el punto donde spawnea la serpiente
	    movlw	b'00000000'
	    movwf	C1
	    movlw	b'00000000'
	    movwf	C2
	    movlw	b'00000000'
	    movwf	C3
	    movlw	b'00001000'	    ; por d efecto spawnea en la columna 4, fila 4
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
;--------------------------------  Loops de Delays  ----------------------------
;-------------------------------------------------------------------------------
delay1	    movwf	temp4
loopy2	    movlw	d'100'	    ;multiplos ode 2.5ms
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
;--------------------------------  Ciclo de Display  ---------------------------
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
;--------------------------------  Entrada de Pulsador  ------------------------
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
GO_UP	    btfsc	Posdir, 1	;nos aseguramos que el snake no pueda volver sobre si mismo
	    goto	GO_DOWN	
	    movlw	b'00000001'
	    movwf	Posdir
	    return
GO_DOWN	    btfsc	Posdir, 0	;nos aseguramos que el snake no pueda volver sobre si mismo
	    goto	GO_UP
	    movlw	b'00000010'
	    movwf	Posdir
	    return
GO_LEFT	    btfsc	Posdir, 3	;nos aseguramos que el snake no pueda volver sobre si mismo
	    goto	GO_RIGHT
	    movlw	b'00000100'
	    movwf	Posdir
	    return
GO_RIGHT    btfsc	Posdir, 2	;nos aseguramos que el snake no pueda volver sobre si mismo
	    goto	GO_LEFT
	    movlw	b'00001000'
	    movwf	Posdir
	    return	    
;-------------------------------------------------------------------------------
;-----------------------------  Programa de Interrupción  -----------------------
;-------------------------------------------------------------------------------	    
ISR	    
	    banksel	PIR1
	    btfsc	PIR1, TMR1IF
	    goto	TMR1_INT
	    btfsc	PIR1, RCIF
	    goto	RX_INT
	    goto	END_ISR
	    
RX_INT	    ; el flag se baja automaticamente luego de leer RCREG
	    banksel		RCREG
	    movf		RCREG, W
	    movwf		Posdir	
	    goto		END_ISR
TMR1_INT
	    bcf		PIR1, TMR1IF	;limpiamos flag del timer1
	    movwf	w_save		;guardamos contexto
	    movf	STATUS, w
	    clrf	STATUS
	    movwf	status_save
	    movf	PCLATH, w
	    movwf	pclath_save	
	    
	    bcf		T1CON, TMR1ON   ; Detenemos el timer
	    movf	T1H, w
	    movwf	TMR1H
	    movlw	b'11011011'
	    movwf	TMR1L		; Cargamos el timer para que interrumpa cada 0,5 s
	    bsf		T1CON, TMR1ON   ; Lanzamos el timer nuevamente
	    
	    btfsc	rattmr, 7	; El bit 7 inidica si hay una rata todavía no comida en el tablero
	    goto	skip		;saltear, si ya hay una rat no se incrementa el contador de 10 interrupciones del timer1
	    incf	rattmr, f	;si no hay rata en la tabla, incrementamos el contador de 10 interrupciones del timer1
	    movf	rattmr, w	; y cuando llega a 10 colocamos una nueva rata en la tabla
	    xorlw	d'10'
	    btfsc	STATUS, Z
	    call	Rat
skip	    ;averiguamos en que columna se encotnraba el head del snake al momento de la interrupción 
	    btfsc	Posind, 7   ; Columna 8?
	    goto	Col8
	    btfsc	Posind, 6   ; Columna 7?
	    goto	Col7
	    btfsc	Posind, 5   ; Columna 6?
	    goto	Col6
	    btfsc	Posind, 4   ; Columna 5?
	    goto	Col5
	    btfsc	Posind, 3   ; Columna 4?
	    goto	Col4
	    btfsc	Posind, 2   ; Columna 3?
	    goto	Col3
	    btfsc	Posind, 1   ; Columna 2?
	    goto	Col2
				    ; Entonces la columna 1    
	    movf	S1, w
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
	    
	    btfsc	Posind, 7   ; Debemos cargar registro de la columna 8?
	    goto	PlacA
	    btfsc	Posind, 6   ; Debemos cargar  registro de la columna 7?
	    goto	PlacB
	    btfsc	Posind, 5   ; Debemos cargar registro de la columna 6?
	    goto	PlacC
	    btfsc	Posind, 4   ; Debemos cargar  registro de la columna 5?
	    goto	PlacD
	    btfsc	Posind, 3   ; Debemos cargar registro de la columna 4?
	    goto	PlacE
	    btfsc	Posind, 2   ; Debemos cargar registro de la columna 3?
	    goto	PlacF
	    btfsc	Posind, 1   ; Debemos cargar registro de la columna 2?
	    goto	PlacG		 
	    movwf	S1	    ; Debemos cargar registro de la columna 1
	    movwf	temp3
	    clrw
	    call	plcdot	    ; El registro a cargar mapea con la columna 1, ahora averiguamos con que fila mapea
	    return
	    
PlacA	    movwf	S8
	    movwf	temp3	    ; guardamos el offset de la columna	    
	    movlw	d'7'	    ; Indicamos la columna en la que estamos
	    call	plcdot	    ; El registro a cargar mapea con la columna 8, ahora averiguamos con que fila mapea
	    return	
PlacB	    movwf	S7
	    movwf	temp3	    ; guardamos el offset de la columna	 	    
	    movlw	d'6'	    ; Indicamos la columna en la que estamos
	    call	plcdot	    ; El registro a cargar mapea con la columna 7, ahora averiguamos con que fila mapea
	    return	
PlacC	    movwf	S6
	    movwf	temp3	    ; guardamos el offset de la columna	 	    
	    movlw	d'5'	    ; Indicamos la columna en la que estamos
	    call	plcdot	    ; El registro a cargar mapea con la columna 6, ahora averiguamos con que fila mapea
	    return	
PlacD	    movwf	S5
	    movwf	temp3	    ; guardamos el offset de la columna	 	    
	    movlw	d'4'	    ; Indicamos la columna en la que estamos
	    call	plcdot	    ; El registro a cargar mapea con la columna 5, ahora averiguamos con que fila mapea
	    return	    
PlacE	    movwf	S4
	    movwf	temp3	    ; guardamos el offset de la columna	 
	    movlw	d'3'	    ; Indicamos la columna en la que estamos
	    call	plcdot	    ; El registro a cargar mapea con la columna 4, ahora averiguamos con que fila mapea
	    return				    		
PlacF	    movwf	S3
	    movwf	temp3	    ; guardamos el offset de la columna	 	    
	    movlw	d'2'	    ; Indicamos la columna en la que estamos
	    call	plcdot	    ; El registro a cargar mapea con la columna 3, ahora averiguamos con que fila mapea
	    return
PlacG	    movwf	S2
	    movwf	temp3	    ; guardamos el offset de la columna	 
	    movlw	d'1'	    ; Indicamos la columna en la que estamos
	    call	plcdot	    ; El registro a cargar mapea con la columna 2, ahora averiguamos con que fila mapea
	    return	    
	    
Checkdir    btfsc	Posdir, 0   ; se desplaza hacia arriba?
	    goto	DirectU
	    btfsc	Posdir, 1   ; se desplaza hacia abajo?
	    goto	DirectD
	    btfsc	Posdir, 2   ; se desplaza a la izquierda?
	    goto	DirectL
	    goto	DirectR     ;entonces se desplaza a la derecha
	    
DirectU	    movwf	temp5
	    rrf		temp5, f    ; verifiamos si la columna activa es la del extremo superior
	    btfsc	STATUS, C
	    bsf		temp5, 7
	    movf	temp5, w
	    return
					
DirectD	    movwf	temp5
	    rlf		temp5, f    ; verifiamos si la columna activa es la del extremo inferior
	    btfsc	STATUS, C
	    call	DirectDa
	    movf	temp5, w
	    return
DirectDa    clrf	temp5
	    bsf		temp5, 0
	    return
	    	    
DirectL	    movwf	temp5
	    rrf		Posind, f
	    btfsc	STATUS, C   ; verifiamos si la columna activa es la del extremo izquierdo
	    bsf		Posind, 7
	    movf	temp5, w
	    return

DirectR	    movwf	temp5
	    rlf		Posind, f
	    btfsc	STATUS, C  ; verifiamos si la columna activa es la del extremo derecho
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
	    iorwf	C6, f
	    movf	S7, w
	    iorwf	C7, f
	    movf	S8, w
	    iorwf	C8, f
	    goto	END_ISR
	    
END_ISR
	    movf	pclath_save, w
	    movwf	PCLATH
	    movf	status_save, w
	    movwf	STATUS
	    swapf	w_save, f
	    swapf	w_save, w
	    retfie
;-------------------------------------------------------------------------------
;----------------------------  Contador de decremento de puntos  --------------- ; para el decremento de los registros cargados previamente por el head del snake
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
	    call	delum		; Apagamos el led si la ram está vacía
	    incf	temp3, f
	    incf	temp3, f
	    incf	temp2, f
	    movf	temp2, w
	    xorlw	d'224'		;este registro es el limite de nuestra matriz
	    btfss	STATUS, Z
	    goto	dotdecloop
	    movf	temp4, w	;apunto a la dirección del registro que se debe cargar
	    movwf	FSR
	    movlw	d'0'
	    addwf	INDF, w		;pregunto si el registro que se debe cargar esta vacío 
	    btfss	STATUS, Z	
	    call	colrat		;si no esta
	    movf	snake, w
	    movwf	INDF
	    return
colrat	    btfsc	INDF, 7		; El bit 7 indica una rata
	    goto	ratcl
	    bsf		colind, 0
	    return
ratcl	    clrf	rattmr
	    incf	snake, f
	    return	    

delum	    movlw	LOW table      ; Apaga el led elegido
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
;----------------------------  Incremento del contador de "puntos"  ------------
;-------------------------------------------------------------------------------	    
plcdot	    addlw	d'160'	    ;A0		; El registro a cargar mapea con la fila 1
	    btfsc	temp3, 7    ;fila 8?
	    addlw	d'56'	    ;D8		; El registro a cargar mapea con la fila 8
	    btfsc	temp3, 6    ;fila 7?
	    addlw	d'48'	    ;D0		; El registro a cargar mapea con la fila 7
	    btfsc	temp3, 5    ;fila 6?
	    addlw	d'40'	    ;C8		; El registro a cargar mapea con la fila 6
	    btfsc	temp3, 4    ;fila 5?
	    addlw	d'32'	    ;C8		; El registro a cargar mapea con la fila 5
	    btfsc	temp3, 3    ;fila 4?
	    addlw	d'24'	    ;B8		; El registro a cargar mapea con la fila 4
	    btfsc	temp3, 2    ;fila 3?
	    addlw	d'16'	    ;B0		; El registro a cargar mapea con la fila 3
	    btfsc	temp3, 1    ;fila 2?
	    addlw	d'8'	    ;A8		; El registro a cargar mapea con la fila 2
	    movwf	temp4			; temp4 contiene ahora el numero de registro que debe cargarse con el tamaño del snake
Ilum	    movlw	d'255'
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
;---------------------------  Generación aleatorio de Rata  --------------------
;-------------------------------------------------------------------------------	    
Rat	    movlw	b'10000000'
	    movwf	rattmr		;limpiamos la cuenta de 10 interrupciones del timer e indicamos que hay una rata en el tablero
	    call	Random		; Generamos un numero "aleatorio" en base al cual elegimos en que registro colocar la rata 
	    addlw	d'159'		
	    movwf	FSR
notclr	    incf	FSR, f
	    movf	INDF, w
	    addlw	d'0'
	    btfsc	STATUS, Z
	    goto	addrat
	    movf	FSR, w
	    addlw	d'33'		;aseguramos que no sea mayor a 223
	    btfss	STATUS, C
	    goto	notclr		; Elegimos otro registro, porque este no esta limpio
	    movlw	d'159'
	    movwf	FSR
	    goto	notclr		; Location not clear, try again.
	    
addrat	    movlw	d'255'		; Cargamos al maximo el registro que habia quedado apuntado por el FSR, el MSB indica
	    movwf	INDF		; si existe una colisión con una rata para el registro en cuestión 
	    movlw	d'7'		; Aumentamos la velocidad de la serpiente, (hacemos que timer1 temporize menos)   
	    addwf	T1H, f			 
	    return			
;-------------------------------------------------------------------------------
;----------------------------  Generación de Número Random  --------------------
;-------------------------------------------------------------------------------	    
Random	    movf	snake, w	;tenemos en cuenta el tamaño del snake como varibale que influye en el numero "random" seleccionado
	    movwf	temp3
	    movlw	LOW Rantbl      ;tomamos la parte baja de la dirección de la tabla
	    addwf	temp3,  w     
	    movlw	HIGH Rantbl    ;tomamos la parte alta de la dirección de la tabla
	    btfsc	STATUS, C       
	    addlw	1              
	    movwf	PCLATH       ;modificamos el PCLATH para modificar el PC   (parte alta)
	    movlw	LOW Rantbl     
	    addwf	temp3, w       
	    movwf	PCL             ;modificamos el PCL para modificar el PC	    
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