#include "timer0.h"

#include <stdint.h>
#include <avr/io.h>
#include <avr/interrupt.h>

void (*timer0_overflow_callback)(void);

ISR(TIMER0_OVF_vect)
{
  if (timer0_overflow_callback)
    timer0_overflow_callback();
}

ISR(TIMER0_COMPA_vect)
{
  //PORTE &= ~(_BV(PORTE4));
}

void timer0_init(void)
{
  //TCCR0B = _BV(CS00) | _BV(CS01); // prescaler = 1/64, 1.024 ms cycle
  TCCR0B = _BV(CS02); // prescaler = 1/256, 4.096 ms cycle
  
  //TCCR1B = _BV(WGM13) ; 
  //TIMSK1 = _BV(OCIE1A);
  
  //DDRB |= _BV(DDB5);
  //OCR1A = 3000;
}

void timer0_set_overflow_callback(void (*callback)(void))
{
  timer0_overflow_callback = callback;
  if (timer0_overflow_callback)
    TIMSK0 |= _BV(TOIE0);
  else
    TIMSK0 &= ~(_BV(TOIE0));
}
