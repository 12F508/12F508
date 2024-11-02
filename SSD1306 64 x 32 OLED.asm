;TAB size is 7  ;TAB size is 7  ;TAB size is 7  ;TAB size is 7  ;TAB size is 7  
;	     October 2024
;
;*************************************************
;
;	SSD1306 64x32 pixel I2C firmware. 
;	When workinmg okay, change to the PIC16F15214 7KB device
;
;*************************************************

;====================================================================================
;
	LIST P=PIC16F628a
	include p16F628a.inc	
;
;*************** register declerations ***********
same equ 1		;Destination of a register being worked on.
	CBLOCK  20h
dcount		;Main delay count.
countbits
nops_
RAM_bytes_count
Display_byte	
I2C_Command_or_Data
times_16
repeat
offset
	ENDC	
;				
SCK equ 2	;A3	Serial ClocK
SDA equ 3	;A2	Serial Data				
LED equ 4	;A4			
;
;- - - - - - - PIC16F628 - - - - - - - -
; SCK		1 A2    A1 18
; SDA		2 A3    A0 17
; LED		3 A4    A7 16
; Vpp		4 A5    A6 15			
;	    0v	5 Vss  Vdd 14 5v
;		6 B0    B7 13			ICSP Data			
;		7 B1    B6 12			ICSP Clock 
;		8 B2    B5 11
;		9 B3    B4 10
;
;*************************************************
	__CONFIG 	_INTRC_OSC_NOCLKOUT & _WDT_OFF & _PWRTE_OFF & _MCLRE_OFF & _BODEN_OFF & _LVP_OFF & _CPD_OFF & _CP_OFF
;*************************************************
	ORG 0x000       ; Reset
	goto Initialise 
;
	ORG 0x004       ; Interrupt vector not used so should
	return          ;  not see this, 'return' entered to be safe.
;*************************************************
	ORG 0x005
Initialise
	clrf PORTA
	clrf PORTB
;
	movlw 07h		;GP0,1&2 is also muxed with Comparator Configuration pins so turn comparators
	movwf CMCON		; off and enable pins for I/O see datasheet INITIALIZING PORTA [& PORTC). 
	bsf STATUS,RP0	;Page 1.
	clrf TRISA
	clrf TRISB
;
; Int Osc. = 4 Mhz, TMR0 increments every (1/4000000)*4 = 1uS
;Prescaler set to 111 gives 1:256, gives increment every 256uS. 
	movlw b'10000111' 	;<7> set to disable weak pull-ups.
	movwf OPTION_REG	;Set prescaler to 1:128. 
	bcf STATUS,RP0	;Page 0.
;
	movlw .061		;Gives ~50mS count. 
	movwf TMR0
	movlw b'00000111'
	movwf PCLATH
;	
	bsf PORTA,SDA		;Use 10k Pull-up.
	bsf PORTA,SCK		;	"" 

	movlw 40h		;NOTE, 7 bit address, with bit[0] as R/W bit, so the 7 bit address is actually $20 
	movlw 08h
	movwf countbits
	movlw 0fh
	movwf nops_
;	
;*************************************************
;
Main	call d1S
	movlw .016
	movwf times_16
;
	call SSD1306_Initialise	;Set parrameters as required
;
;--------------
;Screen one - Checkers.
	movlw .016
	movwf times_16
;
next_16
	movlw .008
	movwf RAM_bytes_count
	call I2C_Start
	call I2C_Address
	movlw 40h		;40=Data stream, or C0h = Data byte.
	call I2C_byte
moreclear_A
	movlw 0Fh		
	call I2C_byte
	decfsz RAM_bytes_count,same
	goto moreclear_A
	call I2C_Stop
;	
	movlw .008
	movwf RAM_bytes_count
	call I2C_Start
	call I2C_Address
	movlw 40h		;40=Data stream, or C0h = Data byte.
	call I2C_byte
moreclear_B
	movlw 0F0h		
	call I2C_byte
	decfsz RAM_bytes_count,same
	goto moreclear_B
	call I2C_Stop
;
	call d100mS		;Small delay between each 16 byte writes for effect.
	decfsz times_16,same
	goto next_16
;--------------------------------
;
	movlw 05h
	movwf repeat
LOOPY	call I2C_Start
	call I2C_Address
	movlw 80h		;Single command;
	call I2C_byte
	movlw 0A7h		;[1] Inverse Display.
	call I2C_byte
	call I2C_Stop
	call d500mS
