#ifndef __ADC_H
#define __ADC_H

#include <stdint.h>
#include <avr/io.h>

void adc_init(void);
uint16_t adc_read(uint8_t channel);
int16_t adc_get_data(uint16_t * dataOut);

#endif // __ADC_H
