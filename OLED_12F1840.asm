;TAB size is 7  ;TAB size is 7  ;TAB size is 7
;	     November 2024
;
;*************************************************
;
;	SSD1306 64x32 pixel I2C OLED firmware		
;	
;===============================================
;   2.7V programming voltage on the PICKit2Plus
;   Midrange/1.8v Min Configuration [Family:14]
;===============================================
;
; PIC12F1840 Configuration Bit Settings;	  
; CONFIG1:
  CONFIG  FOSC = INTOSC         ; Oscillator Selection (INTOSC oscillator: I/O function on CLKIN pin)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable (WDT disabled)
  CONFIG  PWRTE = OFF           ; Power-up Timer Enable (PWRT disabled)
  CONFIG  MCLRE = OFF           ; MCLR Pin Function Select (MCLR/VPP pin function is digital input)
  CONFIG  CP = OFF              ; Flash Program Memory Code Protection (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Memory Code Protection (Data memory code protection is disabled)
  CONFIG  BOREN = OFF           ; Brown-out Reset Enable (Brown-out Reset disabled)
  CONFIG  CLKOUTEN = OFF        ; Clock Out Enable (CLKOUT function is disabled. I/O or oscillator function on the CLKOUT pin)
  CONFIG  IESO = OFF            ; Internal/External Switchover (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enable (Fail-Safe Clock Monitor is disabled)

; CONFIG2:
  CONFIG  WRT = OFF             ; Flash Memory Self-Write Protection (Write protection off)
  CONFIG  PLLEN = OFF           ; PLL Enable (4x PLL disabled)
  CONFIG  STVREN = OFF          ; Stack Overflow/Underflow Reset Disabled (Stack Overflow or Underflow will not cause a Reset)
  CONFIG  BORV = LO             ; Brown-out Reset Voltage Selection (Brown-out Reset Voltage (Vbor), low trip point selected.)
  CONFIG  DEBUG = OFF           ; In-Circuit Debugger Mode (In-Circuit Debugger disabled, ICSPCLK and ICSPDAT are general purpose I/O pins)
  CONFIG  LVP = OFF             ; Low-Voltage Programming Enable (High-voltage on MCLR/VPP must be used for programming)
; 
;*************************************************
;
PROCESSOR 12F1840  ;Required???
;
#define _XC_INC_
#include <pic.inc>
;
#define _XTAL_FREQ 4000000UL
;
 ;*************** register declerations ***********
#define same  1     ;mpasm 'same equ 1' does not work in pic-as, so just define it. 
;
dcount equ 0x20h 		
countbits equ 21h
nops_ equ 22h
offset equ 23h
RAM_bytes_count equ 24h
Display_byte equ 25h
I2C_Command_or_Data equ 26h
times_16 equ 27h
repeat equ 28h
mirror_original equ 29h
mirror equ 2Ah
Page_count equ 2Bh
contrast_ctl equ 2Ch
Bits_Reg equ 2Dh
Left equ 30h
Right equ 31h
L_R equ 32h
hatch_count equ 33h
On_or_Off equ 34h
;				
SCK equ 5
SDA equ 4
LED equ 2
;
;- - - - - - - PIC12F1840 - - - - - - -
;
;	     Vdd. 1	8 Vss.
;I2C Clk    GP5. 2	7 GP0.   (ICSP Data)
;I2C Data   GP4. 3	6 GP1.   (ICSP Clk)
;(ICSP Pgm) GP3. 4	5 GP2.  -
; 
;*************************************************
;PSECT res_vect, class=CODE, delta=2
PSECT reset_, class=CODE, delta=2
reset_:
	ORG 0x000       ; Reset
	 goto Initialise  
;
	 ORG 0x004       ; Interrupt vector not used so should
	 return          ;  not see this, 'return' entered to be safe.
;*************************************************
	 ORG 0x005
Initialise:
;To acheive 4Mhz int osc:
;Oscillator Control Registers; section 5.6	 
	movlb 1
	clrf OSCCON		;
	bcf OSCCON,0		;(x) Internal 
	bsf OSCCON,1		;(1)	 clock.
;
	bsf OSCCON,3		;1101 = 4Mhz 
	bcf OSCCON,4
	bsf OSCCON,5
	bsf OSCCON,6
;	                                                                       
	movlb 0	
	clrf PORTA	
	movlb 2	
	clrf LATA		;Data Latch.	 
	movlb 3
	clrf ANSELA		;All digital I/O.	 
	movlb 1	
	clrf TRISA		;All as o/p.
	movlb 0	
	bsf PORTA,SDA		;Use 10k Pull-up.
	bsf PORTA,SCK		;	"" 
;	
;__ Intitialise Timer 2 __
;With 4Mhz crystal, inst cyc = 1uS.
;1uS *64 = 64uS.	
	bsf T2CON,0		;Prescaler <1-0> 11 = 1:64.
	bsf T2CON,1
;64uS x 5 = 320uS.	
	bcf T2CON,3		;Postscaler <6-3> 1001 1:5. 
	bcf T2CON,4		
	bsf T2CON,5
	bcf T2CON,6
;Inner delay required = 50mS. 50mS / 320uS = 156	
	movlw 156		;
	movwf PR2		;
;Timer ON	
	bsf T2CON,2		;Tmr2 On
;	
	movlw 08h
	movwf countbits
	movlw 0fh 
	movwf nops_
	clrf Bits_Reg
;	
;*************************************************
;
Main:	call d1S
	movlw 16
	movwf times_16
	call SSD1306_Initialise	;Set parrameters as required
;
	;--------------
Top:	call Scn_Checkers
	call d300mS
	movlw 4
	movwf repeat
	call Pixel_invert
	call d100mS
	call Display_off
;--------------------------------
	call Scn_MATCHBOX
	call Display_on
	call d2S
	call d500mS
	call Clear_RAM_20_5F
;-------------------------------		
	call Scn_SUPERKINGS
	call d1S
	movlw 4
	movwf repeat
	call Pixel_invert
	call Clear_RAM_20_5F
;--------------------------------
	call cross_hatch
;--------------------------------	
	call Scn_K97
	call d2S
	call Clear_RAM_20_5F
;--------------------------------
	call Scn_Checkers
	call d700mS
;--------------------------------
	call Scn_POLICE
	call d1S
	movlw 6
	movwf repeat
	call Pixel_invert
	call Clear_RAM_20_5F
;--------------------------------
	call cross_hatch
;--------------------------------	
	call Scn_70
	call d1S
;--------------------------------
	call Scn_Number_plate
	movlw 4
	movwf repeat
Flash_Number_plate:
	call d700mS
	call Display_off
	call d300mS
	call Display_on
	decfsz repeat,same
	goto Flash_Number_plate
	call Clear_RAM_20_5F	
;--------------------------------
	call Scn_FOLLOW_ME
	call d2S
	movlw 5
	movwf repeat
	call Pixel_invert
	call d500mS
	call Clear_RAM_20_5F
	call scn_rst0_3
;--------------------------------
	call Scroll_RAM_clear
	call Scn_Chevron
	call Scroll_Left
	call d3S
	call d3S
	call d200mS
	call Scroll_STOP
	call Clear_RAM_20_5F
;--------------------------------
	call Scn_PULL_OVER
	call d100mS
	call scn_rst0_3
;--------------------------------	
	call Clear_RAM_20_5F
	call Scn_Beacons
;    	call d5S
	call Display_off
;--------------------------------	
	call Clear_RAM_20_5F
	call Display_on
	call d100mS
	call Scn_STOP
	call d2S
	movlw 6
	movwf repeat
	call Pixel_invert
	call Clear_RAM_20_5F
	call d100mS
;--------------------------------	
	 call d3S 
;--------------------------------	
	movlw 8
	movwf repeat 
AC_SL:	call Scn_ACCIDENT
	call Display_on
	call d700mS
	call Display_off
    	call Scn_SLOW
	call Display_on
	call d700mS
	call Display_off
	decfsz repeat
	goto AC_SL
	call scn_rst0_3
	call Clear_RAM_20_5F
;--------------------------------	

CTH:	call cross_hatch
	call cross_hatch
	call cross_hatch

	
;--------------------------------	
;--------------------------------	
	call Display_on	
	clrf PCLATH
	call d5S
	goto Top
;
;
 ;===========================================================
;Subroutines.
 cross_hatch:
;Hoz centre is 3F:40. Data will be FFFF (all on)
    	call Clear_RAM_20_5F
;	movlw 2
;	movwf Bits_Reg   ;Count twice through the 'Left_Right' I2C routine twice.
	movlw 3Fh
	movwf Left
	movlw 40h
	movwf Right
	movlw 31
	movwf hatch_count
ch_1:	call Left_Right
	call d100mS
	movlw 2
	movwf Bits_Reg   ;Count twice through the 'Left_Right' I2C routine twice.
	movf Left,w	   ;Firstly copy the Left side 
	movwf L_R	   ;	   to the shared register.
LRagnclr:   ;Left & Right CLEAR, quicker to clear the previously written 8 bytes, that the entire screen's 256.
	call Two_line_command_write
	movlw 00h
	movwf On_or_Off
	call Two_line_Data_Write ;Now write the line's CLEARING data.
;	
	movf Right,w	   ;Then copy the Right side 
	movwf L_R	   ;	   to the shared register.
	decfsz Bits_Reg,same
	goto LRagnclr
 	decf Left
	incf Right
	decfsz hatch_count,same
	goto ch_1
	call scn_rst0_3  ;Screen back to 256 byte write.
	return
;-----------
Left_Right:
	movlw 2
	movwf Bits_Reg   ;Count twice through the 'Left_Right' I2C routine twice.
	movf Left,w	   ;Firstly copy the Left side 
	movwf L_R	   ;	   to the shared register.
;	
LRagn:	call Two_line_command_write
 	movlw 0FFh
	movwf On_or_Off
	call Two_line_Data_Write ;;Now write the line's data.
;	
	movf Right,w	   ;Then copy the Right side 
	movwf L_R	   ;	   to the shared register.
	decfsz Bits_Reg,same
	goto LRagn
	return
;------------------
	
Two_line_command_write:
   call I2C_Start_then_Address
	movlw 00h		; 00=Command stream.
	call I2C_byte
	movlw 21h		; Column Address;
	call I2C_byte
	movf L_R,w	   ;from
	call I2C_byte
	movf L_R,w	   ;to the same
	call I2C_byte
	call I2C_Stop	
	return
;
Two_line_Data_Write:
	call I2C_Start_then_Address
	movlw 40h		;C0=Data stream.
	call I2C_byte
	movf On_or_Off,w
	call I2C_byte
	movf On_or_Off,w
	call I2C_byte
	movf On_or_Off,w
	call I2C_byte
	movf On_or_Off,w
	call I2C_byte
	call I2C_Stop
	return	
 ;--------------------------------	
 Scn_Checkers:
	movlw 16
	movwf times_16
next_16:
	movlw 8
	movwf RAM_bytes_count
	call I2C_Start_then_Address
	movlw 40h		;40=Data stream, or C0h = Data byte.
	call I2C_byte
moreclear_A:
	movlw 0Fh		
	call I2C_byte
	decfsz RAM_bytes_count,same
	goto moreclear_A
	call I2C_Stop
;	
	movlw 8
	movwf RAM_bytes_count
	call I2C_Start_then_Address
	movlw 40h		;40=Data stream, or C0h = Data byte.
	call I2C_byte
moreclear_B:
	movlw 0F0h		
	call I2C_byte
	decfsz RAM_bytes_count,same
	goto moreclear_B
	call I2C_Stop
;
	call d100mS		;Small delay between each 16 byte writes for effect.
	decfsz times_16,same
	goto next_16
	return
;
;--------------------------------
Scn_MATCHBOX:
	call I2C_Start_then_Address
	movlw 40h		;Data stream.
	call I2C_byte
	movlw 064	
	movwf RAM_bytes_count	
MATCHBOX_page3:		; PAGE3 bytes are All 00h, as such to avoid wasting RETLW memory.
	clrw
	call I2C_byte
	decfsz RAM_bytes_count,same
	goto MATCHBOX_page3
	movlw 191
	movwf offset	
	movlw 192		;Only read data for pages 0,1 & 2, as page 3 bytes are all 00h so use 64 count loop
	movwf RAM_bytes_count	
;
more_MATCHBOX:	
	movlw 06h	
	movwf PCLATH	
	movf offset,w
	callw	  ;MATCHBOX
	clrf PCLATH
	call Byte_mirror
	call I2C_byte
	decf offset		
	decfsz RAM_bytes_count,same	
	goto more_MATCHBOX
	call I2C_Stop
	return
;
;--------------------------------
Scn_SUPERKINGS:
	call screen_bytes_load_for_256
more_SUPERKINGS:
	movlw 0Ch	
	movwf PCLATH	
	movf offset,w
	callw	  ;SUPERKINGS
	clrf PCLATH
	call Byte_mirror
	call I2C_byte
	decf offset		
	decfsz RAM_bytes_count,same	
	goto more_SUPERKINGS
	call I2C_Stop
	return
;
;--------------------------------
Scn_K97:     ;	Albeit subsequent banks this is split over two PCLATH locations.
	; This only needs Columns 16 to 47.
	call I2C_Start_then_Address
	movlw 00h		; 00=Command stream.
	call I2C_byte
	movlw 21h		; Column Address;
	call I2C_byte
	movlw 2Fh		;Column 16.
	call I2C_byte
	movlw 4Eh		;Colum 47.
	call I2C_byte
	call I2C_Stop	
; First bank has 66 bytes.
	movlw 66	
	movwf RAM_bytes_count	
	movlw 65
	movwf offset	
	call I2C_Start_then_Address
	movlw 40h		;Data command.
	call I2C_byte
more_K97a:
	movlw 07h	
	movwf PCLATH	
	movf offset,w
	callw	  ;K97b
	clrf PCLATH
	call Byte_mirror
	call I2C_byte
	decf offset		
	decfsz RAM_bytes_count,same	
	goto more_K97a
; Second bank has 62 bytes.
	movlw 062	
	movwf RAM_bytes_count	
	movlw 253
	movwf offset	
more_K97b:
	movlw 06h	
	movwf PCLATH	
	movf offset,w
	callw	  ;MATCHBOX
	clrf PCLATH
	call Byte_mirror
	call I2C_byte
	decf offset		
	decfsz RAM_bytes_count,same	
	goto more_K97b
	call I2C_Stop	
	return
;
;--------------------------------
Scn_POLICE:
	call screen_bytes_load_for_256
more_POLICE:
	movlw 0Ah		;POLICE table location.
	movwf PCLATH		;High byte of Program Counter!!
	movf offset,w
	callw	  ;POLICE
	clrf PCLATH
	call Byte_mirror
	call I2C_byte
	decf offset		
	decfsz RAM_bytes_count,same	
	goto more_POLICE
	call I2C_Stop
	return
;
;--------------------------------
Scn_70:
    	call I2C_Start_then_Address
	movlw 00h		; 00=Command stream.
	call I2C_byte
	movlw 21h		; Column Address;
	call I2C_byte
	movlw 35h		;Column 22
	call I2C_byte		;   to	    
	movlw 47h		;   Column 40.
	call I2C_byte
	call I2C_Stop	
; First bank has 66 bytes.
	movlw 76	
	movwf RAM_bytes_count	
	movlw 221
	movwf offset
	call I2C_Start_then_Address
	movlw 40h		;Data stream.
	call I2C_byte
more_70:	
	movlw 07h		
	movwf PCLATH		
	movf offset,w
	callw	  ;_70
	clrf PCLATH
	call Byte_mirror
	call I2C_byte
	decf offset		
	decfsz RAM_bytes_count,same	;Unless RAM counter has reached zero. 
	goto more_70
	call I2C_Stop	
	movlw 5
	movwf repeat
Flash_70:
	call d600mS
	call Display_off
	call d300mS
	call Display_on
	decfsz repeat,same
	goto Flash_70
	return
;
;--------------------------------
Scn_FOLLOW_ME:	 
	call screen_bytes_load_PAGE1_PAGE2
	call I2C_Start_then_Address
	movlw 40h		;Data stream.
	call I2C_byte	
more_FOLLOW_ME:
	movlw 05h
	movwf PCLATH	
	movf offset,w
	callw	  ;FOLLOW_ME
	clrf PCLATH
	call Byte_mirror
	call I2C_byte
	decf offset		
	decfsz RAM_bytes_count,same	
	goto more_FOLLOW_ME
	call I2C_Stop
	return
;
;--------------------------------
Scn_Chevron:
 	call Load_21h_command
	movlw 26h		;Column 7 
	call I2C_byte		;   to	    
	movlw 2Ch		;   Column 13 
	call Get_Chevron
	call Load_21h_command
	movlw 3Ch		;Column 29
	call I2C_byte		;   to	    
	movlw 42h		;   Column 35 
	call Get_Chevron
	call Load_21h_command
	movlw 52h		;Column 51
	call I2C_byte		;   to	    
	movlw 58h		;   Column 57 
	call Get_Chevron
	return
Load_21h_command:
	call I2C_Start_then_Address
	movlw 00h		; 00=Command stream.
	call I2C_byte
	movlw 21h		; Column Address;
	call I2C_byte
	return
;
;--------------------------------
Scn_PULL_OVER:	
	call screen_bytes_load_PAGE1_PAGE2
	call I2C_Start_then_Address
	movlw 40h		;Data stream.
	call I2C_byte	
	movlw 255
	movwf offset
more_PULL_OVER:
    	movlw 05h		;PULL_OVER table location.
	movwf PCLATH		;High byte of Program Counter!!
	movf offset,w
	callw	  ;PULL_OVER
	clrf PCLATH
	call Byte_mirror
	call I2C_byte
	decf offset		
	decfsz RAM_bytes_count,same	
	goto more_PULL_OVER
	call I2C_Stop
	call d2S
	call Display_off
	call d300mS
	call Display_on
	call d500mS
	call Display_off
	call d300mS
	call Display_on
	call d500mS
	call Display_off
	call d300mS
	call Display_on
	call d500mS
	call Display_off
	call d300mS
	call Display_on
	call d500mS
	call Display_off
	call d300mS
	call Display_on
	call d500mS
	call Display_off
	call d300mS
	call Display_on
	return
;
;--------------------------------
Scn_Beacons:
    	movlw 8
	movwf repeat
beacon_loop:
	call I2C_Start_then_Address
	movlw 00h		; 00=Command stream.
	call I2C_byte
	movlw 22h		; Page Address, only 1 & 2. 
	call I2C_byte
	movlw 01h		;value 1
	call I2C_byte
	movlw 02h		;value 2
	call I2C_byte
	call I2C_Stop
	call Beacons_RH	;Set up RH beacon write,
	call Beacons_LH	; now Left.
	call d100mS
	call Beacon_flash_ray1   
	call d250mS
	call Beacon_flash_ray2
	call d250mS
	call Beacons_LH	;Set up LH beacon write,
	call Beacons_RH	; now Right.
	call d100mS
	call Beacon_flash_ray1
	call d250mS
	call Beacon_flash_ray2
	call d250mS
	decfsz repeat,same
	goto beacon_loop
	return
;
;--------------------------------	
Scn_STOP:
	call screen_bytes_load_for_256
more_STOP:
	movlw 09h		;STOP table location.
	movwf PCLATH		;High byte of Program Counter!!
	movf offset,w
	callw	  ;STOP
	clrf PCLATH
	call Byte_mirror
	call I2C_byte
	decf offset		
	decfsz RAM_bytes_count,same	
	goto more_STOP
	call I2C_Stop
	return
;
;--------------------------------		
Scn_Number_plate:	 
	call screen_bytes_load_PAGE1_PAGE2
	call I2C_Start_then_Address
	movlw 40h		;Data stream.
	call I2C_byte	
	movlw 241
	movwf offset
more_Number_plate:
	movlw 08h		
	movwf PCLATH		
	movf offset,w
	callw	  ;Number_plate
	clrf PCLATH
	call Byte_mirror
	call I2C_byte
	decf offset		
	decfsz RAM_bytes_count,same	
	goto more_Number_plate
	call I2C_Stop
	return
;
;--------------------------------			
Scn_ACCIDENT:	
	call screen_bytes_load_PAGE1_PAGE2
	call I2C_Start_then_Address
	movlw 40h		;Data stream.
	call I2C_byte	
	movlw 127
	movwf offset
more_ACCIDENT:
    	movlw 0Bh	
	movwf PCLATH	
	movf offset,w
	callw	  ;ACCIDENT
	clrf PCLATH
	call Byte_mirror
	call I2C_byte
	decf offset		
	decfsz RAM_bytes_count,same	
	goto more_ACCIDENT
	call I2C_Stop
	return
;	
;--------------------------------				
Scn_SLOW:	  
	call screen_bytes_load_PAGE1_PAGE2	  ;Changes Pages to just 1 & 2, & also columns 20-5F, 
		      ;but require less as below. Also the Offset, & Ram_bytes_count are changed.
; ONLY Columns 	 16 to 49!!
	call I2C_Start_then_Address
	movlw 00h		; 00=Command stream.
	call I2C_byte
	movlw 21h		; Column Address;
	call I2C_byte
	movlw 2Fh		;Column 16	
	call I2C_byte		;   to	    
	movlw 50h		;   Column 49 
	call I2C_byte
	call I2C_Stop
;	
	movlw 195
	movwf offset
	movlw 68
	movwf RAM_bytes_count
	call I2C_Start_then_Address
	movlw 40h		;Data stream.
	call I2C_byte	
more_SLOW:
    	movlw 0Bh	
	movwf PCLATH	
	movf offset,w
	callw	  ;SLOW
	clrf PCLATH
	call Byte_mirror
	call I2C_byte
	decf offset		
	decfsz RAM_bytes_count,same	
	goto more_SLOW
	call I2C_Stop
	return
;	
;===========================================================
;Sub-subroutines.
;	
Beacon_flash_ray1: ;Beacons rays-1	
	call I2C_Start_then_Address
	movlw 40h		;Data stream.
	call I2C_byte
	movlw 38	
	movwf RAM_bytes_count	
	movlw 75
	movwf offset		
	call more_Beacons
	return
Beacon_flash_ray2: ;Beacons rays-2		
	call I2C_Start_then_Address
	movlw 40h		;Data stream.
	call I2C_byte
	movlw 38	
	movwf RAM_bytes_count	
	movlw 113
	movwf offset		
	call more_Beacons
	return 
display_beacon: ;Just the beacons shape
	call I2C_Start_then_Address
	movlw 40h		;Data stream.
	call I2C_byte
	movlw 38	
	movwf RAM_bytes_count	
	movlw 37
	movwf offset		
	call more_Beacons
	return
more_Beacons: 
	movlw 08h		
	movwf PCLATH		
	movf offset,w
	callw	  ;Beacons
	clrf PCLATH
	call Byte_mirror
	call I2C_byte
	decf offset		
	decfsz RAM_bytes_count,same	
	goto more_Beacons
	call I2C_Stop	   
	return	
Beacons_RH: ;Set RH columns.
	call I2C_Start_then_Address
	movlw 00h		; 00=Command stream.
	call I2C_byte
	movlw 21h		; Column Address;
	call I2C_byte
	movlw 26h		;Column 7	@@@@@@@@@ RIGHT SIDE beacon @@@@@@@@@
	call I2C_byte		;   to	    
	movlw 38h		;   Column 25 
	call I2C_byte
	call I2C_Stop
	call display_beacon
	return
Beacons_LH: ;Set LH columns.
	call I2C_Start_then_Address
	movlw 00h		; 00=Command stream.
	call I2C_byte
	movlw 21h		; Column Address;
	call I2C_byte
	movlw 47h		;Column 40	@@@@@@@@@ LEFT SIDE beacon @@@@@@@@@
	call I2C_byte		;   to	    
	movlw 59h		;   Column 58 
	call I2C_byte
	call I2C_Stop
	call display_beacon
	return	
;--------------------------------
Get_Chevron:
    	call I2C_byte
	call I2C_Stop	
	call I2C_Start_then_Address
	movlw 40h		;Data stream.
	call I2C_byte
	movlw 28	
	movwf RAM_bytes_count	
	movlw 249
	movwf offset		;TableRead off-set.
more_Chevron:
	movlw 07h		
	movwf PCLATH		
	movf offset,w
	callw	  ;_70
	clrf PCLATH
	call Byte_mirror
	call I2C_byte
	decf offset		
	decfsz RAM_bytes_count,same	;Unless RAM counter has reached zero. 
	goto more_Chevron
	call I2C_Stop	   
	return
;--------------------------------
Scroll_Left:
	call I2C_Start_then_Address
	movlw 00h		;00=Command stream. 
	call I2C_byte
	movlw 26h		;[5] Scroll left. 
	call I2C_byte
	movlw 00h		;Dummy byte, as per datasheet.
	call I2C_byte
	movlw 00h		;Scroll starts at; Page 0.
	call I2C_byte
	movlw 05h		;Scroll interval, based on frame rate.
	call I2C_byte		
	movlw 03h		;Scroll end on; Page 3.
	call I2C_byte
	movlw 00h		;Dummy byte, as per datasheet.
	call I2C_byte
	movlw 0FFh		;Dummy byte, as per datasheet.
	call I2C_byte
	movlw 2Fh		;Activate scroll. !!!! 2Eh to deactivate, RAM data then needs rewritting !!!!  
	call I2C_byte
	call I2C_Stop
	return
;--------------------------------	
Scroll_RAM_clear:
   	call I2C_Start_then_Address
	movlw 00h		;00=Command stream.
	call I2C_byte
	movlw 20h		;[2] Addressing Mode
	call I2C_byte
	movlw 00h		;Value 1	
	call I2C_byte
;====== COLUMN		
	movlw 21h		;[3] Column Address;
	call I2C_byte
	movlw 00h		;value 1
	call I2C_byte
	movlw 7Fh		;value 2
	call I2C_byte
;====== PAGE
	movlw 22h		;[3] Page Address
	call I2C_byte
	movlw 00h		;value 1
	call I2C_byte
	movlw 03h		;value 2
	call I2C_byte
	call I2C_Stop
	movlw 4		
	movwf Page_count	;Count 4 pages.
	call I2C_Start_then_Address
	movlw 40h		;40=Data stream.
	call I2C_byte
scroll_clear:
	clrf RAM_bytes_count
scroll_clear_b:
    	movlw 00h
	call I2C_byte
	decfsz RAM_bytes_count,same	;First dec will = 00h, so we get 256 operations, not 255!
	goto scroll_clear_b
	decfsz Page_count,same
	goto scroll_clear
	call I2C_Stop		
	return
;--------------------------------
Scroll_STOP:
	call I2C_Start_then_Address
	movlw 80h		;80=Command byte. 
	call I2C_byte
	movlw 2Eh		;[5] Scroll STOP. 
	call I2C_byte
	return
;--------------------------------	
Display_on:	
	call I2C_Start_then_Address
	movlw 80h		; 80=Command byte.
	call I2C_byte
	movlw 0AFh		;[1] Turn Display ON
	call I2C_byte
	call I2C_Stop
	return	
Display_off:
	call I2C_Start_then_Address
	movlw 80h		; 80=Command byte.
	call I2C_byte
	movlw 0AEh		;[1] Turn Display OFF
	call I2C_byte
	call I2C_Stop
	return
;--------------------------------		
screen_bytes_load_for_256: ;POLICE. SUPERKINGS. STOP.
	movlw 255    
	movwf offset		;TableRead off-set.
	clrf RAM_bytes_count	;256 bytes, but with the addwf,PCL, makes 257, as last read byte is 00h, add that one to the end of this routine.
	call I2C_Start_then_Address
	movlw 40h		;Data stream.
	call I2C_byte	
	return
;--------------------------------		
screen_bytes_load_PAGE1_PAGE2: ;FOLLOW ME. PULL OVER. Number_plate. ACCIDENT. SLOW.
	call Clear_RAM_20_5F
	call scn_rst1_2
	movlw 127
	movwf offset		;TableRead off-set.
	movlw 128
	movwf RAM_bytes_count
	return
;--------------------------------	
Byte_mirror:		   ;Example, if W = 1100 0010, returning W will be 0100 0011.
	 movwf mirror_original   
	 clrf mirror
	 movlw 08h
	 movwf dcount
miror: btfsc mirror_original,7
	 goto mr1
	 bcf mirror,7
	 bra 1	 
mr1:	 bsf mirror,7
    	 decfsz dcount,1
	 bra 2	
	 movf mirror,w
	 return		
	 rlf mirror_original
	 rrf mirror
	 goto miror
;--------------------------------
Clear_RAM_20_5F:
;Clearing ALL memory as when scrolling, random screen junk was seen OUTSIDE the range 
; of the 32x64 screen so firstly adjust Column & Page addresses to full range. 
	call I2C_Start_then_Address
	movlw 00h		;00=Command stream.
	call I2C_byte
	
	movlw 20h		;[2] Addressing Mode
	call I2C_byte
	movlw 00h		;Value 1	
	call I2C_byte
;====== COLUMN		
	movlw 21h		;[3] Column Address;
	call I2C_byte
	movlw 20h		;value 1
	call I2C_byte
	movlw 5Fh		;value 2
	call I2C_byte
;====== PAGE
	movlw 22h		;[3] Page Address
	call I2C_byte
	movlw 00h		;value 1
	call I2C_byte
	movlw 03h		;value 2
	call I2C_byte
	
	call I2C_Stop
	movlw 4		
	movwf Page_count	;Count 4 pages.
	call I2C_Start_then_Address
	movlw 40h		;40=Data stream.
	call I2C_byte
 more_clear:
	movlw 64
	movwf RAM_bytes_count
more_clear_b:
    	movlw 00h
	call I2C_byte
	decfsz RAM_bytes_count,same	;First dec will = 00h, so we get 256 operations, not 255!
	goto more_clear_b
	decfsz Page_count,same
	goto more_clear
	call I2C_Stop		
	return
scn_rst0_3:	    ;now re-adjust Column & page addresses, 0 to 3. 	
	call I2C_Start_then_Address
	movlw 00h		; 00=Command stream.
	call I2C_byte
	movlw 21h		; Column Address;
	call I2C_byte
	movlw 20h		;value 1
	call I2C_byte
	movlw 5Fh		;value 2
	call I2C_byte
	movlw 22h		; Page Address
	call I2C_byte
	movlw 00h		;value 1
	call I2C_byte
	movlw 03h		;value 2
	call I2C_byte
	call I2C_Stop
	return
;	
scn_rst1_2:	    ;now re-adjust Column & page addresses, Only 1 & 2 	
	call I2C_Start_then_Address
	movlw 00h		; 00=Command stream.
	call I2C_byte
	movlw 21h		; Column Address;
	call I2C_byte
	movlw 20h		;value 1
	call I2C_byte
	movlw 5Fh		;value 2
	call I2C_byte
	movlw 22h		; Page Address
	call I2C_byte
	movlw 01h		;value 1
	call I2C_byte
	movlw 02h		;value 2
	call I2C_byte
	call I2C_Stop
	return	
;	
;--------------------------------
Pixel_invert:
	call I2C_Start_then_Address
	movlw 80h		;Single command;
	call I2C_byte
	movlw 0A7h		;[1] Inverse Display.
	call I2C_byte
	call I2C_Stop
	call d400mS
;
	call I2C_Start_then_Address
	movlw 80h		;Single command;
	call I2C_byte
	movlw 0A6h		;[1] Normal Display.
	call I2C_byte
	call I2C_Stop
	call d400mS
	decfsz repeat,same
	goto Pixel_invert
	return
;===========================================================
SSD1306_Initialise:
;======
	call I2C_Start_then_Address
	movlw 00h		;00=Command stream. 40=Data stream. 80=Command byte. C0=Data byte.
	call I2C_byte
;======	
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
;====== Addressing Mode
	movlw 20h		;[2] Addressing Mode
	call I2C_byte
	movlw 00h		;Value 1	
	call I2C_byte
;====== COLUMN		
	movlw 21h		;[3] Column Address;
	call I2C_byte
	movlw 00h		;value 1
	call I2C_byte
	movlw 7Fh		;value 2
	call I2C_byte
;====== PAGE
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
	movlw 0A4h		;[1] Resume to RAM content display
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
;====== Now send DATA bytes NOT a COMMAND, so restart;
;Clear ALL display RAM as part of main Initialise. 
	movlb 0
	movlw 04h
	movwf times_16
more255_Int:
	movlw 0FFh
	movwf RAM_bytes_count
	call I2C_Start_then_Address
	movlw 40h		;40=Data stream, or C0h = Data byte.
	call I2C_byte
moreclear_Int:
	movlw 00h
	call I2C_byte
	decfsz RAM_bytes_count,same
	goto moreclear_Int
	decfsz times_16,same
	goto more255_Int
	call I2C_Stop
;====== Ammend for 12x32 display as 00-7F setting anbove was to clear EVERY ram.
	call I2C_Start_then_Address
	movlw 00h		; 00=Command stream.
	call I2C_byte
	movlw 21h		; Column Address;
	call I2C_byte
	movlw 20h		;value 1	Start column of the 32x64 differs to the 64x128 !!!!!!!!!!!!!!!!!!!!!!!!!!!
	call I2C_byte
	movlw 5Fh		;value 2
	call I2C_byte
;======  Ammend for 32x64 display as previous 00-7F was to clear EVERY ram.
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
	return			;Initialise completed
;
;-----------------------------------------------------
;I2C SUBROUTINES
I2C_Start_then_Address:
;-- Start --
	bcf PORTA,SDA		;START commence, 
	call _nops
	bcf PORTA,SCK		;	START complete.
		;NOTE, 7 bit address, with bit[0] as R/W bit, so the 7 bit address is actually $20 
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
I2C_Ack:
;-- Ack --
	bsf TRISA,SDA		;Set as input to release the line
	call clk_it
	bcf TRISA,SDA		;Set back to output.
	return
;
I2C_byte:
;-- Command {or} Data byte --
	movwf I2C_Command_or_Data
	movlw 8		
	movwf countbits	;count the 8 bits RLF
byte_bits:
	btfss I2C_Command_or_Data,7
	bra 2
	bsf PORTA,SDA
	bra 1
	bcf PORTA,SDA
_clk1:	call clk_it
	decfsz countbits,same
	bra 1
	goto I2C_Ack 
_rlf:	rlf I2C_Command_or_Data
	goto byte_bits
;
I2C_Stop:
;-- Stop --
	bcf PORTA,SDA		;Before STOP, ensure its low.
	call _nops
	bsf PORTA,SCK		;STOP commence,
	call _nops
	bsf PORTA,SDA		;	STOP completed.
	return			;I2C over.
;
;-----------------
clk_it:
	bsf PORTA,SCK
	call _nops		
	bcf PORTA,SCK
	return
;
;-----------------
;
d100mS: movlw 2   
	 goto d_cnt
d150mS: movlw 3
	 goto d_cnt
d200mS: movlw 4
	 goto d_cnt
d250mS: movlw 5
	 goto d_cnt
d300mS: movlw 6
	 goto d_cnt
d400mS: movlw 8
	 goto d_cnt
d500mS: movlw 10
	 goto d_cnt
d600mS: movlw 12
	 goto d_cnt
d700mS: movlw 14
	 goto d_cnt
d1S:	 movlw 20
	 goto d_cnt
d2S:	 movlw 40
	 goto d_cnt
d3S:	 movlw 60
	 goto d_cnt
d5S:	 movlw 100
	 goto d_cnt	 
d12S:	 movlw 240

;--------------	
d_cnt:	movwf dcount
dn:	call d50mS
	decfsz dcount,same
	goto dn
	return
;
d50mS:	bcf TMR2IF	   
	clrf TMR2
_50mS:	nop
	btfss TMR2IF
	goto _50mS
	bcf TMR2IF
	return
;	 
_nops:	 movlw 02h	
	 movwf nops_
bk1:	 nop
	 decfsz nops_,same
	 goto bk1 
	 return
;	
;-----------------------------------
;
psect absSect,class=CODE,space=SPACE_CODE,delta=2,abs,ovrld
	org 0500h
FOLLOW_ME:  ;	  128	   Page1 & 2 only!
	retlw 0FFh   ;PAGE 1
	retlw 0FFh
	retlw 0C3h
	retlw 0C3h
	retlw 0C3h
	retlw 03h	
	retlw 03h
	retlw 00h
	retlw 0FCh
	retlw 0FEh
	retlw 07h
	retlw 03h
	retlw 07h
	retlw 0FEh
	retlw 0FCh
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
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 0FCh
	retlw 0FEh
	retlw 07h	
	retlw 03h	
	retlw 07h	
	retlw 0FEh
	retlw 0FCh
	retlw 00h	
	retlw 0FFh
	retlw 0FFh
	retlw 00h	
	retlw 080h
	retlw 00h	
	retlw 0FFh
	retlw 0FFh
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 0FFh
	retlw 0FEh
	retlw 01Ch
	retlw 0F8h
	retlw 01Ch
	retlw 0FEh
	retlw 0FFh
	retlw 00h	
	retlw 0FFh
	retlw 0FFh
	retlw 0C3h
	retlw 0C3h
	retlw 0C3h
	retlw 03h	
	retlw 03h
	retlw 07Fh      ;PAGE 2
	retlw 07Fh
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 01Fh
	retlw 03Fh
	retlw 070h
	retlw 060h
	retlw 070h
	retlw 03Fh
	retlw 01Fh
	retlw 00h	
	retlw 07Fh
	retlw 07Fh
	retlw 060h
	retlw 060h
	retlw 060h
	retlw 060h
	retlw 00h	
	retlw 07Fh
	retlw 07Fh
	retlw 060h
	retlw 060h
	retlw 060h
	retlw 060h
	retlw 00h	
	retlw 01Fh
	retlw 03Fh
	retlw 070h
	retlw 060h
	retlw 070h
	retlw 03Fh
	retlw 01Fh
	retlw 00h	
	retlw 07Fh
	retlw 03Fh
	retlw 01Ch
	retlw 0Fh	
	retlw 01Ch	
	retlw 03Fh	
	retlw 07Fh	
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 07Fh	
	retlw 07Fh	
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 07Fh	
	retlw 07Fh	
	retlw 00h	
	retlw 07Fh	
	retlw 07Fh	
	retlw 060h	
	retlw 060h	
	retlw 060h	
	retlw 060h	
	retlw 060h	
;
PULL_OVER:  ;	  128	   Page1 & 2 only!
	retlw 0FEh   ;PAGE 1
	retlw 0FFh
	retlw 0C3h
	retlw 0C3h
	retlw 0E7h
	retlw 07Eh
	retlw 018h
	retlw 00h	
	retlw 0FFh
	retlw 0FFh
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 0FFh
	retlw 0FFh
	retlw 00h
	retlw 0FFh
	retlw 0FFh
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
	retlw 00h	
	retlw 00h	
	retlw 0FCh	
	retlw 0FEh	
	retlw 07h	
	retlw 03h	
	retlw 07h
	retlw 0FEh
	retlw 0FCh	
	retlw 00h	
	retlw 0FFh	
	retlw 0FEh	
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 0FEh	
	retlw 0FFh	
	retlw 00h	
	retlw 0FFh	
	retlw 0FFh	
	retlw 0C3h	
	retlw 0C3h	
	retlw 0C3h	
	retlw 03h	
	retlw 03h	
	retlw 00h	
	retlw 0FEh	
	retlw 0FFh	
	retlw 0C3h	
	retlw 0C3h	
	retlw 0E7h	
	retlw 07Fh	
	retlw 03Ch
	retlw 07Fh   ;PAGE 2
	retlw 07Fh	
	retlw 00h	
	retlw 00h	
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 01Fh
	retlw 03Fh
	retlw 070h
	retlw 060h
	retlw 070h
	retlw 03Fh
	retlw 01Fh
	retlw 00h
	retlw 07Fh
	retlw 07Fh
	retlw 060h
	retlw 060h
	retlw 060h
	retlw 060h
	retlw 060h
	retlw 00h	
	retlw 07Fh
	retlw 07Fh
	retlw 060h
	retlw 060h
	retlw 060h
	retlw 060h
	retlw 060h
	retlw 00h	
	retlw 00h	
	retlw 01Fh
	retlw 03Fh
	retlw 070h
	retlw 060h
	retlw 070h
	retlw 03Fh
	retlw 01Fh
	retlw 00h	
	retlw 03h	
	retlw 0Fh	
	retlw 03Eh
	retlw 070h
	retlw 03Eh
	retlw 0Fh	
	retlw 03h	
	retlw 00h	
	retlw 07Fh
	retlw 07Fh
	retlw 060h
	retlw 060h
	retlw 060h
	retlw 060h
	retlw 060h
	retlw 00h	
	retlw 07Fh
	retlw 07Fh
	retlw 00h	
	retlw 03h	
	retlw 0Fh	
	retlw 07Eh
	retlw 070h
;
psect absSect,class=CODE,space=SPACE_CODE,delta=2,abs,ovrld
	org 0600h	
MATCHBOX:   ;	  192
 	retlw 40h    ;PAGE 0
	retlw 0C0h
	retlw 80h
	retlw 00h
	retlw 80h
	retlw 80h
	retlw 00h
	retlw 00h
	retlw 80h
	retlw 80h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 80h
	retlw 80h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 80h
	retlw 80h
	retlw 80h
	retlw 80h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 80h
	retlw 80h
	retlw 80h
	retlw 80h
	retlw 00h
	retlw 80h
	retlw 80h
	retlw 00h
	retlw 00h
	retlw 80h
	retlw 80h
	retlw 00h
	retlw 00h
	retlw 80h
	retlw 80h
	retlw 80h
	retlw 80h
	retlw 80h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 80h
	retlw 80h
	retlw 80h
	retlw 80h
	retlw 00h
	retlw 00h
	retlw 80h
	retlw 80h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 80h
	retlw 80h																																																												
	retlw 00h	  ;PAGE 1
	retlw 0F0h
	retlw 0FFh
	retlw 0Fh
	retlw 01h
	retlw 0F1h
	retlw 0FEh
	retlw 0Eh
	retlw 01h
	retlw 0F1h
	retlw 0FEh
	retlw 0Eh
	retlw 00h
	retlw 0F0h
	retlw 0FEh
	retlw 6Fh
	retlw 61h
	retlw 0F1h
	retlw 0FFh
	retlw 0Eh
	retlw 00h
	retlw 01h
	retlw 0E1h
	retlw 0FFh
	retlw 1Fh
	retlw 01h
	retlw 01h
	retlw 0C0h
	retlw 0FEh
	retlw 3Fh
	retlw 01h
	retlw 01h
	retlw 01h
	retlw 0C0h
	retlw 0FFh
	retlw 7Fh
	retlw 60h
	retlw 0E0h
	retlw 0FFh
	retlw 1Fh
	retlw 00h
	retlw 0E0h
	retlw 0FFh
	retlw 7Fh
	retlw 61h
	retlw 0E1h
	retlw 0FFh
	retlw 1Fh
	retlw 00h
	retlw 0E0h
	retlw 0FFh
	retlw 1Fh
	retlw 01h
	retlw 0E1h
	retlw 0FFh
	retlw 1Fh
	retlw 00h
	retlw 01h
	retlw 07h
	retlw 0DEh
	retlw 78h
	retlw 0E6h
	retlw 81h
	retlw 00h
	retlw 0Fh	  ;PAGE 2
	retlw 0Fh
	retlw 00h
	retlw 00h
	retlw 0Fh
	retlw 0Fh
	retlw 00h
	retlw 00h
	retlw 0Fh
	retlw 0Fh
	retlw 00h
	retlw 00h
	retlw 0Eh
	retlw 0Fh
	retlw 01h
	retlw 00h
	retlw 0Eh
	retlw 0Fh
	retlw 01h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 0Fh
	retlw 0Fh
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 07h
	retlw 0Fh
	retlw 0Ch
	retlw 0Ch
	retlw 0Ch
	retlw 00h
	retlw 0Fh
	retlw 0Fh
	retlw 00h
	retlw 00h
	retlw 0Fh
	retlw 0Fh
	retlw 00h
	retlw 00h
	retlw 0Fh
	retlw 0Fh
	retlw 0Ch
	retlw 0Ch
	retlw 0Fh
	retlw 07h
	retlw 00h
	retlw 00h
	retlw 07h
	retlw 0Fh
	retlw 0Ch
	retlw 0Ch
	retlw 0Fh
	retlw 07h
	retlw 00h
	retlw 08h
	retlw 0Ch
	retlw 03h
	retlw 00h
	retlw 00h
	retlw 01h
	retlw 07h
	retlw 0Eh
;
K97a:	;columns 16 to 47 only!  (128 bytes TOTAL over 4 pages.)
	retlw 0C0h   ;PAGE 0
	retlw 0C0h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 080h
	retlw 0C0h
	retlw 040h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 080h
	retlw 0C0h
	retlw 0C0h
	retlw 0C0h
	retlw 0C0h
	retlw 080h
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
	retlw 080h
	retlw 0FFh   ;PAGE 1	
	retlw 0FFh	
	retlw 080h	
	retlw 0E0h	
	retlw 078h	
	retlw 01Eh	
	retlw 07h	
	retlw 01h	
	retlw 00h	
	retlw 080h	
	retlw 080h	
	retlw 080h	
	retlw 00h	
	retlw 00h	
	retlw 0FFh	
	retlw 0FFh	
	retlw 081h	
	retlw 00h	
	retlw 00h	
	retlw 081h	
	retlw 0FFh	
	retlw 0FFh	
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 0C0h	
	retlw 0F8h	
;	
psect absSect,class=CODE,space=SPACE_CODE,delta=2,abs,ovrld
	org 0700h
K97b:	retlw 03Fh	
	retlw 07h
	retlw 0FFh   ;PAGE 2
	retlw 0FFh
	retlw 01h
	retlw 07h	
	retlw 01Eh
	retlw 078h
	retlw 0E0h	
	retlw 080h	
	retlw 00h	
	retlw 01h	
	retlw 01h	
	retlw 01h	
	retlw 00h	
	retlw 00h	
	retlw 080h	
	retlw 0C1h	
	retlw 03h	
	retlw 03h	
	retlw 03h	
	retlw 03h	
	retlw 0FFh	
	retlw 0FFh	
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 080h	
	retlw 0F0h	
	retlw 07Fh	
	retlw 0Fh	
	retlw 01h	
	retlw 00h	
	retlw 00h
	retlw 07h   ;PAGE 3    
	retlw 07h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 01h
	retlw 07h
	retlw 06h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 03h
	retlw 07h
	retlw 0Ch
	retlw 0Ch
	retlw 0Ch
	retlw 0Eh
	retlw 07h
	retlw 03h	
	retlw 00h	
	retlw 00h	
	retlw 0Ch	
	retlw 0Fh	
	retlw 03h	
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 00h
;
Arrows:     ;Only 20 columns, start at two seperate columns to show two arrows. Can also reverse, to show RH pointing arrow.	
	retlw 00h   ;PAGE 0	
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 080h
	retlw 0E0h
	retlw 060h
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
	retlw 00h	
	retlw 00h
	retlw 080h   ;PAGE 1
	retlw 0E0h
	retlw 0F8h
	retlw 09Eh
	retlw 087h
	retlw 081h
	retlw 080h
	retlw 080h
	retlw 080h
	retlw 080h
	retlw 080h
	retlw 080h
	retlw 080h
	retlw 080h
	retlw 080h
	retlw 080h
	retlw 080h
	retlw 080h
	retlw 080h
	retlw 080h
	retlw 01h   ;PAGE 2	
	retlw 07h	
	retlw 01Fh
	retlw 079h
	retlw 0E1h
	retlw 081h
	retlw 01h	
	retlw 01h	
	retlw 01h	
	retlw 01h	
	retlw 01h	
	retlw 01h	
	retlw 01h	
	retlw 01h	
	retlw 01h	
	retlw 01h	
	retlw 01h	
	retlw 01h	
	retlw 01h	
	retlw 01h
	retlw 00h   ;PAGE 3	
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 01h	
	retlw 07h	
	retlw 06h	
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
	retlw 00h	
	retlw 00h
;
_70:	 ;Only 19 columns.	76 bytes.
	retlw 060h   ;PAGE 
	retlw 060h
	retlw 060h	
	retlw 060h	
	retlw 060h	
	retlw 060h	
	retlw 0E0h	
	retlw 0C0h	
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 0C0h	
	retlw 0E0h	
	retlw 060h	
	retlw 060h	
	retlw 060h	
	retlw 0E0h	
	retlw 0C0h	
	retlw 00h
	retlw 00h   ;PAGE 1	
	retlw 00h	
	retlw 00h	
	retlw 080h	
	retlw 0E0h	
	retlw 0FCh	
	retlw 01Fh	
	retlw 03h	
	retlw 00h	
	retlw 00h	
	retlw 0FFh	
	retlw 0FFh	
	retlw 00h	
	retlw 00h	
	retlw 080h	
	retlw 060h	
	retlw 018h	
	retlw 0FFh	
	retlw 0FFh
	retlw 00h   ;PAGE 2	
	retlw 0C0h	
	retlw 0F8h	
	retlw 03Fh	
	retlw 07h	
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 0FFh	
	retlw 0FFh	
	retlw 018h	
	retlw 06h	
	retlw 01h	
	retlw 00h	
	retlw 00h	
	retlw 0FFh	
	retlw 0FFh
	retlw 06h   ;PAGE 3	
	retlw 07h	
	retlw 01h	
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 03h	
	retlw 07h	
	retlw 06h	
	retlw 06h	
	retlw 06h	
	retlw 07h	
	retlw 03h	
	retlw 00h	   
;	
Chevronn:
	retlw 00h	;PAGE 0
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 080h
	retlw 0E0h	
	retlw 060h
	retlw 080h	;PAGE 1
	retlw 0E0h	
	retlw 0F8h	
	retlw 01Eh	
	retlw 07h	
	retlw 01h	
	retlw 00h
	retlw 01h	;PAGE 2
	retlw 07h
	retlw 01Fh
	retlw 078h
	retlw 0E0h	
	retlw 080h	
	retlw 00h
	retlw 00h	;PAGE 3	
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 01h	
	retlw 07h	
	retlw 06h
	
psect absSect,class=CODE,space=SPACE_CODE,delta=2,abs,ovrld
	org 0800h 
Beacons:	
	retlw 00h    ;PAGE 1. Beacon only
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
	retlw 00h	
	retlw 00h	
	retlw 00h
	retlw 00h    ;PAGE 2. Beacon only
	retlw 00h	
	retlw 0F8h
	retlw 0FCh	
	retlw 0C6h	
	retlw 0C3h	
	retlw 0C1h
	retlw 0C0h
	retlw 0C0h
	retlw 0C0h	
	retlw 0C0h	
	retlw 0C0h	
	retlw 0C1h	
	retlw 0C3h	
	retlw 0C6h	
	retlw 0FCh	
	retlw 0F8h	
	retlw 00h	
	retlw 00h
	retlw 00h    ;PAGE 1. Beacon + 1st ray
	retlw 80h
	retlw 00h	
	retlw 20h	
	retlw 40h	
	retlw 08h	
	retlw 90h	
	retlw 0C0h	
	retlw 0C0h
	retlw 0C0h
	retlw 0C0h
	retlw 0C0h
	retlw 090h
	retlw 08h
	retlw 40h
	retlw 20h
	retlw 00h
	retlw 80h
	retlw 00h
	retlw 00h    ;PAGE 2. Beacon + 1st ray		
	retlw 00h
	retlw 0F9h
	retlw 0FCh
	retlw 0C6h
	retlw 0C3h
	retlw 0C1h
	retlw 0C0h
	retlw 0C0h
	retlw 0C0h
	retlw 0C0h
	retlw 0C0h
	retlw 0C1h
	retlw 0C3h
	retlw 0C6h
	retlw 0FCh
	retlw 0F9h
	retlw 00h
	retlw 00h
	retlw 10h  ;PAGE 1. Beacon + 2nd ray	
	retlw 20h	
	retlw 04h	
	retlw 08h	
	retlw 01h	
	retlw 02h	
	retlw 80h	
	retlw 0C0h	
	retlw 0C0h	
	retlw 0C0h	
	retlw 0C0h	
	retlw 0C0h	
	retlw 80h	
	retlw 02h	
	retlw 01h	
	retlw 08h	
	retlw 04h	
	retlw 20h	
	retlw 10h
	retlw 00h	;PAGE 2. Beacon + 2nd ray	
	retlw 00h	
	retlw 0F8h	
	retlw 0FCh	
	retlw 0C6h	
	retlw 0C3h	
	retlw 0C1h	
	retlw 0C0h	
	retlw 0C0h	
	retlw 0C0h	
	retlw 0C0h	
	retlw 0C0h	
	retlw 0C1h	
	retlw 0C3h	
	retlw 0C6h	
	retlw 0FCh	
	retlw 0F8h	
	retlw 00h	
	retlw 00h
Number_plate:	
	retlw 00h	;PAGE 1
	retlw 0FCh
	retlw 0FEh
	retlw 07h
	retlw 03h
	retlw 07h
	retlw 3Eh
	retlw 3Ch
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 06h
	retlw 03h
	retlw 0FFh
	retlw 0FFh
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 0FFh
	retlw 0FFh
	retlw 0C0h
	retlw 0C0h
	retlw 0C0h
	retlw 0FFh
	retlw 0FFh
	retlw 00h
	retlw 00h
	retlw 3Ch
	retlw 0FEh
	retlw 0E7h
	retlw 0C3h
	retlw 0E7h
	retlw 0FEh
	retlw 3Ch
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 0FFh
	retlw 0FFh
	retlw 0C3h
	retlw 0C3h
	retlw 0C3h
	retlw 03h
	retlw 03h
	retlw 00h
	retlw 00h
	retlw 0FFh
	retlw 0FFh
	retlw 0C3h
	retlw 0C3h
	retlw 0E7h
	retlw 7Fh
	retlw 3Ch
	retlw 00h
	retlw 00h
	retlw 0FFh
	retlw 0FFh
	retlw 0C3h
	retlw 0C3h
	retlw 0E7h
	retlw 7Eh
	retlw 3Ch
	retlw 00h	
	retlw 00h    ;PAGE 2
	retlw 1Fh	
	retlw 3Fh	
	retlw 70h	
	retlw 63h	
	retlw 73h	
	retlw 3Fh	
	retlw 1Fh	
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 60h	
	retlw 60h	
	retlw 7Fh	
	retlw 7Fh	
	retlw 60h	
	retlw 60h	
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 7Fh	
	retlw 7Fh	
	retlw 00h	
	retlw 00h	
	retlw 1Fh	
	retlw 3Fh	
	retlw 71h	
	retlw 60h	
	retlw 71h	
	retlw 3Fh	
	retlw 1Fh	
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 7Fh	
	retlw 7Fh	
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 7Fh	
	retlw 7Fh	
	retlw 00h	
	retlw 03h	
	retlw 0Fh	
	retlw 7Eh	
	retlw 78h	
	retlw 00h	
	retlw 00h	
	retlw 7Fh	
	retlw 7Fh	
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 00h
;	
psect absSect,class=CODE,space=SPACE_CODE,delta=2,abs,ovrld
STOP:	
	org 0900h 
	retlw 00h    ;PAGE 0
	retlw 00h	
	retlw 00h	
	retlw 01h	
	retlw 03h	
	retlw 01h	
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 01h	
	retlw 03h	
	retlw 01h	
	retlw 80h	
	retlw 0C0h	
	retlw 0C0h	
	retlw 0C1h	
	retlw 0C3h	
	retlw 0C1h	
	retlw 80h	
	retlw 00h	
	retlw 00h	
	retlw 81h	
	retlw 0C3h	
	retlw 0C1h	
	retlw 0C0h	
	retlw 0C0h	
	retlw 0C0h	
	retlw 0C1h	
	retlw 0C3h	
	retlw 0C1h	
	retlw 80h	
	retlw 00h	
	retlw 00h	
	retlw 01h	
	retlw 83h	
	retlw 0C1h	
	retlw 0C0h	
	retlw 0C0h	
	retlw 0C0h	
	retlw 0C1h	
	retlw 83h	
	retlw 01h	
	retlw 00h	
	retlw 00h	
	retlw 0C0h	
	retlw 0C1h	
	retlw 0C3h	
	retlw 0C1h	
	retlw 0C0h	
	retlw 0C0h	
	retlw 80h	
	retlw 01h	
	retlw 03h	
	retlw 01h	
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 01h	
	retlw 03h	
	retlw 01h	
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 00h    ;PAGE 1	
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
	retlw 3Eh	
	retlw 7Fh	
	retlw 0E3h	
	retlw 0C0h	
	retlw 80h	
	retlw 00h	
	retlw 01h	
	retlw 03h	
	retlw 0Fh	
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
	retlw 80h
	retlw 80h
	retlw 80h
	retlw 80h
	retlw 0C1h
	retlw 0FFh
	retlw 7Eh
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
	retlw 00h    ;PAGE 2	
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
	retlw 0F0h
	retlw 0C0h
	retlw 80h
	retlw 01h	
	retlw 03h	
	retlw 07h	
	retlw 8Eh
	retlw 0FCh
	retlw 0F8h
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
	retlw 01h	
	retlw 01h	
	retlw 01h	
	retlw 01h	
	retlw 01h	
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
	retlw 00h	
	retlw 00h	
	retlw 00h    ;PAGE 3
	retlw 00h
	retlw 00h
	retlw 80h
	retlw 0C0h
	retlw 80h	
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 80h
	retlw 0C0h
	retlw 80h	
	retlw 01h	
	retlw 03h	
	retlw 03h	
	retlw 83h	
	retlw 0C3h	
	retlw 083h	
	retlw 01h	
	retlw 00h	
	retlw 00h	
	retlw 080h
	retlw 0C0h
	retlw 80h
	retlw 00h	
	retlw 03h	
	retlw 03h	
	retlw 080h
	retlw 0C0h
	retlw 80h
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 80h
	retlw 0C1h
	retlw 083h
	retlw 03h
	retlw 03h
	retlw 03h
	retlw 83h
	retlw 0C1h
	retlw 080h
	retlw 00h
	retlw 00h
	retlw 03h
	retlw 83h
	retlw 0C0h
	retlw 80h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 80h
	retlw 0C0h
	retlw 080h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 80h
	retlw 0C0h
	retlw 80h
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 00h	
;
	psect absSect,class=CODE,space=SPACE_CODE,delta=2,abs,ovrld
POLICE:     
	org 0x0A00
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
		psect absSect,class=CODE,space=SPACE_CODE,delta=2,abs,ovrld
ACCIDENT:     ;2 PAGES
	org 0x0B00
	retlw 00h	;PAGE1
	retlw 0C0h	
	retlw 0F0h
	retlw 03Ch
	retlw 0Eh
	retlw 03Ch
	retlw 0F0h
	retlw 0C0h
	retlw 00h
	retlw 0F8h
	retlw 0FCh
	retlw 0Eh	
	retlw 06h	
	retlw 0Eh	
	retlw 03Ch	
	retlw 38h	
	retlw 00h	
	retlw 00h	
	retlw 0F8h	
	retlw 0FCh	
	retlw 0Eh	
	retlw 06h	
	retlw 0Eh	
	retlw 03Ch	
	retlw 38h	
	retlw 00h	
	retlw 06h	
	retlw 06h	
	retlw 0FEh	
	retlw 0FEh	
	retlw 06h	
	retlw 06h	
	retlw 00h	
	retlw 0FEh	
	retlw 0FEh	
	retlw 06h	
	retlw 06h	
	retlw 0Eh	
	retlw 0FCh	
	retlw 0F8h	
	retlw 00h	
	retlw 0FEh	
	retlw 0FEh	
	retlw 86h	
	retlw 86h	
	retlw 86h	
	retlw 06h	
	retlw 04h	
	retlw 00h	
	retlw 0FEh	
	retlw 0FEh	
	retlw 0F0h	
	retlw 0C0h	
	retlw 00h	
	retlw 0FEh	
	retlw 0FEh	
	retlw 00h	
	retlw 04h	
	retlw 06h	
	retlw 0FEh	
	retlw 0FEh	
	retlw 06h	
	retlw 04h	
	retlw 00h	
	retlw 00h	;PAGE 2
	retlw 0FFh	
	retlw 0FFh	
	retlw 03h	
	retlw 03h	
	retlw 03h	
	retlw 0FFh	
	retlw 0FFh	
	retlw 00h	
	retlw 03Fh	
	retlw 7Fh	
	retlw 0E0h	
	retlw 0C0h	
	retlw 0E0h	
	retlw 07Eh	
	retlw 03Eh	
	retlw 00h	
	retlw 00h	
	retlw 03Fh	
	retlw 07Fh	
	retlw 0E0h	
	retlw 0C0h	
	retlw 0E0h	
	retlw 07Eh	
	retlw 03Eh	
	retlw 00h	
	retlw 0C0h	
	retlw 0C0h	
	retlw 0FFh	
	retlw 0FFh	
	retlw 0C0h	
	retlw 0C0h
	retlw 00h	
	retlw 0FFh
	retlw 0FFh
	retlw 0C0h
	retlw 0C0h
	retlw 0E0h
	retlw 07Fh
	retlw 03Fh
	retlw 00h	
	retlw 0FFh
	retlw 0FFh
	retlw 0C1h
	retlw 0C1h
	retlw 0C1h
	retlw 0C0h
	retlw 40h
	retlw 00h	
	retlw 0FFh
	retlw 0FFh
	retlw 00h	
	retlw 03h	
	retlw 0Fh	
	retlw 0FFh
	retlw 0FFh
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 0FFh
	retlw 0FFh
	retlw 00h	
	retlw 00h	
	retlw 00h	
;	
slow:	 ;34 COLUMNS, 2 PAGES
	retlw 078h   ;PAGE 1
	retlw 0FCh	
	retlw 0CEh	
	retlw 086h	
	retlw 0Eh	
	retlw 03Ch	
	retlw 038h	
	retlw 00h	
	retlw 00h	
	retlw 0FEh	
	retlw 0FEh	
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 0F8h	
	retlw 0FCh	
	retlw 0Eh	
	retlw 06h	
	retlw 0Eh	
	retlw 0FCh	
	retlw 0F8h	
	retlw 00h	
	retlw 00h	
	retlw 0FEh	
	retlw 0FEh	
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 0FEh	
	retlw 0FEh
	retlw 038h	;PAGE 2
	retlw 078h	
	retlw 0E1h	
	retlw 0C3h	
	retlw 0E7h	
	retlw 07Eh	
	retlw 03Ch	
	retlw 00h	
	retlw 00h	
	retlw 0FFh	
	retlw 0FFh	
	retlw 0C0h	
	retlw 0C0h	
	retlw 0C0h	
	retlw 0C0h	
	retlw 0C0h	
	retlw 00h	
	retlw 00h	
	retlw 03Fh	
	retlw 07Fh	
	retlw 0E0h	
	retlw 0C0h	
	retlw 0E0h	
	retlw 07Fh	
	retlw 03Fh	
	retlw 00h	
	retlw 00h	
	retlw 0FFh	
	retlw 07Fh	
	retlw 038h	
	retlw 01Fh	
	retlw 038h	
	retlw 07Fh	
	retlw 0FFh
;
	org 0C00h
SUPERKINGS: 
	retlw 00h    ;PAGE 0
	retlw 00h   
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 078h
	retlw 0FCh
	retlw 0CEh
	retlw 086h
	retlw 0Eh
	retlw 03Ch
	retlw 038h
	retlw 00h
	retlw 00h
	retlw 0FEh
	retlw 0FEh
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 0FEh
	retlw 0FEh
	retlw 00h
	retlw 00h
	retlw 0FCh
	retlw 0FEh
	retlw 086h
	retlw 086h
	retlw 0CEh
	retlw 0FCh
	retlw 030h
	retlw 00h	
	retlw 00h	
	retlw 0FEh
	retlw 0FEh
	retlw 086h
	retlw 086h
	retlw 086h
	retlw 06h	
	retlw 06h	
	retlw 00h	
	retlw 00h	
	retlw 0FCh
	retlw 0FEh
	retlw 086h
	retlw 086h
	retlw 0CEh
	retlw 0FEh
	retlw 078h
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
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 00h       ;PAGE 1 
	retlw 00h
	retlw 00h
	retlw 00h
	retlw 00h	
	retlw 038h
	retlw 078h	
	retlw 0E1h	
	retlw 0C3h	
	retlw 0E7h	
	retlw 07Eh	
	retlw 03Ch	
	retlw 00h	
	retlw 00h	
	retlw 03Fh	
	retlw 07Fh	
	retlw 0E0h	
	retlw 0C0h	
	retlw 0E0h	
	retlw 07Fh	
	retlw 03Fh	
	retlw 00h	
	retlw 00h	
	retlw 0FFh	
	retlw 0FFh	
	retlw 01h	
	retlw 01h	
	retlw 01h	
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 0FFh	
	retlw 0FFh	
	retlw 0C1h	
	retlw 0C1h	
	retlw 0C1h	
	retlw 0C0h	
	retlw 0C0h	
	retlw 00h	
	retlw 00h	
	retlw 0FFh	
	retlw 0FFh	
	retlw 01h	
	retlw 07h	
	retlw 01Fh	
	retlw 0FCh	
	retlw 0E0h	
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
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 00h    ;PAGE 2
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
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 0FEh
	retlw 0FEh
	retlw 080h
	retlw 0E0h
	retlw 078h
	retlw 01Eh
	retlw 06h	
	retlw 00h	
	retlw 00h	
	retlw 06h	
	retlw 06h	
	retlw 0FEh
	retlw 0FEh
	retlw 06h	
	retlw 06h	
	retlw 00h	
	retlw 00h	
	retlw 0FEh
	retlw 0FEh
	retlw 078h
	retlw 0E0h
	retlw 080h
	retlw 0FEh
	retlw 0FEh
	retlw 00h	
	retlw 00h	
	retlw 0F8h
	retlw 0FCh
	retlw 0Eh	
	retlw 06h	
	retlw 0Eh	
	retlw 07Ch
	retlw 078h
	retlw 00h	
	retlw 00h	
	retlw 078h
	retlw 0FCh
	retlw 0CEh
	retlw 086h
	retlw 0Eh	
	retlw 03Ch
	retlw 038h
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 00h    ;PAGE 3
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
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 0FFh	
	retlw 0FFh	
	retlw 01h	
	retlw 07h	
	retlw 01Eh	
	retlw 0F8h	
	retlw 0E0h	
	retlw 00h	
	retlw 00h	
	retlw 0C0h	
	retlw 0C0h	
	retlw 0FFh	
	retlw 0FFh	
	retlw 0C0h	
	retlw 0C0h	
	retlw 00h	
	retlw 00h	
	retlw 0FFh	
	retlw 0FFh	
	retlw 00h	
	retlw 01h	
	retlw 07h	
	retlw 0FFh	
	retlw 0FFh	
	retlw 00h	
	retlw 00h	
	retlw 03Fh	
	retlw 07Fh	
	retlw 0E0h	
	retlw 0C6h	
	retlw 0E6h	
	retlw 07Eh	
	retlw 03Eh	
	retlw 00h	
	retlw 00h	
	retlw 038h	
	retlw 078h	
	retlw 0E1h	
	retlw 0C3h	
	retlw 0E7h	
	retlw 07Eh	
	retlw 03Ch	
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 00h	
	retlw 00h	
;	
	
	
	
	
;--------------------
;	
    END reset_