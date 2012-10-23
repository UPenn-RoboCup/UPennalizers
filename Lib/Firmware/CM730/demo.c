/*
This file is part of the Darwin-OP project.
BSD-style license.
Author: Stephen McGill
 */

#include "demo.h"
void _delay_us(u32 delay_us);

/*
Use the same function definitions as the old CM720 code
 */

u32 tick_us = 0;
u32 desired_us = 0;

int rs485_send(DynamixelPacket *pktSend) {
  // Write packet to RS485
  rs485_putstrn( (u32)pktSend, pktSend->length+4 );
  return 0;
}


int rs485_recv(DynamixelPacket *pktRecv) {
  int c;
  int npkt = 0;
  c = rs485_getchar();
  while (c != EOF) {
    // Process char from RS485 input
    npkt = dynamixel_input(pktRecv, c, npkt);
    if (npkt == -1) {
      return 1;
    }
    c = rs485_getchar();
    if (c == EOF) {
      // Delay and try last time
      _delay_us(20);
      c = rs485_getchar();
    }
  }
  return 0;
}

int rs485_recv_timeout(DynamixelPacket *pktRecv, int utimeout) {
  int c;
  int npkt = 0;
  int ncount = 0;
  int usleep = 10;
  while (ncount <= utimeout/usleep) {
    c = rs485_getchar();
    if (c != EOF) {
      // Process char from RS485 input
      npkt = dynamixel_input(pktRecv, c, npkt);
      if (npkt == -1) {
	return 1;
      }
    }
    else {
      _delay_us(usleep);
      ncount++;
    }
  }
  return 0;
}

/* Implementing a usleep alternative*/
void _delay_us(u32 delay_us)
{
  tick_us = 0;
  desired_us = delay_us;
  systick_counter_enable();
  while( tick_us < desired_us);// This provides the busy-wait
  systick_counter_disable();// Kill the interrupt if not using it.  The ISR just slows down the uC
}

/* The usleep stuff requires systick*/
void systick_init(){
  /* 72MHz / 8 => 9000000 counts per second */
  systick_set_clocksource(STK_CTRL_CLKSOURCE_AHB_DIV8);
  /* 9000000/9 = 1 000 000 overflows per second - every us one interrupt */
  systick_set_reload(9);
  systick_interrupt_enable();
}

/* Setup the interrupt for systick */
void sys_tick_handler() {
  tick_us++;
}


// Setup the main loop
int main(void) {

  // Set the system clock:
  rcc_clock_setup_in_hse_16mhz_out_72mhz();
  systick_init();

  // Setup the GPIO for the Indicator LED
  rcc_peripheral_enable_clock(&RCC_APB2ENR, RCC_APB2ENR_IOPCEN);
  gpio_set_mode(GPIOC, GPIO_MODE_OUTPUT_2_MHZ, GPIO_CNF_OUTPUT_PUSHPULL, GPIO12);

  // Set the memory in the stack
  char dyn_on[8] = "\xFF\xFF\xFE\x04\x03\x19\x01\xE0";
  char dyn_off[8] = "\xFF\xFF\xFE\x04\x03\x19\x00\xE1";

  // Initialize the RS485 communication system
  // This requires use of DMA1 Channel 4 and USART1
  rs485_init( 2000000 );

  while(1){

      // Init on every loop
      rs485_init( 2000000 );

    // On for half a second, off for half a second
    gpio_clear(GPIOC, GPIO12);
    rs485_putstrn( (u32) &dyn_on, 8);
    _delay_us( 250000 );
    
    // Off...
    gpio_set(GPIOC, GPIO12);
    rs485_putstrn( (u32) &dyn_off, 8);
    _delay_us( 250000 );
    
  }

  return 0;

}
