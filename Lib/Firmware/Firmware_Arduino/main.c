#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/eeprom.h>
#include <util/delay.h>
#include <stdio.h>

#include "uart0.h"
#include "rs485.h"
#include "timer1.h"
#include "dynamixel.h"
#include "ctable.h"
#include "adc.h"

#include "config.h"
#include "attitudeFilter.h"

#define CONTROLLER_NAME "ArduinoMEGA controller"
#define cbi(REG8,BIT) REG8 &= ~(_BV(BIT))
#define sbi(REG8,BIT) REG8 |= _BV(BIT)

volatile unsigned long nOVF1 = 0;
void timer1_callback(void)
{
  nOVF1++;


  // Read START button and set AUX Led
  if (nOVF1 % 25 == 0) {
		if (PINB & _BV(PB4)) {
		  controlTable.button = 0;
		}
		else {
		  controlTable.button = 1;
		}
  }
/*
  // Set PLAY Led
  if (controlTable.led) {
    cbi(PORTC, PORTC6);
  }
  else {
    sbi(PORTC, PORTC6);
  }
  */
}

void init(void)
{
  // Enable outputs
  DDRC = 0b11111111;
  PORTC = 0xFF;
  // Turn on PWR Led
  cbi(PORTC, PORTC0);

  uart0_init();
  uart0_setbaud(HOST_BAUD_RATE);

  rs485_init();
  rs485_setbaud(BUS_BAUD_RATE);

  ctable_init();
  adc_init();
  
  //timer1_init();
  //timer1_set_overflow_callback(timer1_callback);

  sei();
}

int uart0_send(DynamixelPacket *pktSend) {
  // Write packet to uart0
  uart0_putstrn((char *)pktSend, pktSend->length+4);
  return 0;
}

int uart0_recv(DynamixelPacket *pktRecv) {
  int c; // needs to be int, not char, for EOF processing
  int npkt = 0;
  c = uart0_getchar();
  while (c != EOF) {
    // Process char from RS485 input
    npkt = dynamixel_input(pktRecv, c, npkt);
    if (npkt == -1) {
      return 1;
    }
    c = uart0_getchar();
    if (c == EOF) {
      // Delay and try last time
      _delay_us(100);
      c = uart0_getchar();
    }
  }
  return 0;
}

int rs485_send(DynamixelPacket *pktSend) {
  // Write packet to RS485
  rs485_putstrn((char *)pktSend, pktSend->length+4);
  return 0;
}

int rs485_recv(DynamixelPacket *pktRecv) {
  int c;
  int npkt = 0;
  c = rs485_getchar();
  while (c != EOF) {
    // Process char from RS485 input
    npkt = dynamixel_input(pktRecv, c, npkt);
    if (npkt == -1) {
      return 1;
    }
    c = rs485_getchar();
    if (c == EOF) {
      // Delay and try last time
      _delay_us(20);
      c = rs485_getchar();
    }
  }
  return 0;
}

int rs485_recv_timeout(DynamixelPacket *pktRecv, int utimeout) {
  int c;
  int npkt = 0;
  int ncount = 0;
  int usleep = 10;
  while (ncount <= utimeout/usleep) {
    c = rs485_getchar();
    if (c != EOF) {
      // Process char from RS485 input
      npkt = dynamixel_input(pktRecv, c, npkt);
      if (npkt == -1) {
	return 1;
      }
    }
    else {
      _delay_us(usleep);
      ncount++;
    }
  }
  return 0;
}

//process fresh ADC data
int ProcessAdcData()
{

  return 0;
}

