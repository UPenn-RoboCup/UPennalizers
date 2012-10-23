/*
  Uses UART1 for RS485 communication using MAX485 driver
*/

#include "config.h"
#include "rs485.h"

#include <stdint.h>
#include <avr/io.h>
#include <avr/interrupt.h>
#include "CBUF.h"
#include <util/delay.h>

#define DEFAULT_BAUDRATE 57600

#define uart1_getbuf_SIZE 128
#define uart1_putbuf_SIZE 128
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
    // Enable RS485 transmitter:
    RS485_TX_ENABLE_PORT |= _BV(RS485_TX_ENABLE_PIN);
    UDR1 = CBUF_Pop(uart1_putbuf);
  }
  else 
  {
    // Disable interrupt
    UCSR1B &= ~(_BV(UDRIE1));
  }
}

ISR(USART1_TX_vect)
{
  // Disable RS485 transmitter:
  if (CBUF_IsEmpty(uart1_putbuf))
  {
    _delay_us(1);
    RS485_TX_ENABLE_PORT &= ~(_BV(RS485_TX_ENABLE_PIN));
  }
}

void rs485_init(void)
{
  // Enable output:
  RS485_TX_ENABLE_DDR |= _BV(RS485_TX_ENABLE_PIN);
  RS485_TX_ENABLE_PORT &= ~(_BV(RS485_TX_ENABLE_PIN));

  CBUF_Init(uart1_getbuf);
  CBUF_Init(uart1_putbuf);

  rs485_setbaud(DEFAULT_BAUDRATE);
  // Parity 8N1
  UCSR1C = _BV(UCSZ11) | _BV(UCSZ10);
  // Enable tx/rx, rxc interrupts
  UCSR1B = _BV(TXEN1) | _BV(RXEN1)
    | _BV(RXCIE1) | _BV(TXCIE1);
}

int rs485_setbaud(long baudrate)
{
  // Set U2X
  UCSR1A |= _BV(U2X1);
  UBRR1 = (F_CPU/baudrate + 4) / 8 - 1;
  return UBRR1;
}

int rs485_getchar()
{
  int ret;
  
  //disable rxc interrupt while reading the circular buffer
  //UCSR1B &= ~(_BV(RXCIE1));

  if (!CBUF_IsEmpty(uart1_getbuf))
    ret = CBUF_Pop(uart1_getbuf);
  else
    ret = EOF;
    
  //re-enable rxc interrupt
  //UCSR1B |= _BV(RXCIE1);
  
  return ret;
}

int rs485_putchar(char c)
{
  //disable txc interrupt while reading the circular buffer
  //UCSR1B &= ~(_BV(UDRIE1));

  CBUF_Push(uart1_putbuf, c);
  
  //re-enable interrupt (or just enable)
  UCSR1B |= _BV(UDRIE1);
  
  return c;
}

int rs485_putstrn(char *str, int n) {
  int i;
  for (i = 0; i < n; i++) {
    rs485_putchar(str[i]);
  }
  return i;
}
