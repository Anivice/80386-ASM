[bits 16]                                   ; 16-bit mode

GPU_REGISTER_INDEX      equ 0x3d4
GPU_CURSOR_H8_BIT       equ 0x0e
GPU_CURSOR_L8_BIT       equ 0x0f
GPU_INDEXED_REG_IO      equ 0x3d5
RTC_REGISTER_INDEX      equ 0x70
RTC_REGISTER_IO         equ 0x71
RTC_REGISTER_A          equ 0x0A
RTC_REGISTER_B          equ 0x0B
RTC_REGISTER_C          equ 0x0C
RTC_REGISTER_D          equ 0x0D
RTC_REGISTER_SEC        equ 0x00
RTC_REGISTER_MIN        equ 0x02
RTC_REGISTER_HUR        equ 0x04
RTC_REGISTER_WEK        equ 0x06
RTC_REGISTER_DAY        equ 0x07
RTC_REGISTER_MON        equ 0x08
RTC_REGISTER_YER        equ 0x09
I8259_IMR               equ 0xA1

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
putc:   ; putc(al=character)
    pusha                                   ; preserve state
    push        ds
    push        es

    mov         bl,         al              ; save character to bl

    ; get_cursor() -> ax
    call        get_cursor

    ; check if we have reached the bottom of the screen
    ; when that happens, we first, need to move the content on the screen upwards one line (+80 characters)
    ; first instance: last line and attempt a newline (ax >= 1920)
    ; check if (ax >= 1920 AND bl == 0x0A) OR (ax == 1999)

    ; First Condition: ax >= 1920
    cmp         ax,         1920
    jl          .check_second_condition ; If ax < 1920, skip to second condition

    ; ax >= 1920, now check if bl == 0x0A
    cmp         bl,         0x0A
    jne         .check_second_condition ; If bl != 0x0A, skip to second condition

    ; Both conditions met: ax >= 1920 AND bl == 0x0A
    jmp         .start_of_scrolling     ; Jump to start scrolling

    ; Second Condition: ax == 1999
    .check_second_condition:
        cmp     ax,         1999
        jne     .end_of_scrolling       ; If ax != 1999, jump to end_of_scrolling

    ; at here, condition met: ax == 1999

    .start_of_scrolling:
        ; destination:
        mov         cx,         0xB800
        mov         es,         cx
        xor         di,         di

        ; source:
        mov         ds,         cx
        mov         si,         80 * 2          ; start of the second line

        ; { 2000 (all the character on screen) - 80 (first line) } * 2 == all the data on screen except for the first line
        mov         cx,         2000 - 80

        cld
        rep movsw

        ; now we need to clear all the characters at the bottom of the screen
        mov         di,         1920 * 2
        mov         cx,         80

        .clear_bottom:
            mov byte    [es:di],        ' '
            inc         di
            mov byte    [es:di],        0x07
            inc         di
        loop        .clear_bottom

        ; reset cursor to the start of the last line
        ; if bl != 0x0A, continue putc, else, we end putc (since we already handled 0x0A by scrolling)
        cmp         bl,         0x0A
        je          .set_cursor_with_bx_equals_to_0x0A

        mov         ax,         1919            ; line start at the bottom of the screen
        call        set_cursor                  ; set cursor
        jmp         .end_of_scrolling           ; end scrolling handling, continue to put the character

        ; move cursor to start at the bottom of the screen if bl == 0x0A
        ; and we end our putc, since this is basically print a newline
        .set_cursor_with_bx_equals_to_0x0A:
            mov     ax,         1920            ; move cursor to start at the bottom of the screen
            call    set_cursor                  ; set cursor
            jmp     .end                        ; finish putc, since we basically did the whole thing

    .end_of_scrolling:

    ; newline handler:
    cmp         bl,         0x0A            ; if it's a newline marker
    je          .set_cursor_to_newline      ; jump to putc.set_cursor_to_newline

    ; Normal print:
    ; show the character
    mov         cx,         0xB800          ; Segment of video memory
    mov         es,         cx              ; set segmentation of video memory to es

    ; multiply ax by 2 using cx, since the max value of the cursor is 1999, it will not overflow in 16bit register
    ; meaning dx is not need to be considered
    mov         cx,         2
    mul         cx
    mov         di,         ax

    mov byte    [es:di],    bl
    mov byte    [es:di+1],  0x07

    ; set cursor at the updated location
    div         cx
    inc         ax
    call        set_cursor
    jmp         .end                        ; jump over the newline section

    ; print '\n'
    .set_cursor_to_newline:
        ; we called get_cursor()->ax before hand, linear address is already in ax
        ; now that we already know the input character is '\n', we can discard the content inside bx
        mov         bx,         80
        xor         dx,         dx

        ; we do a division, the y will be inside ax and x will be inside dx
        div         bx

        ; now, we only care about ax(y), since x is always 0 at a new line
        inc         ax                      ; move to next line

        ; ax * 80 => ax, obtain the linear address
        mov         bx,         80
        xor         dx,         dx
        mul         bx

        call        set_cursor              ; now, we set the new location for cursor
        ; done.

    .end:
    pop             es
    pop             ds
    popa                                    ; restore
    ret                                     ; return

