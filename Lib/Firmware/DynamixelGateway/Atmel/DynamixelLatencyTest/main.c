#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/eeprom.h>
#include <util/delay.h>
#include <stdio.h>

#include "uart0.h"
#include "rs485.h"


void init(void)
{


  uart0_init();
  uart0_setbaud(230400);

  rs485_init();
  rs485_setbaud(1000000);
  
  TCCR1B = _BV(CS10);  //enable timer with prescaler = 1
  
  DDRE |= _BV(PINE4);

  sei();
}

int main(void)
{
  int c;
  char cmd[] = {0xFF, 0xFF, 0x00, 0x04, 0x02, 0x24, 0x02, 0xD3};
  uint8_t cmdLen=8;
  uint8_t respLen = 0;
  const uint8_t respExpLen = 8;
  char respBuf[respExpLen];
  uint8_t ii;
  uint16_t rtt;  //round trip time

  init();
  uart0_putstr("\r\nDynamixel latency tester ready\r\n");

  uint16_t * angle;

  while (1) 
  {
    //reset the response length counter
    respLen = 0;

    //set the pin high
    PORTE |= _BV(PINE4);

    //reset the counter
    TCNT1=0;

    //push the outgoing packet into the buffer
    for (ii=0; ii<cmdLen; ii++)
      rs485_putchar(cmd[ii]);
    //uart0_putstr("\r\nSent request\r\n");    

    //wait until full packet is received
    while(respLen < respExpLen)
    {
      c = rs485_getchar();
      if (c != EOF)
      {
        //uart0_putchar('.');
        //uart0_printf("0x%02X ",c);
        respBuf[respLen] = c;   
        respLen++;
      }
    }
    
    //save the counter
    rtt = TCNT1;
    
    //set the pin low
    PORTE &= ~(_BV(PINE4));
    
    angle = (uint16_t*)(respBuf+5);

    uart0_printf("angle = %d, %d cycles\r\n",*angle,rtt);
    
    //delay for a bit
    _delay_ms(15);
  }

  return 0;
}
