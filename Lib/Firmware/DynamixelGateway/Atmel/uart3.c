#include "config.h"
#include "uart3.h"

#include <stdint.h>
#include <avr/io.h>
#include <avr/interrupt.h>
#include "CBUF.h"

#define DEFAULT_BAUDRATE 57600

#define uart3_getbuf_SIZE 128
#define uart3_putbuf_SIZE 128
volatile struct {
  uint8_t m_getIdx;
  uint8_t m_putIdx;
  uint8_t m_entry[ uart3_getbuf_SIZE ];
} uart3_getbuf;
volatile struct {
  uint8_t m_getIdx;
  uint8_t m_putIdx;
  uint8_t m_entry[ uart3_putbuf_SIZE ];
} uart3_putbuf;

ISR(USART3_RX_vect)
{
  char c;
  // LED on
  //PORTB |= _BV(PORTB7);  
  c = UDR3;
  CBUF_Push(uart3_getbuf, c);
  
  //uart3_putchar(c);
  //  nRX0++;
  //  rs485_putchar(c);
  // LED off
  //PORTB &= ~(_BV(PORTB7));
}

ISR(USART3_UDRE_vect)
{
  if (!CBUF_IsEmpty(uart3_putbuf)) {
    UDR3 = CBUF_Pop(uart3_putbuf);
  }
  else {
    // Disable interrupt
    UCSR3B &= ~(_BV(UDRIE3));
  }
}

ISR(USART3_TX_vect)
{

}

void uart3_init(void)
{
  CBUF_Init(uart3_getbuf);
  CBUF_Init(uart3_putbuf);

  uart3_setbaud(DEFAULT_BAUDRATE);
  // 8N1
  UCSR3C = _BV(UCSZ31) | _BV(UCSZ30);
  // Enable tx/rx
  UCSR3B = _BV(TXEN3) | _BV(RXEN3);

  // Enable uart rxc interrupt
  UCSR3B |= _BV(RXCIE3);
}

int uart3_setbaud(long baudrate)
{
  // Set U2X
  UCSR3A |= _BV(U2X3);
  UBRR3 = (F_CPU/baudrate + 4) / 8 - 1;
  return UBRR3;
}

int uart3_getchar()
{
  /*
  loop_until_bit_is_set(UCSR3A, RXC3);
  if (UCSR3A & _BV(FE3))
    return _FDEV_EOF;
  if (UCSR3A & _BV(DOR3))
    return _FDEV_ERR;
  return UDR3;
  */
  if (!CBUF_IsEmpty(uart3_getbuf))
    return CBUF_Pop(uart3_getbuf);
  else
    return EOF;
}

int uart3_putchar(char c)
{
  CBUF_Push(uart3_putbuf, c);
  // Enable interrupt
  UCSR3B |= _BV(UDRIE3);
  return c;
}

int uart3_putstr(char *str) {
  int i = 0;
  while(str[i] != '\0')
    uart3_putchar(str[i++]);
  return i;
}

int uart3_printf(char *fmt, ...) {
  char buf[60];
  va_list ap;
  int retval = 0;

  va_start(ap, fmt);
  retval = vsnprintf(buf, 60, fmt, ap);
  va_end(ap);
    
  uart3_putstr(buf);
  return retval;
}
