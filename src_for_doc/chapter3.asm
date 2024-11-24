[bits 16]          ; 16-bit mode
[org 0x7C00]       ; Boot sector loads at 0x7C00

start:
    mov ax, 0xB800
    mov es, ax
    mov byte [es:0x0000], 'A'
    mov byte [es:0x0001], 0x9A

    jmp $

times 510-($-$$) db 0
dw 0xAA55
