[bits 16]
    mov     sp,     0x7C00

    ; here, we calculated the GDT segmentation and offset into ds and bx
    mov     ax,     [cs:gdt_base+0x7C00]
    mov     dx,     [cs:gdt_base+0x7C00+2]
    mov     bx,     16
    div     bx
    mov     ds,     ax
    mov     bx,     dx

    ; first, we define a NULL descriptor
    mov dword       [bx],       0x00
    mov dword       [bx+4],     0x00

    ; second, we define a protect mode Segmentation
    mov dword       [bx+8],     0x7C0001FF  ; 0x7C00    (Segmentation Base Address 0-15)
                                            ; 0x01FF    (Segmentation Limit 0-15)
    mov dword       [bx+12],    0x00409800  ; 0x00      (Segmentation Base Address 24-31)
                                            ; 0x4       (0100, G=0,D/B=1,L=0,ALV=0)
                                            ; 0x0,      (Segmentation Limit, 16-19)
                                            ; 0x9       (1001, P=1, DPL=00, S=1)
                                            ; 0x8       (1000, TYPE=1000)
                                            ; 0x00      (Segmentation Base Address, 16-23)

    ; Segmentation information:
    ;     SegBaseAddr: 0x00007C00
    ;     SegLim: 0x001FF, G=0
    ;     32BitOperands (D/B=1)
    ;     32BitMode (L=0)
    ;     SegPresent (P=1)
    ;     DPL=0
    ;     UserSeg (S=1)
    ;     TYPE=X---

    ; third, we define a protected mode data segmentation
    mov dword       [bx+16],    0x8000FFFF  ; 0x8000    (Segmentation Base Address 0-15)
                                            ; 0xFFFF    (Segmentation Limit 0-15)
    mov dword       [bx+20],    0x0040920B  ; 0x00      (Segmentation Base Address 24-31)
                                            ; 0x4       (0100, G=0,D/B=1,L=0,ALV=0)
                                            ; 0x0,      (Segmentation Limit, 16-19)
                                            ; 0x9       (1001, P=1, DPL=00, S=1)
                                            ; 0x2       (0010, TYPE=0010)
                                            ; 0x0B      (Segmentation Base Address, 16-23)

    ; Segmentation information:
    ;     SegBaseAddr: 0x000B8000
    ;     SegLim: 0x0FFFF, G=0
    ;     32BitOperands (D/B=1)
    ;     32BitMode (L=0)
    ;     SegPresent (P=1)
    ;     DPL=0
    ;     UserSeg (S=1)
    ;     TYPE=--W-


    mov dword       [bx+24],    0x00007A00  ; 0x0000    (Segmentation Base Address 0-15)
                                            ; 0x7A00    (Segmentation Limit 0-15)
    mov dword       [bx+28],    0x00409600  ; 0x00      (Segmentation Base Address 24-31)
                                            ; 0x4       (0100, G=0,D/B=1,L=0,ALV=0)
                                            ; 0x0,      (Segmentation Limit, 16-19)
                                            ; 0x9       (1001, P=1, DPL=00, S=1)
                                            ; 0x6       (0110, TYPE=0110)
                                            ; 0x00      (Segmentation Base Address, 16-23)

    ; Segmentation information:
    ;     SegBaseAddr: 0x00000000
    ;     SegLim: 0x07A00, G=0
    ;     32BitOperands (D/B=1)
    ;     32BitMode (L=0)
    ;     SegPresent (P=1)
    ;     DPL=0
    ;     UserSeg (S=1)
    ;     TYPE=-EW- (Segmentation Grow Downwards)

    mov word        [cs:gdt_boundary+0x7C00], 31                    ; boundary = size - 1

    lgdt            [cs:GDT+0x7C00]

    ; fast A20
    in              al,                     0x92
    or              al,                     00000010B
    out             0x92,                   al

    cli

    mov             eax,                    cr0
    or              eax,                    1
    mov             cr0,                    eax

    jmp dword       0000000000001_0_00B:_start                      ; 1, first selector

[bits 32]
_start:
    mov             cx,                     0000000000010_0_00B     ; 2, third selector
    mov             ds,                     cx

    mov             cx,                     00000000000_11_000B     ; 3, forth selector
    mov             ss,                     cx

    mov             esp,                    0x7C00                  ; right before the boot code

    mov byte        [0x00],                 'S'
    mov byte        [0x02],                 'y'
    mov byte        [0x04],                 's'
    mov byte        [0x06],                 't'
    mov byte        [0x08],                 'e'
    mov byte        [0x0A],                 'm'
    mov byte        [0x0C],                 ' '
    mov byte        [0x0E],                 'i'
    mov byte        [0x10],                 's'
    mov byte        [0x12],                 ' '
    mov byte        [0x14],                 'i'
    mov byte        [0x16],                 'n'
    mov byte        [0x18],                 ' '
    mov byte        [0x1A],                 '3'
    mov byte        [0x1C],                 '2'
    mov byte        [0x1E],                 'b'
    mov byte        [0x20],                 'i'
    mov byte        [0x22],                 't'

    hlt
_end:

GDT:
gdt_boundary:    dw 0
gdt_base:        dd 0x00007C00 + 512

times 510-($-$$) db 0
dw 0xAA55
