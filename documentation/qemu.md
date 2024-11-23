# QEMU

## BIOS (Basic I/O System)

The Intel 8086 processor can access up to 1 MB of memory, 
with address ranges from `0x00000` to `0xFFFFF`.
However, this 1 MB is not exclusively allocated to DRAM (Dynamic Random Access Memory).
The architecture of the Intel 8086 divides the memory into two primary segments:

| Memory Range      | Device                                 |
|-------------------|----------------------------------------|
| `0x00000-0x9FFFF` | Dynamic Random Access Memory (DRAM)    |
| `0xF0000-0xFFFFF` | Read Only Memory (ROM)                 |

In the Intel 8086 processor, the memory is segmented into distinct
areas over its 1 MB addressable space. DRAM (Dynamic Random Access Memory)
is mapped to the lower 640 KB, from address `0x00000` to `0x9FFFF`.
The upper 64 KB, from `0xF0000` to `0xFFFFF`, is designated for
Read Only Memory (ROM), typically containing the system's firmware.
The middle region between these areas is reserved for external devices,
which will be discussed in more detail later.

When the Intel 8086 processor initializes, the Code Segment (CS) register is set to
`0xFFFF` and the Instruction Pointer (IP) register to `0x0000`.
Consequently, the address for the first instruction to be executed is
calculated by the processor as `0xFFFF0` (`0xFFFF` shifted left by 4 bits plus `0x0000`),
which falls within the ROM area in the upper 64 KB of the memory map.
This ensures that the 8086 starts executing from a fixed, read-only location,
typically where the system's firmware or bootstrap loader is stored.

## Hard Disk, HDD

A hard disk is a storage device used to store substantial amounts of data.
Below is an image depicting the internal structure of a hard disk:
![HDD Internal Structure](./hard-drive.png)

Additionally, the video below demonstrates the startup
and shutdown processes of a hard disk:
![HDD Startup and Shutdown](./HDD_Startup_and_Shutdown.gif)

