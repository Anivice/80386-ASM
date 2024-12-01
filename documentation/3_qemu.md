# Chapter 3: QEMU

## BIOS (Basic Input Output System)

The Intel 8086 processor can access up to 1 MB of memory, as we have discussed before,
with the address ranges from `0x00000` to `0xFFFFF`.
However, this 1 MB is not solely allocated to DRAM (Dynamic Random Access Memory).
Intel 8086 divides the memory into multiple parts, and here we will discuss the following
two:

| Memory Range      | Device                                 |
|-------------------|----------------------------------------|
| `0x00000-0x9FFFF` | Dynamic Random Access Memory (DRAM)    |
| `0xF0000-0xFFFFF` | Read Only Memory (ROM)                 |

In the Intel 8086 processor, the memory is divided into distinct
areas over its 1 MB addressable space. DRAM (Dynamic Random Access Memory)
is mapped to the lower 640 KB (yeah you can see where Bill Gates got his 640 KB from huh,
wonder if he is still worshipping his 640 KB computers while having Windows 11 eating
half of my RAM), from address `0x00000` to `0x9FFFF`.
The upper 64 KB, from `0xF0000` to `0xFFFFF`, is designated for
Read-Only Memory (ROM), or BIOS-ROM, typically containing the system's BIOS firmware.
The middle region between these areas is reserved for external devices and such,
which we will discuss later.

When the Intel 8086 initializes, the Code Segment (CS) register is set to `0xFFFF` and
the rest of the registers are set to `0x0000`.
This process points the first instruction to be executed to be `0xFFFF0`
(`0xFFFF` shifted left by 4 bits plus `0x0000`),
which is at the starting point at the upper 64 KB of the memory map.
This ensures that the 8086 starts by executing the BIOS firmware, which usually involves
hardware health validation and other self-inspection processes, before loading the
operating system.

## Hard Disk Drive, HDD

A hard disk drive (HDD), or hard disk, is a storage device used to store large amounts of data.
Nowadays, we usually use SSDs, they are considerably faster when it comes to read/write with,
well, considerably higher price in some cases.
The difference between a SSD and an HDD is their internal structures.

### Hard Disk Internal Layout

Below is an image of the internal structure of a hard disk:

<div style="text-align: center;">
  <img src="./hard-drive.png" alt="HDD Internal Structure">
</div>

As illustrated above, a hard disk consists of one or more metal disks mounted on a motor.
The "head," which reads and writes data, is attached to a metal arm, powered by a separate motor.

The disk motor operates at a relatively constant speed, which varies among different disks.
Typically, the speed ranges from $5,400$ to $7,200$ RPM (Revolutions Per Minute, ***NOT Round per Minute***).
However, some hard disks achieve speeds of $10,000$ RPM or even $15,000$ RPM.
These high-speed disks are generally designed for high-performance applications, primarily in server setups.

#### Head

Each disk inherently features two sides (obviously), and accordingly, there are two heads per disk.
These heads are systematically labeled from top to bottom,
starting at 0 and increasing sequentially: 0, 1, 2, 3, and so forth.

All the heads are grouped together, and when the head motor operates,
it moves all the heads simultaneously to the same position.

#### Track and Cylinder

When the disk spins and the head remains in a fixed position above the disk,
the path scanned by the head creates a loop. This path is referred to as a
**track**. Since all heads move in unison, the tracks aligned at the same
position collectively form what is known as a **cylinder**.

> **Note:** Each track and cylinder is assigned a unique index number,
> starting from 0 and increasing incrementally from the outer edge of
> the disk towards the center.

**Cylinder** is a concept designed to optimize I/O speed.
The ideal I/O pattern involves maintaining the head position as much as possible,
as seeking time for the head is generally extensive to CPU.
The worst case for a filesystem is when its data being dispersed across the disk.
Data should be distributed across different tracks that are positioned at the same cylinder,
ensuring optimal access efficiency.

#### Sectors

