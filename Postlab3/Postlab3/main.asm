//***************************************************
;
; Universidad del Valle de Guatemala
; IE2023: Programación de Microcontroladores
; Autor: Angel Velásquez
; Descripción: Laboratorio 3, contador binario que se muestra en un display de 7 segmentos, controlado por timer0.
; Hardware: atmega328p
; Proyecto: AssemblerApplication1.asm
; Created: 12/02/2024 
;
//**************************************************


//**************************************************
; ENCABEZADO
//**************************************************
.include "M328PDEF.inc"
.cseg								//Indica inicio del código
.org 0x00							//Indica en que dirección va a estar el vector RESET
	JMP MAIN
.org 0x0006
	JMP ISR_PCINT0
.org 0x0020
	JMP ISR_TIMER0_OV0


MAIN:
//**************************************************
; Configuración de pila
//**************************************************
LDI R16, LOW(RAMEND)              //STACKPOINTER, PARTE BAJA
OUT SPL, R16
LDI R16, HIGH(RAMEND)             //STACKPOINTER, PARTE DE ARRIBA
OUT SPH, R16

//**************************************************
; Tabla de datos
//**************************************************
TABLA7SEG: .DB 0b0011_1111, 0b1000_0101, 0b1101_1011 , 0b0100_1111, 0b0110_0101, 0b0110_1110, 0b1111_1110, 0b0000_0111, 0b1111_1111, 0b0110_1111, 0b0111_0111, 0b0111_1100, 0b0011_1001, 0b0101_1110, 0b0111_1001, 0b0111_0001


//**************************************************
; CONFIGURACIÓN MCU
//**************************************************
SETUP:
LDI R16, 0b1000_0000		  // 
STS CLKPR,R16				  // Habilitar el prescaler (STS GUARDA R16 EN UN LUGAR FUERA DE I/O)
LDI R16, 0b0000_0100
STS CLKPR,R16				  // Definir el prescaler de 16 Fcpu = 1MHz

LDI R16, 0b0000_1100		  //PUERTO B 
OUT DDRB, R16			
LDI R16, 0b1000_0011	  //PULL-UPS de los pines
OUT PORTB, R16	  

LDI R16, 0b0000_1111		  //PUERTO C
OUT DDRC, R16

LDI R16, 0b0111_1111	  //PUERTO D
OUT DDRD, R16


LDI R16, (1 << PCINT1) | (1 << PCINT0)
STS PCMSK0, R16

LDI R16, (1 << PCIE0)
STS PCICR, R16

CALL INIT_T0

LDI R17, 0b1111_0000 //Registro del binario
LDI R18, 0b0000_0000 //Contador de repeticiones del timer0
LDI R22, 0b0000_0000 // Registro unidades del contador del timer
LDI R23, 0b0000_0000 // Registro decenas del contador del timer
LDI R24, LOW(TABLA7SEG <<1) //INICIAL ZL
LDI R27, 0
LDI R28, 30

SEI			//Habilito las banderas globales

LDI R20, 1
LDI ZH, HIGH(TABLA7SEG <<1)
LDI ZL, LOW(TABLA7SEG <<1)

LPM R21, Z
OUT PORTD, R21






//**************************************************
; LOOP INFINITO
//*************************************************

LOOP:	//LOOP INFINITO DEL PROGRAMA 


RJMP LOOP


//**************************************************
; SUBRUTINAS
//**************************************************


//////////////////////////////////////////
//      init_TIMER0						//
//////////////////////////////////////////
INIT_T0:
//LDI R16, 0b0000_0000
//OUT TCCR0A, R16			// El temporizador en modo normal

LDI R16, (1 << CS02) | (1 << CS00)
OUT TCCR0B,  R16		// Prescaler a 1024

LDI R16, 245 //CARGO EL VALOR DONDE DEBERIA EMPEZAR A CONTAR
OUT TCNT0, R16

LDI R16, (1 << TOIE0)
STS TIMSK0, R16
RET


//////////////////////////////////////////
//      SUBRUTINA TIMER0				//
//////////////////////////////////////////
ISR_TIMER0_OV0:
ENTRAR_T0:
PUSH R16
IN R16, SREG
PUSH R16


CPI R27, 0
BRNE P1
RJMP P2

P1:

//UNIDADES

;LDI R16, 0b0000_0000
;OUT PORTD, R16

LDI R16, 0b0000_0111
OUT PORTB, R16 

ADD ZL, R22
LPM R19, Z
SBC ZL, R22

OUT PORTD, R19
DEC R27
RJMP SEGUIR_T0

P2:

//DECENAS
;LDI R16, 0b0000_0000
;OUT PORTD, R16

LDI R16, 0b0000_1011
OUT PORTB, R16

ADD ZL, R23
LPM R19, Z
SBC ZL, R23
OUT PORTD, R19
INC R27
RJMP SEGUIR_T0





SEGUIR_T0:
LDI R16, 245 //CARGO EL VALOR DONDE DEBERIA EMPEZAR A CONTAR
OUT TCNT0, R16
SBI TIFR0, TOV0

CPI R18, 100  
BRNE INC_T0
RJMP RESET_T0

INC_T0:
INC R18
RJMP SALIR_T0

RESET_T0:
LDI R18, 0b0000_0000
RJMP INC_DIS7

INC_DIS7:
CPI R22, 9 
BRNE INCRME
RJMP RESET_C

INCRME:
INC R22
RJMP SALIR_T0

RESET_C:
LDI R22, 0b0000_0000
CPI R23, 5
BRNE INCR_DE
RJMP RESET_D

INCR_DE:
INC R23
RJMP SALIR_T0

RESET_D:
LDI R23, 0b0000_0000
RJMP SALIR_T0

SALIR_T0:

POP R16
OUT SREG, R16
POP R16
RETI




//////////////////////////////////////////
//      SUBRUTINA ISR INT0				//
//////////////////////////////////////////
ISR_PCINT0:

ENTRAR:
PUSH R16
IN R16, SREG
PUSH R16

IN R18, PINB
SBRS R18, PB0
RJMP C_PB0

SBRS R18, PB1
RJMP C_PB1

RJMP SALIR


C_PB0:
IN R16, TCNT0
LDI R25, 30
ADD R16, R25

ESPERA_0:
IN R26, TCNT0
CP R26, R16
BRNE ESPERA_0
RJMP C_PB0_D

C_PB0_D:
IN R26, PINB
SBRS R26, PB0
RJMP C_PB0
CPI R17, 0b1111_1111
BRNE N1_add
RJMP SALIR

C_PB1:
IN R16, TCNT0
LDI R25, 30
ADD R16, R25
ESPERA_1:
IN R26, TCNT0
CP R26, R16
BRNE ESPERA_1
RJMP C_PB1_D

C_PB1_D:
IN R26, PINB
SBRS R26, PB1
RJMP C_PB1
CPI R17, 0b1111_0000
BRNE N1_res
RJMP SALIR

N1_res:
DEC R17
RJMP SALIR

N1_add:
INC R17
RJMP SALIR


SALIR:
//ACTUALIZAR LEDS
OUT PORTC, R17
///////////////////////

SBI PCIFR, PCIF0
POP R16
OUT SREG, R16
POP R16
RETI
