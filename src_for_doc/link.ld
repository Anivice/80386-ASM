/* Define the memory layout */
SECTIONS
{
    /* Set the starting address to 0x0000 */
    . = 0x10000;

    /* Place the .text section first */
    .text :
    {
        *(.text)           /* Include all .text sections from input files */
    }

    /* Place the .rodata section next */
    .rodata :
    {
        *(.rodata)         /* Include all .rodata sections */
    }

    /* Then the .data section */
    .data :
    {
        *(.data)           /* Include all .data sections */
    }

    /* Followed by the .bss section */
    .bss :
    {
        *(.bss)            /* Include all .bss sections */
        *(COMMON)
    }

    /* Optionally, discard unwanted sections */
    /DISCARD/ :
    {
        *(.eh_frame*)
        *(.comment)
        *(.note*)
        *(.dy*)
    }
}
