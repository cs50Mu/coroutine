format ELF64

;; implemented in c
extrn coroutine_switch_context      

public coroutine_yield
;;; when enter this procedure, rsp points at [ret address]
;;; [ regs ][ret address]
;;;         ^
;;;         rsp
coroutine_yield:
    ;; save the registers on the stack
    push rdi
	push rbx
	push rbp
	push r12
	push r13
	push r14
	push r15
    ;; prepare parameter for the function `coroutine_switch_context`
    ;; save rsp to rdi for the c function to use
    mov rdi, rsp
    jmp coroutine_switch_context

public coroutine_restore_context
coroutine_restore_context:
    mov rsp, rdi
	pop r15
	pop r14
	pop r13
	pop r12
	pop rbp
	pop rbx
    pop rdi
    ret
