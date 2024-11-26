[bits 16]
StartingPoint equ 0x7c00
[org StartingPoint]
jmp _start

_data:
    dw 1234, 1235
    .len:
    dw ($ - _data) / 2

_start:
    mov ax, 0x07C0
    mov ds, ax

    mov cx, [ds:_data.len - StartingPoint]              ; set the counter

    ; loop body
    _loop:
    .start:
        ; first, we compare if cx is 0
        cmp cx, 0x00
        je .stop                                        ; jump to stop label if cx equals to 0

        ; otherwise, continue:
        dec cx
        jmp .start

    .stop:
        jmp $
times 510-($-$$) db 0                                   ; Fill with zeros
dw 0xAA55                                               ; Boot sector signature
