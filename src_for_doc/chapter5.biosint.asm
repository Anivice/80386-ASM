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

segment _code_head align=16
_code_start:

segment code align=16 vstart=0
_entry_point: ; _entry_point()
    pusha

    .loop:
        xor         ah,         ah          ; 0 => ah
        int         0x16                    ; monitor keyboard interruption

        ; print content inside keyboard, content is in al
        mov         ah,         0x0E
        int         0x10
    jmp         .loop

    popa
    retf
segment _code_tail align=16
_code_end:

segment _data_head align=16
_data_start:
segment data align=16 vstart=0
segment _data_tail align=16
_data_end:

segment _stack_reserved align=16
_stack_start:
    resb 0x1FF
_stack_end:

segment tail align=16
_program_end:
    ; this is just used to fill the parts not in the alignment with 0
    times 16 db 0
