[bits 16]                                   ; 16-bit mode

GPU_REGISTER_INDEX      equ 0x3d4
GPU_CURSOR_H4_BIT       equ 0x0e
GPU_CURSOR_L4_BIT       equ 0x0f
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
    mov         bl,         al              ; save character to bl

    ; get_cursor() -> ax
    call        get_cursor

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

    ; set cursor at updated location
    div         cx
    inc         ax
    call        set_cursor

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

    ; now, point the GPU register index to the cursor register (higher 4 bit)
    mov         dx,         GPU_REGISTER_INDEX
    mov         al,         GPU_CURSOR_H4_BIT
    out         dx,         al

    ; now, read from GPU register IO port, which is cursor register (higher 4 bit)
    mov         dx,         GPU_INDEXED_REG_IO
    in          al,         dx

    mov         ah,         al

    ; now, point the GPU register index to the cursor register (lower 4 bit)
    mov         dx,         GPU_REGISTER_INDEX
    mov         al,         GPU_CURSOR_L4_BIT
    out         dx,         al

    ; now, read from GPU register IO port, which is cursor register (lower 4 bit)
    mov         dx,         GPU_INDEXED_REG_IO
    in          al,         dx

    pop         dx
    ret

set_cursor: ; set_cursor(ax)
    push        dx
    push        bx

    mov         bx,         ax              ; save ax to bx

    ; now, point the GPU register index to the cursor register (higher 4 bit)
    mov         dx,         GPU_REGISTER_INDEX
    mov         al,         GPU_CURSOR_H4_BIT
    out         dx,         al

    ; now, read from GPU register IO port, which is cursor register (higher 4 bit)
    mov         dx,         GPU_INDEXED_REG_IO
    mov         al,         bh
    out         dx,         al

    ; now, point the GPU register index to the cursor register (lower 4 bit)
    mov         dx,         GPU_REGISTER_INDEX
    mov         al,         GPU_CURSOR_L4_BIT
    out         dx,         al

    ; now, read from GPU register IO port, which is cursor register (lower 4 bit)
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
    db 'Bill Gates is the most famous and the world renowned genius of all time.', 0x0A
    db 'Some of his famous and absolutely correct quotes are as follwing:', 0x0A
    db '640 KB [of memory] ought to be enough for anybody.', 0x0A ; yeah this aged well
    db 'No one will need more than 637 kilobytes of memory for a personal computer.', 0x0A
    ; yes, and he still uses a 637 KB memory computer
    db 'Windows Isnt for Everyone.', 0x0A ; He said that CLI is for business workers. Well, I don't think so.
    db 'We Always Overestimate the Change That Will Occur in the Next 2 Years and Underestimate'
    db 'the Change That Will Occur in the Next 10', 0x00
    ; the last two years Microsoft bought OpenAI and basically slapped everything with it, including github

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
