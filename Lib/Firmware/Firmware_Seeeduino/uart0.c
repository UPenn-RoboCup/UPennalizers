#include "config.h"
#include "uart0.h"

#include <stdint.h>
#include <avr/io.h>
#include <avr/interrupt.h>
#include "CBUF.h"

#define DEFAULT_BAUDRATE 57600

#define uart0_getbuf_SIZE 256
#define uart0_putbuf_SIZE 256
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
  c = UDR0;
  CBUF_Push(uart0_getbuf, c);
}

ISR(USART0_UDRE_vect)
{
  if (!CBUF_IsEmpty(uart0_putbuf)) 
  {
    UDR0 = CBUF_Pop(uart0_putbuf);
  }
  else 
  {
    // Disable interrupt
    UCSR0B &= ~(_BV(UDRIE0));
    
    //signal to FTDI chip to flush the buffer
    USB_FLUSH_PORT ^= _BV(USB_FLUSH_PIN);
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
  
  //enable pin for flushing the USB chip
  USB_FLUSH_DDR |= _BV(USB_FLUSH_PIN);
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
  int ret;
  
  //disable rxc interrupt while accessing the circular buffer
  //UCSR0B &= ~(_BV(RXCIE0));
  
  if (!CBUF_IsEmpty(uart0_getbuf))
    ret = CBUF_Pop(uart0_getbuf);
  else
    ret = EOF;
    
  //re-enable rxc interrupt
  //UCSR0B |= _BV(RXCIE0);
  
  return ret;
}

int uart0_putchar(char c)
{
  //disable txc interrupt while accessing the circular buffer
  //UCSR0B &= ~(_BV(UDRIE0));

  CBUF_Push(uart0_putbuf, c);
  
  //re-enable interrupt (or just enable)
  UCSR0B |= _BV(UDRIE0);
  
  return c;
}

int uart0_putstr(char *str) {
  int i = 0;
  while(str[i] != '\0')
    uart0_putchar(str[i++]);
  return i;
}

int uart0_putstrn(char *str, int n) {
  int i;
  for (i = 0; i < n; i++)
    CBUF_Push(uart0_putbuf, str[i]);
  // Enable interrupt
  UCSR0B |= _BV(UDRIE0);
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

int uart0_putdata(char *data, int size)
{
  int i;
  for (i=0; i<size; i++)
    uart0_putchar(*data++);
    
  return i;
}
