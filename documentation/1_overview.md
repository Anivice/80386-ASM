# Chapter 1: Overview

## Intel 8086

The Intel 8086, firstly introduced back in 1978, was Intel's first 16-bit processor.
Intel 8086 was very iconic and was also very popular in both offices and domestic home use.
Popularity attracted vendor support, and countless software was developed for Intel 8086.
According to the design theory of compatibility, especially given how popular the original
8086 was, Intel ensured their successors' compatibility towards the original 8086.

That is why, understanding the original old 8086 before we talk about Intel 80386 is such
a priority.

### Registers
Intel 8086 has eight registers that can be used in various contexts, which are:
`AX`, `BX`, `CX`, `DX`, `SI`, `DI`, `BP`, and `SP`.

The first four registers, `AX`, `BX`, `CX`, and `DX`, can each be further divided into
two 8-bit registers:
`AH` (high byte) and `AL` (low byte) for `AX`,
`BH` and `BL` for `BX`,
`CH` and `CL` for `CX`,
and `DH` and `DL` for `DX`.

### Segmentation

#### Why Segmented Memory Addressing in 16-bit Processors?

Due to the limited 16-bit registers of the old Intel 8086,
the maximum memory it can theoretically access is $2^{16} = 65,536 \text{ bytes}$, meaning,
$\frac{65,536}{1,024} = 64 \text{ KB}$. 64 KB, even at that time,
was extremely limited. Even billionaires like Bill Gates said he needs 640 KB for his work
(and apparently all of his tasks can be done using that 640 KB memory: 
"640K software is all the memory anybody would ever need on a computer." Well, maybe
that why Windows 11 eats 32 out of 64 GB total memory on my laptop on startup.)

To address this limitation, Intel introduced maybe the weirdest memory addressing mode
in computer history: Segmentation, or segmented addressing.
Segmented addressing effectively allows CPU to access memory beyond 16-bit BUS scope,
which, in the context of Intel 8086, was 20-bit (1 MB).

#### Segmented Memory Addressing in 8086

The 8086 processor uses four registers specifically designed for
segmented memory addressing: `CS`, `DS`, `ES`, and `SS`.

- **`CS` (Code Segment)**: Serve as a segmentation address for code addressing.
- **`DS` (Data Segment)**: Serve as a segmentation address for data addressing.
- **`ES` (Extra Segment)**: Provides convenient access to two different data segments.
                            In most contexts, it is usually used together with `DS`.
- **`SS` (Stack Segment)**: Segmentation address for stack, which will be discussed later.

There is a special register called `IP` (Instruction Pointer),
which is exclusively accessible to the processor itself only.
The `IP` register works in conjunction with the `CS` (Code Segment) register,
serving as an offset within the Code Segment to determine where the next instruction
pending for execution is.

So, how much memory can the 8086 access in total?  
As we had discussed before, it is from `0x00000` to `0xFFFFF`, a 20-bit address bus
mapping a total of 1 MB memory.

Segmented address is not linear, and how can Intel 8086 access such a wide area beyond
16-bit BUS limitation? Well, we can take a peak from the following formula converting
the segmented address to linear address:

$$\text{PhysicalAddress} = (\text{SegmentRegister} \ll 4) + \text{offset}$$

In this formula, the segment register is shifted 4 bits to the left 
(equivalent to multiplying by 10 in base-16 or 16 in base-10), 
and the offset (16-bit) is then added to calculate the physical address.
This is how Intel 8086 access the area beyond the 16-bit scope.
However, we have to be careful of overflowing, since the address bus is 20-bit in width,
but the extreme condition of calculation process, $\text{0xFFFF} \ll 4 + \text{0xFFFF}$,
which is theoretically the maximum address for both `SegmentRegister` and `offset`,
equals to `0x10FFEF`, which is beyond 20-bit and will cause an overflow.

> A little trivia here:
> Without segmentations overlapping, we can have a total of $65,536$ segmentations.
> The segment addresses range from `0x0000` to `0xFFFF`,
> with the size of each segmentation being $16 \text{ bytes}$.
> Again, without segmentations overlapping, we can have a total of $16$ segmentations.
> The segment addresses range from `0x0000` to `0x000F`,
> with each segmentation spanning $64 \text{ KB}$.

The standard notation for memory addressing in Intel syntax is represented as follows:

$$\text{SegmentAddress}:\text{Offset}$$

> There are other syntax for memory addressing, like AT&T, and I **personally** think AT&T
> syntax is absolutely trash. The human readability for them is terrible, they are hard
> to format, hard to write, and hard to understand. Using AT&T syntax is a good way to
> encrypt my assembly by hand and drastically decrease its maintainability.

---

[Chapter 2](2_assembly_and_nasm.md)

[Back to the Main Page](../README.md)

