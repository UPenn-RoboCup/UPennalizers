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
#include "imu.h"

#define CONTROLLER_NAME "CM720 controller"
#define cbi(REG8,BIT) REG8 &= ~(_BV(BIT))
#define sbi(REG8,BIT) REG8 |= _BV(BIT)

volatile unsigned long ovf1 = 0;
// callback runs at 4.1 ms cycle:
void t1_ovf_callback(void)
{
  // Re-enable interrupts to allow capturing from UART's
  sei();

  ovf1++;
  if (ovf1 % 4 == 0) {
    if (adc_complete()) {
      uint16_t *adcData = adc_get_data();
      controlTable.imuAcc[0] = adcData[9];	//z & x are swapped
      controlTable.imuAcc[1] = adcData[8];
      controlTable.imuAcc[2] = adcData[7]; //z & x are swapped
      controlTable.imuGyr[0] = adcData[11];
      controlTable.imuGyr[1] = adcData[10]; //pitch
      controlTable.imuGyr[2] = 252;

      imu_filter_gyr(controlTable.imuGyr, 0.016);
      imu_filter_acc(controlTable.imuAcc, 0.016);
      float *imuAngle = imu_get_angle();
      controlTable.imuAngle[0] = 32768+1024*imuAngle[0];
      controlTable.imuAngle[1] = 32768+1024*imuAngle[1];
      controlTable.imuAngle[2] = 32768;

      adc_start();
    }
  }

  if (ovf1 % 25 == 0) {
    // Read START button and set AUX Led
    if (PIND & _BV(PD0)) {
      controlTable.button = 0;
      sbi(PORTC, PORTC3);
    }
    else {
      controlTable.button = 1;
      cbi(PORTC, PORTC3);
    }

    // Set PLAY Led
    if (controlTable.led) {
      cbi(PORTC, PORTC6);
    }
    else {
      sbi(PORTC, PORTC6);
    }
  }  
}

void init(void)
{
  // Enable outputs
  DDRC = 0b11111111;
  PORTC = 0xFF;
  // Turn on PWR Led
  cbi(PORTC, PORTC0);

  uart1_init();
  uart1_setbaud(57600);

  rs485_init();
  rs485_setbaud(1000000);

  ctable_init();
  adc_init();
  
  timer1_init();
  timer1_set_ovf_callback(t1_ovf_callback);

  sei();
}

int uart1_send(DynamixelPacket *pktSend) {
  // Write packet to uart1
  uart1_putstrn((char *)pktSend, pktSend->length+4);
  return 0;
}

int uart1_recv(DynamixelPacket *pktRecv) {
  int c; // needs to be int, not char, for EOF processing
  int npkt = 0;
  c = uart1_getchar();
  while (c != EOF) {
    // Process char from RS485 input
    npkt = dynamixel_input(pktRecv, c, npkt);
    if (npkt == -1) {
      return 1;
    }
    c = uart1_getchar();
    if (c == EOF) {
      // Delay and try last time
      _delay_us(20);
      c = uart1_getchar();
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

int rs485_flush() {
  int n = 0;
  while (rs485_getchar() != EOF) {
    n++;
  }
  return n;
}

int main(void)
{
  int i;
  int led = 0;
  unsigned long count = 0;
  //  unsigned long baud = 57600;
  unsigned long baud = 1000000;

  // Variables to keep track for reading servos
  int nRead=0, idRead=0;
  uint8_t *ctableByte;
  int serialWait = 0;
  
  // Dynamixel packets and counters for input/output
  DynamixelPacket *pktReadData, *pktStatus;
  DynamixelPacket pktSerialInput, pktRs485Input;

  init();
  uart1_printf("\r\nStarting %s\r\n", CONTROLLER_NAME);
  uart1_printf("Switching serial to %lu baud...\r\n", baud);
  _delay_ms(100);
  uart1_setbaud(baud);
  uart1_printf("\r\nRunning serial at %lu baud\r\n", baud);
  _delay_ms(100);

  // Set Dynamixel return delay
  rs485_putstrn("\xFF\xFF\xFE\x04\x03\x05\x00\xF5", 8);
  _delay_ms(10);
  rs485_flush();

  // Set Dynamixel EEPROM lock
  rs485_putstrn("\xFF\xFF\xFE\x04\x03\x2F\x01\xCA", 8);
  _delay_ms(10);
  rs485_flush();

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
    }

    if (uart1_recv(&pktSerialInput)) {
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
	uart1_send(pktStatus);
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
    } // if (uart1_recv())


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
	// Forward packet to UART1
	uart1_send(&pktRs485Input);
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

  } // while (1)

  return 0;
}
