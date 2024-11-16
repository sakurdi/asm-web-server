.intel_syntax noprefix
.globl _start

.section .data

req_body:
    .skip 500
buffer:
    .skip 1025
file_content:
    .skip 1025

.section .text

_start:

    mov rdi, 2
    mov rsi, 1
    mov rdx, 0
    mov rax, 41     # __x64_sys_socket
    syscall
    mov r11, rax
    xor rdi, rdi
    mov rdi, rax
    xor rax, rax
    xor rsi, rsi
    xor rdx, rdx
    push rax
    push rax
    pushw 0x5000
    pushw 2
    mov rsi, rsp
    mov dl, 16
    mov rax, 49     # __x64_sys_bind
    syscall
    xor rax, rax
    xor rsi, rsi
    mov rax, 50
    syscall         # __x64_sys_listen
accept:
    xor rax, rax
    xor rdx, rdx
    mov rdi, 3
    mov rax, 43     # __x64_sys_accept
    syscall
    push rax

    mov r9, rax
    mov rax, 57     # __x64_sys_fork
    syscall

    cmp al, 0
    je child

    mov rax, 3      # __x64_sys_close
    pop rdi
    syscall

    jmp accept
child:
    mov rax, 3
    mov rdi, 3
    syscall         # __x64_sys_listen

    mov rdi, 4
    mov rax, 0
    lea rsi, [rip + req_body]
    mov rdx, 450
    syscall         # __x64_sys_read
    push rax

    mov r9, rax
    #mov rcx, 5
    xor rcx, rcx
    xor r8, r8
    xor rax, rax
get_type:
   movb al, [req_body+rcx]
   inc rcx
   cmp ax, 32
   jne get_type
   cmp rcx, 4
   je parse_get
   xor rax, rax
   mov rcx, 5
parse_post:
    mov al, [req_body+rcx]
    mov [buffer+r8], al
    inc r8
    inc rcx
    mov al, [req_body+rcx]
    cmp al, 32
    jne parse_post
    movb [buffer+r8], 0

    mov rax, 2
    lea rdi, [rip+buffer]
    mov rsi, 0101
    mov rdx, 0777
    syscall         # __x64_sys_open

    xor rcx, rcx
    pop rcx
    mov r9, rcx
    xor rax, rax
    dec rcx
get_nl:
    movb al, [req_body+rcx]
    dec rcx
    cmp al, 10
    jne get_nl

    add rcx, 2


    mov rdi, 3
    lea rsi, [req_body+rcx]
    sub r9, rcx
    mov rdx, r9
    mov rax, 1
    syscall         # __x64_sys_write

    mov rax, 3
    mov rdi, 3
    syscall         # __x64_sys_close

    mov rax, 1
    xor rdx, rdx
    mov rax, 1
    mov rdi, 4
    lea rsi, [rip + res]
    mov rdx, 19
    syscall         # __x64_sys_write

    jmp exit
parse_get:
    movb al, [req_body+rcx]
    mov [buffer+r8], al
    inc rcx
    inc r8
    cmp al, 32
    jne parse_get
    dec r8
    movb [buffer+r8], 0

    mov rax, 2
    lea rdi, [rip+buffer]
    xor rsi, rsi
    syscall         # __x64_sys_open

    mov rdi, rax
    xor rax, rax
    lea rsi, [rip+file_content]
    mov rdx, 400
    syscall         # __x64_sys_read


    push rax

    mov rax, 3
    mov rdi, 3
    syscall         # __x64_sys_close

    mov rax, 3

    mov rax, 1
    mov rdi, 4
    lea rsi, [rip+res]
    mov rdx, 19
    syscall         # __x64_sys_write

    mov rax, 1
    mov rdi, 4
    lea rsi, [rip+file_content]
    pop rdx
    syscall         # __x64_sys_write
exit:
    mov rdi, 0
    mov rax, 60     # SYS_exit
    syscall

res:
    .ascii "HTTP/1.0 200 OK\r\n\r\n"
