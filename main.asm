PROCESSOR 16F877A
INCLUDE "P16F877A.INC"
#define BANK0  (0x000)
#define BANK1  (0x080)
#define BANK2  (0x100)
#define BANK3  (0x180) 
; Speed of sound in air, units micrometers per microsecond
#define SPEED_OF_SOUND (343)
; Application data space
MainData    UDATA   0x20
A_reg:      res 2            ; used by Math functions, 16-bit input  register A
B_reg:                       ; used by Math functions, 16-bit input  register B, not register shares 16-bits with the output register
D_reg:      res 4            ; used by Math functions, 32-bit output register D
__CONFIG 0x3731




R1_LSB EQU 0x20       ; Define the memory location for R1's Least Significant Byte
R1_MSB EQU 0x21       ; Define the memory location for R1's Most Significant Byte
R2_LSB EQU 0x22       ; Define the memory location for R2's Least Significant Byte
R2_MSB EQU 0x23       ; Define the memory location for R2's Most Significant Byte
TEMP_LSB EQU 0x24     ; Define the memory location for temporary storage (Least Significant Byte)
TEMP_MSB EQU 0x25     ; Define the memory location for temporary storage (Most Significant Byte)

Distance EQU 0x26
TimeOfFlight EQU 0x27

C1 EQU 0x29
C2 EQU 0x2A
C3 EQU 0x2B
C4 EQU 0x2C
C5 EQU 0x2D

Timer1	EQU	70		
TimerX	EQU	71	

RESULT_LSB EQU 0x30   ; Define the memory location for the result (Least Significant Byte)
RESULT_MSB EQU 0x31   ; Define the memory location for the result (Most Significant Byte)
CURSOR EQU 0x34
BCDvalH EQU 0x35
BCDvalM EQU 0x36
BCDvalL EQU 0x37
MCount  EQU 0x38
NUMHI EQU 0x3E
NUMLO EQU 0x3F
TIMER_INDEX EQU 0x3B
Temp EQU 0x3C
NEXT_STATE EQU 0x2E
OPERATION EQU 0x2F

R1_C1 EQU 0x40
R1_C2 EQU 0x41
R1_C3 EQU 0x42
R1_C4 EQU 0x43
R1_C5 EQU 0x44
R2_C1 EQU 0x45
R2_C2 EQU 0x46
R2_C3 EQU 0x47
R2_C4 EQU 0x48
R2_C5 EQU 0x49
count EQU 0x50

DIGIT6 EQU 0x50
DIGIT5 EQU 0x51
DIGIT4 EQU 0x52
DIGIT3 EQU 0x53
DIGIT2 EQU 0x54
DIGIT1 EQU 0x55


num_sensor EQU 0x62
dL EQU 0x63
dH EQU 0x64

CARRY_SAVED EQU 0x4B
TEMP EQU 0x28       ; Define the memory location for unused temporary storage (not used in this code)
TEMP_10 EQU 0x65

first_us EQU 0x66
second_us EQU 0x67
third_us EQU 0x68
fourth_us EQU 0x69
number EQU 0x80

num1_L EQU 0x56
num1_H EQU 0x57
num1_N EQU 0x58

num2_L EQU 0x59
num2_H EQU 0x5A
num2_N EQU 0x5B

num3_L EQU 0x5C
num3_H EQU 0x5D
num3_N EQU 0x5E

num4_L EQU 0x5F
num4_H EQU 0x60
num4_N EQU 0x61

TEMP_D3 EQU 0x81

ORG 0x00
GOTO init

ORG 0x04
GOTO ISR

; Initialization
init:
	CLRF R1_C1
	CLRF R1_C2
	CLRF R1_C3
	CLRF R1_C4
	CLRF R1_C5
	CLRF R2_C1
	CLRF R2_C2
	CLRF R2_C3
	CLRF R2_C4
	CLRF R2_C5
	CLRF RESULT_LSB
	CLRF RESULT_MSB
	CLRF R1_LSB
	CLRF R2_LSB
	CLRF R1_MSB
	CLRF R2_MSB
	CLRF TEMP_LSB
	CLRF TEMP_MSB
	CLRF NEXT_STATE
	MOVLW '0'
	MOVWF C1
	MOVWF C2
	MOVWF C3
	MOVWF C4
	MOVWF C5
	CLRF dH
	CLRF dL
	CLRF num_sensor
	CLRF first_us
	CLRF second_us
	CLRF third_us
	CLRF fourth_us
	CLRF number

	CLRF num1_L
	CLRF num1_H
	CLRF num1_N
	CLRF num2_L
	CLRF num2_H
	CLRF num2_N
	CLRF num3_L
	CLRF num3_H
	CLRF num3_N
	CLRF num4_L
	CLRF num4_H
	CLRF num4_N

    ; Set RB0-RB5 as outputs
    BANKSEL TRISB
    CLRF TRISB
    ; Set RC0-RC7 as outputs
    BANKSEL TRISC
    CLRF TRISC
    
    MOVLW 0x07
    MOVWF ADCON1
    ; Set RA0-RA2 as outputs and RA3-RA5 as inputs
    BANKSEL TRISA
    MOVLW b'00111000'
    MOVWF TRISA
    ; Set RD0 as output
    BANKSEL TRISD
    BCF TRISD, TRISD0

    ; Initialize LCD
    BANKSEL TRISD
    CLRF TRISD
    
    BANKSEL PORTD
    CLRF PORTD

    CALL xms
    CALL xms
    CALL inid	; Initialize LCD

    MOVLW    3        ; number of times to blink
    MOVWF    count

    GOTO start

ISR:
    retfie

INCLUDE "LCDIS_PORTD.INC" ; If you want to use LCD on PORT D

start:
    CALL printWelcome	; make the print welcome blinking 3 times with 0.5 second delay
    DECFSZ  count, 1    ; Decrement the counter and skip if zero
    GOTO   start
	CALL printReadingSensors
	
    GOTO loop
  
loop:
	CLRF num_sensor

    CLRF num1_L
	CLRF num1_H
	CLRF num1_N
	CLRF num2_L
	CLRF num2_H
	CLRF num2_N
	CLRF num3_L
	CLRF num3_H
	CLRF num3_N
	CLRF num4_L
	CLRF num4_H
	CLRF num4_N

;Ultrasonic Sensor #1
    INCF num_sensor,1
    CALL USS1 ; calculate the time for sensor1
	CALL compareTo4_andShift
	;CALL display_highest_four_sensors	
    CALL onesecond

;Ultrasonic Sensor #2
    INCF num_sensor,1
    CALL USS2
	CALL compareTo4_andShift
	;CALL display_highest_four_sensors	
    CALL onesecond

;Ultrasonic Sensor #3    
	INCF num_sensor,1
    CALL USS3
	CALL compareTo4_andShift
	;CALL display_highest_four_sensors	
    CALL onesecond

;Ultrasonic Sensor #4   
	INCF num_sensor,1
    CALL USS4
	CALL compareTo4_andShift
	;CALL display_highest_four_sensors	
    CALL onesecond



;Ultrasonic Sensor #5
    INCF num_sensor,1
    CALL USS5
	CALL compareTo4_andShift
	;CALL display_highest_four_sensors	
    CALL onesecond