int main(void)
{
  int i;
  int led = 0;
  unsigned long count = 0;
  //  unsigned long baud = 57600;
  unsigned long baud = 1000000;
  int ret;
  volatile float imuAngle[3];

  // Variables to keep track for reading servos
  int nRead=0, idRead=0;
  uint8_t *ctableByte;
  int serialWait = 0;
  
  // Dynamixel packets and counters for input/output
  DynamixelPacket *pktReadData, *pktStatus;
  DynamixelPacket pktSerialInput, pktRs485Input;

  init();
  uart0_printf("\r\nStarting %s\r\n", CONTROLLER_NAME);
  uart0_printf("Switching serial to %lu baud...\r\n", baud);
  _delay_ms(100);
  uart0_setbaud(baud);
  uart0_printf("\r\nRunning serial at %lu baud\r\n", baud);
  _delay_ms(100);

  // Set Dynamixel return delay
  rs485_putstrn("\xFF\xFF\xFE\x04\x03\x05\x00\xF5", 8);

  while (1) {
    count++;

    if (count % 1000 == 0) {
      // Toggle MON and Dynamixel Leds
      if (led) {
	led = 0;
	sbi(PORTC, PORTC4);
	rs485_putstrn("\xFF\xFF\xFE\x04\x03\x19\x00\xE1", 8);
      }
      else {
	led = 1;
	cbi(PORTC, PORTC4);
	rs485_putstrn("\xFF\xFF\xFE\x04\x03\x19\x01\xE0", 8);
      }
      _delay_us(100);
    }


    if (uart0_recv(&pktSerialInput)) {
      // RxD LED on
      cbi(PORTC, PORTC1);

      if (pktSerialInput.id == controlTable.id) {
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
	uart0_send(pktStatus);
      }

      else {
	// Forward packet to RS485
	rs485_send(&pktSerialInput);
	if (pktSerialInput.id != DYNAMIXEL_BROADCAST_ID) {
	  serialWait = 1;
	}
      }
      // RxD LED off
      sbi(PORTC, PORTC1);
    } // if (uart0_recv())

    if (!serialWait) {
      // TxD LED on
      cbi(PORTC, PORTC2);

      // Query servo for data in round robin fashion:
      if (++nRead >= controlTable.nServo) nRead = 0;
      idRead = controlTable.idMap[nRead];
      pktReadData = dynamixel_instruction_read_data(idRead,
						    controlTable.addrRead,
						    controlTable.lenRead);
      rs485_send(pktReadData);
      // TxD LED off
      sbi(PORTC, PORTC2);
    } // if (!serialWait)

    while (rs485_recv_timeout(&pktRs485Input, 300)) {
      // Check if status packet contains requested read data
      if (serialWait) {
	// Forward packet to uart0
	uart0_send(&pktRs485Input);
      }
      else if ((pktRs485Input.id == idRead) &&
	       (pktRs485Input.instruction == 0) &&
	       (pktRs485Input.length == controlTable.lenRead+2)) {
	// Packet is correct return, flash EDIT Led
	cbi(PORTC, PORTC3);
	ctableByte = controlTable.dataRead + nRead*(controlTable.lenRead+1);
	*ctableByte++ = idRead;
	for (i=0; i<controlTable.lenRead; i++) {
	  *ctableByte++ = pktRs485Input.parameter[i];
	}
	sbi(PORTC, PORTC3);
      }
    } // while (rs485_recv())

    // Timeout waiting for serial response
    if (serialWait) {
      if (++serialWait > 3) serialWait = 0;
    }
    
    
     //check to see if we got full set of adc values
    //if the data is ready, it will be copied to the provided pointer
    cli();   //disable interrupts to prevent race conditions while copying, 
             //since the interrupt-based ADC cycle will write asynchronously
    ret = adc_get_data(controlTable.imuAcc);
    sei();   //re-enable interrupts
    
    
    if (ret > 0) {
    ProcessImuReadings(controlTable.imuAcc,imuAngle);
    for (i = 0; i<3;i++)
    	controlTable.imuAngle[i]=  32768 + (int16_t) (1024* imuAngle[i]) ;
    }
    
    
		if (PINB & _BV(PB4)) {
		  controlTable.button = 0;
		}
		else {
		  controlTable.button = 1;
		}

  } // while (1)

  return 0;
}
