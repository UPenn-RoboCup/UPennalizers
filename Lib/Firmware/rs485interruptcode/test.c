#include <avr/io.h>
#include <avr/interrupt.h>
#include <util/delay.h>
#include <stdio.h>
#include "uarts.h"

#define cbi(REG8,BIT) REG8 &= ~(_BV(BIT))
#define sbi(REG8,BIT) REG8 |= _BV(BIT)

volatile uint16_t nOC1A;
uint16_t nrx0, nrx1;

ISR(TIMER1_COMPA_vect)
//ISR(SIG_OUTPUT_COMPARE1A)
{
  nOC1A++;
  if (nOC1A % 1000 == 0) {
    // Toggle D13 LED
    //    PORTB ^= _BV(PORTB7);
    uart0_printf("nrx: %d %d\r\n", nrx0, nrx1);
  }
}

/*
//ISR(SIG_USART0_RECV)
ISR(USART_RX_vect)
{
  char c = UDR0;
  uart0_printf("Keyboard: %c\r\n", c);
}
*/

void init(void)
{
  // Enable output
  DDRB |= _BV(DDB7);
  DDRC |= _BV(DDC7);

  TIMSK1 = _BV(OCIE1A);
  TCCR1B = _BV(CS11) | _BV(CS10) // prescaler = 64
         | _BV(WGM12); // CTC mode, TOP = OCR1A
  OCR1A = 250;

  /* Setup ADC */
  ADCSRA |= (1 << ADPS0) | (1 << ADPS1) | (1 << ADPS2); // A/D converter prescaler of 128
  //  ADMUX |= (1 << REFS0); // Ref is VCC
  ADMUX &= ~(0 << REFS0); // Ref is external AREF
  //  ADMUX |= (1 << ADLAR); // Left adjust ADC result to allow easy 8 bit reading
  ADCSRA |= (1 << ADEN); //Enable ADC

  uart0_init();
  uart1_init();
  //  UCSR0B |= _BV(RXCIE0);

  sei();
}

int main(void)
{
  char c;
  int i, n=0;
  unsigned char x[64];

  init();
  uart0_putstr("\r\nStarting Arduino Mega Relay program\r\n");

  while (1) {
    if (UCSR0A & _BV(RXC0)) {
      PORTB |= _BV(PORTB7);
      if (UCSR0A & _BV(FE0)) {
	uart0_putstr("UART0: frame error\r\n");
      }
      if (UCSR0A & _BV(DOR0)) {
	uart0_putstr("UART0: data overrun\r\n");
      }

      c = UDR0;
      nrx0++;

      for (i = 0; i < n; i++) {
	uart0_printf("%u\r\n",x[i]);
      }
      n = 0;

      // Enable RS485 transmission:
      PORTC |= _BV(PORTC7);

      //uart1_putstr("\xFF\xFF\x01\x02\x01\xFB");
      //uart1_putstr("\xFF\xFF\x01\x04\x02\x00\x03\xF5");
      //	loop_until_bit_is_set(UCSR1A, UDRE1);
      //	UDR1 = c;
      uart1_putchar(255);
      loop_until_bit_is_set(UCSR1A, TXC1);
      uart1_putchar(255);
      loop_until_bit_is_set(UCSR1A, TXC1);
      uart1_putchar(1);
      loop_until_bit_is_set(UCSR1A, TXC1);
      uart1_putchar(2);
      loop_until_bit_is_set(UCSR1A, TXC1);
      uart1_putchar(1);
      loop_until_bit_is_set(UCSR1A, TXC1);
      uart1_putchar(251);
      loop_until_bit_is_set(UCSR1A, TXC1);
      //      uart1_putchar(c);
      // loop_until_bit_is_set(UCSR1A, TXC1);
      // Enable RS485 receiver:

      PORTC &= ~(_BV(PORTC7));
      PORTB &= ~(_BV(PORTB7));
    }

    if (UCSR1A & _BV(RXC1)) {
      if (UCSR1A & _BV(FE1)) {
	uart0_putstr("UART1: frame error\r\n");
      }
      if (UCSR1A & _BV(DOR1)) {
	uart0_putstr("UART1: data overrun\r\n");
      }
      c = UDR1;
      nrx1++;

      uart0_putchar(c);
      x[n++] = c;
    }
  }

  return 0;
}
