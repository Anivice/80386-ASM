[bits 16]                                   ; 16-bit mode

GPU_REGISTER_INDEX      equ 0x3d4
GPU_CURSOR_H8_BIT       equ 0x0e
GPU_CURSOR_L8_BIT       equ 0x0f
GPU_INDEXED_REG_IO      equ 0x3d5

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

_entry_point: ; _entry_point()
    pusha

    call        print

    popa
    retf                                    ; since we did a far call, we use a far return

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

segment _code_tail align=16
_code_end:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
segment _data_head align=16
_data_start:

segment data align=16 vstart=0
msg:
    db "Bill Gates is the most famous and the world renowned genius of all time.", 0x0A
    db "Some of his famous and absolutely correct quotes are as follwing:", 0x0A
    db "640 KB [of memory] ought to be enough for anybody.", 0x0A ; yeah this aged well
    db "No one will need more than 637 kilobytes of memory for a personal computer.", 0x0A
    ; yes, and he still uses a 637 KB memory computer
    db "Windows Isn't for Everyone.", 0x0A ; He said that CLI is for business workers. Well, I don't think so.
    db "We Always Overestimate the Change That Will Occur in the Next 2 Years and Underestimate "
    db "the Change That Will Occur in the Next 10", 0x0A
    ; the last two years Microsoft bought OpenAI and basically slapped everything with it, including github
    db "And, we have Steve Jobs being an absolute God under his cult Apple. And here is his, "
    db "again, absolutely correct statements:", 0x0A
    db "People don't know what they want until you show it to them.", 0x0A ; oh no please I don't want it
    db "I'm not going to spend my life trying to turn a wooden nickel(bad products) "
    db "into a silver one(good one, by his standard).", 0x0A ; he did exactly that
    db "We have always been shameless about stealing great ideas.", 0x0A ; lmao
    db "I'm an artist. I'm a person who likes to create.", 0x0A ; lmfao
    db "And we have Linus Torvalds, God of Enternity, if you will:", 0x0A
    db "No One Cares About Your Fancy Interface!", 0x0A ; maybe that why Linux has trash GUI?
    db "I Don't Care About You!", 0x0A ; well that's warm, really a big fan when the programmers don't give a shit about their end user
    db "Microkernels are a joke!", 0x0A ; yeah this aged so well lmao
    db "If you don't like the way Linux works, you're free to fork it!", 0x0A ; or just use *BSD, it's much more consistent and it actually gives a shit
    db "You're Stupid!", 0x0A ; another heart warming statement from God. Mind you, heed that!
    db "Security patches are annoying!", 0x0A ; and is this why major cooperations tend to use *BSD?
    db "We don't need fancy IDEs, just a good text editor!", 0x0A ; in another way, he needs fancy IDEs that looks like a text editor
    db "The cloud is just somebody else's computer.", 0x00 ; yeah and no, and I don't deploy my products on mailing lists
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