;
	call I2C_Start
	call I2C_Address
	movlw 80h		;Single command;
	call I2C_byte
	movlw 0A6h		;[1] Normal Display.
	call I2C_byte
	call I2C_Stop
	call d500mS
	decfsz repeat,same
	goto LOOPY

;--------------------------------
;Clear RAM
more255
	movlw .255
	movwf RAM_bytes_count
	call I2C_Start
	call I2C_Address
	movlw 40h		;40=Data stream, or C0h = Data byte.
	call I2C_byte
moreclear_
	movlw 00h
	call I2C_byte
	decfsz RAM_bytes_count,same
	goto moreclear_
	movlw 00h
	call I2C_byte		;256th BYTE! Caught me out as the loop is 255!!!!
	call I2C_Stop
;--------------------------------
;Screen 2 - POLICE.
	clrf offset		;TableRead off-set.
	movlw .255
	movwf RAM_bytes_count	
	call I2C_Start
	call I2C_Address
	movlw 40h		;Data stream command.
	call I2C_byte
	movlw 05h		;POLICE table location.
	movwf PCLATH		;High byte of Program Counter!!
;
more_POLICE
	movf offset,w
	call POLICE
	call I2C_byte
	incf offset		;Increment the table off-set for next byte, 
	decfsz RAM_bytes_count,same	;Unless RAM counter has reached zero. 
	goto more_POLICE
	call I2C_Stop
;
;--------------------------------
LOOPZ	call I2C_Start
	call I2C_Address
	movlw 80h		;Single command;
	call I2C_byte
	movlw 0A7h		;[1] Inverse Display.
	call I2C_byte
	call I2C_Stop
	call d300mS
;
	call I2C_Start
	call I2C_Address
	movlw 80h		;Single command;
	call I2C_byte
	movlw 0A6h		;[1] Normal Display.
	call I2C_byte
	call I2C_Stop
	call d300mS
	goto LOOPZ	
;
;===========================================================
SSD1306_Initialise
;======
	call I2C_Start
	call I2C_Address
	movlw 00h		;00=Command stream. 40=Data stream. 80=Command byte. C0=Data byte.
	call I2C_byte
	movlw 0AEh		;[1] Set Display OFF.
	call I2C_byte
;======
	movlw 0D5h		;[2] Display Clock
	call I2C_byte
	movlw 80h		;value 1			____AS RESET____
	call I2C_byte
;======
	movlw 0A8h		;[2] Multiplex Ratio.
	call I2C_byte
	movlw 3Fh		;value 1			____AS RESET____
	call I2C_byte
;======
	movlw 40h		;[1] Display Start Row	____AS RESET____
	call I2C_byte
;======
	movlw 0B0h		;[1] Page 0~ for PAGE adressing mode only.
	call I2C_byte
;======
	movlw 0A0h		;[1] ;Set Segment Re-map. A0h = normal, A1h= column address 127 mapped to SEG0.
	call I2C_byte
;======
	movlw 0C0h		;[1] Scan direction. C0 normal(R-L). C8 L-R 
	call I2C_byte
;======	Addressing Mode	Addressing Mode	Addressing Mode
	movlw 20h		;[2] Addressing Mode
	call I2C_byte
	movlw 00h		;value 1	
	call I2C_byte

;======	COLUMN		COLUMN		COLUMN		COLUMN		COLUMN		
	movlw 21h		;[3] Column Address;
	call I2C_byte
	movlw 00h		;value 1	NOT Column ZERO!! For some strang ereason
	call I2C_byte
	movlw 7Fh		;value 2
	call I2C_byte
;======	PAGE	PAGE	PAGE	PAGE	PAGE	PAGE	PAGE	PAGE
	movlw 22h		;[3] Page Address
	call I2C_byte
	movlw 00h		;value 1
	call I2C_byte
	movlw 07h		;value 2
	call I2C_byte
;======
	movlw 0DAh		;[2] Set COM pins hardware configuration.
	call I2C_byte
	movlw 12h		; DO NOT EVER CHANGE!! DO NOT EVER CHANGE!! DO NOT EVER CHANGE!! 	
	call I2C_byte
;======
	movlw 81h		;[2] Contrast Control
	call I2C_byte
	movlw 0CFh		;value 1
	call I2C_byte
;======
	movlw 0D9h		;[2] Pre-charge period.
	call I2C_byte
	movlw 0F1h		;value 1
	call I2C_byte
