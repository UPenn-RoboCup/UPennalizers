#include <avr/io.h>
#include <avr/interrupt.h>
#include <util/delay.h>
#include <stdio.h>

#include "uart1.h"
#include "rs485.h"
#include "timer1.h"
#include "adc.h"
#include "dynamixel.h"

#define cbi(REG8,BIT) REG8 &= ~(_BV(BIT))
#define sbi(REG8,BIT) REG8 |= _BV(BIT)


volatile unsigned long nOVF = 0;
void t1_ovf_callback(void)
{
  static char led = 0;

  nOVF++;
  //  PORTE |= _BV(PORTE4);

  /*
  if (nOVF % 30 == 0) {
    // Toggle MON and Dynamixel Leds
    if (led) {
      led = 0;
      //      rs485_putstrn("\xFF\xFF\xFE\x04\x03\x19\x00\xE1", 8);
      PORTC |= _BV(PORTC4);
    }
    else {
      led = 1;
      //      rs485_putstrn("\xFF\xFF\xFE\x04\x03\x19\x01\xE0", 8);
      PORTC &= ~(_BV(PORTC4));
    }
  }
  */

}


void init(void)
{
  // Enable outputs
  DDRC = 0b11111111;
  PORTC = 0xFF;
  // Turn on PWR Led
  PORTC &= ~(_BV(PORTC0));

  //  adc_init();

  uart1_init();
  uart1_setbaud(57600);

  rs485_init();
  rs485_setbaud(1000000);

  timer1_init();
  timer1_set_ovf_callback(t1_ovf_callback);

  sei();
}

int main(void)
{
  int c;
  int led = 0;
  unsigned long count = 0;
  unsigned long baud = 1000000;

  init();
  uart1_putstr("\r\nStarting CM720 Dynamixel relay controller\r\n");
  uart1_printf("Switching serial to %lu baud...\r\n", baud);
  _delay_ms(100);
  uart1_setbaud(baud);
  uart1_printf("\r\nRunning serial at %lu baud\r\n", baud);
  _delay_ms(100);

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

    c = uart1_getchar();
    while (c != EOF) {
      // RxD LED on
      cbi(PORTC, PORTC1);

      rs485_putchar(c);
      c = uart1_getchar();
    }
    // RxD LED off
    sbi(PORTC, PORTC1);

    c = rs485_getchar();
    while (c != EOF) {
      // TxD LED on
      cbi(PORTC, PORTC2);

      uart1_putchar(c);
      c = rs485_getchar();
    }
    // TxD LED off
    sbi(PORTC, PORTC2);

  }

  return 0;
}
