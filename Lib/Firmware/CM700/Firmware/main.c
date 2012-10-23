#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/eeprom.h>
#include <util/delay.h>
#include <stdio.h>

#include "uart1.h"
#include "rs485.h"
#include "timer1.h"
#include "dynamixel.h"
#include "ctable.h"
#include "adc.h"

#define cbi(REG8,BIT) REG8 &= ~(_BV(BIT))
#define sbi(REG8,BIT) REG8 |= _BV(BIT)

volatile unsigned long nOVF = 0;
void t1_overflow(void)
{
  static char led = 0;
  nOVF++;

  // Read START button and set AUX Led
  if (PIND & _BV(PD0)) {
    controlTable.button = 0;
    PORTC |= _BV(PORTC3);
  }
  else {
    controlTable.button = 1;
    PORTC &= ~(_BV(PORTC3));
  }

  // Set PLAY Led
  if (controlTable.led) {
    PORTC &= ~(_BV(PORTC6));
  }
  else {
    PORTC |= _BV(PORTC6);
  }

  if (nOVF % 30 == 0) {
    // Toggle MON and Dynamixel Leds
    if (led) {
      led = 0;
      rs485_putstrn("\xFF\xFF\xFE\x04\x03\x19\x00\xE1", 8);
      PORTC |= _BV(PORTC4);
    }
    else {
      led = 1;
      rs485_putstrn("\xFF\xFF\xFE\x04\x03\x19\x01\xE0", 8);
      PORTC &= ~(_BV(PORTC4));
    }
  }
}

void init(void)
{
  // Enable outputs
  DDRC = 0b11111111;
  PORTC = 0xFF;
  // Turn on PWR Led
  PORTC &= ~(_BV(PORTC0));

  uart1_init();
  uart1_setbaud(57600);

  rs485_init();
  rs485_setbaud(1000000);

  ctable_init();
  adc_init();
  
  timer1_init();
  timer1_set_overflow_callback(t1_overflow);

  sei();
}

int uart1_send(DynamixelPacket *pktSend) {
  // Write packet to uart1
  uart1_putstrn((char *)pktSend, pktSend->length+4);
  return 1;
}

int rs485_send_recv(DynamixelPacket *pktSend, DynamixelPacket *pktRecv) {
  int c;
  int count = 0;
  int nRecv = 0;

  // Write packet to RS485
  rs485_putstrn((char *)pktSend, pktSend->length+4);

  // Wait for response from RS485
  do {
    count++;
    _delay_ms(1);
    c = rs485_getchar();
    if (c != EOF) {
      nRecv = dynamixel_input(pktRecv, c, nRecv);
      if (nRecv == -1) {
	return 1;
      }
    }
  } while (count < 100);

  return 0;
}


int main(void)
{
  // int for reading, cannot be char since EOF=-1
  int c;
  int i;
  unsigned long count = 0;

  // Variables to keep track reading servos
  int nRead=0, idRead=0;
  
  // Dynamixel packets and counters for input/output
  DynamixelPacket *pktReadData, *pktStatus;
  DynamixelPacket pktSerialInput, pktRs485Input;
  int nSerialInput = 0, nRs485Input = 0;
  int serialRs485Forwarded = 0;

  init();
  uart1_putstr("\r\nStarting CM700 Dynamixel relay program\r\n");
  uart1_putstr("Switching to 1000000 baud...\r\n");
  _delay_ms(100);
  uart1_setbaud(1000000);
  uart1_putstr("Running at 1000000 baud\r\n");

  while (1) {
    count++;

    c = uart1_getchar();
    while (c != EOF) {
      // Process char from serial input
      nSerialInput = dynamixel_input(&pktSerialInput, c, nSerialInput);
      if (nSerialInput == -1) {
	// Well-formed serial input packet
	if (pktSerialInput.id != controlTable.id) {
	  // Forward packet to RS485
	  rs485_putstrn((char *)&pktSerialInput, pktSerialInput.length+4);
	  serialRs485Forwarded = 1;
	}
	else {
	  // Packet is for CM700, flash EDIT Led
	  PORTC &= ~(_BV(PORTC5));
	  switch (pktSerialInput.instruction) {
	  case INST_WRITE:
	    for (i = 1; i < pktSerialInput.length-2; i++) {
	      controlTablePtr[pktSerialInput.parameter[0]+i-1] =
		pktSerialInput.parameter[i];
	    }
	    // Status packet
	    pktStatus = dynamixel_status(controlTable.id,
					 0, NULL, 0);
	    break;
	  case INST_READ:	    
	    pktStatus = dynamixel_status(controlTable.id, 0,
	      (uchar *)controlTablePtr+pktSerialInput.parameter[0],
	      pktSerialInput.parameter[1]);
	    break;
	  case INST_PING:
	    pktStatus = dynamixel_status(controlTable.id,
					 0, NULL, 0);
	    break;
	  default:
	    // Unknown command
	    pktStatus = dynamixel_status(controlTable.id,
					 1, NULL, 0);
	    break;
	  }
	  uart1_putstrn((char *)pktStatus, pktStatus->length+4);
	  PORTC |= _BV(PORTC5);
	}
      }
      c = uart1_getchar();
    }

    if (!serialRs485Forwarded) {
      // Query servo for position in round robin fashion:
      if (++nRead >= controlTable.nServo) nRead = 0;
      idRead = controlTable.idMap[nRead];
      pktReadData = dynamixel_instruction_read_data(idRead,
						    controlTable.addrRead,
						    controlTable.lenRead);
      rs485_putstrn((char *)pktReadData, pktReadData->length+4);
      _delay_us(500);
    }

    c = rs485_getchar();
    while (c != EOF) {
      // Process char from RS485 input
      nRs485Input = dynamixel_input(&pktRs485Input, c, nRs485Input);
      if (nRs485Input == -1) {
	// Well-formed RS485 packet
	PORTC &= ~(_BV(PORTC6));
	if (serialRs485Forwarded) {
	  // Return status packet to serial
	  uart1_putstrn((char *)&pktRs485Input, pktRs485Input.length+4);
	  serialRs485Forwarded = 0;
	}
	else {
	  // Check if status packet contains requested read data
	  if ((pktRs485Input.id == idRead) &&
	      (pktRs485Input.length == controlTable.lenRead+2)) {
	    for (i=0; i<controlTable.lenRead; i++) {
	      controlTable.dataRead[nRead*controlTable.lenRead + i] =
		pktRs485Input.parameter[i];
	    }
	  }
	} // else
	PORTC |= (_BV(PORTC6));
      } // if
      c = rs485_getchar();
    } // while c

  }

  return 0;
}
