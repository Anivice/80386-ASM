[bits 16]
[org 0x7C00]

jmp start

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
    mov     al,     0x01                ; 1 block/sector
    mov     dx,     IO_BLOCK_COUNT      ; set out port
    out     dx,     al

    ; Step 2 : Set the start block of LBA28
    mov     al,     0x01                ; second block, LBA starts from 0
    mov     dx,     IO_LBA28_0_7
    out     dx,     al

    xor     al,     al
    mov     dx,     IO_LBA28_8_15
    out     dx,     al

    mov     dx,     IO_LBA28_16_23
    out     dx,     al

    mov     al,     11100000B           ; 1 [LBA=1/CHS=0] 1 [IDE Master=1/IDE Slave=0] 0 0 0 0
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
    ; 1. Setup DS:SI
    xor     ax,     ax
    mov     ds,     ax

    mov     si,     _buffer

    ; 2. Read
    mov     cx,     256                 ; the I/O port is 16-bit width, meaning 512 bytes is 256 words
    mov     dx,     IO_PORT

    .iteration_loop_read_word_from_disk:
        in          ax,         dx
        mov word    [ds:si],    ax
        add         si,         2       ; 2 bytes, 1 word

        ; loop logic is similar to do { ... } while (--cx != 0)
        loop .iteration_loop_read_word_from_disk

    ; Now, we print it to the screen
    mov     si,     _buffer
    .print:
        cmp byte    [ds:si],    0x00
        je          .end

        mov         ah,         0x0E    ; TTY Output Function
        mov         al,         [ds:si] ; Character to print
        int         0x10                ; Call BIOS interrupt
        inc         si

        jmp         .print
    .end:

    ; halt the system
_infinite_loop:
    hlt
    jmp _infinite_loop

_buffer:
    times 510-($-$$) db 0

; Boot signature
dw 0xAA55
