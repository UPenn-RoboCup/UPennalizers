#ifndef __UART0_H
#define __UART0_H

#include <stdio.h>

void uart0_init(void);
int uart0_setbaud(long baud);

int uart0_getchar();
int uart0_putchar(char c);
int uart0_putstr(char *str);
int uart0_printf(char *fmt, ...);

#endif // __UART0_H