;Ultrasonic Sensor #6
    INCF num_sensor,1
    CALL USS6
	CALL compareTo4_andShift
	;CALL display_highest_four_sensors	
    CALL onesecond

;Ultrasonic Sensor #7
    INCF num_sensor,1
    CALL USS7
	CALL compareTo4_andShift
	;CALL display_highest_four_sensors	
    CALL onesecond
 
;Ultrasonic Sensor #8
    INCF num_sensor,1
    CALL USS8
	CALL compareTo4_andShift
	;CALL display_highest_four_sensors	
    CALL onesecond
    
;Ultrasonic Sensor #9
    INCF num_sensor,1
    CALL USS9
	CALL compareTo4_andShift
	;CALL display_highest_four_sensors	
    CALL onesecond
    
;Ultrasonic Sensor #10
    INCF num_sensor,1
    CALL USS10
	CALL compareTo4_andShift
	;CALL display_highest_four_sensors	
    CALL onesecond
    
;Ultrasonic Sensor #11
    INCF num_sensor,1
    CALL USS11
	CALL compareTo4_andShift
	;CALL display_highest_four_sensors	
    CALL onesecond
    
;Ultrasonic Sensor #12
    INCF num_sensor,1
    CALL USS12
	CALL compareTo4_andShift
	;CALL display_highest_four_sensors	
    CALL onesecond
    
;Ultrasonic Sensor #13
    INCF num_sensor,1
    CALL USS13
	CALL compareTo4_andShift
	;CALL display_highest_four_sensors	
    CALL onesecond
    
;Ultrasonic Sensor #14
    INCF num_sensor,1
    CALL USS14
	CALL compareTo4_andShift
	;CALL display_highest_four_sensors	
    CALL onesecond
    
;Ultrasonic Sensor #15
    INCF num_sensor,1
    CALL USS15
	CALL compareTo4_andShift
	;CALL display_highest_four_sensors	
    CALL onesecond
    
;Ultrasonic Sensor #16
    INCF num_sensor,1
    CALL USS16
	CALL compareTo4_andShift
	;CALL display_highest_four_sensors	
    CALL onesecond
    
;Ultrasonic Sensor #17
    INCF num_sensor,1
    CALL USS17
	CALL compareTo4_andShift
	;CALL display_highest_four_sensors	
    CALL onesecond
    
;Ultrasonic Sensor #18
    INCF num_sensor,1
    CALL USS18
	CALL compareTo4_andShift
	;CALL display_highest_four_sensors	
    CALL onesecond
    
;Ultrasonic Sensor #19
    INCF num_sensor,1
    CALL USS19
	CALL compareTo4_andShift
	;CALL display_highest_four_sensors	
    CALL onesecond
    
;Ultrasonic Sensor #20
    INCF num_sensor,1
    CALL USS20
	CALL compareTo4_andShift
	;CALL display_highest_four_sensors	
    CALL onesecond
    
;Ultrasonic Sensor #21
    INCF num_sensor,1
    CALL USS21
	CALL compareTo4_andShift
	;CALL display_highest_four_sensors	
    CALL onesecond
    
;Ultrasonic Sensor #22
    INCF num_sensor,1
    CALL USS22
	CALL compareTo4_andShift
	;CALL display_highest_four_sensors	
    CALL onesecond
    
;Ultrasonic Sensor #23
    INCF num_sensor,1
    CALL USS23
	CALL compareTo4_andShift
	;CALL display_highest_four_sensors	
    CALL onesecond
    
;Ultrasonic Sensor #24
    INCF num_sensor,1
    CALL USS24
	CALL compareTo4_andShift
	CALL display_highest_four_sensors	
    CALL onesecond
    


    GOTO loop


; Wait for Echo
WAIT_FOR_ECHO3:
    BANKSEL PORTA
    BTFSS PORTA,3         ; Wait until RA3 goes high
    GOTO WAIT_FOR_ECHO3    ; Stay in loop until echo is received
    CALL START_TIMER      ; Start the timer

; Wait for Echo to go low
WAIT_FOR_ECHO_LOW3:
    BTFSC PORTA, 3        ; Check if RA3 is low
    GOTO WAIT_FOR_ECHO_LOW3
    CALL STOP_TIMER       ; Stop the timer
    RETURN

; Wait for Echo
WAIT_FOR_ECHO4:
    BANKSEL PORTA
    BTFSS PORTA,4         ; Wait until RA3 goes high
    GOTO WAIT_FOR_ECHO4    ; Stay in loop until echo is received
    CALL START_TIMER      ; Start the timer

; Wait for Echo to go low
WAIT_FOR_ECHO_LOW4:
    BTFSC PORTA, 4        ; Check if RA4 is low
    GOTO WAIT_FOR_ECHO_LOW4
    CALL STOP_TIMER       ; Stop the timer
    RETURN

; Wait for Echo
WAIT_FOR_ECHO5:
    BANKSEL PORTA
    BTFSS PORTA, 5         ; Wait until RA3 goes high
    GOTO WAIT_FOR_ECHO5    ; Stay in loop until echo is received
    CALL START_TIMER      ; Start the timer

; Wait for Echo to go low
WAIT_FOR_ECHO_LOW5:
    BTFSC PORTA, 5        ; Check if RA4 is low
    GOTO WAIT_FOR_ECHO_LOW5
    CALL STOP_TIMER       ; Stop the timer
    RETURN

USS1:
    ;trig ----------------------------
    banksel PORTB
    BSF PORTB, 0          ; RB0 low
    BSF PORTB, 1
    BCF PORTB, 2
    CALL DELAY_2US        ; Wait for 2 microseconds
    BCF PORTB, 0          ; RB0 low
    BCF PORTB, 1
    BCF PORTB, 2
    CALL DELAY_10US       ; Wait for 10 microseconds
    BSF PORTB, 0          ; RB0 low
    BSF PORTB, 1
    BCF PORTB, 2
    ;----------------------------------
    ;echo------------------------------
    banksel PORTC
    BCF PORTC, 3          
    BCF PORTC, 4
    BCF PORTC, 5

	; Set RA3 as input
    BANKSEL TRISA
    BSF TRISA, 3    ; Set RA3 as input

	CALL WAIT_FOR_ECHO3
	RETURN

USS2:
    ;trig ----------------------------
    banksel PORTB
    BCF PORTB, 0          ; RB0 low
    BSF PORTB, 1
    BCF PORTB, 2
    CALL DELAY_2US        ; Wait for 2 microseconds
    BCF PORTB, 0          ; RB0 low
    BCF PORTB, 1
    BCF PORTB, 2
    CALL DELAY_10US       ; Wait for 10 microseconds
    BCF PORTB, 0          ; RB0 low
    BSF PORTB, 1
    BCF PORTB, 2
    ;----------------------------------
    ;echo------------------------------
    banksel PORTC
    BSF PORTC, 3          
    BCF PORTC, 4
    BCF PORTC, 5
    
	; Set RA3 as input
    BANKSEL TRISA
    BSF TRISA, 3    ; Set RA3 as input

	CALL WAIT_FOR_ECHO3
	RETURN
   