Each track is divided into atomic units known as sectors.
The number of sectors per track can vary according to the manufacturer's design,
but it is commonly 63 sectors (I don't know if this is outdated information).
Typically, each sector has a capacity of 512 bytes (True across most of the vendors).
**Notably, each sector is also assigned an index number which,
in the most gruesome and despicable way possible to punish anyone who chose the computer science major,
begins at ***1*** rather than ***0***.**

A sector begins with the sector header, which contains crucial information for
the disk's microcontroller, including the current **head**, **track**, and
**sector** number. This header also includes various flags that indicate
the health, replacement sector in case of malfunction in reserved area, and other information useful to the
microcontroller.

Additionally, the video below demonstrates the startup and shutdown processes of a hard disk:
> ⚠ USER DISCRETION IS ADVISED ⚠: the following video contains imagery of a hard disk turned inside out.

<div style="text-align: center;">
  <a href="https://www.youtube.com/watch?v=TqV8AO57LQc" target="_blank">
    HDD Startup and Shutdown
  </a>
</div>

## Cylinder 0, Head 0, Sector 1

After the initialization process in ROM-BIOS, the code in ROM-BIOS will attempt
to jump to an area specified in the BIOS settings (the setting is usually called boot device).
When the BIOS is configured to boot from a hard disk drive, the first 512 bytes of the hard
disk - specifically from Head 0, Cylinder 0, Sector 1, known as the *boot sector* - are
loaded into memory at the address `0x0000:0x7c00`.
This address is chosen because the designer at that time went through some emotional trauma
that is unthinkable, unimaginable and impossible to understand for a regular human being (so was the decision)
that he/she chose to traumatize the entire industry for that.

## Logical Block Address, LBA

CHS (Cylinder, Head, Sector) mode was challenging to operate (yeah, I wonder why)
and was already considered a legacy system by the 1990s.
**Logical Block Addressing** (LBA) system was developed to specifically heal the mental disorders caused this crazy
operation mode.
LBA simplifies addressing by linearizing the disk's geometry into a
single addressable space.
The linear addressing scheme by nature means it maps disk data in a continuous range of logical block addresses,
making hardware details like cylinder, head, and sector invisible to the user or operating system.
This simplifies storage management and is especially useful as disk optimization using CHS mode became obsolete.

> **Note:** LBA (Logical Block Addressing) assigns linear block addresses and maps the disk in continuous logical blocks,
> where the size of each block is predefined, typically set to 512 bytes.

The calculation for LBA is as follows:

$$\text{LBA} = (\text{Cylinder} \times \text{HeadCount} \times
\text{SectorCountOnTracks}) + (\text{Head} \times \text{SectorCountOnTracks}) +
(\text{Sector} - 1)$$

**where**

- **Cylinder**: The cylinder number.
- **HeadCount**: The total number of heads in the disk.
- **SectorCountOnTracks**: The number of sectors per track.
- **Head**: The current head number.
- **Sector**: The current sector number (note that sector indexing typically starts at 1, which is why the formula subtracts 1).

### Example:

Here is an example of using the above formula to calculate an arbitrary address on HDD:

**Disk Geometry:**
- Total Cylinders: 1000
- Heads per Cylinder: 10
- Sectors per Track: 50

**Random Location (CHS):**
- Cylinder: 500
- Head: 5
- Sector: 25

$$\text{LBA} = (500 \times 10 \times 50) + (5 \times 50) + (25 - 1)$$

$$\text{LBA} = 250,000 + 250 + 24 = 250,274$$

## Main Boot Sector (MBR)

### Text Mode
The default resolution for BIOS text mode is set at 25 rows by 80 columns,
which allows for a display of 2,000 characters on the screen. In this mode,
the Video RAM (VRAM) is mapped to the memory range `0xB8000` to `0xBFFFF`.

A valid character in this context is represented by 16-bit data, consisting
of two parts. The first part is the 8-bit ASCII code, which identifies the
specific character displayed. The second part is an 8-bit attribute code,
formatted as `KRGBIRGB`, which determines the visual attributes such as color
and blinking of the character， if your screen supports them, that is.

| Bit Pattern | Attribute               | Description                                             |
|-------------|-------------------------|---------------------------------------------------------|
| K           | Blink/Bright Background | 0 = No Blink, 1 = Blink or Bright Background (varies)   |
| RGB         | Background Color        | Sets the background color using RGB values              |
| I           | Foreground Intensity    | 0 = Normal, 1 = High Intensity/Bright                   |
| RGB         | Foreground Color        | Sets the foreground color using RGB values              |

Here is an example that shows an 'A' on the screen:

```nasm
[bits 16]           ; 16-bit mode
[org 0x7C00]        ; Boot sector loads at 0x7C00

    ; set extra segment
    mov ax, 0xB800
    mov es, ax
    
    ; set the first character on screen as A with
    ; green text and blue background 
    mov byte [es:0x0000], 'A'
    mov byte [es:0x0001], 0x9A
    
    jmp $           ; infinite loop, so the processor don't wonder off
```

That's some good stuff, huh.
But, for a BIOS to recognize that MBR is bootable, the last two digits
of the sector must be `0x55` and `0xAA`. Therefore, we have to add a bit more lines:

```nasm
    times 510-($-$$) db 0
    dw 0xAA55
```

The line `times 510-($-$$) db 0` in NASM assembly code serves as a method
to fill a specific amount of space with zeros, up to a specified offset
within the assembly code file. Here's a breakdown of each component in the
line to clarify its function:

1. **`times`**: This is a NASM directive used to repeat the following
                instruction or data declaration a specified number of times.

2. **`510-($-$$)`**: This is the expression that calculates how many times
                     the following data declaration should be repeated.
    - **`510`**: This represents the total number of bytes that should precede
                 the boot signature in the boot sector. Since the boot signature
                 should be at byte 510 and 511 in a 512-byte boot sector, you start
                 filling from byte 0 up to byte 509 with the actual boot code or
                 padding.
    - **`$`**: This is a special NASM symbol that represents the current assembly
               position as an offset from the start of the section.
    - **`$$`**: This is another special NASM symbol that represents the start address
                of the current section (in this case, set by `ORG 0x7C00`).
    - **`$ - $$`**: This calculates the current offset in bytes from the start
                    of the section.
    - **`510-($-$$)`**: The result of this expression tells NASM how many bytes of
                        padding are needed to reach the 510th byte.

3. **`db 0`**: This declares a byte of data with the value `0`.
               Combined with the `times` directive, it fills the calculated number
               of bytes with zeros.

### Debug

Debugging in 16-bit real mode with QEMU sucks enormous f**king d*ck since GDB knows absolutely nothing about segmented
addressing (how did people even develop MBR in the past with QEMU, were they using the old `bochs` the whole time?)
Unfortunately for them, fortunately for us, there are automated tools specifically cures this mental breakdown.

```bash
    # Make sure you are at the root of the project tree and launched QEMU
    cd gdb
    ./debug_in_real_mode.sh
```
> **Note:** This script doesn't care about your current `$PWD` however, you can use a relative path or an absolute path
> to launch it, and it won't affect your current PWD settings in any way, without a multitasking design built in mind.
> But it is an interactive tool, you are not supposed to use that shell feature anyway.

```bash
    # disassemble
    disassemble [Starting Addr], +[Length]
    disassemble [Starting Addr], [End Addr]
    
    # step over
    stepi
    
    # set break at address
    break *[Addr]
    
    # continue after break
    continue
    
    # show registers
    info registers
    
    # show memory
    # Example, `x/10hx` shows 32 bytes memory area starting from 0x7C00 in 16-bit hexadecimal format
    #     10: Number of 16-bit words to display (10 = 10 words = 20 bytes).
    #     h:  Interpret as half-word (16-bit, since QEMU is 32bit atomic).
    #     x:  Display in hexadecimal format.
    #     0x7C00: The starting address to examine.
    x/10hx 0x7C00
    
    # Show context System Context: Includes the stack, data segment (DS:SI),
    # extra segment (ES:DI), general-purpose registers, flags, 
    # and queued instructions.
    # Note that context command is invoked every time stepi is invoked
    context
```

> Now, you may say: "Hay, Anivice, this is just cancer.
> We can use BOCHS, and it works just fine, if not better."
> I know, I know, I love the old BOCHS as much as the next person, and I know QEMU+GDB
> is absolutely lame in real mode, but, QEMU+GDB can be really powerful in protected mode along with IDEs like CLion.
> I'm using CLion right now,
> and it can natively set breakpoints, access stack frames, set watchers, and all other tasks that are
> just a pain in the a** to do in command line.
> So, bear with me, it gets good.

---

[Chapter 3.1](./3.1_assembly_example_movsb.md)

[Back to the Main Page](../README.md)

