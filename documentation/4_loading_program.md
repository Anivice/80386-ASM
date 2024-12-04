# Chapter 4: Loading a Program

The boot sector has a maximum size of 512 bytes.
Thus, any complicated programming is off the table, not even with assembly.
More than often, it only serves as a loader to load more complicated programs into memory.
These programs are not necessarily operating system kernels but can be sophisticated tools like advanced
bootloaders (that load other more complicated programs, again, not necessarily operating system kernels. Yeah, I know).

Now, this chapter is one of those that is long and tedious, and potentially confusing.
I'll try my best to negate all these factors, but if they still persist, I apologize in advance.

In this chapter, we have the following goals to achieve:

1. Access hardware beyond processor scope.
2. Program loading process that demonstrates the relocation of segmentations.

The Master Boot Record (MBR) we attempt to write this time is a loader that loads the program starting at the next sector.
But first, we need to know how to operate IDE/ATA Hard Disks using I/O Ports on CPU to read specific data.

## Read From a Disk

Line 1 to 5 starts as usual, we define offset to be `0x7C00`, starting as 16bit mode, and jump to start label.
But, right after that, we defined the following constants:

```nasm
  6  IO_PORT                 equ 0x1F0
  7  IO_ERR_STATE            equ 0x1F1
  8  IO_BLOCK_COUNT          equ 0x1F2
  9  IO_LBA28_0_7            equ 0x1F3
 10  IO_LBA28_8_15           equ 0x1F4
 11  IO_LBA28_16_23          equ 0x1F5
 12  IO_LBA28_24_27_W_4_CTRL equ 0x1F6
 13  IO_REQUEST_AND_STATE    equ 0x1F7
 14  
 15  IO_READ                 equ 0x20
```

Before we delve into the meaning behind these constants, we have to understand two instructions: `in` and `out`.
`in` reads data from a port on CPU, and `out` output data to a port.
Different from the registers inside CPU, these ports, or pin, connects to external hardware beyond CPU scope.
We can have a look with the pictures of an old CPU silicon die
(a piece of flat, usually square, silicon with circuits on it)
taken by Ken Shirriff, who has vast knowledge on these old school pieces of hardware:
![CPU DIE](die-labeled-w-text.png)

The bond wire provides a connection between the silicon die and the external hardware,
usually, expose themselves as pins outside the chip package.

Each communication port has a specific address to identify themselves. Thus, the port numbers listed from line 6 to 13.
CPU send and receive data using `in` and `out` instructions, which only takes `al` or `ax` as 8bit or 16bit to send or
receive data, and `dx` or constants to specify the ports, meaning:

```nasm
    in  ax, dx
    in  al, 0x37

    out dx,   al
    out 0x37, ax
```

> **Important Note:** While `dx` can specify port addresses up to 16-bit width,
> constants on the other hand, **can only address 8-bit port addresses**.
> It means ```in al, 0x1F0``` is ***NOT*** a valid operation,
> but NASM **might allow it** in the compilation process, which it really shouldn't.
> Do be cautious.

Now, unlike microprocessors, these pins on CPU are not connected to the hardware like hard disk or GPU directly.
They are connected to what we know as Input & Output Controller Hub, or ICH bridge.
CPU connects itself to ICH, and ICH then connects itself to Bus.
Bus is a huge cable line consisting of multiple cables,
where ultimately all external devices, like sound cards, GPUs, keyboards, connect.

We explain each port as we go.

## Read From Hard Disk

Reading from hard disks consists of multiple steps:

### Step 1: specify the disk sectors I'd like to read:

```nasm
 17  start:
 18      ; Step 1: Set number of the blocks/sectors pending to read
 19      mov     al,     0x01                ; 1 block/sector
 20      mov     dx,     IO_BLOCK_COUNT      ; set out port
 21      out     dx,     al
```

As you can see, we first load `IO_BLOCK_COUNT` port address into `dx`, then load the sectors we want to read into `al`.
Since it is an 8-bit port, the maximum sectors we can read at one time are 256.

