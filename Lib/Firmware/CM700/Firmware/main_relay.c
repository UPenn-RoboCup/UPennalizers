#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/eeprom.h>
#include <util/delay.h>
#include <stdio.h>

#include "uart1.h"
#include "rs485.h"
#include "timer1.h"
//#include "adc.h"
#include "dynamixel.h"

#define cbi(REG8,BIT) REG8 &= ~(_BV(BIT))
#define sbi(REG8,BIT) REG8 |= _BV(BIT)


/*
#define NUM_CONTROL_ENTRIES 16
uint8_t controlTable[NUM_CONTROL_ENTRIES];

#define EEPROM_BASE_ADDRESS 11
static void updateEEPROM(void)
{
  eeprom_write_byte((uint8_t*)(EEPROM_BASE_ADDRESS - 1), 16);
}
*/


volatile unsigned long nOVF = 0;
void t1_overflow(void)
{
  static char led = 0;

  nOVF++;
  //  PORTE |= _BV(PORTE4);

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

  //  adc_init();

  uart1_init();
  uart1_setbaud(57600);

  rs485_init();
  rs485_setbaud(1000000);

  timer1_init();
  timer1_set_overflow_callback(t1_overflow);

  sei();
}

int main(void)
{
  int c;
  unsigned long count = 0;

  init();
  uart1_putstr("\r\nStarting CM700 Dynamixel relay program\r\n");

  while (1) {
    count++;

    c = uart1_getchar();
    if (c != EOF) {
      rs485_putchar(c);
      if (dynamixel_input(c, 0)) {
	uart1_putstr("USB packet.\n");
      }
    }

    c = rs485_getchar();
    if (c != EOF) {
      uart1_putchar(c);
    }

  }

  return 0;
}
