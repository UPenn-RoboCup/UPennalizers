#ifndef __ADC_H
#define __ADC_H

#include <stdint.h>
#include <avr/io.h>

void adc_init(void);
void adc_start(void);
int adc_complete(void);
uint16_t *adc_get_data(void);

uint16_t adc_read(int channel);

#endif // __ADC_H
