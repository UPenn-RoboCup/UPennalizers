/*
This file is part of the Darwin-OP project.
BSD-style license.
Author: Stephen McGill, December 2010

This sets up an rs485 communiation system.
Requirements:
-Available DMA1 channel 4
-Use of GPIO B6
-Use of GPIO USART1
 */

#include "rs485.h"

// Setup the receive buffer
#define uart1_getbuf_SIZE 256
volatile struct {
  uint8_t m_getIdx;
  uint8_t m_putIdx;
  uint8_t m_entry[ uart1_getbuf_SIZE ];
} uart1_getbuf;


void deinit_dma(){
    DMA_CCR4(DMA1) = 0;
    DMA_CNDTR1(DMA1) = 0;
    DMA1_IFCR |= DMA_IFCR_CTCIF4;
    DMA1_IFCR |= DMA_IFCR_CTEIF4;
    DMA1_IFCR |= DMA_IFCR_CGIF4;//idk - why not?

}

/**
 * This function initializes all the characteristics of the USART1 that we use for rs 485 communication
 */
void usart1_init( u32 baud ){

  // Enable USART interrupts
  nvic_enable_irq( NVIC_USART1_IRQ );
  nvic_set_priority( NVIC_USART1_IRQ, 5);

  // Enable clocks for GPIO port A and USART1.
  rcc_peripheral_enable_clock(&RCC_APB2ENR, RCC_APB2ENR_IOPAEN);
  rcc_peripheral_enable_clock(&RCC_APB2ENR, RCC_APB2ENR_USART1EN);

  // Setup GPIO pin GPIO_USART1_TX/GPIO9 on GPIO port A for transmit
  gpio_set_mode(GPIOA, GPIO_MODE_OUTPUT_50_MHZ, GPIO_CNF_OUTPUT_ALTFN_PUSHPULL, GPIO_USART1_TX);
  // Setup GPIO pin GPIO_USART1_RX/GPI10 on GPIO port A for receive
  gpio_set_mode(GPIOA, GPIO_MODE_INPUT, GPIO_CNF_INPUT_FLOAT, GPIO_USART1_RX);


  // Setup the USART1 for use in Dynamixel communication
  usart_set_baudrate(USART1, baud );
  usart_set_databits(USART1, 8);
  usart_set_stopbits(USART1, USART_STOPBITS_1);

  // Use as send and receive
  usart_set_mode(USART1, USART_MODE_TX | USART_MODE_RX);
  usart_set_parity(USART1, USART_PARITY_NONE);
  usart_set_flow_control(USART1, USART_FLOWCONTROL_NONE);

  // Do no setup interrupts just yet!
  // The DMA system will enable these

  // Begin the USART1 engine
  usart_enable(USART1);

  // Wait for the buffer to be empty - this will allow the DMA to put stuff in.
  // If it were full, DMA wouldn't be able to put stuff in
  while( (USART1_SR & USART_SR_TXE)==0 ){}

  // Enable DMA usage for USART1
  USART1_CR3 |= USART_CR3_DMAT;

}

/*
 * Setup our 485 system
 */
void rs485_init( u32 baud ){

  // Enable the clock for DMA1
  rcc_peripheral_enable_clock(&RCC_AHBENR, RCC_AHBENR_DMA1EN);

  // Use PortB6 for the direction control
  rcc_peripheral_enable_clock(&RCC_APB2ENR, RCC_APB2ENR_IOPBEN);
  gpio_set_mode(GPIOB, GPIO_MODE_OUTPUT_10_MHZ, GPIO_CNF_OUTPUT_PUSHPULL, GPIO6 );

  // Setup the DMA interrupt
  nvic_enable_irq( NVIC_DMA1_CHANNEL4_IRQ ); // Setup the DMA interrupt
  nvic_set_priority( NVIC_DMA1_CHANNEL4_IRQ, 4);

  // Initialize and start USART1
  usart1_init( baud );

}

