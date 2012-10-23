/*
  Uses UART0 for RS485 communication to Dynamixel bus
*/

#include "rs485.h"
#include <stdio.h>
#include <stdint.h>
#include <avr/io.h>
#include <avr/interrupt.h>
#include <util/delay.h>
#include "CBUF.h"

#define DEFAULT_BAUDRATE 1000000

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

// Macros for setting txd/rxd direction
#define DIR_TXD PORTE &= ~0x08, PORTE |= 0x04
#define DIR_RXD PORTE &= ~0x04, PORTE |= 0x08

ISR(USART0_RX_vect)
{
  char c;
  c = UDR0;
  CBUF_Push(uart0_getbuf, c);
}

ISR(USART0_UDRE_vect)
{
  if (!CBUF_IsEmpty(uart0_putbuf)) {
    // Enable RS485 transmitter:
    DIR_TXD;
    UDR0 = CBUF_Pop(uart0_putbuf);
  }
  else {
    // Disable interrupt
    UCSR0B &= ~(_BV(UDRIE0));
  }
}

ISR(USART0_TX_vect)
{
  if (CBUF_IsEmpty(uart0_putbuf)) {
    _delay_us(3);
    // Disable RS485 transmitter:
    DIR_RXD;
  }
}

void rs485_init(void)
{
  CBUF_Init(uart0_getbuf);
  CBUF_Init(uart0_putbuf);

  // set UART register A
  //Bit 7: USART Receive Complete
  //Bit 6: USART Transmit Complete
  //Bit 5: USART Data Resigter Empty 
  //Bit 4: Frame Error
  //Bit 3: Data OverRun
  //Bit 2: Parity Error
  //Bit 1: Double The USART Transmission Speed
  //Bit 0: Multi-Processor Communication Mode
  UCSR0A = 0b01000010;

  // set UART register B
  // bit7: enable rx interrupt
  // bit6: enable tx interrupt
  // bit4: enable rx
  // bit3: enable tx
  // bit2: set sending size(0 = 8bit)
  UCSR0B = 0b11011000;

  // set UART register C
  // bit6: communication mode (1 = synchronize, 0 = asynchronize)
  // bit5,bit4: parity bit(00 = no parity) 
  // bit3: stop bit(0 = stop bit 1, 1 = stop bit 2)
  // bit2,bit1: data size(11 = 8bit)
  // 8N1 parity
  UCSR0C = 0b00000110;

  // set baud
  rs485_setbaud(DEFAULT_BAUDRATE);

  // initialize
  UDR0 = 0xFF;

  DDRE |= 0b00001100;
  DIR_RXD;
}

int rs485_setbaud(long baudrate)
{
  UBRR0 = (F_CPU/baudrate + 4) / 8 - 1;
  return UBRR0;
}

int rs485_getchar()
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

int rs485_putchar(char c)
{
  CBUF_Push(uart0_putbuf, c);
  // Enable interrupt
  UCSR0B |= _BV(UDRIE0);
  return c;
}

int rs485_putstr(char *str) {
  int i = 0;
  while(str[i] != '\0')
    CBUF_Push(uart0_putbuf, str[i++]);
  // Enable interrupt
  UCSR0B |= _BV(UDRIE0);
  return i;
}

int rs485_putstrn(char *str, int n) {
  int i;
  for (i = 0; i < n; i++)
    CBUF_Push(uart0_putbuf, str[i]);
  // Enable interrupt
  UCSR0B |= _BV(UDRIE0);
  return i;
}
