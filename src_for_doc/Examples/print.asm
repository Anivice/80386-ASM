[bits 16]                                       ; 16-bit mode
StartingPoint equ 0x7C00                        ; Boot sector loads at 0x7C00
[org StartingPoint]

; jump over the data section
jmp start

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Message:
msg:
    db 'H', 0x07, 'e', 0x07, 'l', 0x07, 'l', 0x07, 'o', 0x07, ',', 0x07, ' ', 0x07
    db 'W', 0x07, 'o', 0x07, 'r', 0x07, 'l', 0x07, 'd', 0x07, '!', 0x07
msg_len:
    dw $ - msg                                  ; Length of the message

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start:
    ; Setup data segment
    mov ax, 0x07C0                              ; Segment of the bootloader
    mov ds, ax

    ; Setup source [DS:SI]
    mov si, msg - StartingPoint                 ; SI points to the message

    ; Setup destination [ES:DI] (Video memory at 0xB8000)
    mov ax, 0xB800                              ; Segment of video memory
    mov es, ax
    xor di, di                                  ; DI starts at offset 0

    ; Set CX to the length of the message
    mov cx, [ds:msg_len - StartingPoint]        ; CX = length of the message in bytes

    ; Ensure forward direction
    cld                                         ; Clear the Direction Flag

    ; Copy message to video memory
    rep movsb                                   ; Copy CX bytes from [DS:SI] to [ES:DI]

    ; Halt
    jmp $                                       ; Infinite loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Padding to fill the boot sector
times 510-($-$$) db 0                           ; Fill with zeros
dw 0xAA55                                       ; Boot sector signature
