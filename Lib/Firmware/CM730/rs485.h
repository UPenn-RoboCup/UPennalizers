#ifndef __RS485_H
#define __RS485_H

// Add the clock management headers
#include <libopencm3/stm32/rcc.h>
// Add the I/O headers
#include <libopencm3/stm32/gpio.h>
// Add the serial communication headers
#include <libopencm3/stm32/usart.h>
// Add the DMA headers
#include <libopencm3/stm32/dma.h>
// Add interrupt vectors support - for use in DMA and RX/TX interrupts
#include <libopencm3/stm32/nvic.h>
// Include a circular buffer
#include "CBUF.h"

// Set the size of the Receiving Buffer
#define uart1_getbuf_SIZE 256

// Set the EOF character...
#define EOF -1

void rs485_init( u32 baud );
void rs485_putstrn( u32 buf, u16 len );
int rs485_getchar();

#endif
