#ifndef __UART_H
#define __UART_H

#include <stdio.h>

void uart_init(void);
int uart_setbaud(long baud);

int uart_getchar();
int uart_putchar(char c);
int uart_putstr(char *str);
int uart_printf(char *fmt, ...);

#endif // __UART_H
