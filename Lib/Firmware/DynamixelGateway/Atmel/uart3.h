#ifndef __UART3_H
#define __UART3_H

#include <stdio.h>

void uart3_init(void);
int uart3_setbaud(long baud);

int uart3_getchar();
int uart3_putchar(char c);
int uart3_putstr(char *str);
int uart3_printf(char *fmt, ...);

#endif // __UART3_H
