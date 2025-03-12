#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <stdint.h>
#include <stdbool.h>

// Initial capacity of a dynamic array
#ifndef DA_INIT_CAP
#define DA_INIT_CAP 256
#endif

// Append an item to a dynamic array
#define da_append(da, item)                                                          \
    do {                                                                                 \
        if ((da)->count >= (da)->capacity) {                                             \
            (da)->capacity = (da)->capacity == 0 ? DA_INIT_CAP : (da)->capacity*2;   \
            (da)->items = realloc((da)->items, (da)->capacity*sizeof(*(da)->items)); \
            assert((da)->items != NULL && "Buy more RAM lol");                       \
        }                                                                                \
                                                                                         \
        (da)->items[(da)->count++] = (item);                                             \
    } while (0)


typedef struct {
  void *rsp;
  void *stack_base;
} Context;

typedef struct {
  Context *items;
  size_t count;
  size_t capacity;
  size_t current;
} Contexts;

Contexts contexts = {0};

void coroutine_yield(void);
void coroutine_restore_context(void *rsp);

void coroutine_switch_context(void *rsp)
{
  contexts.items[contexts.current].rsp = rsp;
  contexts.current = (contexts.current + 1) % contexts.count;
  coroutine_restore_context(contexts.items[contexts.current].rsp);
}

void coroutine_init(void)
{
  da_append(&contexts, (Context){0});
}

#define STACK_CAPACITY (4*1024)

// for cleanup stuff
void coroutine_finish(void)
{
  /* if (contexts.current == 0) { */
  /*   contexts.count = 0; */
  /*   return; */
  /* } */
  Context t = contexts.items[contexts.current];
  contexts.items[contexts.current] = contexts.items[contexts.count-1];
  contexts.items[contexts.count-1] = t;
  contexts.count -= 1;
  contexts.current %= contexts.count;  // ??
  /* printf("current: %ld, count: %ld\n", contexts.current, contexts.count); */

  coroutine_restore_context(contexts.items[contexts.current].rsp);
}

void coroutine_go(void (*f)(void*), void *arg)
{
  // [                 ]
  //                   ^
  // alloc stack for `f`
  void *stack_base = malloc(STACK_CAPACITY);
  void **rsp = (void **)((char *)stack_base + STACK_CAPACITY);
  // we should prepare the stack as follows:
  // [ regs ][ret address][coroutine_finish]
  // ^
  // rsp
  // so that for the `coroutine_restore_context` assembly
  // procedure to run properly
  *(--rsp) = coroutine_finish;
  *(--rsp) = f;
  *(--rsp) = arg;    // rdi, parameter for the function `f`
  *(--rsp) = 0;      // rbx
  *(--rsp) = 0;      // rbp
  *(--rsp) = 0;      // r12
  *(--rsp) = 0;      // r13
  *(--rsp) = 0;      // r14
  *(--rsp) = 0;      // r15
  da_append(&contexts, ((Context){
      .rsp = rsp,
      .stack_base = stack_base,
      }));
}

void counter(void *arg)
{
  // and restore the number from the pointer
 long int n = (long int)arg;
  for (int i = 0; i < n; ++i) {
    printf("[%zu] %d\n", contexts.current, i);
    coroutine_yield();
  }
}

int main()
{
  coroutine_init();
  // notice you can store a number as a pointer
  coroutine_go(&counter, (void*)5);
  coroutine_go(&counter, (void*)10);

  while (contexts.count > 1) coroutine_yield();
  return 0;
}
