[bits 16]
[org 0x7C00]

jmp start

SYS_STARTINGPOINT       equ 0x7C00

IO_PORT                 equ 0x1F0
IO_ERR_STATE            equ 0x1F1
IO_BLOCK_COUNT          equ 0x1F2
IO_LBA28_0_7            equ 0x1F3
IO_LBA28_8_15           equ 0x1F4
IO_LBA28_16_23          equ 0x1F5
IO_LBA28_24_27_W_4_CTRL equ 0x1F6
IO_REQUEST_AND_STATE    equ 0x1F7

IO_READ                 equ 0x20

start:
    ; Step 1: Set number of the blocks/sectors pending to read
    mov     al,     0x01                            ; 1 block/sector
    mov     dx,     IO_BLOCK_COUNT                  ; set out port
    out     dx,     al

    ; Step 2 : Set the start block of LBA28
    mov     al,     0x01                            ; second block, LBA starts from 0
    mov     dx,     IO_LBA28_0_7
    out     dx,     al

    xor     al,     al
    mov     dx,     IO_LBA28_8_15
    out     dx,     al

    mov     dx,     IO_LBA28_16_23
    out     dx,     al

    mov     al,     11100000B                       ; 1 [LBA=1/CHS=0] 1 [IDE Master=1/IDE Slave=0] 0 0 0 0
    mov     dx,     IO_LBA28_24_27_W_4_CTRL
    out     dx,     al

    ; Step 3: Request ICH I/O Read
    mov     dx,     IO_REQUEST_AND_STATE
    mov     al,     IO_READ
    out     dx,     al

    ; Step 4: Wait for the operation to finish
    .wait_for_disk_ops:
        in          al,         dx
        and         al,         10001000B
        cmp         al,         00001000B
        jne     .wait_for_disk_ops

    ; Step 5: Read the Data from Buffer
    ; 1. Setup ES:DI
    mov     ax,     0x07C0
    mov     es,     ax
    mov     di,     _buffer - SYS_STARTINGPOINT

    ; 2. Read
    mov     cx,     256                             ; the I/O port is 16-bit width, meaning 512 bytes is 256 words
    mov     dx,     IO_PORT

    .iteration_loop_read_word_from_disk:
        in          ax,         dx
        mov word    [es:di],    ax
        add         di,         2                   ; 2 bytes, 1 word

        ; loop logic is similar to do { ... } while (--cx != 0)
        loop .iteration_loop_read_word_from_disk

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov         di,                 _buffer - SYS_STARTINGPOINT     ; reset the index to the starting point

    ; Now, we relocate the user program. The allocation is hardcoded for simplicity
    ; new_seg_addr = cur_seg + (cur_index + off_in_prog) >> 4

    ; set stack segmentation
    mov word    ax,                 [es:di + 12]                    ; stack segmentation starting address
    add         ax,                 di
    shr         ax,                 4
    add         ax,                 0x07C0
    mov         ss,                 ax

    mov word    ax,                 [es:di + 12]                    ; stack segmentation starting address
    mov word    bx,                 [es:di + 14]                    ; stack segmentation end address
    sub         bx,                 ax
    mov         sp,                 bx

    ; set up data segmentation
    mov word    ax,                 [es:di + 4]                     ; data segmentation starting address
    add         ax,                 di
    shr         ax,                 4
    add         ax,                 0x07C0
    mov         ds,                 ax
    xor         si,                 si

    ; attempt to call _entry_point()
    mov         bx,                 [es:di + 2]                     ; get entry point offset
    mov         ax,                 [es:di + 8]                     ; get code segmentation starting address
    add         bx,                 _buffer
    add         bx,                 ax
    call        bx

    ; halt the system
_infinite_loop:
    hlt
    jmp _infinite_loop

times 16 - (($-$$) % 16) db 0
times 128 - (16 - (($-$$) % 16)) db 0

_stack:
_buffer:

times 510-($-$$) db 0
; Boot signature
dw 0xAA55