;======
	movlw 0DBh		;[2] VCOMH Deselect Level.
	call I2C_byte
	movlw 40h		;value 1
	call I2C_byte
;======
	movlw 0A4h		;[1] Entire display on.
	call I2C_byte
;======
	movlw 0A6h		;[1] Normal/Inverse Display.
	call I2C_byte
;======
	movlw 8Dh		;[2] Charge pump;
	call I2C_byte
	movlw 14h		;value 1
	call I2C_byte
	call I2C_Stop
;
;====== DATA byte sent, NOT COMMAND!!DATA byte sent, NOT COMMAND!!
;Clear ALL display RAM as part of main Initialise. 
	movlw 04h
	movwf times_16
more255_Int
	movlw .255
	movwf RAM_bytes_count
	call I2C_Start
	call I2C_Address
	movlw 40h		;40=Data stream, or C0h = Data byte.
	call I2C_byte
moreclear_Int
	movlw 00h
	call I2C_byte
	decfsz RAM_bytes_count,same
	goto moreclear_Int
	decfsz times_16,same
	goto more255_Int
	call I2C_Stop
;
;====== Ammend for 12x32 display as 00-7F setting anbove was to clear EVERY ram.
	call I2C_Start
	call I2C_Address
	movlw 00h		; 00=Command stream.
	call I2C_byte
	movlw 21h		; Column Address;
	call I2C_byte
	movlw 20h		;value 1	
	call I2C_byte
	movlw 5Fh		;value 2
	call I2C_byte
;======  Ammend for 12x32 display as 00-7F setting anbove was to clear EVERY ram.
	movlw 22h		; Page Address
	call I2C_byte
	movlw 00h		;value 1
	call I2C_byte
	movlw 03h		;value 2
	call I2C_byte
;======	
	movlw 0AFh		;[1] Turn Display ON
	call I2C_byte
	call I2C_Stop
;
;======
	return			;Initialise completed
;
;-----------------------------------------------------
;I2C SUBROUTINES
I2C_Start
;-- Start --
	bcf PORTA,SDA		;START commence, 
	call _nops
	bcf PORTA,SCK		;	START complete.
	return
