#ifndef __UART1_H
#define __UART1_H

void uart1_init(void);
int uart1_setbaud(long baud);

int uart1_getchar();
int uart1_putchar(char c);
int uart1_putstr(char *str);
int uart1_putstrn(char *str, int n);
int uart1_printf(char *fmt, ...);

#endif // __UART1_H
