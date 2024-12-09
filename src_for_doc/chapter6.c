__asm__(
    ".intel_syntax noprefix                 \n\t"
    "__global_start:                        \n\t"
    ".short __global_end - __global_start   \n\t"
    "jmp __start                            \n\t"
    ".att_syntax prefix                     \n\t");

#define __INLINE_ASM__(asm)                 \
    __asm__(                                \
        ".intel_syntax noprefix\n\t"        \
        asm                                 \
        "\n\t.att_syntax prefix\n\t")

#define __VOLATILE_INLINE_ASM__(asm)        \
__asm__ __volatile__(                       \
        ".intel_syntax noprefix\n\t"        \
        asm                                 \
        "\n\t.att_syntax prefix\n\t")

#define __STARTING_POINT__() __asm__ __volatile__(".intel_syntax noprefix\n\t__start:\n\t")
#define __END_POINT__() __asm__("__halt_system: hlt\n\tjmp __halt_system\n\t");

static void __start__ (void)
{
    __STARTING_POINT__();

    __VOLATILE_INLINE_ASM__("mov byte ptr [ds:0x00], 'S'");
    __VOLATILE_INLINE_ASM__("mov byte ptr [ds:0x02], 'y'");
    __VOLATILE_INLINE_ASM__("mov byte ptr [ds:0x04], 's'");
    __VOLATILE_INLINE_ASM__("mov byte ptr [ds:0x06], 't'");
    __VOLATILE_INLINE_ASM__("mov byte ptr [ds:0x08], 'e'");
    __VOLATILE_INLINE_ASM__("mov byte ptr [ds:0x0A], 'm'");
    __VOLATILE_INLINE_ASM__("mov byte ptr [ds:0x0C], ' '");
    __VOLATILE_INLINE_ASM__("mov byte ptr [ds:0x0E], 'i'");
    __VOLATILE_INLINE_ASM__("mov byte ptr [ds:0x10], 's'");
    __VOLATILE_INLINE_ASM__("mov byte ptr [ds:0x12], ' '");
    __VOLATILE_INLINE_ASM__("mov byte ptr [ds:0x14], 'i'");
    __VOLATILE_INLINE_ASM__("mov byte ptr [ds:0x16], 'n'");
    __VOLATILE_INLINE_ASM__("mov byte ptr [ds:0x18], ' '");
    __VOLATILE_INLINE_ASM__("mov byte ptr [ds:0x1A], '3'");
    __VOLATILE_INLINE_ASM__("mov byte ptr [ds:0x1C], '2'");
    __VOLATILE_INLINE_ASM__("mov byte ptr [ds:0x1E], 'b'");
    __VOLATILE_INLINE_ASM__("mov byte ptr [ds:0x20], 'i'");
    __VOLATILE_INLINE_ASM__("mov byte ptr [ds:0x22], 't'");

    __END_POINT__();
}

__asm__("__global_end:\n\t");