/*******
 * Send a string out on the rs485 serial line, using DMA
 *
 * Input
 * buf: a pointer to the data to be sent
 * len: the number of bytes to send
 * Requirements:
 * Use DMA 1 Channel 4, which corresponds to USART1
 *
 * TODO: Make the functions in DMA inline.
 * Also, the DMA functions are missing break statements
*/
void rs485_putstrn( u32 buf, u16 len ) {

    // Try resetting the channel each time
    deinit_dma();
  
  // Set the source and destination of the dma.
  // Place the data at buf in data register of USART1 TX
  // We use USART1 as the Peripheral source, with buf being the memory source
  u32 dest = (u32)(&USART1_DR);
  dma_set_peripheral_address(DMA1, DMA_CHANNEL4, dest ); 
  dma_set_memory_address(DMA1, DMA_CHANNEL4, buf);

  // Set the amount of data to transfer, in chunks of memory_size (seen later)
  dma_set_number_of_data(DMA1, DMA_CHANNEL4, len);

  // Priority is high
  dma_set_priority(DMA1, DMA_CHANNEL4, DMA_CCR1_PL_HIGH);

  // Transfer Direction
  // Put the stuff from memory area into the peripheral area
  dma_set_read_from_memory(DMA1, DMA_CHANNEL4); 

  // Memory increment mode
  // Don't increment the USART address because the USART DR has only one addr
  // Increment the memory source pointer, because it has variable 8 bit segments
  dma_enable_memory_increment_mode(DMA1, DMA_CHANNEL4);

  // Setup the data size
  dma_set_memory_size(DMA1, DMA_CHANNEL4, DMA_CCR1_MSIZE_8BIT);
  dma_set_peripheral_size(DMA1, DMA_CHANNEL4, DMA_CCR1_PSIZE_8BIT);
  
  // We want to set up an interrupt on completion, and error, too
  dma_enable_transfer_complete_interrupt(DMA1, DMA_CHANNEL4);
  dma_enable_transfer_error_interrupt(DMA1, DMA_CHANNEL4);

  // I read somewhere that you should clear the interrupt flags initially
  DMA1_IFCR |= DMA_IFCR_CTCIF4;
  DMA1_IFCR |= DMA_IFCR_CTEIF4;

  // Clear the TC bit in the USART TC.
  // Section 26.3.13 of Tech Ref Manual (Version 2.1? April 2010)
  USART1_SR &= ~USART_SR_TC;

  // **RS-485 specific**
  // SAFETY on RX-TX short
  // Set mode to PUSH-PULL
  gpio_set_mode(GPIOA, GPIO_MODE_OUTPUT_50_MHZ, GPIO_CNF_OUTPUT_ALTFN_PUSHPULL, GPIO_USART1_TX);
  // Set the direction bit high, so the chip knows we are transmitting.
  gpio_set(GPIOB, GPIO6);

  // Alrighty - start the transfer!
  DMA_CCR4(DMA1) |= DMA_CCR4_EN;
  // NOTE: The libopenstm32 library doesn't have break statements
  // Thus, the following would start ALL channels
  //dma_enable_channel(DMA1, DMA_CHANNEL4);

}

/*
 * This function returns the item on top of our circular buffer stack
 * Thus, the buffer is decremented an element
 */
int rs485_getchar() {
  if (!CBUF_IsEmpty(uart1_getbuf))
    return CBUF_Pop(uart1_getbuf);
  else
    return EOF;
}

/* INTERRUPT HANDLERS */
// First, the DMA handler
void dma1_channel4_isr() {

  // Transfer is complete!
  if( DMA1_ISR & DMA_ISR_TCIF4 ){

    // Turn on the USART TC interrupt
    USART1_CR1 |= USART_CR1_TCIE;

    // Turn off the DMA TC interrupt
    dma_disable_transfer_complete_interrupt(DMA1, DMA_CHANNEL4);

    // Clear the interrupt flag - yes, write 1 to DMA_IFCR_CTCIF4 register
    DMA1_IFCR |= DMA_IFCR_CTCIF4;

  }

  // There was an error...
  if( DMA1_ISR & DMA_ISR_TEIF4 ){
    // Clear the interrupt flag - yes, write 1 to DMA_IFCR_CTCIF4 register
    DMA1_IFCR |= DMA_IFCR_CTEIF4;
    return;
  }

}

// Now the USART handler
void usart1_isr() {

  // Did we receive a byte?
  if( USART1_SR & USART_SR_RXNE ){
    // If so, add that byte to our buffer
    CBUF_Push( uart1_getbuf, USART1_DR );
  }

  // Is our sending complete?
  if( USART1_SR & USART_SR_TC ){
    // Clear the direction line - back into receive mode
    gpio_clear(GPIOB, GPIO6);
    // SAFETY
    // Make the TX in recv mode
    gpio_set_mode(GPIOA, GPIO_MODE_OUTPUT_50_MHZ, GPIO_MODE_INPUT, GPIO_USART1_TX);
    // Turn off the USART TC interrupt
    USART1_CR1 &= ~USART_CR1_TCIE;
    // Clear the TC (Transfer Complete) interrupt flag
    USART1_SR &= ~USART_SR_TC;
  }
  
}
