#ifndef CONFIG_H
#define CONFIG_H



//pin for flushing the usb buffer to host
#define USB_FLUSH_DDR DDRA
#define USB_FLUSH_PORT PORTA
#define USB_FLUSH_PIN PINA7

//pint for enabling the rs485 transmission
#define RS485_TX_ENABLE_PORT PORTH
#define RS485_TX_ENABLE_PIN PORTH5
#define RS485_TX_ENABLE_DDR DDRH


#endif //CONFIG_H
