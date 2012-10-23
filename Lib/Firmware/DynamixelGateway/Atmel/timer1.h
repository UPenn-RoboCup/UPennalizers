#ifndef __TIMER1_H
#define __TIMER1_H

void timer1_init(void);
void timer1_set_overflow_callback(void (*callback)(void));
void timer1_set_compa_callback(void (*callback)(void));

#endif // __TIMER1_H
