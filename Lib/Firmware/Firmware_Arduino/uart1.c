#include "uart1.h"
#include <stdio.h>
#include <stdint.h>
#include <avr/io.h>
#include <avr/interrupt.h>
#include "CBUF.h"

#define DEFAULT_BAUDRATE 57600

#define uart1_getbuf_SIZE 256
#define uart1_putbuf_SIZE 256
volatile struct {
  uint8_t m_getIdx;
  uint8_t m_putIdx;
  uint8_t m_entry[ uart1_getbuf_SIZE ];
} uart1_getbuf;
volatile struct {
  uint8_t m_getIdx;
  uint8_t m_putIdx;
  uint8_t m_entry[ uart1_putbuf_SIZE ];
} uart1_putbuf;

ISR(USART1_RX_vect)
{
  char c;
  c = UDR1;
  CBUF_Push(uart1_getbuf, c);
}

ISR(USART1_UDRE_vect)
{
  if (!CBUF_IsEmpty(uart1_putbuf)) {
    UDR1 = CBUF_Pop(uart1_putbuf);
  }
  else {
    // Disable interrupt
    UCSR1B &= ~(_BV(UDRIE1));
  }
}

ISR(USART1_TX_vect)
{
}

void uart1_init(void)
{
  CBUF_Init(uart1_getbuf);
  CBUF_Init(uart1_putbuf);

  // set UART register A
  //Bit 7: USART Receive Complete
  //Bit 6: USART Transmit Complete
  //Bit 5: USART Data Resigter Empty 
  //Bit 4: Frame Error
  //Bit 3: Data OverRun
  //Bit 2: Parity Error
  //Bit 1: Double The USART Transmission Speed
  //Bit 0: Multi-Processor Communication Mode
  UCSR1A = 0b01000010;

  // set UART register B
  // bit7: enable rx interrupt
  // bit6: enable tx interrupt
  // bit4: enable rx
  // bit3: enable tx
  // bit2: set sending size(0 = 8bit)
  UCSR1B = 0b10011000;

  // set UART register C
  // bit6: communication mode (1 = synchronize, 0 = asynchronize)
  // bit5,bit4: parity bit(00 = no parity) 
  // bit3: stop bit(0 = stop bit 1, 1 = stop bit 2)
  // bit2,bit1: data size(11 = 8bit)
  // 8N1 parity
  UCSR1C = 0b00000110;

  // set baud
  uart1_setbaud(DEFAULT_BAUDRATE);

  // initialize
  UDR1 = 0xFF;
}

int uart1_setbaud(long baudrate)
{
  UBRR1 = (F_CPU/baudrate + 4) / 8 - 1;
  return UBRR1;
}

int uart1_getchar()
{
  /*
  loop_until_bit_is_set(UCSR1A, RXC1);
  if (UCSR1A & _BV(FE1))
    return _FDEV_EOF;
  if (UCSR1A & _BV(DOR1))
    return _FDEV_ERR;
  return UDR1;
  */
  if (!CBUF_IsEmpty(uart1_getbuf))
    return CBUF_Pop(uart1_getbuf);
  else
    return EOF;
}

int uart1_putchar(char c)
{
  CBUF_Push(uart1_putbuf, c);
  // Enable interrupt
  UCSR1B |= _BV(UDRIE1);
  return c;
}

int uart1_putstr(char *str) {
  int i = 0;
  while(str[i] != '\0')
    CBUF_Push(uart1_putbuf, str[i++]);
  // Enable interrupt
  UCSR1B |= _BV(UDRIE1);
  return i;
}

int uart1_putstrn(char *str, int n) {
  int i;
  for (i = 0; i < n; i++)
    CBUF_Push(uart1_putbuf, str[i]);
  // Enable interrupt
  UCSR1B |= _BV(UDRIE1);
  return i;
}

int uart1_printf(char *fmt, ...) {
  char buf[60];
  va_list ap;
  int retval = 0;

  va_start(ap, fmt);
  retval = vsnprintf(buf, 60, fmt, ap);
  va_end(ap);
    
  uart1_putstr(buf);
  return retval;
}
