#include "timer1.h"

#include <stdint.h>
#include <avr/io.h>
#include <avr/interrupt.h>

void (*timer1_overflow_callback)(void);
void (*timer1_compa_callback)(void);

ISR(TIMER1_OVF_vect)
{
  if (timer1_overflow_callback)
    timer1_overflow_callback();
}

ISR(TIMER1_COMPA_vect)
{
  if (timer1_compa_callback)
    timer1_compa_callback();
}

void timer1_init(void)
{
  TCCR1B = _BV(CS10); // CS10: prescaler = 1, 4.1 ms overflow cycle
  TCNT1=0;
}

void timer1_set_overflow_callback(void (*callback)(void))
{
  timer1_overflow_callback = callback;
  if (timer1_overflow_callback)
    TIMSK1 |= _BV(TOIE1);
  else
    TIMSK1 &= ~(_BV(TOIE1));
  TCNT1=0;
}

void timer1_set_compa_callback(void (*callback)(void))
{
  timer1_compa_callback = callback;
  if (timer1_compa_callback)
    TIMSK1 |= _BV(OCIE1A);
  else
    TIMSK1 &= ~(_BV(OCIE1A));
}
