[bits 16]
[org 0x7C00]

SYS_STARTINGPOINT           equ 0x7C00

; The above is the same as before, so I won't do very complicated explanation here

; refer to the documentation for detailed explanation of the following marcos
IO_PORT                     equ 0x1F0
IO_ERR_STATE                equ 0x1F1
IO_BLOCK_COUNT              equ 0x1F2
IO_LBA28_0_7                equ 0x1F3
IO_LBA28_8_15               equ 0x1F4
IO_LBA28_16_23              equ 0x1F5
IO_LBA28_24_27_W_4_CTRL     equ 0x1F6
IO_REQUEST_AND_STATE        equ 0x1F7

IO_READ                     equ 0x20
DRQ                         equ 0x08

USER_PROGRAM_SECTOR_SZ      equ 3

start:
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; First things first, we have to load our program into the memory
    ; Step 1: Set number of the blocks/sectors pending to read
    mov         al,                     USER_PROGRAM_SECTOR_SZ
    mov         dx,                     IO_BLOCK_COUNT                  ; set out port
    out         dx,                     al

    ; Step 2 : Set the start block of LBA28
    mov         al,                     0x01                            ; second block, LBA starts from 0
    mov         dx,                     IO_LBA28_0_7
    out         dx,                     al

    xor         al,                     al
    mov         dx,                     IO_LBA28_8_15
    out         dx,                     al

    mov         dx,                     IO_LBA28_16_23
    out         dx,                     al

    mov         al,                     11100000B                       ; 1 [LBA=1/CHS=0] 1 [IDE Master=1/IDE Slave=0] 0 0 0 0
    mov         dx,                     IO_LBA28_24_27_W_4_CTRL
    out         dx,                     al

    ; Step 3: Request ICH I/O Read
    mov         dx,                     IO_REQUEST_AND_STATE
    mov         al,                     IO_READ
    out         dx,                     al

    ; Step 4: Read the Data from Buffer
    ; Step 4.1. Setup ES:DI to point to the reserved buffer space
    mov         ax,                     0x07C0
    mov         es,                     ax
    mov         di,                     _buffer - SYS_STARTINGPOINT

    ; Step 4.2. Read
    mov         bp,                     USER_PROGRAM_SECTOR_SZ          ; the I/O port is 16-bit width, meaning 512 bytes is 256 words

    .iteration_loop_read_word_from_disk:
    ; Step 4.2.1: Wait for the operation to finish !! We do this for each sector !!
    mov         dx,                     IO_REQUEST_AND_STATE
    .wait_for_disk_read_ops:
        in          al,                 dx
        test        al,                 DRQ                             ; performs a bitwise AND check
                                                                        ; and see if Zero Flag (when result == 0) is set
        jz          .wait_for_disk_read_ops

        ; here is the sub loop body, for simplicity we use cx+loop instruction
        mov             cx,                     256                     ; we read one sector and one sector only
        mov             dx,                     IO_PORT                 ; set dx to IO port
        .read_sector:
            in          ax,                     dx                      ; read from IO port
            mov word    [es:di],                ax                      ; write to buffer
            add         di,                     2                       ; 2 bytes, 1 word
        ; loop logic is similar to: do { ... } while (--cx != 0)
        loop            .read_sector

        dec             bp                                              ; decrease bp
        cmp             bp,                     0x00                    ; compare bp to 0
        jne             .iteration_loop_read_word_from_disk             ; if bp != 0, repeat, if bp == 0, continue downwards

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov         di,                     _buffer - SYS_STARTINGPOINT     ; reset the index to the starting point

    ; Now, we relocate the user program. The allocation is hardcoded for simplicity
    ; new_seg_addr = cur_seg + (cur_index + off_in_prog) >> 4

    ; set stack segmentation
    mov word    ax,                     [es:di + 12]                    ; stack segmentation starting address
    add         ax,                     di
    shr         ax,                     4
    add         ax,                     0x07C0
    mov         ss,                     ax

    mov word    ax,                     [es:di + 12]                    ; stack segmentation starting address
    mov word    bx,                     [es:di + 14]                    ; stack segmentation end address
    sub         bx,                     ax
    mov         sp,                     bx

    ; set up data segmentation
    mov word    ax,                     [es:di + 4]                     ; data segmentation starting address
    add         ax,                     di
    shr         ax,                     4
    add         ax,                     0x07C0
    mov         ds,                     ax
    xor         si,                     si

    ; attempt to call _entry_point() with correct code segment (offset starts with 0x0000)
    mov         bx,                     [es:di + 2]                     ; get entry point offset
    mov         ax,                     [es:di + 8]                     ; get code segmentation starting address
    add         ax,                     _buffer                         ; pending the current buffer segment
    shr         ax,                     4                               ; they are all flat address, so we shift 4 bits to the right

    ; Now we clear es to 0, so that we can access our own data section.
    ; with ds now point to the program's own data section, our default
    ; data addressing is now invalid! Luckily, MBR code position is known
    ; so we can override with known values, in this case, the easiest one is
    ; to just use '0x00'
    xor         cx,                     cx
    mov         es,                     cx

    ; to perform a long call, we need to provide both Code Segmentation address for CS, and offset index for IP
    ; Now that call doesn't accept register combination for long call, we use memory instead
    ; the memory map should look like this: offset, segmentation.
    mov         [es:_far_call],         bx                              ; offset
    mov         [es:_far_call+2],       ax                              ; segmentation

    call far    [es:_far_call]

    ; The loaded program will return to here after it's done with it's designed job
    ; thus, we have to halt the system in case that the processor wonders off
_infinite_loop:
    hlt
    jmp _infinite_loop

_far_call:
    dw 0, 0

; What does this do and why it's here? good question. This thing does one job, ensure alignment of _buffer without
; having to setup a separate code segmentation that will messing with the code size
times 16 - (($ - $$) % 16) db 0

_buffer:

times 510 - ($ - $$) db 0
; Boot signature
dw 0xAA55