> **Note:** You may ask: why not 255? Here is its logic in C:
> ```C
>   uint8_t sector_count = 0x00;
>   do {
>       /* Read Operation */
>   } while (--sector_count != 0);
> ```
> Since the microprocessor does a ```--sector_count``` first, which is basically a `dec` instruction,
> the original `0x00` becomes `-1`, which is an overflow.
> This overflow causes the 8-bit register to become `0xFF`, which is `255` in decimal, then continuing
> decreasing until it becoming `0`, which is when the operation ultimately finishes.
> As a result, we can ultimately read 256 sectors in total.
> However, depending on the vendors, this might not be true.
> Consider this as a hack, and a hack is never recommended and only supposed to serve as a temporary solution.

## Step 2: Specify the Starting Sector/Block Desired to Read

We have covered LBA before, it is a logic block addressing mode in hard disks.
Now, LBA has multiple different standards, which mainly have the differences in the addressing width.
A simple LBA addressing mode is 28 bits in width.
Twenty-eight bits gives us $2^{28} \times 512 = 268,435,456 \times 512 = 137,438,953,472 = 128 \text{GB}$ accessible disk space.
Remember, that was an era where owning a 2 GB disk is considered rich, 128 GB is usually unheard of.
Technology quickly evolves, normally we use 48-bit LBA mode to manage our disks now.
LBA 48 gives us $2^{48} \times 512 = 128 \text{PB}$ manageable disk,
equaling to $134,217,728$ GB addressable disk space, which is unheard of for personal use as of December 4th, 2024.

> **Note:** I know I use GB and GiB interchangeably, but in storage, GB and GiB are two different units.
> And by default, when I say GB, I mean GiB.
> I don't know why people tend to use that "GB" instead of GiB since that unit makes little sense to me.
> When we use "GB" instead of GiB, the calculation becomes: 1 GB = 1,000,000,000 bytes ($10^9$)
> (While 1 GiB = $1 \times 1024 \times 1024 \times 1024$ Bytes, which is what I always use).
> This might make sense for common users, but it causes a lot of inconveniences in programming.
> This unit makes LBA28's addressable space become 137.438 GB instead of a sensible integer (128).
> CPU is terrible, very imprecise, and resource-demanding when it comes to floating-points.
> That's why we tend to avoid that.

Now, we set the start block in LBA28.
The configuration is simple: we'd like to read the first block. Since LBA starts from 0, the number is
`0000 0000 0000 0000 0000 0000 0001`, which is, well, 1.
Now, `IO_LBA28_0_7`, `IO_LBA28_8_15`, `IO_LBA28_16_23` are easy to understand.
They are 8-bit width ports, and correspond to the bits in LBA28.

`IO_LBA28_24_27_W_4_CTRL`, however, is a bit different (four bits different, actually).
The following table is its higher four bits:

<table style="width: 100%; text-align: center; border-collapse: collapse;">
  <tr>
    <td style="border: 1px solid black; padding: 5px; width: 30px;">7</td>
    <td style="border: 1px solid black; padding: 5px; width: 30px;">6</td>
    <td style="border: 1px solid black; padding: 5px; width: 30px;">5</td>
    <td style="border: 1px solid black; padding: 5px; width: 30px;">4</td>
  </tr>
  <tr>
    <td style="border: 1px solid black; padding: 5px; width: 30px;" colspan="1">1</td>
    <td style="border: 1px solid black; padding: 5px; width: 30px;" colspan="1">CHS=0<br>LBA=1</td>
    <td style="border: 1px solid black; padding: 5px; width: 30px;" colspan="1">1</td>
    <td style="border: 1px solid black; padding: 5px; width: 30px;" colspan="1">Master=0<br>Slave=1</td>
  </tr>
</table>

The lower four bits are for LBA28 addressing, but the higher four bits are used for configuration.
We ignore the seventh and fifth bit for now, which is always 1 in our cases.
The configuration we actually want to pay attention to is the sixth and fourth bit.
The sixth bit sets our addressing mode, which, in our case, should be 1 (LBA).
The fourth bit is the disk we want to read.
IDE controller allows us to mount two disks on one cable.
When two disks are mounted simultaneously, one should be configured as "Master," and the other as "Slave."
(Seriously, I know a BDSM play when I see it).

The configuration for the higher bits should be `1110`, which stands for `[1] [LBA=1] [1] [IDE Master Disk=0]`,
LBA mode, read from IDE Master disk.

