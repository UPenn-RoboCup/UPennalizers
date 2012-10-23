#include "adc.h"

void adc_init(void)
{
  // Set prescalar to 128
  ADCSRA = _BV(ADPS0) | _BV(ADPS1) | _BV(ADPS2);

  // Ref is VCC
  ADMUX = _BV(REFS0);
  // Ref is external AREF
  //ADMUX = 0;

  // Left adjust result to allow easy 8 bit reading
  // ADMUX |= _BV(ADLAR);

  // Enable ADC
  ADCSRA |= _BV(ADEN) | _BV(ADSC);
}

uint16_t adc_read(int channel)
{
  ADMUX = (ADMUX & (_BV(REFS1)|_BV(REFS0)|_BV(ADLAR))) | channel;

  // Start conversion
  ADCSRA |= _BV(ADSC);
  loop_until_bit_is_clear(ADCSRA, ADSC);

  return ADCW;
}
