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
        "__sys_halt: hlt                    \n\t"           \
        "jmp __sys_halt                     \n\t"           \
        ".att_syntax prefix                 \n\t")

static void print_at_loc(const char character, int loc)
{
    __VOLATILE_INLINE_ASM__("mov ecx, 0x10");
    __VOLATILE_INLINE_ASM__("mov es, ecx");
    loc *= 2;
    __asm__ __volatile__(
        "mov %0, %%ebx               \n\t"  // Move 'loc' into ebx
        "mov %1, %%al                \n\t"  // Move 'character' into al
        "movb %%al, %%es:(%%ebx)     \n\t"  // Store the byte at the location pointed by ebx
        :
        : "r"(loc), "r"(character)          // Input operands: loc -> any register, character -> any register
        : "eax", "ebx", "memory"            // Clobbered registers and memory
    );
}

const char * string = "Hello World!";

void * deference(unsigned int label)
{
    return (void*)label;
}

static void __start__ (void)
{
    int i = 0;
    char c = string[i];
    unsigned int label = (unsigned int)(void*)string;
    // while (string[i] != 0)
    // {
    //     print_at_loc(string[i], i);
    //     i++;
    // }
    __END_POINT__();
}

__asm__("__global_end:\n\t");
