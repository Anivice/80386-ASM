[bits 16]                                   ; 16-bit mode

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

segment head align=16 vstart=0
    dw _program_end                         ; program length                                    +0
    dw _entry_point                         ; program entry point(index) in code segmentation   +2
    dw _data_start                          ; data segmentation start point                     +4
    dw _data_end                            ; data segmentation end point                       +6
    dw _code_start                          ; code segmentation start point                     +8
    dw _code_end                            ; code segmentation end point                       +10
    dw _stack_start                         ; stack segmentation start point                    +12
    dw _stack_end                           ; stack segmentation end point                      +14

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
segment _code_head align=16
_code_start:

segment code align=16 vstart=0
read_disk:  ; read_disk(al=sector_count,ah=starting_sector) ==> es:di
    pusha
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; we preserve the number of sectors to read to bp
    mov         bx,                     ax
    xor         bh,                     bh
    mov         bp,                     bx

    ; First things first, we have to load our program into the memory
    ; Step 1: Set number of the blocks/sectors pending to read
    mov         dx,                     IO_BLOCK_COUNT                  ; set out port
    out         dx,                     al

    mov         al,                     ah                              ; ah => al, the starting sector

    ; Step 2 : Set the start block of LBA28
    mov         dx,                     IO_LBA28_0_7
    out         dx,                     al

    xor         al,                     al
    mov         dx,                     IO_LBA28_8_15
    out         dx,                     al

    mov         dx,                     IO_LBA28_16_23
    out         dx,                     al

    mov         al,                     11100000B                       ; 1 [LBA=1/CHS=0] 1 [IDE Master=0/IDE Slave=1] 0 0 0 0
    mov         dx,                     IO_LBA28_24_27_W_4_CTRL
    out         dx,                     al

    ; Step 3: Request ICH I/O Read
    mov         dx,                     IO_REQUEST_AND_STATE
    mov         al,                     IO_READ
    out         dx,                     al

    ; Step 4: Read the Data from Buffer
    ; Step 4.2. Read
    ; bp contains the sector count we set at the start of the function
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

    popa
    ret

_entry_point:
    ; first, we load user program
    ; _program_end / 512 ==> ax, _program_end % 512 ==> dx
    mov     ax,     _program_end
    xor     dx,     dx
    mov     bx,     512
    div     bx

    ; if (dx != 0) { ax++ }
    cmp     dx,     0
    je      .skip_add
    inc     ax
    .skip_add:

    ; add boot sector
    inc     ax

    ; backup starting sector to bp
    mov     bp,     ax

    ; load our program at 0x10000
    mov     cx,     0x1000
    mov     es,     cx
    xor     di,     di
    shl     ax,     8
    mov     al,     128
    call    read_disk

    ; we hard coded the wanted parameters here:
    ; here, we calculated the GDT segmentation and offset into ds and bx
    mov     ax,     [gdt_base]
    mov     dx,     [gdt_base+2]
    mov     bx,     16
    div     bx
    mov     es,     ax
    mov     bx,     dx

    ; # 0
    ; first, we define a NULL descriptor
    mov dword       [es:bx],       0x00
    mov dword       [es:bx+4],     0x00

    ; # 1
    ; second, we define a protect mode Segmentation
    xor             eax,            eax
    mov             ax,             cs
    shl             eax,            4

    mov word        [es:bx+8],      0xFFFF      ; 0xFFFF    (Segmentation Limit 0-15)
    mov word        [es:bx+10],     ax          ; ------    (Segmentation Base Address 0-15)
    shr             eax,            16
    mov byte        [es:bx+12],     al          ; ------    (Segmentation Base Address, 16-23)
    mov byte        [es:bx+13],     0x98        ; 0x9       (1001, P=1, DPL=00, S=1)
                                                ; 0x8       (1000, TYPE=1000)
    mov byte        [es:bx+14],     0x4F        ; 0x4       (0100, G=0,D/B=1,L=0,ALV=0)
                                                ; 0xF,      (Segmentation Limit, 16-19)
    mov byte        [es:bx+15],     ah          ; -----     (Segmentation Base Address 24-31)

    ; # 2
    ; third, we define a protected mode data segmentation
    mov dword       [es:bx+16],    0x8000FFFF   ; 0x8000    (Segmentation Base Address 0-15)
                                                ; 0xFFFF    (Segmentation Limit 0-15)
    mov dword       [es:bx+20],    0x0040920B   ; 0x00      (Segmentation Base Address 24-31)
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

    ; # 3
    mov dword       [es:bx+24],    0x00007A00   ; 0x0000    (Segmentation Base Address 0-15)
                                                ; 0x7A00    (Segmentation Limit 0-15)
    mov dword       [es:bx+28],    0x00409600   ; 0x00      (Segmentation Base Address 24-31)
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

    ; # 4
    mov dword       [es:bx+32],    0x9FFF0016   ; 0x9FFF    (Segmentation Base Address 0-15)
                                                ; 0x0016    (Segmentation Limit 0-15)
    mov dword       [es:bx+36],    0x00409200   ; 0x00      (Segmentation Base Address 24-31)
                                                ; 0x4       (0100, G=0,D/B=1,L=0,ALV=0)
                                                ; 0x0,      (Segmentation Limit, 16-19)
                                                ; 0x9       (1001, P=1, DPL=00, S=1)
                                                ; 0x2       (0010, TYPE=0010)
                                                ; 0x00      (Segmentation Base Address, 16-23)

    ; # 5
    mov word        [es:bx+40],     0xFFFF      ; Limit Low = 0xFFFF
    mov word        [es:bx+42],     0x0000      ; Base Low = 0x0000
    mov byte        [es:bx+44],     0x00        ; Base Mid = 0x00
    mov byte        [es:bx+45],     0x98        ; Access Byte = 0x98
    mov byte        [es:bx+46],     0xCF        ; Granularity = 0x4F
    mov byte        [es:bx+47],     0x00        ; Base High = 0x00

    mov word        [gdt_boundary], 47          ; boundary = size - 1

    lgdt            [gdt48]

    ; fast A20
    in              al,                     0x92
    or              al,                     00000010B
    out             0x92,                   al

    cli

    mov             eax,                    cr0
    or              eax,                    1
    mov             cr0,                    eax

    ; Protect Mode Starts Here:
    jmp dword       0000000000001_0_00B:_start                      ; 1, first selector

    ; 32bit Mode Starts Here
[bits 32]
_start:

    mov             cx,                     0000000000010_0_00B     ; 2, third selector
    mov             ds,                     cx

    mov             cx,                     0000000000011_0_00B     ; 3, forth selector
    mov             ss,                     cx

    mov             cx,                     0000000000100_0_00B
    mov             es,                     cx

    mov             esp,                    0x7C00                  ; right before the boot code

    mov dword       [es:0x00],              0x10000
    mov word        [es:0x04],              0000000000101_0_00B

    ; far call
    call far        [es:0x00]

    ; if code exit, we halt the system in case the processor wonders off
_end:
    hlt
    jmp _end

segment _code_tail align=16
_code_end:

segment _data_head align=16
_data_start:

segment data align=16 vstart=0
gdt48:
    gdt_boundary:    dw 0
    gdt_base:        dd 0x90000
segment _data_tail align=16
_data_end:

segment _stack_reserved align=16
_stack_start:
    resb 0xF0
_stack_end:

segment tail align=16
_program_end:
