__asm__(
    ".intel_syntax noprefix                 \n\t"
    "__global_start:                        \n\t"
    "jmp __start__                          \n\t"
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

// Since __start__ is not called by C functions, but by far call from loader directly from assembly,
// we have to override the default exit handling inside C code.
// The reason why we actually jump to __start__ is to ensure the correct stack segmentation initialization process
// so that we can obtain the correct variable values in C.
#define __END_POINT__()                                     \
    __asm__(                                                \
        ".intel_syntax noprefix             \n\t"           \
        "add esp, 0x10                      \n\t"           \
        "pop ebp                            \n\t"           \
        "retf                               \n\t"           \
        ".att_syntax prefix                 \n\t")

static int add(const int a, const int b)
{
    return a + b;
}

static void __start__ (void)
{
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

    int b = add(1, 3);

    __END_POINT__();
}

__asm__("__global_end:\n\t");
