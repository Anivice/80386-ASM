

__asm__(".intel_syntax noprefix\n\t"
    "nop\n\t"
    "nop\n\t"
    "nop\n\t"
    "nop\n\t"
    "nop\n\t"
    ".att_syntax prefix\n\t"
);

void start(void)
{
    __asm__ __volatile__("nop");
    __asm__ __volatile__("nop");
    __asm__ __volatile__("nop");
    __asm__ __volatile__(".intel_syntax noprefix\n\t"

      "mov byte ptr [0x00], 'S'     \n\t"
      "mov byte ptr [0x02], 'y'     \n\t"
      "mov byte ptr [0x04], 's'     \n\t"
      "mov byte ptr [0x06], 't'     \n\t"
      "mov byte ptr [0x08], 'e'     \n\t"
      "mov byte ptr [0x0A], 'm'     \n\t"
      "mov byte ptr [0x0C], ' '     \n\t"
      "mov byte ptr [0x0E], 'i'     \n\t"
      "mov byte ptr [0x10], 's'     \n\t"
      "mov byte ptr [0x12], ' '     \n\t"
      "mov byte ptr [0x14], 'i'     \n\t"
      "mov byte ptr [0x16], 'n'     \n\t"
      "mov byte ptr [0x18], ' '     \n\t"
      "mov byte ptr [0x1A], '3'     \n\t"
      "mov byte ptr [0x1C], '2'     \n\t"
      "mov byte ptr [0x1E], 'b'     \n\t"
      "mov byte ptr [0x20], 'i'     \n\t"
      "mov byte ptr [0x22], 't'     \n\t"

      ".att_syntax prefix\n\t");

    int a = 12;
    a++;
    int c = a;
    c--;
    __asm__ __volatile__("nop");
    __asm__ __volatile__("nop");
    __asm__ __volatile__("nop");
}