USS3:
    ;trig ----------------------------
    banksel PORTB
    BSF PORTB, 0          ; RB0 low
    BCF PORTB, 1
    BCF PORTB, 2
    CALL DELAY_2US        ; Wait for 2 microseconds
    BCF PORTB, 0          ; RB0 low
    BCF PORTB, 1
    BCF PORTB, 2
    CALL DELAY_10US       ; Wait for 10 microseconds
    BSF PORTB, 0          ; RB0 low
    BCF PORTB, 1
    BCF PORTB, 2
    ;----------------------------------
    ;echo------------------------------
    banksel PORTC
    BCF PORTC, 3          
    BSF PORTC, 4
    BCF PORTC, 5
    
	; Set RA3 as input
    BANKSEL TRISA
    BSF TRISA, 3    ; Set RA3 as input

	CALL WAIT_FOR_ECHO3
	RETURN
  
USS4:
    ;trig ----------------------------
    banksel PORTB
    BCF PORTB, 0          ; RB0 low
    BCF PORTB, 1
    BCF PORTB, 2
    CALL DELAY_2US        ; Wait for 2 microseconds
    BSF PORTB, 0          ; RB0 low
    BCF PORTB, 1
    BCF PORTB, 2
    CALL DELAY_10US       ; Wait for 10 microseconds
    BCF PORTB, 0          ; RB0 low
    BCF PORTB, 1
    BCF PORTB, 2
    ;----------------------------------
    ;echo------------------------------
    banksel PORTC
    BSF PORTC, 3          
    BSF PORTC, 4
    BCF PORTC, 5
    
	; Set RA3 as input
    BANKSEL TRISA
    BSF TRISA, 3    ; Set RA3 as input

	CALL WAIT_FOR_ECHO3
	RETURN
  
USS5:
    ;trig ----------------------------
    banksel PORTB
    BSF PORTB, 0          ; RB0 low
    BSF PORTB, 1
    BSF PORTB, 2
    CALL DELAY_2US        ; Wait for 2 microseconds
    BCF PORTB, 0          ; RB0 low
    BCF PORTB, 1
    BCF PORTB, 2
    CALL DELAY_10US       ; Wait for 10 microseconds
    BSF PORTB, 0          ; RB0 low
    BSF PORTB, 1
    BSF PORTB, 2
    ;----------------------------------
    ;echo------------------------------
    banksel PORTC
    BCF PORTC, 3          
    BCF PORTC, 4
    BSF PORTC, 5
    
	; Set RA3 as input
    BANKSEL TRISA
    BSF TRISA, 3    ; Set RA3 as input

	CALL WAIT_FOR_ECHO3
	RETURN
       
USS6:
    ;trig ----------------------------
    banksel PORTB
    BCF PORTB, 0          ; RB0 low
    BSF PORTB, 1
    BSF PORTB, 2
    CALL DELAY_2US        ; Wait for 2 microseconds
    BCF PORTB, 0          ; RB0 low
    BCF PORTB, 1
    BCF PORTB, 2
    CALL DELAY_10US       ; Wait for 10 microseconds
    BCF PORTB, 0          ; RB0 low
    BSF PORTB, 1
    BSF PORTB, 2
    ;----------------------------------
    ;echo------------------------------
    banksel PORTC
    BSF PORTC, 3          
    BCF PORTC, 4
    BSF PORTC, 5
    
	; Set RA3 as input
    BANKSEL TRISA
    BSF TRISA, 3    ; Set RA3 as input

	CALL WAIT_FOR_ECHO3
	RETURN
  
USS7:
    ;trig ----------------------------
    banksel PORTB
    BSF PORTB, 0          ; RB0 low
    BCF PORTB, 1
    BSF PORTB, 2
    CALL DELAY_2US        ; Wait for 2 microseconds
    BCF PORTB, 0          ; RB0 low
    BCF PORTB, 1
    BCF PORTB, 2
    CALL DELAY_10US       ; Wait for 10 microseconds
    BSF PORTB, 0          ; RB0 low
    BCF PORTB, 1
    BSF PORTB, 2
    ;----------------------------------
    ;echo------------------------------
    banksel PORTC
    BCF PORTC, 3          
    BSF PORTC, 4
    BSF PORTC, 5
    
	; Set RA3 as input
    BANKSEL TRISA
    BSF TRISA, 3    ; Set RA3 as input

	CALL WAIT_FOR_ECHO3
	RETURN
  
USS8:
    ;trig ----------------------------
    banksel PORTB
    BCF PORTB, 0          ; RB0 low
    BCF PORTB, 1
    BSF PORTB, 2
    CALL DELAY_2US        ; Wait for 2 microseconds
    BCF PORTB, 0          ; RB0 low
    BCF PORTB, 1
    BCF PORTB, 2
    CALL DELAY_10US       ; Wait for 10 microseconds
    BCF PORTB, 0          ; RB0 low
    BCF PORTB, 1
    BSF PORTB, 2
    ;----------------------------------
    ;echo------------------------------
    banksel PORTC
    BSF PORTC, 3          
    BSF PORTC, 4
    BSF PORTC, 5
    
	; Set RA3 as input
    BANKSEL TRISA
    BSF TRISA, 3    ; Set RA3 as input

	CALL WAIT_FOR_ECHO3
	RETURN
   
USS9:
    ;trig ----------------------------
    banksel PORTC
    BSF PORTC, 0          ; RB0 low
    BSF PORTC, 1
    BCF PORTC, 2
    CALL DELAY_2US        ; Wait for 2 microseconds
    BCF PORTC, 0          ; RB0 low
    BCF PORTC, 1
    BCF PORTC, 2
    CALL DELAY_10US       ; Wait for 10 microseconds
    BSF PORTC, 0          ; RB0 low
    BSF PORTC, 1
    BCF PORTC, 2
    ;----------------------------------
    ;echo------------------------------
    banksel PORTB
    BSF PORTB, 3          
    BSF PORTB, 4
    BCF PORTB, 5
    
	; Set RA4 as input
    BANKSEL TRISA
    BSF TRISA, 4    ; Set RA4 as input

	CALL WAIT_FOR_ECHO4
	RETURN
    
USS10:
    ;trig ----------------------------
    banksel PORTC
    BCF PORTC, 0          ; RB0 low
    BSF PORTC, 1
    BCF PORTC, 2
    CALL DELAY_2US        ; Wait for 2 microseconds
    BCF PORTC, 0          ; RB0 low
    BCF PORTC, 1
    BCF PORTC, 2
    CALL DELAY_10US       ; Wait for 10 microseconds
    BCF PORTC, 0          ; RB0 low
    BSF PORTC, 1
    BCF PORTC, 2
    ;----------------------------------
    ;echo------------------------------
    banksel PORTB
    BCF PORTB, 3          
    BSF PORTB, 4
    BCF PORTB, 5
    
	; Set RA4 as input
    BANKSEL TRISA
    BSF TRISA, 4    ; Set RA4 as input

	CALL WAIT_FOR_ECHO4
	RETURN
    
