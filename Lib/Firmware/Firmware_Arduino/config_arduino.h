#ifndef CONFIG_H
#define CONFIG_H

//communications with host
#define HOST_BAUD_RATE 1000000
#define BUS_BAUD_RATE 1000000

/*
//pin for flushing the usb buffer to host
#define USB_FLUSH_DDR DDRA
#define USB_FLUSH_PORT PORTA
#define USB_FLUSH_PIN PINA7


//rs485 tx enable pin (used in rs485.h)
#define RS485_TX_ENABLE_PORT PORTH
#define RS485_TX_ENABLE_PIN PORTH5
#define RS485_TX_ENABLE_DDR DDRH
*/

// This is for the Arduino
//pin for flushing the usb buffer to host
#define USB_FLUSH_DDR DDRH
#define USB_FLUSH_PORT PORTH
#define USB_FLUSH_PIN PINH5


//rs485 tx enable pin (used in rs485.h)
#define RS485_TX_ENABLE_PORT PORTC
#define RS485_TX_ENABLE_PIN PORTC7
#define RS485_TX_ENABLE_DDR DDRC



#include "ctable.h"

#define LED_ERROR_PIN   PH4
#define LED_ERROR_PORT  PORTH
#define LED_ERROR_DDR   DDRH

#define LED_PC_ACT_PIN  PH3
#define LED_PC_ACT_PORT PORTH
#define LED_PC_ACT_DDR  DDRH

#define LED_ESTOP_PIN   PE3
#define LED_ESTOP_PORT  PORTE
#define LED_ESTOP_DDR   DDRE

#define LED_GPS_PIN     PG5
#define LED_GPS_PORT    PORTG
#define LED_GPS_DDR     DDRG

#define LED_RC_PIN      PE5
#define LED_RC_PORT     PORTE
#define LED_RC_DDR      DDRE


#define ADC_TIMER_PERIOD_TICS 2500 //2500 = 100Hz with 1/64 prescaler

#include "timer5.h"
#define ADC_TIMER_RESET timer5_reset
#define ADC_TIMER_INIT timer5_init
#define ADC_TIMER_SET_COMPA_CALLBACK timer5_set_compa_callback
#define ADC_TIMER_COMPA timer5_compa

#endif //CONFIG_H
