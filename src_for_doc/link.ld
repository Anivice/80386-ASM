SECTIONS
{
    /* Set the starting address */
    . = 0x10000;

    /* Place the .text section */
    .text :
    {
        _text_start = .;       /* Define start of text */
        *(.text)               /* Include all .text sections */
        *(.text.*)             /* Include all .text.* sections */
        _text_end = .;         /* Define end of text */
    }

    /* Place the .rodata section */
    .rodata :
    {
        _rodata_start = .;     /* Define start of rodata */
        *(.rodata)
        *(.rodata.*)
        _rodata_end = .;       /* Define end of rodata */
    }

    /* Place the .data section */
    .data :
    {
        _data_start = .;       /* Define start of data */
        *(.data)
        *(.data.*)
        _data_end = .;         /* Define end of data */
    }

    /* Place the .bss section */
    .bss :
    {
        _bss_start = .;        /* Define start of bss */
        *(.bss)
        *(COMMON)
        _bss_end = .;          /* Define end of bss */
    }

    /* Optionally discard sections */
    /DISCARD/ :
    {
        *(.eh_frame*)
        *(.comment)
        *(.note*)
        *(.dy*)
    }

    /* Define the entry point */
    . = ALIGN(4);              /* Ensure alignment */
    _end = .;                  /* Define the end of memory */
}
