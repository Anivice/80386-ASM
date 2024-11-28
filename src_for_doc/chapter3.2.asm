[bits 16]                                           ; Set the program to run in 16-bit mode

StartingPoint equ 0x7c00                            ; Define the starting point of the bootloader at memory address 0x7c00
[org StartingPoint]                                 ; Set the origin of the program to 0x7c00, meaning the program code starts at this memory address
jmp _start                                          ; Jump to the _start label to begin the bootloader execution

_data:                                              ; Define a data section with two 16-bit words (1234 and 1235)
    dw 1234, 1235                                   ; Declare two data words 1234 and 1235
    .len:                                           ; Create a label called .len to calculate the length of the data
    dw ($ - _data) / 2                              ; Calculate the length of the data array in 16-bit units and store it in .len (number of elements)

_start:
    mov ax, 0x07C0                                  ; Load 0x07C0 into AX, the segment address for the bootloader
    mov ds, ax                                      ; Set the data segment (DS) to the bootloader segment

    mov cx, [ds:_data.len - StartingPoint]          ; Load the length of the _data array into CX by calculating the difference between the address of .len and the StartingPoint
                                                    ; The result in CX will be the number of 16-bit words in the data (2 words in this case)

    ; Loop body
    _loop:
    .start:
        cmp cx, 0x00                                ; Compare the value in CX (the counter) with 0
        je .stop                                    ; If CX equals 0, jump to the .stop label to exit the loop

        dec cx                                      ; Decrement CX (reduce the counter by 1)
        jmp .start                                  ; Jump back to .start to continue the loop if CX is not 0

    .stop:
        jmp $                                       ; Jump to the current address, creating an infinite loop at this point to halt execution

times 510-($-$$) db 0                               ; Fill the remaining space in the boot sector with zeros, ensuring the total size is 510 bytes
dw 0xAA55                                           ; Append the boot sector signature (0xAA55) to indicate a valid boot sector