print:  ; print(ds:si=string)
    pusha                                   ; preserve state

    xor         bx,         bx              ; clear bx

    ; loop body:
    .loop:
        mov byte    al,         [ds:si + bx]    ; move ds:si(string starting addr) + bx(offset) to al
        cmp byte    al,         0x00            ; compare al with 0x00

        je          .end                        ; if al == 0x00(null terminator), jump to .end

        call        putc                        ; call putc(al=character)
        inc         bx                          ; move to next character by increasing bx by 1
        jmp         .loop

    ; end of the function
    .end:
    popa                                    ; restore state
    ret

get_cursor: ; get_cursor()->ax
    push        dx

    ; now, point the GPU register index to the cursor register (higher 8 bit)
    mov         dx,         GPU_REGISTER_INDEX
    mov         al,         GPU_CURSOR_H8_BIT
    out         dx,         al

    ; now, read from GPU register IO port, which is cursor register (higher 8 bit)
    mov         dx,         GPU_INDEXED_REG_IO
    in          al,         dx

    mov         ah,         al

    ; now, point the GPU register index to the cursor register (lower 8 bit)
    mov         dx,         GPU_REGISTER_INDEX
    mov         al,         GPU_CURSOR_L8_BIT
    out         dx,         al

    ; now, read from GPU register IO port, which is cursor register (lower 8 bit)
    mov         dx,         GPU_INDEXED_REG_IO
    in          al,         dx

    pop         dx
    ret

set_cursor: ; set_cursor(ax)
    push        dx
    push        bx

    mov         bx,         ax              ; save ax to bx

    ; now, point the GPU register index to the cursor register (higher 8 bit)
    mov         dx,         GPU_REGISTER_INDEX
    mov         al,         GPU_CURSOR_H8_BIT
    out         dx,         al

    ; now, read from GPU register IO port, which is cursor register (higher 8 bit)
    mov         dx,         GPU_INDEXED_REG_IO
    mov         al,         bh
    out         dx,         al

    ; now, point the GPU register index to the cursor register (lower 8 bit)
    mov         dx,         GPU_REGISTER_INDEX
    mov         al,         GPU_CURSOR_L8_BIT
    out         dx,         al

    ; now, read from GPU register IO port, which is cursor register (lower 8 bit)
    mov         dx,         GPU_INDEXED_REG_IO
    mov         al,         bl
    out         dx,         al

    pop         bx
    pop         dx
    ret

_entry_point: ; _entry_point()
    pusha
    push        es
    push        ds
    push        ss

    ; print greeting message:
    mov         si,         greet
    call        print

    ; install a new interruption handler on 0x70 (Clock)
    mov         ax,         0x70
    mov         bl,         4
    mul         bl
    mov         bx,         ax              ; ax cannot be used as effective addresses, remember?

    ; disable interruption
    cli

    ; clear es to 0
    xor         ax,         ax              ; clear ax
    mov         es,         ax              ; 0 => es

    ; install our new interruption
    mov word    [es:bx],    int_0x70_handler
    mov word    [es:bx+2],  cs

    ; print "done!"
    mov         si,         done_msg
    call        print

    ; print "Setting up..." prompt
    mov         si,         access_reg_b
    call        print

    ; Access RTC Register B
    mov         al,         RTC_REGISTER_B
    or          al,         0x80            ; disable NMI
    out         RTC_REGISTER_INDEX,     al  ; select RTC register B
    mov         al,         00010010B       ; disable periodic interruption, interruption after update, and BCD, 24 hour time
    out         RTC_REGISTER_IO,        al

    ; Access RTC Register C, so that we clear all interruption flags
    mov         al,         RTC_REGISTER_C  ; we actually want to resume NMI here
    out         RTC_REGISTER_INDEX,     al  ; NMI is now resumed
    in          al,         RTC_REGISTER_IO

    in          al,         I8259_IMR       ; read from 8259
    and         al,         0xFE            ; 0xFE is 0x11111110, clear RTC port so we can receive RTC interruptions
    out         I8259_IMR,  al              ; write back

    ; print done
    mov         si,         done_msg
    call        print

    ; set up correct cursor starting point
    call        get_cursor
    add         ax,         19
    call        set_cursor

    ; enable interruption
    sti

    .loop:
        hlt
        jmp     .loop

    pop         ss
    pop         ds
    pop         es
    popa
    retf                                    ; since we did a far call, we use a far return


