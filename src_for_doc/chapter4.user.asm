[bits 16]                                   ; 16-bit mode

segment head align=16 vstart=0
    dw _program_end                         ; program length                                    +0
    dw _entry_point                         ; program entry point(index) in code segmentation   +2
    dw _data_start                          ; data segmentation start point                     +4
    dw _data_end                            ; data segmentation end point                       +6
    dw _code_start                          ; code segmentation start point                     +8
    dw _code_end                            ; code segmentation end point                       +10
    dw _stack_start                         ; stack segmentation start point                    +12
    dw _stack_end                           ; stack segmentation end point                      +14

segment _data_head align=16
_data_start:
segment data align=16 vstart=0
    msg: db "Hello, World!", 0
segment _data_tail align=16
_data_end:

segment _code_head align=16
_code_start:
segment code align=16 vstart=0
putc:   ; putc(al=character)
    push        ax                          ; preserve ax

    mov         ah,         0x0E            ; tty output function
    int         0x10                        ; call BIOS interrupt

    pop         ax                          ; load the original ax
    ret                                     ; return

print:  ; print(ds:si=string)
    push        bx                          ; preserve bx
    push        ax                          ; preserve ax

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
    pop         ax                          ; load the original ax
    pop         bx                          ; load the original bx
    ret

_entry_point: ;_entry_point(es:di=head_address)
    pusha

    call        print

    popa
    retf                                    ; since we did a far call, we use a far return

segment _code_tail align=16
_code_end:

segment _stack_reserved align=16
_stack_start:
    times 0x00FF db 0
_stack_end:

segment tail align=16
_program_end:
    ; this is just used to fill the parts not in the alignment with 0
    times 16 db 0
