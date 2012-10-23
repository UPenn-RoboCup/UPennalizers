#include "config.h"
#include "uart2.h"

#include <stdint.h>
#include <avr/io.h>
#include <avr/interrupt.h>
#include "CBUF.h"

#define DEFAULT_BAUDRATE 57600

#define uart2_getbuf_SIZE 128
#define uart2_putbuf_SIZE 128
volatile struct {
  uint8_t m_getIdx;
  uint8_t m_putIdx;
  uint8_t m_entry[ uart2_getbuf_SIZE ];
} uart2_getbuf;
volatile struct {
  uint8_t m_getIdx;
  uint8_t m_putIdx;
  uint8_t m_entry[ uart2_putbuf_SIZE ];
} uart2_putbuf;

ISR(USART2_RX_vect)
{
  char c;
  // LED on
  //PORTB |= _BV(PORTB7);  
  c = UDR2;
  CBUF_Push(uart2_getbuf, c);
  
  //uart2_putchar(c);
  //  nRX0++;
  //  rs485_putchar(c);
  // LED off
  //PORTB &= ~(_BV(PORTB7));
}

ISR(USART2_UDRE_vect)
{
  if (!CBUF_IsEmpty(uart2_putbuf)) {
    UDR2 = CBUF_Pop(uart2_putbuf);
  }
  else {
    // Disable interrupt
    UCSR2B &= ~(_BV(UDRIE2));
  }
}

ISR(USART2_TX_vect)
{

}

void uart2_init(void)
{
  CBUF_Init(uart2_getbuf);
  CBUF_Init(uart2_putbuf);

  uart2_setbaud(DEFAULT_BAUDRATE);
  // 8N1
  UCSR2C = _BV(UCSZ21) | _BV(UCSZ20);
  // Enable tx/rx
  UCSR2B = _BV(TXEN2) | _BV(RXEN2);

  // Enable uart rxc interrupt
  UCSR2B |= _BV(RXCIE2);
}

int uart2_setbaud(long baudrate)
{
  // Set U2X
  UCSR2A |= _BV(U2X2);
  UBRR2 = (F_CPU/baudrate + 4) / 8 - 1;
  return UBRR2;
}

int uart2_getchar()
{
  /*
  loop_until_bit_is_set(UCSR2A, RXC2);
  if (UCSR2A & _BV(FE2))
    return _FDEV_EOF;
  if (UCSR2A & _BV(DOR2))
    return _FDEV_ERR;
  return UDR2;
  */
  if (!CBUF_IsEmpty(uart2_getbuf))
    return CBUF_Pop(uart2_getbuf);
  else
    return EOF;
}

int uart2_putchar(char c)
{
  CBUF_Push(uart2_putbuf, c);
  // Enable interrupt
  UCSR2B |= _BV(UDRIE2);
  return c;
}

int uart2_putstr(char *str) {
  int i = 0;
  while(str[i] != '\0')
    uart2_putchar(str[i++]);
  return i;
}

int uart2_printf(char *fmt, ...) {
  char buf[60];
  va_list ap;
  int retval = 0;

  va_start(ap, fmt);
  retval = vsnprintf(buf, 60, fmt, ap);
  va_end(ap);
    
  uart2_putstr(buf);
  return retval;
}