> A bit of information here: When you config the IDE disks, you actually have to wire two pins on the disk
> to tell the controller who is Master and who is Slave.
> There are these small devices called jump wires, as shown below:
> ![Jump Wire](JumpWire.png)
> These are female-female jump wires, connecting two male pins.
> ![Disk Master Slave](disk-master-and-slave.png)
> ![Disk Master Slave Side](disk-master-and-slave-side-view.png)
> The pins on the disk are two male pins (pins that poke out).
> ~~(On a total side note, whoever came up with these names is a real legend.)~~

```nasm
 23      ; Step 2 : Set the start block of LBA28
 24      mov     al,     0x01                ; second block, LBA starts from 0
 25      mov     dx,     IO_LBA28_0_7
 26      out     dx,     al
 27  
 28      xor     al,     al
 29      mov     dx,     IO_LBA28_8_15
 30      out     dx,     al
 31  
 32      mov     dx,     IO_LBA28_16_23
 33      out     dx,     al
 34  
 35      mov     al,     11100000B           ; 1 [LBA=1/CHS=0] 1 [IDE Master=0/IDE Slave=1] 0 0 0 0
 36      mov     dx,     IO_LBA28_24_27_W_4_CTRL
 37      out     dx,     al
```

## Step 3: Request Read

Now that we have written the relevant information to the controller, we can tell the controller that we'd
like to read some data from the disk.

```nasm
 39      ; Step 3: Request ICH I/O Read
 40      mov     dx,     IO_REQUEST_AND_STATE
 41      mov     al,     IO_READ
 42      out     dx,     al
```

By writing to the port `IO_REQUEST_AND_STATE` with `IO_READ`, we just requested the controller to read the disk.

## Step 4: Wait for Disk to Finish Operation

`IO_REQUEST_AND_STATE` is both an output port and an input port.
That's why we call it "IO_REQUEST_AND_STATE," it outputs IO request and gets IO state.
Now, there are only three bits we are interested in: seventh, third, and zeroth, and they are `BSY`, `DRQ` and `ERR`.

<table style="width: 100%; text-align: center; border-collapse: collapse;">
  <tr>
    <td style="border: 1px solid black; padding: 5px; width: 30px;">7</td>
    <td style="border: 1px solid black; padding: 5px; width: 30px;">6</td>
    <td style="border: 1px solid black; padding: 5px; width: 30px;">5</td>
    <td style="border: 1px solid black; padding: 5px; width: 30px;">4</td>
    <td style="border: 1px solid black; padding: 5px; width: 30px;">3</td>
    <td style="border: 1px solid black; padding: 5px; width: 30px;">2</td>
    <td style="border: 1px solid black; padding: 5px; width: 30px;">1</td>
    <td style="border: 1px solid black; padding: 5px; width: 30px;">0</td>
  </tr>
  <tr>
    <td style="border: 1px solid black; padding: 5px; width: 30px;" colspan="1">BSY</td>
    <td style="border: 1px solid black; padding: 5px; width: 30px;"></td>
    <td style="border: 1px solid black; padding: 5px; width: 30px;"></td>
    <td style="border: 1px solid black; padding: 5px; width: 30px;"></td>
    <td style="border: 1px solid black; padding: 5px; width: 30px;" colspan="1">DRQ</td>
    <td style="border: 1px solid black; padding: 5px; width: 30px;"></td>
    <td style="border: 1px solid black; padding: 5px; width: 30px;"></td>
    <td style="border: 1px solid black; padding: 5px; width: 30px;" colspan="1">ERR</td>
  </tr>
</table>

When `BSY` is `1`, controller tells CPU that it is busy reading data, and is not ready to exchange data.
When `DRQ`, which stands for `Data Request`, is `1`, and `BSY` is `0`, ICH indicates that the controller
is done reading and is ready to exchange data.
So, we have to wait until that happens.

> **Important Note:** You have to wait for the operation to complete for every single sector!
> Otherwise, the input port will provide a bunch of zeros. 

```nasm
 44      ; Step 4: Wait for the operation to finish
 45      .wait_for_disk_ops:
 46          in          al,         dx
 47          and         al,         10001000B
 48          cmp         al,         00001000B
 49          jne         .wait_for_disk_ops
```

The above code ignores error handling for simplicity.
Now, if you do encounter an error, `ERR` will be marked as `1` and `IO_ERR_STATE` will provide the error code.
The error code varies across different systems, but the following is a reference.

