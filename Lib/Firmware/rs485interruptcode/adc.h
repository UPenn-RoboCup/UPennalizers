#ifndef __ADC_H
#define __ADC_H

#include <stdint.h>
#include <avr/io.h>

void adc_init(void);
uint16_t adc_read(int channel);

#endif // __ADC_H
