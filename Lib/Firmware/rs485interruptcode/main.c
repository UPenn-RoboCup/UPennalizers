#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/eeprom.h>
#include <util/delay.h>
#include <stdio.h>

#include "uart0.h"
#include "rs485.h"
#include "adc.h"
#include "timer1.h"

#define cbi(REG8,BIT) REG8 &= ~(_BV(BIT))
#define sbi(REG8,BIT) REG8 |= _BV(BIT)

#define NUM_CONTROL_ENTRIES 16
uint8_t controlTable[NUM_CONTROL_ENTRIES];

#define EEPROM_BASE_ADDRESS 11
static void updateEEPROM(void)
{
  eeprom_write_byte((uint8_t*)(EEPROM_BASE_ADDRESS - 1), 16);
}


volatile unsigned long n1OVF = 0;
void t1_overflow(void)
{
  static char led = 0;

  n1OVF++;
  PORTE |= _BV(PORTE4);

  if (n1OVF % 30 == 0) {
    // Toggle D13 LED
    // PORTB ^= _BV(PORTB7);

    if (led) {
      led = 0;
      //rs485_putstrn("\xFF\xFF\xFE\x04\x03\x19\x00\xE1", 8);
      //PORTB &= ~(_BV(PORTB7));
    }
    else {
      led = 1;
      //rs485_putstrn("\xFF\xFF\xFE\x04\x03\x19\x01\xE0", 8);
      //PORTB |= _BV(PORTB7);
    }
  }
}

void init(void)
{
  // Enable outputs
  DDRB |= _BV(DDB7);

  adc_init();

  uart0_init();
  uart0_setbaud(1000000);

  rs485_init();
    //rs485_setbaud(57600);
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
  uart0_putstr("\r\nStarting Arduino Mega Relay program\r\n");

  while (1) {
    count++;

    c = uart0_getchar();
    if (c != EOF) {
      rs485_putchar(c);
    }

    c = rs485_getchar();
    if (c != EOF) {
      uart0_putchar(c);
    }
    /*
    if (count % 100000 == 0) {
      uart0_printf("AD %d %d %d %d %d %d\r\n",
		   adc_read(0), adc_read(1), adc_read(2),
		   adc_read(3), adc_read(4), adc_read(5));
    }
    */
      

  }

  return 0;
}
