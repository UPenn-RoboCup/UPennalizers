#ifndef __TIMER4_H
#define __TIMER4_H

#include <stdint.h>

void timer4_init(void);
void timer4_set_overflow_callback(void (*callback)(void));
void timer4_set_compa_callback(void (*callback)(void));
void timer4_reset();
void timer4_enable_overflow_callback();
void timer4_disable_overflow_callback();
void timer4_enable_compa_callback();
void timer4_disable_compa_callback();

#endif // __TIMER4_H