USS11:
    ;trig ----------------------------
    banksel PORTC
    BSF PORTC, 0          ; RB0 low
    BCF PORTC, 1
    BCF PORTC, 2
    CALL DELAY_2US        ; Wait for 2 microseconds
    BCF PORTC, 0          ; RB0 low
    BCF PORTC, 1
    BCF PORTC, 2
    CALL DELAY_10US       ; Wait for 10 microseconds
    BSF PORTC, 0          ; RB0 low
    BCF PORTC, 1
    BCF PORTC, 2
    ;----------------------------------
    ;echo------------------------------
    banksel PORTB
    BSF PORTB, 3          
    BCF PORTB, 4
    BCF PORTB, 5
    
	; Set RA4 as input
    BANKSEL TRISA
    BSF TRISA, 4    ; Set RA4 as input

	CALL WAIT_FOR_ECHO4
	RETURN
    
USS12:
    ;trig ----------------------------
    banksel PORTC
    BCF PORTC, 0          ; RB0 low
    BCF PORTC, 1
    BCF PORTC, 2
    CALL DELAY_2US        ; Wait for 2 microseconds
    BCF PORTC, 0          ; RB0 low
    BSF PORTC, 1
    BCF PORTC, 2
    CALL DELAY_10US       ; Wait for 10 microseconds
    BCF PORTC, 0          ; RB0 low
    BCF PORTC, 1
    BCF PORTC, 2
    ;----------------------------------
    ;echo------------------------------
    banksel PORTB
    BCF PORTB, 3          
    BCF PORTB, 4
    BCF PORTB, 5
    
	; Set RA4 as input
    BANKSEL TRISA
    BSF TRISA, 4    ; Set RA4 as input

	CALL WAIT_FOR_ECHO4
	RETURN
      
USS13:
    ;trig ----------------------------
    banksel PORTC
    BSF PORTC, 0          ; RB0 low
    BSF PORTC, 1
    BSF PORTC, 2
    CALL DELAY_2US        ; Wait for 2 microseconds
    BCF PORTC, 0          ; RB0 low
    BCF PORTC, 1
    BCF PORTC, 2
    CALL DELAY_10US       ; Wait for 10 microseconds
    BSF PORTC, 0          ; RB0 low
    BSF PORTC, 1
    BSF PORTC, 2
    ;----------------------------------
    ;echo------------------------------
    banksel PORTB
    BSF PORTB, 3          
    BSF PORTB, 4
    BSF PORTB, 5
    
	; Set RA4 as input
    BANKSEL TRISA
    BSF TRISA, 4    ; Set RA4 as input

	CALL WAIT_FOR_ECHO4
	RETURN
   
 USS14:
    ;trig ----------------------------
    banksel PORTC
    BCF PORTC, 0          ; RB0 low
    BSF PORTC, 1
    BSF PORTC, 2
    CALL DELAY_2US        ; Wait for 2 microseconds
    BCF PORTC, 0          ; RB0 low
    BCF PORTC, 1
    BCF PORTC, 2
    CALL DELAY_10US       ; Wait for 10 microseconds
    BCF PORTC, 0          ; RB0 low
    BSF PORTC, 1
    BSF PORTC, 2
    ;----------------------------------
    ;echo------------------------------
    banksel PORTB
    BCF PORTB, 3          
    BSF PORTB, 4
    BSF PORTB, 5
    
	; Set RA4 as input
    BANKSEL TRISA
    BSF TRISA, 4    ; Set RA4 as input

	CALL WAIT_FOR_ECHO4
	RETURN
 
USS15:
    ;trig ----------------------------
    banksel PORTC
    BSF PORTC, 0          ; RB0 low
    BCF PORTC, 1
    BSF PORTC, 2
    CALL DELAY_2US        ; Wait for 2 microseconds
    BCF PORTC, 0          ; RB0 low
    BCF PORTC, 1
    BCF PORTC, 2
    CALL DELAY_10US       ; Wait for 10 microseconds
    BSF PORTC, 0          ; RB0 low
    BCF PORTC, 1
    BSF PORTC, 2
    ;----------------------------------
    ;echo------------------------------
    banksel PORTB
    BSF PORTB, 3          
    BCF PORTB, 4
    BSF PORTB, 5
    
	; Set RA4 as input
    BANKSEL TRISA
    BSF TRISA, 4    ; Set RA4 as input

	CALL WAIT_FOR_ECHO4
	RETURN

USS16:
    ;trig ----------------------------
    banksel PORTC
    BCF PORTC, 0          ; RB0 low
    BCF PORTC, 1
    BSF PORTC, 2
    CALL DELAY_2US        ; Wait for 2 microseconds
    BCF PORTC, 0          ; RB0 low
    BCF PORTC, 1
    BCF PORTC, 2
    CALL DELAY_10US       ; Wait for 10 microseconds
    BCF PORTC, 0          ; RB0 low
    BCF PORTC, 1
    BSF PORTC, 2
    ;----------------------------------
    ;echo------------------------------
    banksel PORTB
    BCF PORTB, 3          
    BCF PORTB, 4
    BSF PORTB, 5
    
	; Set RA4 as input
    BANKSEL TRISA
    BSF TRISA, 4    ; Set RA4 as input

	CALL WAIT_FOR_ECHO4
	RETURN
       
USS17:
    ;trig ----------------------------
    banksel PORTA
    BSF PORTA, 0          ; RB0 low
    BCF PORTA, 1
    BCF PORTA, 2
    CALL DELAY_2US        ; Wait for 2 microseconds
    BCF PORTA, 0          ; RB0 low
    BCF PORTA, 1
    BCF PORTA, 2
    CALL DELAY_10US       ; Wait for 10 microseconds
    BSF PORTA, 0          ; RB0 low
    BCF PORTA, 1
    BCF PORTA, 2
    ;----------------------------------
    ;echo------------------------------
    banksel PORTC
    BCF PORTC, 6         
    BSF PORTC, 7
    BANKSEL PORTD
    BSF PORTD, 0
    
	; Set RA5 as input
    BANKSEL TRISA
    BSF TRISA, 5    ; Set RA5 as input

	CALL WAIT_FOR_ECHO5
	RETURN

