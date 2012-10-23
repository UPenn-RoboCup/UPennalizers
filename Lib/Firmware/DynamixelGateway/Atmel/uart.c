#include "uart.h"

#include <stdint.h>
#include <avr/io.h>
#include <avr/interrupt.h>
#include "CBUF.h"

#define DEFAULT_BAUDRATE 57600

#define uart_getbuf_SIZE 128
#define uart_putbuf_SIZE 128
volatile struct {
  uint8_t m_getIdx;
  uint8_t m_putIdx;
  uint8_t m_entry[ uart_getbuf_SIZE ];
} uart_getbuf;
volatile struct {
  uint8_t m_getIdx;
  uint8_t m_putIdx;
  uint8_t m_entry[ uart_putbuf_SIZE ];
} uart_putbuf;

ISR(USART_RX_vect)
{
  char c;
  // LED on
  //PORTB |= _BV(PORTB7);  
  c = UDR0;
  CBUF_Push(uart_getbuf, c);
  //uart_putchar(c);
  //  nRX0++;
  //  rs485_putchar(c);
  // LED off
  //PORTB &= ~(_BV(PORTB7));
}

ISR(USART_UDRE_vect)
{
  if (!CBUF_IsEmpty(uart_putbuf)) {
    UDR0 = CBUF_Pop(uart_putbuf);
  }
  else {
    // Disable interrupt
    UCSR0B &= ~(_BV(UDRIE0));
  }
}

ISR(USART_TX_vect)
{

}

void uart_init(void)
{
  CBUF_Init(uart_getbuf);
  CBUF_Init(uart_putbuf);

  uart_setbaud(DEFAULT_BAUDRATE);
  // 8N1
  UCSR0C = _BV(UCSZ01) | _BV(UCSZ00);
  // Enable tx/rx
  UCSR0B = _BV(TXEN0) | _BV(RXEN0);

  // Enable uart rxc interrupt
  UCSR0B |= _BV(RXCIE0);
}

int uart_setbaud(long baudrate)
{
  // Set U2X
  UCSR0A |= _BV(U2X0);
  UBRR0 = (F_CPU/baudrate + 4) / 8 - 1;
  return UBRR0;
}

int uart_getchar()
{
  /*
  loop_until_bit_is_set(UCSRA, RXC);
  if (UCSRA & _BV(FE))
    return _FDEV_EOF;
  if (UCSRA & _BV(DOR))
    return _FDEV_ERR;
  return UDR;
  */
  if (!CBUF_IsEmpty(uart_getbuf))
    return CBUF_Pop(uart_getbuf);
  else
    return EOF;
}

int uart_putchar(char c)
{
  CBUF_Push(uart_putbuf, c);
  // Enable interrupt
  UCSR0B |= _BV(UDRIE0);
  return c;
}

int uart_putstr(char *str) {
  int i = 0;
  while(str[i] != '\0')
    uart_putchar(str[i++]);
  return i;
}

int uart_printf(char *fmt, ...) {
  char buf[60];
  va_list ap;
  int retval = 0;

  va_start(ap, fmt);
  retval = vsnprintf(buf, 60, fmt, ap);
  va_end(ap);
    
  uart_putstr(buf);
  return retval;
}
