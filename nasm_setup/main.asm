[BITS 16]          ; 16-bit mode
[ORG 0x7C00]       ; Boot sector loads at 0x7C00

start:
    mov ah, 0x0E   ; BIOS teletype function
    mov al, 'H'
    int 0x10       ; Display 'H'
    mov al, 'i'
    int 0x10       ; Display 'i'

hang:
    jmp hang       ; Infinite loop to hang

times 510 - ($ - $$) db 0 ; Pad to 510 bytes
dw 0xAA55             ; Boot signature
