#ifndef __UART2_H
#define __UART2_H

#include <stdio.h>

void uart2_init(void);
int uart2_setbaud(long baud);

int uart2_getchar();
int uart2_putchar(char c);
int uart2_putstr(char *str);
int uart2_printf(char *fmt, ...);

#endif // __UART2_H
