#include "adc.h"

#include <avr/interrupt.h>

uint8_t adcChannelMin = 7;
uint8_t adcChannelMax = 11;
uint8_t adcComplete = 0;
uint8_t adcChannel = 0;
uint16_t adcData[16];

void adc_start_conversion(uint8_t channel)
{
  if (channel < 8) {
    ADMUX = (ADMUX & (_BV(REFS1)|_BV(REFS0)|_BV(ADLAR))) | channel;
    ADCSRB &= ~(_BV(MUX5));
  }
  else {
    ADMUX = (ADMUX & (_BV(REFS1)|_BV(REFS0)|_BV(ADLAR))) | (channel-8);
    ADCSRB |= _BV(MUX5);
  }

  // Start conversion
  ADCSRA |= _BV(ADSC);
}

ISR(ADC_vect) {
  // Store the conversion result
  adcData[adcChannel] = ADCW;

  // Increment channel number for next conversion
  adcChannel++;

  // Disable interrupt if done with all channels
  if (adcChannel > adcChannelMax) {
    ADCSRA &= ~(_BV(ADIE));
    adcComplete = 1;
    adcChannel = adcChannelMin;
  }
  else {
    // Start next conversion
    adc_start_conversion(adcChannel);
  }
}

void adc_init(void) {
  // Set prescalar to 128
  ADCSRA = _BV(ADPS0) | _BV(ADPS1) | _BV(ADPS2);

  // Ref is VCC
  // ADMUX = _BV(REFS0);
  // Ref is external AREF
  ADMUX = 0;

  // Left adjust result to allow easy 8 bit reading
  // ADMUX |= _BV(ADLAR);

  // Enable ADC
  ADCSRA |= _BV(ADEN) | _BV(ADSC);

  // Do first conversion
  adc_start();
}

void adc_start(void) {
  // Clear ready flag
  adcComplete = 0;

  // Reset channel
  adcChannel = adcChannelMin;

  // Enable ADC conversion complete interrupt
  ADCSRA |= _BV(ADIE);

  // Start first conversion
  adc_start_conversion(adcChannel);
}

int adc_complete(void) {
  return adcComplete;
}

uint16_t* adc_get_data(void) {
  return adcData;
}

// Polling method
uint16_t adc_read(int channel)
{
  ADMUX = (ADMUX & (_BV(REFS1)|_BV(REFS0)|_BV(ADLAR))) | channel;

  // Start conversion
  ADCSRA |= _BV(ADSC);
  loop_until_bit_is_clear(ADCSRA, ADSC);

  return ADCW;
}
