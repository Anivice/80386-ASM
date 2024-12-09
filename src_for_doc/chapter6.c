__asm__(
    ".intel_syntax noprefix                 \n\t"
    "__global_start:                        \n\t"
    ".short __global_end - __global_start   \n\t"
    "jmp __start                            \n\t"
    ".att_syntax prefix                     \n\t");

static void __start__ (void)
{
    __asm__ __volatile__(".intel_syntax noprefix    \n\t"
        "__start:                                   \n\t"
        "mov byte ptr [ds:0x00], 'S'     \n\t"
        "mov byte ptr [ds:0x02], 'y'     \n\t"
        "mov byte ptr [ds:0x04], 's'     \n\t"
        "mov byte ptr [ds:0x06], 't'     \n\t"
        "mov byte ptr [ds:0x08], 'e'     \n\t"
        "mov byte ptr [ds:0x0A], 'm'     \n\t"
        "mov byte ptr [ds:0x0C], ' '     \n\t"
        "mov byte ptr [ds:0x0E], 'i'     \n\t"
        "mov byte ptr [ds:0x10], 's'     \n\t"
        "mov byte ptr [ds:0x12], ' '     \n\t"
        "mov byte ptr [ds:0x14], 'i'     \n\t"
        "mov byte ptr [ds:0x16], 'n'     \n\t"
        "mov byte ptr [ds:0x18], ' '     \n\t"
        "mov byte ptr [ds:0x1A], '3'     \n\t"
        "mov byte ptr [ds:0x1C], '2'     \n\t"
        "mov byte ptr [ds:0x1E], 'b'     \n\t"
        "mov byte ptr [ds:0x20], 'i'     \n\t"
        "mov byte ptr [ds:0x22], 't'     \n\t"
      ".att_syntax prefix\n\t");

    __asm__("hlt");
    __asm__("jmp .");
}

__asm__("__global_end:\n\t");
