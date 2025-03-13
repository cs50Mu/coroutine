#ifndef COROUTINE_H_
#define COROUTINE_H_
#include <stdint.h>
#include <stdlib.h>

void coroutine_init(void);
void coroutine_finish(void);
void coroutine_yield(void);
void coroutine_go(void (*f)(void *), void *arg);
size_t coroutine_id(void);
size_t coroutine_active(void);

#endif // COROUTINE_H_
