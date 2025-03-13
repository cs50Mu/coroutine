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

// when enter this procedure, rsp points at [ret address]
// [ regs ][ret address]
//         ^
//         rsp
void __attribute__((naked)) coroutine_yield(void)
{
  // save the registers on the stack
  asm("pushq %rdi\n"
      "pushq %rbx\n"
      "pushq %rbp\n"
      "pushq %r12\n"
      "pushq %r13\n"
      "pushq %r14\n"
      "pushq %r15\n"
      // prepare parameter for the function `coroutine_switch_context`
      // save rsp to rdi for the c function to use
      "movq %rsp, %rdi\n"
      "jmp coroutine_switch_context\n");

}
void __attribute__((naked)) coroutine_restore_context(void *rsp)
{
  // when we uncomment the following line, `zig build` will complain:
  // `non-ASM statement in naked function is not supported`. so we have
  // to comment it for now, despite the warning: `unused variable`
  /* (void)rsp; */
  asm("movq %rdi, %rsp\n"
      "popq %r15\n"
      "popq %r14\n"
      "popq %r13\n"
      "popq %r12\n"
      "popq %rbp\n"
      "popq %rbx\n"
      "popq %rdi\n"
      "ret");
}

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
  *(--rsp) = coroutine_finish;   // push coroutine_finish
  *(--rsp) = f;                  // push return address
  *(--rsp) = arg;                // push rdi, parameter for the function `f`
  *(--rsp) = 0;                  // push rbx
  *(--rsp) = 0;                  // push rbp
  *(--rsp) = 0;                  // push r12
  *(--rsp) = 0;                  // push r13
  *(--rsp) = 0;                  // push r14
  *(--rsp) = 0;                  // push r15
  da_append(&contexts, ((Context){
      .rsp = rsp,
      .stack_base = stack_base,
      }));
}

size_t coroutine_id(void)
{
  return contexts.current;
}

size_t coroutine_active(void)
{
  return contexts.count;
}
