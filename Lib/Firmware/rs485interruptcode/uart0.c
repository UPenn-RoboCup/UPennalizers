#include "uart0.h"

#include <stdint.h>
#include <avr/io.h>
#include <avr/interrupt.h>
#include "CBUF.h"

#define DEFAULT_BAUDRATE 57600

#define uart0_getbuf_SIZE 128
#define uart0_putbuf_SIZE 128
volatile struct {
  uint8_t m_getIdx;
  uint8_t m_putIdx;
  uint8_t m_entry[ uart0_getbuf_SIZE ];
} uart0_getbuf;
volatile struct {
  uint8_t m_getIdx;
  uint8_t m_putIdx;
  uint8_t m_entry[ uart0_putbuf_SIZE ];
} uart0_putbuf;

ISR(USART0_RX_vect)
{
  char c;
  // LED on
  PORTB |= _BV(PORTB7);  
  c = UDR0;
  CBUF_Push(uart0_getbuf, c);
  //  uart0_putchar(c); //return the char back to UART0
  //  nRX0++;
  //  rs485_putchar(c);
  // LED off
  PORTB &= ~(_BV(PORTB7));
}

ISR(USART0_UDRE_vect)
{
  if (!CBUF_IsEmpty(uart0_putbuf)) {
    UDR0 = CBUF_Pop(uart0_putbuf);
  }
  else {
    // Disable interrupt
    UCSR0B &= ~(_BV(UDRIE0));
  }
}

ISR(USART0_TX_vect)
{

}

void uart0_init(void)
{
  CBUF_Init(uart0_getbuf);
  CBUF_Init(uart0_putbuf);

  uart0_setbaud(DEFAULT_BAUDRATE);
  // 8N1
  UCSR0C = _BV(UCSZ01) | _BV(UCSZ00);
  // Enable tx/rx
  UCSR0B = _BV(TXEN0) | _BV(RXEN0);

  // Enable uart rxc interrupt
  UCSR0B |= _BV(RXCIE0);
}

int uart0_setbaud(long baudrate)
{
  // Set U2X
  UCSR0A |= _BV(U2X0);
  UBRR0 = (F_CPU/baudrate + 4) / 8 - 1;
  return UBRR0;
}

int uart0_getchar()
{
  /*
  loop_until_bit_is_set(UCSR0A, RXC0);
  if (UCSR0A & _BV(FE0))
    return _FDEV_EOF;
  if (UCSR0A & _BV(DOR0))
    return _FDEV_ERR;
  return UDR0;
  */
  if (!CBUF_IsEmpty(uart0_getbuf))
    return CBUF_Pop(uart0_getbuf);
  else
    return EOF;
}

int uart0_putchar(char c)
{
  CBUF_Push(uart0_putbuf, c);
  // Enable interrupt
  UCSR0B |= _BV(UDRIE0);
  return c;
}

int uart0_putstr(char *str) {
  int i = 0;
  while(str[i] != '\0')
    uart0_putchar(str[i++]);
  return i;
}

int uart0_printf(char *fmt, ...) {
  char buf[60];
  va_list ap;
  int retval = 0;

  va_start(ap, fmt);
  retval = vsnprintf(buf, 60, fmt, ap);
  va_end(ap);
    
  uart0_putstr(buf);
  return retval;
}
