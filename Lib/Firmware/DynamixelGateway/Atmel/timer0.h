#ifndef __TIMER0_H
#define __TIMER0_H

void timer0_init(void);
void timer0_set_overflow_callback(void (*callback)(void));

#endif // __TIMER0_H
