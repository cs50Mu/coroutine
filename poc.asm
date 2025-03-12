format ELF64 executable

COROUTINE_CAPATICY = 10
STACK_CAPACITY = 4*1024
SYS_write = 1
SYS_exit = 60
STDIN_FILENO = 0
STDOUT_FILENO = 1
STDERR_FILENO = 2

print:
    mov     r9, -3689348814741910323
    sub     rsp, 40
    mov     BYTE [rsp+31], 10
    lea     rcx, [rsp+30]
.L2:
    mov     rax, rdi
    lea     r8, [rsp+32]
    mul     r9
    mov     rax, rdi
    sub     r8, rcx
    shr     rdx, 3
    lea     rsi, [rdx+rdx*4]
    add     rsi, rsi
    sub     rax, rsi
    add     eax, 48
    mov     BYTE [rcx], al
    mov     rax, rdi
    mov     rdi, rdx
    mov     rdx, rcx
    sub     rcx, 1
    cmp     rax, 9
    ja      .L2
    lea     rax, [rsp+32]
    mov     edi, 1
    sub     rdx, rax
    xor     eax, eax
    lea     rsi, [rsp+32+rdx]
    mov     rdx, r8
    mov     rax, 1
    syscall
    add     rsp, 40
    ret

entry main

segment readable executable
counter:
   push rbp
   mov rbp, rsp
   sub rsp, 8

   mov qword [rbp-8], 0
.again:
   cmp qword [rbp-8], 10
   jge .over

   mov rdi, [rbp-8]
   call print
   call coroutine_yield

   inc qword [rbp-8]
   jmp .again

.over:
   add rsp, 8
   pop rbp
   ret

coroutine_init:
   cmp qword [contexts_count], COROUTINE_CAPATICY
   jge overflow_fail

   mov rbx, [contexts_count]  ;; rbx has the index of the current context
   inc qword [contexts_count]

   pop rax    ;; return address is in rax now

   mov [contexts_rsp+rbx*8], rsp
   mov [contexts_rbp+rbx*8], rbp
   mov [contexts_rip+rbx*8], rax

   jmp rax

;; rdi - procedure to start in a new coroutine
coroutine_go:
   cmp qword [contexts_count], COROUTINE_CAPATICY
   jge overflow_fail

   mov rbx, [contexts_count]  ;; rbx has the index of the current context
   inc qword [contexts_count]

   mov rax, [stacks_end]      ;; rax has the rsp of the new routine

   sub qword [stacks_end], STACK_CAPACITY

   ;; prepare the return address for the coroutine
   sub rax, 8
   mov qword [rax], coroutine_finish

   mov [contexts_rsp+rbx*8], rax
   mov qword [contexts_rbp+rbx*8], 0
   mov [contexts_rip+rbx*8], rdi

   ret

coroutine_yield:
   mov rbx, [contexts_current]

   ;; save the context of the current procedure
   pop rax
   mov [contexts_rsp+rbx*8], rsp
   mov [contexts_rbp+rbx*8], rbp
   mov [contexts_rip+rbx*8], rax

   ;; increment contexts_current
   inc rbx
   xor rcx, rcx  ;; to get the value: 0
   cmp rbx, [contexts_count]
   ;; conditional move: only works when the condition is true
   ;; 注意：cmp 之后就立即要 cmovge 才行，中间不能再插入别的指令了，否
   ;; 则会污染 condition
   cmovge rbx, rcx
   mov [contexts_current], rbx

   ;; restore the next procedure's context
   mov rsp, [contexts_rsp+rbx*8]
   mov rbp, [contexts_rbp+rbx*8]
   jmp qword [contexts_rip+rbx*8]

coroutine_finish:
   mov rax, SYS_write
   mov rdi, STDOUT_FILENO
   mov rsi, not_implemented_msg
   mov rdx, not_implemented_msg_len
   syscall

   mov rax, SYS_exit
   mov rdi, 69
   syscall

main:
   ;; call counter
   call coroutine_init

   mov rdi, counter
   call coroutine_go
   mov rdi, counter
   call coroutine_go
.forever:
   call coroutine_yield
   jmp .forever

   mov rax, SYS_write
   mov rdi, STDOUT_FILENO
   mov rsi, ok_msg
   mov rdx, ok_msg_len
   syscall

   mov rax, SYS_exit
   mov rdi, 0
   syscall


overflow_fail:
   mov rax, SYS_write
   mov rdi, STDERR_FILENO
   mov rsi, too_many_coroutines_msg
   mov rdx, too_many_coroutines_msg_len
   syscall


segment readable writable

too_many_coroutines_msg db "too many coroutines!", 0, 10
too_many_coroutines_msg_len = $ - too_many_coroutines_msg
ok_msg db "OK!", 0, 10
ok_msg_len = $ - ok_msg
not_implemented_msg db "not implemented!", 0, 10
not_implemented_msg_len  = $ - not_implemented_msg

contexts_count dq 0
contexts_current dq 0
stacks_end dq stacks+COROUTINE_CAPATICY*STACK_CAPACITY
stacks rb COROUTINE_CAPATICY*STACK_CAPACITY
contexts_rsp rq COROUTINE_CAPATICY
contexts_rbp rq COROUTINE_CAPATICY
contexts_rip rq COROUTINE_CAPATICY