USS18:
    ;trig ----------------------------
    banksel PORTA
    BSF PORTA, 0          ; RB0 low
    BSF PORTA, 1
    BCF PORTA, 2
    CALL DELAY_2US        ; Wait for 2 microseconds
    BCF PORTA, 0          ; RB0 low
    BCF PORTA, 1
    BCF PORTA, 2
    CALL DELAY_10US       ; Wait for 10 microseconds
    BSF PORTA, 0          ; RB0 low
    BSF PORTA, 1
    BCF PORTA, 2
    ;----------------------------------
    ;echo------------------------------
    banksel PORTC
    BCF PORTC, 6         
    BCF PORTC, 7
    BANKSEL PORTD
    BSF PORTD, 0
    
	; Set RA5 as input
    BANKSEL TRISA
    BSF TRISA, 5    ; Set RA5 as input

	CALL WAIT_FOR_ECHO5
	RETURN 
    
 USS19:
    ;trig ----------------------------
    banksel PORTA
    BSF PORTA, 0          ; RB0 low
    BCF PORTA, 1
    BSF PORTA, 2
    CALL DELAY_2US        ; Wait for 2 microseconds
    BCF PORTA, 0          ; RB0 low
    BCF PORTA, 1
    BCF PORTA, 2
    CALL DELAY_10US       ; Wait for 10 microseconds
    BSF PORTA, 0          ; RB0 low
    BCF PORTA, 1
    BSF PORTA, 2
    ;----------------------------------
    ;echo------------------------------
    banksel PORTC
    BCF PORTC, 6         
    BSF PORTC, 7
    BANKSEL PORTD
    BCF PORTD, 0
    
	; Set RA5 as input
    BANKSEL TRISA
    BSF TRISA, 5    ; Set RA5 as input

	CALL WAIT_FOR_ECHO5
	RETURN     
    
 USS20:
    ;trig ----------------------------
    banksel PORTA
    BSF PORTA, 0          ; RB0 low
    BSF PORTA, 1
    BSF PORTA, 2
    CALL DELAY_2US        ; Wait for 2 microseconds
    BCF PORTA, 0          ; RB0 low
    BCF PORTA, 1
    BCF PORTA, 2
    CALL DELAY_10US       ; Wait for 10 microseconds
    BSF PORTA, 0          ; RB0 low
    BSF PORTA, 1
    BSF PORTA, 2
    ;----------------------------------
    ;echo------------------------------
    banksel PORTC
    BCF PORTC, 6         
    BCF PORTC, 7
    BANKSEL PORTD
    BCF PORTD, 0
    
	; Set RA5 as input
    BANKSEL TRISA
    BSF TRISA, 5    ; Set RA5 as input

	CALL WAIT_FOR_ECHO5
	RETURN       
    
 USS21:
    ;trig ----------------------------
    banksel PORTA
    BCF PORTA, 0          ; RB0 low
    BCF PORTA, 1
    BCF PORTA, 2
    CALL DELAY_2US        ; Wait for 2 microseconds
    BSF PORTA, 0          ; RB0 low
    BCF PORTA, 1
    BCF PORTA, 2
    CALL DELAY_10US       ; Wait for 10 microseconds
    BCF PORTA, 0          ; RB0 low
    BCF PORTA, 1
    BCF PORTA, 2
    ;----------------------------------
    ;echo------------------------------
    banksel PORTC
    BSF PORTC, 6         
    BSF PORTC, 7
    BANKSEL PORTD
    BSF PORTD, 0
    
	; Set RA5 as input
    BANKSEL TRISA
    BSF TRISA, 5    ; Set RA5 as input

	CALL WAIT_FOR_ECHO5
	RETURN  
    
 USS22:
    ;trig ----------------------------
    banksel PORTA
    BCF PORTA, 0          ; RB0 low
    BSF PORTA, 1
    BCF PORTA, 2
    CALL DELAY_2US        ; Wait for 2 microseconds
    BCF PORTA, 0          ; RB0 low
    BCF PORTA, 1
    BCF PORTA, 2
    CALL DELAY_10US       ; Wait for 10 microseconds
    BCF PORTA, 0          ; RB0 low
    BSF PORTA, 1
    BCF PORTA, 2
    ;----------------------------------
    ;echo------------------------------
    banksel PORTC
    BSF PORTC, 6         
    BCF PORTC, 7
    BANKSEL PORTD
    BSF PORTD, 0
    
	; Set RA5 as input
    BANKSEL TRISA
    BSF TRISA, 5    ; Set RA5 as input

	CALL WAIT_FOR_ECHO5
	RETURN      
       
 USS23:
    ;trig ----------------------------
    banksel PORTA
    BCF PORTA, 0          ; RB0 low
    BCF PORTA, 1
    BSF PORTA, 2
    CALL DELAY_2US        ; Wait for 2 microseconds
    BCF PORTA, 0          ; RB0 low
    BCF PORTA, 1
    BCF PORTA, 2
    CALL DELAY_10US       ; Wait for 10 microseconds
    BCF PORTA, 0          ; RB0 low
    BCF PORTA, 1
    BSF PORTA, 2
    ;----------------------------------
    ;echo------------------------------
    banksel PORTC
    BSF PORTC, 6         
    BSF PORTC, 7
    BANKSEL PORTD
    BCF PORTD, 0
	; Set RA5 as input
    BANKSEL TRISA
    BSF TRISA, 5    ; Set RA5 as input

	CALL WAIT_FOR_ECHO5
	RETURN 

 USS24:
    ;trig ----------------------------
    banksel PORTA
    BCF PORTA, 0          ; RB0 low
    BSF PORTA, 1
    BSF PORTA, 2
    CALL DELAY_2US        ; Wait for 2 microseconds
    BCF PORTA, 0          ; RB0 low
    BCF PORTA, 1
    BCF PORTA, 2
    CALL DELAY_10US       ; Wait for 10 microseconds
    BCF PORTA, 0          ; RB0 low
    BSF PORTA, 1
    BSF PORTA, 2
    ;----------------------------------
    ;echo------------------------------
    banksel PORTC
    BSF PORTC, 6         
    BCF PORTC, 7
    BANKSEL PORTD
    BCF PORTD, 0
    
	; Set RA5 as input
    BANKSEL TRISA
    BSF TRISA, 5    ; Set RA5 as input

	CALL WAIT_FOR_ECHO5
	RETURN    
  

   
; Timer routines
START_TIMER:
    ; Echo Pin is high, start Timer1
    banksel TMR1H
    CLRF TMR1H
    CLRF TMR1L
    banksel PIR1
    BCF PIR1, TMR1IF      ; Clear Timer1 overflow flag

    banksel T1CON
    BSF T1CON, 0

    RETURN
   
STOP_TIMER:
    banksel T1CON
    BCF T1CON, 0

   ; Echo Pin is low, stop Timer1
    banksel TMR1L
    MOVF TMR1L, W
    MOVWF R1_LSB
    banksel TMR1H
    MOVF TMR1H, W
    MOVWF R1_MSB
    RETURN
 
CALCULATE_DISTANCE:
	;Get time of flight,that calculated
	;Store time of flight in R1_LSB,R1_MSB
	;Divide the time by 58,
	;To convert time in micro to distance in cm

    BCF STATUS, C
    BCF STATUS, Z 

    ;Load 58 to R2
    MOVLW 0x3A
    MOVWF R2_LSB 
    
    MOVLW 0x03       ; wait for 3 seconds
    CALL DELAY_10US
    
    CALL DIVIDE
    CALL HexBCD     
    CALL load_distance

    ;MOVLW 0x03       ; wait for 3 seconds
    CALL DELAY_10US
    
    RETURN

SUB:
	COMF R2_LSB, 0        ; Compute the two's complement of R2_LSB
	ADDWF TEMP_LSB, 0     ; Add 1 to get the two's complement
	BTFSC STATUS, 0       ; Check if there was a carry from the previous addition
	INCF TEMP_MSB         ; If there was a carry, increment TEMP_MSB
	ADDLW 0x01            ; Add 1 to W register
	BTFSC STATUS, 0       ; Check if there was a carry from the previous addition
	INCF TEMP_MSB         ; If there was a carry, increment TEMP_MSB
	MOVWF TEMP_LSB        ; Move the result of two's complement to TEMP_LSB
	COMF R2_MSB, 0        ; Compute the two's complement of R2_MSB
	ADDWF TEMP_MSB, 0     ; Add 1 to get the two's complement
	MOVWF TEMP_MSB        ; Move the result of two's complement to TEMP_MSB
	RETURN                ; Return from the subroutine

