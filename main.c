#include <stdio.h>
#include "coroutine.h"

void counter(void *arg)
{
  // restore the number from the pointer
 long int n = (long int)arg;
  for (int i = 0; i < n; ++i) {
    printf("[%zu] %d\n", coroutine_id(), i);
    coroutine_yield();
  }
}

int main()
{
  coroutine_init();
  // notice you can store a number as a pointer
  coroutine_go(&counter, (void*)5);
  coroutine_go(&counter, (void*)10);

  while (coroutine_active() > 1) coroutine_yield();
  return 0;
}
