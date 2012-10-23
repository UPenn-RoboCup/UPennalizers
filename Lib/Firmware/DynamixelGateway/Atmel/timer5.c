#include "config.h"
#include "timer5.h"

#include <stdint.h>
#include <avr/io.h>
#include <avr/interrupt.h>

void (*timer5_overflow_callback)(void);
void (*timer5_compa_callback)(void);


ISR(TIMER5_OVF_vect)
{
  if (timer5_overflow_callback)
    timer5_overflow_callback();
}

ISR(TIMER5_COMPA_vect)
{
  if (timer5_compa_callback)
    timer5_compa_callback();
}

void timer5_reset()
{
  TCNT5=0;
}

void timer5_init(void)
{
  TCCR5B = _BV(CS50) | _BV(CS51); // prescaler = 1/64, 4us per tic, 262ms cycle
  
  OCR5A = ADC_TIMER_PERIOD_TICS;   

}

void timer5_set_overflow_callback(void (*callback)(void))
{
  timer5_overflow_callback = callback;
  if (timer5_overflow_callback)
    TIMSK5 |= _BV(TOIE5);
  else
    TIMSK5 &= ~(_BV(TOIE5));
}

void timer5_set_compa_callback(void (*callback)(void))
{
  timer5_compa_callback = callback;
  if (timer5_compa_callback)
    TIMSK5 |= _BV(OCIE5A);
  else
    TIMSK5 &= ~(_BV(OCIE5A));
}