DIVIDE:
	CLRF RESULT_MSB      	; Clear the result's Most Significant Byte
	CLRF RESULT_LSB      	; Clear the result's Least Significant Byte
	CLRF CARRY_SAVED
	MOVF R1_LSB, W       	; Move the value in R1_LSB to TEMP_LSB (temporary storage)
	MOVWF TEMP_LSB
	MOVF R1_MSB, W       	; Move the value in R1_MSB to TEMP_MSB (temporary storage)
	MOVWF TEMP_MSB
	MOVF R2_LSB, W        	; Move the value in R2_LSB to W register
	BTFSC STATUS, Z	   		; Check if the divisor is 0
	GOTO UPPER_BITS 	; If it is, check the upper bits
	GOTO DIVLOOP          	; If it isn't, continue the division loop
	
UPPER_BITS:
	MOVF R2_MSB, 0        ; Move the value in R2_MSB to W register
	BTFSC STATUS, Z       ; Check if the divisor is 0
	GOTO DIVEND           ; If it is, exit the loop (division complete)
	
DIVLOOP:
	CALL SUB              ; Call the SUB subroutine to perform subtraction
	BTFSS STATUS, 0       ; Check if there was a borrow (no carry) from the previous subtraction
	GOTO DIVEND           ; If no borrow, exit the loop (division complete)	
	INCF RESULT_LSB       ; Increment the result's Least Significant Byte
	MOVF RESULT_LSB,0
	BTFSC STATUS, 2       ; Check if the register is overflown
	INCF RESULT_MSB       ; If it is, increment the result's Most Significant Byte
	GOTO DIVLOOP          ; Continue the division loop
	 
DIVEND:
	MOVF RESULT_LSB,0
	BTFSS STATUS,Z
	INCF RESULT_LSB
	RETURN                ; Return from the DIVIDE subroutine


HexBCD: 
    movlw d'16'			; Set the counter to 16
    movwf MCount 		; Move the counter to MCount
    clrf BCDvalH 		; Clear the BCD value's Most Significant Byte
    clrf BCDvalM		; Clear the BCD value's Middle Significant Byte
    clrf BCDvalL		; Clear the BCD value's Least Significant Byte
    bcf STATUS,C 		; Clear the carry bit
    ;----------------------------

loop16:  
    rlf RESULT_LSB,F 	;
    rlf RESULT_MSB,F
    rlf BCDvalL,F
    rlf BCDvalM,F
    rlf BCDvalH,F

    decf MCount,F
    btfsc STATUS,Z
    return

adjDEC:   
	movlw BCDvalL
	movwf FSR
	call adjBCD
	movlw BCDvalM
	movwf FSR
	call adjBCD
	movlw BCDvalH
	movwf FSR
	call adjBCD
	goto loop16

adjBCD 
	movlw d'3'
	addwf INDF,W
	movwf Temp
	btfsc Temp,3
	movwf INDF
	movlw 30h
	addwf INDF,W
	movwf Temp
	btfsc Temp,7
	movwf INDF
	RETURN

dec2bin16
    movf  C4,W        ; (C4 + C2) * 2
    addwf C2,W
    movwf NUMLO
    rlf   NUMLO,F

    swapf C3,W        ; + C3 * 16 + C3
    addwf C3,W
    addwf NUMLO,F

    rlf   C1,W        ; + (C1 * 2 + C2) * 256
    addwf C2,W
    movwf NUMHI

    rlf   NUMLO,F     ; * 2
    rlf   NUMHI,F

    swapf C2,W        ; - C2 * 16
    subwf NUMLO,F
    skpc
    decf  NUMHI,F

    swapf C3,W        ; + C3 * 16 + C4
    addwf C4,W
    addwf NUMLO,F
    skpnc
    incf  NUMHI,F

    swapf C1,W        ; + C1 * 16 + C5
    addwf C5,W

    rlf   NUMLO,F     ; * 2
    rlf   NUMHI,F

    addwf NUMLO,F
    skpnc
    incf  NUMHI,F

    movf  C1,W        ; - C1 * 256
    subwf NUMHI,F

    swapf C1,W        ; + C1 * 16 * 256 * 2
    addwf NUMHI,F
    addwf NUMHI,F

    return            ; Q.E.D.

load_distance:

	SWAPF BCDvalH, 1
	MOVF BCDvalH, 0
	ANDLW 0x0F
	ADDLW '0'
	MOVWF DIGIT6
	
	SWAPF BCDvalH, 1
	MOVF BCDvalH, 0
	ANDLW 0x0F
	ADDLW '0'
	MOVWF DIGIT5
	
	SWAPF BCDvalM, 1
	MOVF BCDvalM, 0
	ANDLW 0x0F
	ADDLW '0'
	MOVWF DIGIT4
	
	SWAPF BCDvalM, 1
	MOVF BCDvalM, 0
	ANDLW 0x0F
	ADDLW '0'
	MOVWF DIGIT3
	
	SWAPF BCDvalL, 1
	MOVF BCDvalL, 0
	ANDLW 0x0F
	ADDLW '0'
	MOVWF DIGIT2
	
	SWAPF BCDvalL, 1
	MOVF BCDvalL, 0
	ANDLW 0x0F
	ADDLW '0'
	MOVWF DIGIT1
	
	
	BTFSC CARRY_SAVED, 0
	CALL  NORMALIZE_NUMBER
	

	MOVLW D'40'
	MOVWF TIMER_INDEX
	RETURN
	
NORMALIZE_NUMBER:
	MOVLW 6
	ADDWF DIGIT1, 0
	MOVWF DIGIT1
	SUBLW 0x39			; CHECK IF IT HAS EXCEEDED '9'
	BTFSC STATUS, 0		; NUMBER IS NEGATIVE
	GOTO NORMALIZE_NUMBER_2
	MOVLW D'10'
	SUBWF DIGIT1, 1
	INCF DIGIT2

NORMALIZE_NUMBER_2:
	MOVLW 3
	ADDWF DIGIT2, 0
	MOVWF DIGIT2
	SUBLW 0x39		; CHECK IF IT HAS EXCEEDED '9'
	BTFSC STATUS, 0		; NUMBER IS NEGATIVE
	GOTO NORMALIZE_NUMBER_3
	MOVLW D'10'
	SUBWF DIGIT2, 1
	INCF DIGIT3

NORMALIZE_NUMBER_3:
	MOVLW 5
	ADDWF DIGIT3, 0
	MOVWF DIGIT3
	SUBLW 0x39			; CHECK IF IT HAS EXCEEDED '9'
	BTFSC STATUS, 0		; NUMBER IS NEGATIVE
	GOTO NORMALIZE_NUMBER_4
	MOVLW D'10'
	SUBWF DIGIT3, 1
	INCF DIGIT4

NORMALIZE_NUMBER_4:
	MOVLW 5
	ADDWF DIGIT4, 0
	MOVWF DIGIT4
	SUBLW 0x39			; CHECK IF IT HAS EXCEEDED '9'
	BTFSC STATUS, 0		; NUMBER IS NEGATIVE
	GOTO NORMALIZE_NUMBER_5
	MOVLW D'10'
	SUBWF DIGIT4, 1
	INCF DIGIT5

