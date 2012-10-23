#ifndef __RS485_H
#define __RS485_H

void rs485_init(void);
int rs485_setbaud(long baudrate);

int rs485_getchar();
int rs485_putchar(char c);
int rs485_putstrn(char *str, int n);

#endif // __RS485_H
