#ifndef __TIMER5_H
#define __TIMER5_H

#include <stdint.h>

void timer5_init(void);
void timer5_set_overflow_callback(void (*callback)(void));
void timer5_set_compa_callback(void (*callback)(void));
void timer5_reset();

#endif // __TIMER5_H