NORMALIZE_NUMBER_5:
	MOVLW 6
	ADDWF DIGIT5, 0
	MOVWF DIGIT5
	SUBLW 0x39			; CHECK IF IT HAS EXCEEDED '9'
	BTFSC STATUS, 0		; NUMBER IS NEGATIVE
	GOTO NORMALIZE_NUMBER_6
	MOVLW D'10'	
	SUBWF DIGIT5, 1
	INCF DIGIT6

NORMALIZE_NUMBER_6:
	RETURN
	
; Delay for 10 microseconds
DELAY_10US:
    ; Implement your delay here, ensuring it lasts for about 10 microseconds
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    RETURN
    
; Delay for 2 microseconds
DELAY_2US:
    ; Implement your delay here, ensuring it lasts for about 2 microseconds
    NOP
    NOP
    RETURN

; Clear the display and return the cursor to the home position
clearDisplay:
    BANKSEL PORTD		; Select bank 0
    BCF	    Select, RS       ; Select command mode
    MOVLW    0x01	    ; clear display
    CALL    send	    ; and send code
    MOVLW	0x80	    ; position to home cursor
    CALL	send	    ; and send code 
    RETURN

; print welcome message on the LCD
printWelcome:
    ; clear the display
    CALL clearDisplay
    BSF    Select,RS	; Select data mode

    ; delay for 500ms to make the print blinking
    MOVLW   D'500'
    CALL    xms
    

    ; print "Welcome to" in the first line
    MOVLW	'W'		
    CALL	send		; and send code
    MOVLW	'e'
    CALL	send
    MOVLW	'l'
    CALL	send
    MOVLW	'c'
    CALL	send
    MOVLW	'o'
    CALL	send
    MOVLW	'm'
    CALL	send
    MOVLW	'e'
    CALL	send
    MOVLW	' '
    CALL	send
    MOVLW	't'
    CALL	send
    MOVLW	'o'
    CALL	send


    ; move cursor to the second line
    BCF     Select,RS	; Select command mode
    MOVLW	0xC0	    ; position to home cursor
    CALL	send	    ; and send code
    BSF     Select,RS	; Select data mode
    
    ; print "SRF04 Modules" in the second line
    MOVLW	'S'
    CALL	send
    MOVLW	'R'
    CALL	send
    MOVLW	'F'
    CALL	send
    MOVLW	'0'
    CALL	send
    MOVLW	'4'
    CALL	send
    MOVLW	' '
    CALL	send
    MOVLW	'M'
    CALL	send
    MOVLW	'o'
    CALL	send
    MOVLW	'd'
    CALL	send
    MOVLW	'u'
    CALL	send
    MOVLW	'l'
    CALL	send
    MOVLW	'e'
    CALL	send
    MOVLW	's'
    CALL	send


    ; delay for 500ms 
    MOVLW   D'500'
    CALL    xms

    RETURN
printReadingSensors:
    ; clear the display
    CALL clearDisplay
    BSF    Select,RS	; Select data mode

    ; delay for 500ms to make the print blinking
    MOVLW   D'500'
    CALL    xms
    

    ; print "Welcome to" in the first line
    MOVLW	'R'		
    CALL	send		; and send code
    MOVLW	'e'
    CALL	send
    MOVLW	'a'
    CALL	send
    MOVLW	'd'
    CALL	send
    MOVLW	'i'
    CALL	send
    MOVLW	'n'
    CALL	send
    MOVLW	'g'
    CALL	send
    MOVLW	'.'
    CALL	send
    MOVLW	'.'
    CALL	send
    MOVLW	'.'
    CALL	send
    MOVLW	'2'
    CALL	send
    MOVLW	'4'
    CALL	send
    MOVLW	's'
    CALL	send

    ; move cursor to the second line
    BCF     Select,RS	; Select command mode
    MOVLW	0xC0	    ; position to home cursor
    CALL	send	    ; and send code
    BSF     Select,RS	; Select data mode
    
    ; print "SRF04 Modules" in the second line
    MOVLW	'S'
    CALL	send
    MOVLW	'R'
    CALL	send
    MOVLW	'F'
    CALL	send
    MOVLW	'0'
    CALL	send
    MOVLW	'4'
    CALL	send
    MOVLW	' '
    CALL	send
    MOVLW	'M'
    CALL	send
    MOVLW	'o'
    CALL	send
    MOVLW	'd'
    CALL	send
    MOVLW	'u'
    CALL	send
    MOVLW	'l'
    CALL	send
    MOVLW	'e'
    CALL	send
    MOVLW	's'
    CALL	send


    ; delay for 500ms 
    MOVLW   D'500'
    CALL    xms

    RETURN

      
; Write "Result" in the first line
printResult:
    MOVLW 0x00  
    MOVWF TEMP_D3
    BSF    Select,RS	; Select data mode
	 
    MOVLW	'U'
    CALL	send
    MOVLW	'S'
    CALL	send

	CALL get_index

	MOVF dH,W
	ADDLW 0x30
	CALL send

	MOVF dL,W
	ADDLW 0x30
	CALL send

    MOVLW ':'
	CALL send

    MOVF DIGIT3, W
	BTFSC STATUS, Z       ; Check if the result is zero 
    GOTO skip_d3          ; If DIGIT3 is zero, skip sending
    ; Compare if DIGIT3 is ASCII zero
    XORLW 0x30            ; XOR with ASCII value of '0'
    BTFSC STATUS, Z       ; Check if the result is zero (meaning DIGIT3 was '0')
    GOTO skip_d3          ; If DIGIT3 is ASCII '0', skip sending

	MOVLW 0x01  
   	MOVWF TEMP_D3
	MOVF DIGIT3, W
	CALL send

skip_d3: 
	MOVF DIGIT2, 0
	CALL send
	 
	MOVF DIGIT1, 0
	CALL send
    RETURN
  
get_index:
   ; Clear digit registers
    CLRF dL
    CLRF dH

    ; Load number into W register
    MOVF number,0

	; Check if the number is greater than 9
	MOVWF TEMP
	;---------------
	MOVWF TEMP_10
	MOVLW 0x0A
	;MOVWF TEMP_10
	;---------------
    SUBWF TEMP_10, W
    BTFSC STATUS, C
	call more_than_10
	
	MOVFW TEMP
	MOVWF dL
	RETURN

more_than_10:
	MOVWF TEMP
	MOVLW 0x01   
   	MOVWF dH
	MOVFW TEMP   
	; Check if the number is greater than 9
	MOVWF TEMP_10
	MOVLW 0x0A
	;MOVWF TEMP_10
	;---------------
    SUBWF TEMP_10, W
    BTFSC STATUS, C
	call more_than_20
	RETURN

more_than_20:
	MOVWF TEMP
	MOVLW 0x02   
   	MOVWF dH
	MOVFW TEMP   
	; Check if the number is greater than 9
	MOVWF TEMP_10
	MOVLW 0x0A
	;MOVWF TEMP_10
	;---------------
    SUBWF TEMP_10, W
	RETURN	


display_highest_four_sensors:
	; clear the display
    CALL clearDisplay

