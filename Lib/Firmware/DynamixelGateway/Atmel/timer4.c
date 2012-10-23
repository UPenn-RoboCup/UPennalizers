#include "timer4.h"

#include <stdint.h>
#include <avr/io.h>
#include <avr/interrupt.h>

void (*timer4_overflow_callback)(void);
void (*timer4_compa_callback)(void);

ISR(TIMER4_OVF_vect)
{
  if (timer4_overflow_callback)
    timer4_overflow_callback();
}

ISR(TIMER4_COMPA_vect)
{
  if (timer4_compa_callback)
    timer4_compa_callback();
}

void timer4_reset()
{
  TCNT4=0;
}

void timer4_init(void)
{
  TCCR4B = _BV(CS41); // C41: prescaler = 8, 32.8 ms overflow cycle
  TCNT4=0;
}

void timer4_set_overflow_callback(void (*callback)(void))
{
  timer4_overflow_callback = callback;
  if (timer4_overflow_callback)
    TIMSK4 |= _BV(TOIE4);
  else
    TIMSK4 &= ~(_BV(TOIE4));
    
  TCNT4=0;
}

void timer4_set_compa_callback(void (*callback)(void))
{
  timer4_compa_callback = callback;
  if (timer4_compa_callback)
    TIMSK4 |= _BV(OCIE4A);
  else
    TIMSK4 &= ~(_BV(OCIE4A));
}

void timer4_enable_overflow_callback()
{
  TIMSK4 |= _BV(TOIE4);
}

void timer4_disable_overflow_callback()
{
  TIMSK4 &= ~(_BV(TOIE4));
}

void timer4_enable_compa_callback()
{
  TCNT4=0;
  TIMSK4 |= _BV(OCIE4A);
}

void timer4_disable_compa_callback()
{
  TIMSK4 &= ~(_BV(OCIE4A));
}