read_reg_into_al: ; read_reg_into_al(al=index)
    xor         ah,         ah
    or          al,         0x80
    out         RTC_REGISTER_INDEX, al
    in          al,         RTC_REGISTER_IO
    ret

bcd_to_ascii: ; bcd_to_ascii(al=packed bcd)=>ax
    xor         ah,         ah
    shl         ax,         4               ; ax << 4
    shr         al,         4               ; al >> 4

    ; now, ah is the higher 4 bits of BCD, al is the lower 4 bits of BCD
    add         ah,         '0'
    add         al,         '0'

    ret

output_digits: ; (ah=digit,al=digit)
    pusha

    mov byte    [_display_buffer],      ah
    mov byte    [_display_buffer+1],    al
    mov byte    [_display_buffer+2],    0

    mov         si,         _display_buffer
    call        print

    popa
    ret

print_single_char: ; print_single_char(al=char)
    push        si

    mov byte    [_display_buffer],      al
    mov byte    [_display_buffer+1],    0
    mov         si,                     _display_buffer
    call        print

    pop         si
    ret

print_endl:
    push        ax
    mov         al,         0x0A
    call        print_single_char
    pop         ax
    ret

print_dash:
    push        ax
    mov         al,         '-'
    call        print_single_char
    pop         ax
    ret

print_col:
    push        ax
    mov         al,         ':'
    call        print_single_char
    pop         ax
    ret

print_space:
    push        ax
    mov         al,         ' '
    call        print_single_char
    pop         ax
    ret

int_0x70_handler:
    pusha
    push        es
    push        ds

    call        get_cursor
    sub         ax,         19
    call        set_cursor

    mov         al,         RTC_REGISTER_SEC
    call        read_reg_into_al
    push        ax

    mov         al,         RTC_REGISTER_MIN
    call        read_reg_into_al
    push        ax

    mov         al,         RTC_REGISTER_HUR
    call        read_reg_into_al
    push        ax

    mov         al,         RTC_REGISTER_DAY
    call        read_reg_into_al
    push        ax

    mov         al,         RTC_REGISTER_MON
    call        read_reg_into_al
    push        ax

    mov         al,         RTC_REGISTER_YER
    call        read_reg_into_al
    push        ax

    ; print year
    mov byte    [_display_buffer],      '2'
    mov byte    [_display_buffer+1],    '0'
    mov byte    [_display_buffer+2],    0
    mov         si,                     _display_buffer
    call        print

    pop         ax
    call        bcd_to_ascii
    call        output_digits

    call        print_dash

    ; print month
    pop         ax
    call        bcd_to_ascii
    call        output_digits

    call        print_dash

    ; print day
    pop         ax
    call        bcd_to_ascii
    call        output_digits

    call        print_space

    ; print hour
    pop         ax
    call        bcd_to_ascii
    call        output_digits

    call        print_col

    ; print minute
    pop         ax
    call        bcd_to_ascii
    call        output_digits

    call        print_col

    ; print second
    pop         ax
    call        bcd_to_ascii
    call        output_digits

    ; print '\n'
;    call        print_endl

    ; Clear the RTC interrupt flags by reading Register C
    mov         al,         RTC_REGISTER_C
    out         RTC_REGISTER_INDEX, al      ; Select Register C, and enable NMI
    in          al,         RTC_REGISTER_IO ; Read Register C to clear flags

    ; Send End of Interrupt (EOI) signals
    mov         al,         0x20
    out         0xa0,       al              ; EOI to slave PIC
    out         0x20,       al              ; EOI to master PIC

    pop         ds
    pop         es
    popa
    iret
segment _code_tail align=16
_code_end:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
segment _data_head align=16
_data_start:

segment data align=16 vstart=0
greet:
    db "Program loading complete!", 0x0A
    db "Installing new interruption...", 0
access_reg_b:
    db "Setting up...", 0
done_msg:
    db "done!", 0x0A, 0
_display_buffer:
    resb 16
segment _data_tail align=16
_data_end:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
segment _stack_reserved align=16
_stack_start:
    resb 0x1FF
_stack_end:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

segment tail align=16
_program_end:
    ; this is just used to fill the parts not in the alignment with 0
    times 16 db 0