I2C_Address
;-- Address_byte --			;= 78h (bit [0] = R/W. Writing, so = 0.
	bcf PORTA,SDA		;bit 7
	call clk_it		
	bsf PORTA,SDA		;bit 6
	call clk_it		
	bsf PORTA,SDA		;bit 5
	call clk_it
	bsf PORTA,SDA		;bit 4		
	call clk_it	
	bsf PORTA,SDA		;bit 3	
	call clk_it
	bcf PORTA,SDA		;bit 2	
	call clk_it
	bcf PORTA,SDA		;bit 1
	call clk_it
	bcf PORTA,SDA		;bit 0 (R/W bit)
	call clk_it
;
I2C_Ack
;-- Ack --
	bsf STATUS,RP0	;Page 1.
	bsf TRISA,SDA		;Set as input to release the line
	bcf STATUS,RP0	;Page 0.
	call clk_it
	bsf STATUS,RP0	;Page 1.
	bcf TRISA,SDA		;Set back to output.
	bcf STATUS,RP0	;Page 0.
	return
;
I2C_byte
;-- Command {or} Data byte --
	movwf I2C_Command_or_Data
	movlw 08h		
	movwf countbits	;count the 8 bits RLF
byte_bits
	btfss I2C_Command_or_Data,7
	goto low_bit1
	bsf PORTA,SDA
	goto _clk1
low_bit1
	bcf PORTA,SDA
_clk1	call clk_it
	decfsz countbits,same
	goto _rlf
	goto I2C_Ack 
_rlf	rlf I2C_Command_or_Data
	goto byte_bits
;
I2C_Stop
;-- Stop --
	bcf PORTA,SDA		;Before STOP, ensure its low.
	call _nops
	bsf PORTA,SCK		;STOP commence,
	call _nops
	bsf PORTA,SDA		;	STOP completed.
	call d50mS
	return			;I2C over.
;
;-----------------
clk_it	nop
	nop
	nop
	nop
	nop
	nop	
	bsf PORTA,SCK
	call _nops		
	bcf PORTA,SCK
	nop
	nop
	nop
	nop
	nop
	nop
	return
;
;-----------------
;
d100mS	movlw .002
	goto d_cnt
d150mS	movlw .003
	goto d_cnt
d200mS	movlw .004
	goto d_cnt
d250mS	movlw .005
	goto d_cnt
d300mS	movlw .006
	goto d_cnt
d400mS	movlw .008
	goto d_cnt
d500mS	movlw .010
	goto d_cnt
d1S	movlw .020
	goto d_cnt
d2S	movlw .040
	goto d_cnt
d12S	movlw .240

;--------------	
d_cnt	movwf dcount
dn	call d50mS
	decfsz dcount,same
	goto dn
	return
;
d50mS	movlw .061	;Give ~50mS
ldTMR0	movwf TMR0
	movf TMR0,W	
	bcf INTCON,T0IF
wait2	btfss INTCON,T0IF	;Wait for time delay
	goto wait2
	return

_nops	movlw 3fh	;=253uS
	movwf nops_
bk1	nop
	decfsz nops_,same
	goto bk1 
	return
;	
;-----------------------------------
;
	org 0x0500
POLICE	addwf PCL,same
	retlw 00h	;PAGE 0
	retlw 0C0h
	retlw 0C0h
	retlw 0C0h
	retlw 0C0h
	retlw 0C0h
	retlw 0C0h
	retlw 80h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 80h
	retlw 0C0h
	retlw 0C0h
	retlw 0C0h
	retlw 0C0h
	retlw 0C0h
	retlw 80h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 0C0h
	retlw 0C0h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 0C0h
	retlw 0C0h
	retlw 0C0h
	retlw 0C0h
	retlw 0C0h
	retlw 0C0h
	retlw 0C0h
	retlw 0C0h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 80h
	retlw 0C0h
	retlw 0C0h
	retlw 0C0h
	retlw 0C0h
	retlw 0C0h
	retlw 80h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 0C0h
	retlw 0C0h
	retlw 0C0h
	retlw 0C0h
	retlw 0C0h
	retlw 0C0h
	retlw 0C0h
	retlw 0C0h
	retlw 0C0h
	retlw 00h
	retlw 00h	;PAGE 1
	retlw 0FFh
	retlw 0FFh
	retlw 80h
	retlw 80h
	retlw 80h
	retlw 80h
	retlw 0C1h
	retlw 0FFh
	retlw 7Eh
	retlw 00h
	retlw 00h
	retlw 0FFh
	retlw 0FFh
	retlw 01h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 01h
	retlw 0FFh
	retlw 0FFh
	retlw 00h
	retlw 00h
	retlw 0FFh
	retlw 0FFh
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 0FFh
	retlw 0FFh
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 0FFh
	retlw 0FFh
	retlw 01h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 01h
	retlw 07h
	retlw 07h
	retlw 00h
	retlw 00h
	retlw 0FFh
	retlw 0FFh
	retlw 80h
	retlw 80h
	retlw 80h
	retlw 80h
	retlw 80h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 00h	;PAGE 2
	retlw 0FFh
	retlw 0FFh
	retlw 01h
	retlw 01h
	retlw 01h
	retlw 01h
	retlw 01h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 0FFh
	retlw 0FFh
	retlw 80h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 80h
	retlw 0FFh
	retlw 0FFh
	retlw 00h
	retlw 00h
	retlw 0FFh
	retlw 0FFh
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 0FFh
	retlw 0FFh
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 0FFh
	retlw 0FFh
	retlw 80h	
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 80h
	retlw 0E0h
	retlw 0E0h
	retlw 00h
	retlw 00h
	retlw 0FFh
	retlw 0FFh
	retlw 01h
	retlw 01h
	retlw 01h
	retlw 01h
	retlw 01h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 00h	;PAGE 3
	retlw 03h
	retlw 03h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 01h
	retlw 03h
	retlw 03h
	retlw 03h
	retlw 03h
	retlw 03h
	retlw 01h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 03h
	retlw 03h
	retlw 03h
	retlw 03h
	retlw 03h
	retlw 03h
	retlw 03h
	retlw 03h
	retlw 03h
	retlw 00h
	retlw 03h
	retlw 03h
	retlw 03h
	retlw 03h
	retlw 03h
	retlw 03h
	retlw 03h
	retlw 03h
	retlw 00h
	retlw 00h
	retlw 01h
	retlw 01h
	retlw 03h
	retlw 03h
	retlw 03h
	retlw 03h
	retlw 03h
	retlw 01h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 03h
	retlw 03h
	retlw 03h
	retlw 03h
	retlw 03h
	retlw 03h
	retlw 03h
	retlw 03h
	retlw 03h
	retlw 00h
;
	end

