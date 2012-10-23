#include "timer1.h"

#include <stdint.h>
#include <avr/io.h>
#include <avr/interrupt.h>

void (*timer1_overflow_callback)(void);

ISR(TIMER1_OVF_vect)
{
  if (timer1_overflow_callback)
    timer1_overflow_callback();
}

ISR(TIMER1_COMPA_vect)
{
  PORTE &= ~(_BV(PORTE4));
}

void timer1_init(void)
{
  TCCR1B = _BV(CS11); // prescaler = 8, 32.8 ms cycle
  TIMSK1 = _BV(OCIE1A);
  
  DDRE |= _BV(DDE4);
  OCR1A = 3000;
}

void timer1_set_overflow_callback(void (*callback)(void))
{
  timer1_overflow_callback = callback;
  if (timer1_overflow_callback)
    TIMSK1 |= _BV(TOIE1);
  else
    TIMSK1 &= ~(_BV(TOIE1));
}
