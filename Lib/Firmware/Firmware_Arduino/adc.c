#include "config.h"
#include "adc.h"
#include "timer5.h"
#include "string.h"

#include <avr/interrupt.h>

volatile uint16_t adcData[NUM_ADC];
volatile uint8_t  adcChannel = 0;
volatile uint8_t  adcReady   = 0;

void adc_start_conversion(uint8_t channel)
{
  if (channel < 8)
  {
    ADMUX = (ADMUX & (_BV(REFS1)|_BV(REFS0)|_BV(ADLAR))) | channel;
    ADCSRB &= ~(_BV(MUX5));
  }
  else
  {
    ADMUX = (ADMUX & (_BV(REFS1)|_BV(REFS0)|_BV(ADLAR))) | (channel-8);
    ADCSRB |= _BV(MUX5);
  }

  // Start conversion
  ADCSRA |= _BV(ADSC);
}

void ADC_TIMER_COMPA(void)
{
	// Re-enable interrupts to allow capturing from UART's
  sei();
  
  //reset the counter
  ADC_TIMER_RESET();
        
  //make sure that data is not read before all channels are sampled
  adcReady   = 0;
        
  //reset the current ADC channel
  adcChannel = 0;
    
  //enable the ADC Conversion Complete interrupt
  ADCSRA    |= _BV(ADIE);
    
  //start the first conversion
  adc_start_conversion(adcChannel);
}

ISR(ADC_vect)
{
  //store the conversion result
  adcData[adcChannel] = ADCW;

  //disable the interrupt if done with all channels
  if (adcChannel == (NUM_ADC-1))
  {
    //disable the ADC Conversion Complete interrupt
    ADCSRA &= ~(_BV(ADIE));
    
    //reset channel just in case
    adcChannel = 0;
    
    //signal that data is ready
    adcReady = 1;
  }
  else
  {
    //increment the channel for next conversion
    adcChannel++;
  
    //start the next conversion
    adc_start_conversion(adcChannel);
  }
}

int16_t adc_get_data(uint16_t * dataOut)
{
  int16_t ret = -1;
  uint8_t ch;
  
  if(adcReady)
  {
    for (ch=0; ch<NUM_ADC; ch++)
      dataOut[NUM_ADC - 1 - ch] = adcData[ch]; //values are flipped for arduino
    adcReady = 0;
    ret = NUM_ADC;
  }
  
  return ret;
}

void adc_init(void)
{
  // Set prescalar to 128
  ADCSRA = _BV(ADPS0) | _BV(ADPS1) | _BV(ADPS2);

  // Ref is VCC
  //ADMUX = _BV(REFS0);
  // Ref is external AREF
  //ADMUX = 0;
  // Ref is 2.56
  ADMUX = _BV(REFS0) | _BV(REFS1);
  
  // Left adjust result to allow easy 8 bit reading
  // ADMUX |= _BV(ADLAR);

  // Enable ADC
  ADCSRA |= _BV(ADEN) | _BV(ADSC);
  
  
  //timer will trigger the conversion
  ADC_TIMER_INIT();
  ADC_TIMER_SET_COMPA_CALLBACK(ADC_TIMER_COMPA);
}

//for manually reading adc channels
uint16_t adc_read(uint8_t channel)
{
  adc_start_conversion(channel);
  loop_until_bit_is_clear(ADCSRA, ADSC);

  return ADCW;
}