display_first_sensor:
	MOVF num1_L,0
	MOVWF R1_LSB
	MOVF num1_H,0
	MOVWF R1_MSB
    CALL CALCULATE_DISTANCE ; Calculate distance

	MOVF num1_N,0 
	MOVWF number

	CALL printResult ;display distance
	MOVLW 0x01
	SUBWF TEMP_D3, W
	BTFSC STATUS, Z
	goto display_second_sensor
	MOVLW ' '
	CALL send

display_second_sensor:
	MOVF num2_L,0
	MOVWF R1_LSB
	MOVF num2_H,0
	MOVWF R1_MSB
    CALL CALCULATE_DISTANCE ; Calculate distance

	MOVF num2_N,0 
	MOVWF number

	CALL printResult ;display distance

    ; move cursor to the second line
    BCF     Select,RS	; Select command mode
    MOVLW	0xC0	    ; position to home cursor
    CALL	send	    ; and send code
    BSF     Select,RS	; Select data mode
    
display_third_sensor:
	MOVF num3_L,0
	MOVWF R1_LSB
	MOVF num3_H,0
	MOVWF R1_MSB
    CALL CALCULATE_DISTANCE ; Calculate distance

	MOVF num3_N,0 
	MOVWF number

	CALL printResult ;display distance
	MOVLW 0x01
	SUBWF TEMP_D3, W
	BTFSC STATUS, Z
	goto display_fourth_sensor
	MOVLW ' '
	CALL send

display_fourth_sensor:
	MOVF num4_L,0
	MOVWF R1_LSB
	MOVF num4_H,0
	MOVWF R1_MSB
    CALL CALCULATE_DISTANCE ; Calculate distance

	MOVF  num4_N,0 
	MOVWF number

	CALL printResult ;display distance

	return

compare_two_numbers:
	MOVLW 0x00  
   	MOVWF TEMP
	MOVLW 0x00  
   	MOVWF TEMP_10
	;--------------------------
	MOVFW TEMP_MSB
	SUBWF R1_MSB, W
	BTFSC STATUS, Z      ; If zero set (TEMP1 == TEMP2), high bytes are equal
    goto compare_low_byte ; If they are equal, compare low bytes

	BTFSC STATUS, C
	call New_is_more ;WHEN NUM1_H < R1_MSB

ALL_EQUAL:
	
	RETURN

compare_low_byte:
	MOVFW TEMP_LSB
	SUBWF R1_LSB, W
	BTFSC STATUS, Z      ; If zero set (TEMP1 == TEMP2), high bytes are equal
    goto sameNumber ; If they are equal, compare low bytes

	BTFSC STATUS, C 
	call New_is_more ; R1_LSB > NUM1_H

	goto ALL_EQUAL

New_is_more:
	MOVLW 0x01  
   	MOVWF TEMP
	RETURN

sameNumber:
	MOVLW 0x01  
   	MOVWF TEMP_10
	goto ALL_EQUAL

compareTo4_andShift:
	
	;FIRST ROUND
	MOVFW num1_L
	MOVWF TEMP_LSB
	MOVFW num1_H
	MOVWF TEMP_MSB
	CALL compare_two_numbers

	MOVLW 0x01
	SUBWF TEMP_10, W
	BTFSC STATUS, Z      ; If zero set (TEMP1 == TEMP2), high bytes are equal
    goto doneShift
	
	MOVLW 0x01
	SUBWF TEMP, W
	BTFSC STATUS, Z      ; If zero set (TEMP1 == TEMP2), high bytes are equal
    goto shiftFirst
	;-----------------------------

	;SECOND ROUND
	MOVFW num2_L
	MOVWF TEMP_LSB
	MOVFW num2_H
	MOVWF TEMP_MSB
	CALL compare_two_numbers

	MOVLW 0x01
	SUBWF TEMP_10, W
	BTFSC STATUS, Z      ; If zero set (TEMP1 == TEMP2), high bytes are equal
    goto doneShift
	
	MOVLW 0x01
	SUBWF TEMP, W
	BTFSC STATUS, Z      ; If zero set (TEMP1 == TEMP2), high bytes are equal
    goto shiftSecond

	;-----------------------------

	;THIRD ROUND
	MOVFW num3_L
	MOVWF TEMP_LSB
	MOVFW num3_H
	MOVWF TEMP_MSB
	CALL compare_two_numbers

	MOVLW 0x01
	SUBWF TEMP_10, W
	BTFSC STATUS, Z      ; If zero set (TEMP1 == TEMP2), high bytes are equal
    goto doneShift
	
	MOVLW 0x01
	SUBWF TEMP, W
	BTFSC STATUS, Z      ; If zero set (TEMP1 == TEMP2), high bytes are equal
    goto shiftThird

	;-----------------------------

	;FIURTH ROUND
	MOVFW num4_L
	MOVWF TEMP_LSB
	MOVFW num4_H
	MOVWF TEMP_MSB
	CALL compare_two_numbers


    MOVLW 0x01
	SUBWF TEMP_10, W
	BTFSC STATUS, Z      ; If zero set (TEMP1 == TEMP2), high bytes are equal
    goto doneShift

	
	MOVLW 0x01
	SUBWF TEMP, W
	BTFSC STATUS, Z      ; If zero set (TEMP1 == TEMP2), high bytes are equal
    goto shiftFourth

	;-----------------------------
	
doneShift:

	RETURN

shiftFirst:
	MOVFW num3_L
	MOVWF num4_L	
	MOVFW num3_H
	MOVWF num4_H
	MOVFW num3_N
	MOVWF num4_N
	
	MOVFW num2_L
	MOVWF num3_L
	MOVFW num2_H
	MOVWF num3_H
	MOVFW num2_N
	MOVWF num3_N

	MOVFW num1_L
	MOVWF num2_L
	MOVFW num1_H
	MOVWF num2_H
	MOVFW num1_N
	MOVWF num2_N

	MOVFW R1_LSB
	MOVWF num1_L
	MOVFW R1_MSB
	MOVWF num1_H
	MOVFW num_sensor
	MOVWF num1_N
	goto doneShift

shiftSecond:
	MOVFW num3_L
	MOVWF num4_L
	MOVFW num3_H
	MOVWF num4_H
	MOVFW num3_N
	MOVWF num4_N
	
	MOVFW num2_L
	MOVWF num3_L
	MOVFW num2_H
	MOVWF num3_H
	MOVFW num2_N
	MOVWF num3_N

	MOVFW R1_LSB
	MOVWF num2_L
	MOVFW R1_MSB
	MOVWF num2_H
	MOVFW num_sensor
	MOVWF num2_N
	goto doneShift

shiftThird:
	MOVFW num3_L
	MOVWF num4_L
	MOVFW num3_H
	MOVWF num4_H
	MOVFW num3_N
	MOVWF num4_N
	
	MOVFW R1_LSB
	MOVWF num3_L
	MOVFW R1_MSB
	MOVWF num3_H
	MOVFW num_sensor
	MOVWF num3_N
	goto doneShift

shiftFourth:
	MOVFW R1_LSB
	MOVWF num4_L
	MOVFW R1_MSB
	MOVWF num4_H
	MOVFW num_sensor
	MOVWF num4_N
	goto doneShift


END