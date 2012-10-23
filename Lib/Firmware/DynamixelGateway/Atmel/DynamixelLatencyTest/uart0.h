#ifndef __UART0_H
#define __UART0_H

#include <stdio.h>

void uart0_init(void);
int uart0_setbaud(long baud);

int uart0_getchar();
int uart0_putchar(char c);
int uart0_putstr(char *str);
int uart0_printf(char *fmt, ...);
int uart0_putdata(char *data, int size);

#endif // __UART0_H