| **Bit** | **Name**                       | **Description**                                                                |
|---------|--------------------------------|--------------------------------------------------------------------------------|
| **0**   | ABRT (Abort)                   | Command aborted by host.                                                       |
| **1**   | TK0NF (Track 0 Not Found)      | Track 0 not found.                                                             |
| **2**   | AMNF (Address Mark Not Found)  | Address mark not found; data integrity issue.                                  |
| **3**   | TKONF (Track Overflow)         | Track overflow detected; head moved beyond cylinder boundary.                  |
| **4**   | CRC (CRC Error)                | CRC error in data transfer; indicates data corruption during transfer.         |
| **5**   | ICRC (Interface CRC Error)     | CRC error in the interface; communication error between controller and device. |
| **6**   | UNC (Uncorrectable Data Error) | Uncorrectable data error; severe data corruption.                              |
| **7**   | BBK (Bad Block Detected)       | Bad block detected on the media; physical sector damage.                       |

## Step 5: Read Data from Buffer

### Step 5.1: Prepare a Buffer Space (Optional)

Read operation is quite simple. Here we first set up our buffer inside the memory:

```nasm
 51      ; Step 5: Read the Data from Buffer
 52      ; 1. Setup DS:SI
 53      xor     ax,     ax
 54      mov     ds,     ax
 55  
 56      mov     si,     _buffer
```

### Step 5.2: Read Data:

Now, we attempt to read.
The input port, `IO_PORT`, is actually 16-bit width.
So, to read 512 bytes of data, we actually only need to repeat the operation 256 times.

```nasm
 58      ; 2. Read
 59      mov     cx,     256                 ; the I/O port is 16-bit width, meaning 512 bytes is 256 words
 60      mov     dx,     IO_PORT
 61  
 62      .iteration_loop_read_word_from_disk:
 63          in          ax,         dx
 64          mov word    [ds:si],    ax
 65          add         si,         2       ; 2 bytes, 1 word
 66  
 67          ; loop logic is similar to do { ... } while (--cx != 0)
 68          loop .iteration_loop_read_word_from_disk
```

The `loop` instruction operates like this:
```nasm
    .loop:
        ; Operation that I want to do
        dec cx
        cmp cx, 0
        jne .loop
```
which is similar to what I wrote in the comments in C. `loop` is just a simpler version of the above code.

And, just like that,
we have walked through the whole process of reading a sector from the hard disk using the IDE controller.
Actually, ATA controllers are supposed to behave the exact same.

## Print the Data (Optional)

Below is a code that we don't have to fully understand right now.
It uses a BIOS print call to print the character right at the cursor's location.
We will talk about how to manipulate cursor location and communicate with GPU directly
without the involvement of BIOS interruption calls or any third party software.

A simple explanation here is that by setting `ah` to `0x0E`, and use the interruption instruction `int 0x10`,
we just told BIOS to print the content in `al`, which is an ASCII code, on screen, right at where cursor is,
and move the cursor to the position of the next character.

> ***A quick explanation here:** Interruption is somewhat like a function call,
> but the actual jump sequence is handled by hardware. We don't need to know where this function is actually
> located in memory, we can just call it without that knowledge.
> When an interruption is performed, the current task is actually halted during the handling.* 

```nasm
 70      ; Now, we print it to the screen
 71      mov     si,     _buffer
 72      .print:
 73          cmp byte    [ds:si],    0x00
 74          je          .end
 75  
 76          mov         ah,         0x0E    ; TTY Output Function
 77          mov         al,         [ds:si] ; Character to print
 78          int         0x10                ; Call BIOS interrupt
 79          inc         si
 80  
 81          jmp         .print
 82      .end:
```

And below, we have the good old halting the system, so the processor doesn't wonder off and execute code we
don't want to execute.
Also, we defined the buffer here so the data we just read are put right after the MBR code.
And the boot signature, of course.

```nasm
 84      ; halt the system
 85  _infinite_loop:
 86      hlt
 87      jmp _infinite_loop
 88  
 89  _buffer:
 90      times 510-($-$$) db 0
 91  
 92  ; Boot signature
 93  dw 0xAA55
```

---

[Chapter 5](./5_other_hardware_control.md)

[Back to the Main Page](../README.md)
