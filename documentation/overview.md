# Overview

---

## Intel 8086

The Intel 8086, introduced in 1978, was Intel's first 16-bit processor. 
Its powerful capabilities made it both a groundbreaking and highly successful product. 
Due to its popularity, countless software applications were designed specifically 
for the 8086. As a result, when Intel began designing its next processor, 
ensuring compatibility with the 8086 became a top priority.

Therefore, understanding the 8086 architecture is essential when
beginning to learn about the 80386.

### Registers
The 8086 featured eight 16-bit general-purpose registers, named:
`AX`, `BX`, `CX`, `DX`, `SI`, `DI`, `BP`, and `SP`.

The first four registers, `AX`, `BX`, `CX`, and `DX`, can each be divided into two 8-bit registers:
`AH` (high byte) and `AL` (low byte) for `AX`,
`BH` and `BL` for `BX`,
`CH` and `CL` for `CX`,
and `DH` and `DL` for `DX`.

### Segmentation

#### Why Segmented Memory Addressing in 16-bit Processors?

Due to the limited 16-bit memory bus of the 8086 processor,
the maximum memory it can theoretically access is $2^{16} = 65,536 \text{ bytes}$. 
This equates to $\frac{65,536}{1,024} = 64 \text{ KB}$,
which is clearly insufficient for operating systems to function effectively.

To address this limitation, segmented memory access was introduced.
Segmented memory utilizes two key registers:
the **Code Segment (CS)** and the **Data Segment (DS)**,
enabling more efficient memory management and access.

As a result, constant addresses in the code can be represented as *offsets*.
By setting the `CS` and `DS` registers appropriately, the processor can correctly
and efficiently access the corresponding memory addresses.

#### Segmented Memory Addressing in 8086

The 8086 processor features four registers specifically designed for
segmented memory addressing: `CS`, `DS`, `ES`, and `SS`.

- **`CS` (Code Segment)**: Used to access the code segment of memory.
- **`DS` (Data Segment)**: Used for accessing data.
- **`ES` (Extra Segment)**: Facilitates operations that require access to two different data segments.
                            Used Together with `DS`.
- **`SS` (Stack Segment)**: Handles stack operations, which will be discussed later.

There is a special register called `IP` (Instruction Pointer),
which is exclusively accessible to the processor.
The `IP` register works in conjunction with the `CS` (Code Segment) register,
serving as an offset within the Code Segment to determine the next instruction to execute.

So, how much memory can the 8086 access in total?  
The answer is from `0x00000` to `0xFFFFF`, giving the 8086 a 20-bit address bus.

The physical address is calculated using the following formula:
$$\text{PhysicalAddress} = (\text{SegmentRegister} \ll 4) + \text{offset}$$

In this formula, the segment register is shifted 4 bits to the left 
(equivalent to multiplying by 10 in base-16 or 16 in base-10), 
and the offset (16-bit) is added to calculate the physical address.

Without segments overlapping, we can have a total of $65,536$ segments.
The segment addresses range from `0x0000` to `0xFFFF`,
with each segment spanning $16 \text{ bytes}$.

Without segments overlapping, we can have a total of $16$ segments.
The segment addresses range from `0x0000` to `0x000F`,
with each segment spanning $64 \text{ KB}$.

The standard notation for memory addressing in the 8086 architecture is
represented as follows:
$$\text{SegmentAddress}:\text{Offset}$$

---

[Chapter 2]()

[Back To Main Page](../README.md)
