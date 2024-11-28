[bits 16]                                       ; Set 16-bit mode for the program

StartingPoint equ 0x7c00                        ; Define the starting point of the bootloader at memory address 0x7c00
[org StartingPoint]                             ; Set the origin for the program, meaning the code will start at memory address 0x7c00
jmp _start                                      ; Jump to the _start label to begin execution of the bootloader

msg: db "Hello, World!", 0                      ; Define a null-terminated string "Hello, World!" that will be printed to the screen

_print:
    pusha                                       ; Push all general-purpose registers (AX, BX, CX, DX, SI, DI, BP, SP) onto the stack to preserve their values

    ; Setup source [DS:SI] (source segment and index for loading data)
    ; Setup data segment
    mov ax, 0x07C0                              ; Load the value 0x07C0 into AX, which is the segment address of the bootloader
    mov ds, ax                                  ; Set the data segment (DS) to the bootloader's segment

    mov bp, sp                                  ; Set BP (base pointer) to point to the current stack pointer (SP), which holds the string base address
    mov ax, [ss:bp + 18]                        ; Load the address from the stack at [SS:BP+18], which is the parameter provided before calling, into AX

    sub ax, StartingPoint                       ; Subtract the StartingPoint address from the value in AX to get the relative position of the message
    mov si, ax                                  ; Store the result into SI, which now holds the relative position of the message for the data segment to work

    ; Setup destination [ES:DI] (destination segment and index for video memory)
    mov ax, 0xB800                              ; Load 0xB800 into AX, which is the segment address of video memory in text mode
    mov es, ax                                  ; Set the extra segment (ES) to the video memory segment
    xor di, di                                  ; Clear DI to 0, DI will be used as the destination index in video memory

    _loop:
    .begin:
        mov byte al, [ds:si]                    ; Load the byte at [DS:SI] into AL (this is a character from the "Hello, World!" string)
        cmp al, 0                               ; Compare AL with 0 (null terminator)
        je .end                                 ; If AL is 0 (null terminator), jump to the .end label to finish the printing process

        ; Print character:
        mov byte [es:di], al                    ; Store the character in AL at the video memory address [ES:DI]
        inc di                                  ; Increment DI to move to the next position in video memory
        mov byte [es:di], 0x97                  ; Store 0x97 (attribute byte, color) at [ES:DI] for the character
        inc di                                  ; Increment DI to point to the next space for the next character

        inc si                                  ; Increment SI to point to the next character in the source string
        jmp .begin                              ; Jump back to .begin to process the next character
    .end:

    popa                                        ; Pop all general-purpose registers from the stack to restore their original values
    ret                                         ; Return to the caller (the return address will be popped from the stack)

_start:
    ; Initialize segment registers for the bootloader to run properly
    mov ax, 0x9000                              ; Load 0x9000 into AX, which is the segment for the stack
    mov ss, ax                                  ; Set SS (stack segment) to the value in AX (0x9000)
    mov sp, 0xFFFF                              ; Set the stack pointer (SP) to 0xFFFF, which is at the top of DRAM

    push word msg                               ; Push the address of the msg string onto the stack
    call _print                                 ; Call the _print function to display the message on the screen

_end:
    hlt                                         ; Halt the processor (end of the program)
    jmp near _end                               ; If the processor is not halted, jump to _end to create an infinite loop

times 510-($-$$) db 0                           ; Fill the rest of the boot sector with zeros until it is 510 bytes in total
dw 0xAA55                                       ; Append the boot sector signature 0xAA55 to mark it as a valid bootable sector
