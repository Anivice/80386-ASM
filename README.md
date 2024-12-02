# Fool's Guide to Intel 80386 Assembly

Welcome to Fool's Guide to Intel 80386 assembly!
This resource provides a comprehensive walkthrough for writing functional
Intel 80386 code in both Real Mode and Protected Mode (Seriously, it really is
a tutorial, I'm not even kidding here).

## Table of Contents

### [Chapter 1: Overview](documentation/1_overview.md)
> The Intel 8086 is a 16-bit processor, introduced segmentation to access up to 1 MB of memory.

### [Chapter 2: Assembly and NASM](documentation/2_assembly_and_nasm.md)
> Assembly language; use NASM to compile and disassemble code.

### [Chapter 3: QEMU Emulation and Debugging](documentation/3_qemu.md)
> Debugging 16-bit real mode with QEMU+GDB;
- ### [Chapter 3.1: Assembly Example `movsb`](documentation/3.1_assembly_example_movsb.md)
  > The `movsb` instruction simplifies copying blocks of data in memory,
- ### [Chapter 3.2: Conditional Jump](documentation/3.2_conditional_jump.md)
  > Conditional jumps in assembly based on flags for loop control.
- ### [Chapter 3.3: Stack and Function](documentation/3.3_stack_and_function.md)
  > The 8086 stack and how to write a function in assembly preserving CPU state before calling.
- ### [Chapter 3.4: Memory Addressing (And Some Other Notes)](documentation/3.4_memory_addressing.md)
  > Intel 80386 real mode memory addressing.

---

## Why 80386 When RISCV64, AARCH64, and AMD64(x86_64) are the Dominant Architecture Now?
Yes, it may seem pointless.
However, 80386 is, well, not the simplest architecture to work with, but does have the
following edge compared to other architectures:
1. **Abundant Resource:** Intel 80386 is the most used architecture in the PC market ever,
                          making it well documented and well-supported by both hardware vendors
                          and software developers, with countless well-tested emulators and
                          real hardware debuggers to choose from.
                          (there are even FPGA projects to reimplement the good old 80386)

2. **Rather Flat Learning Curve:** Intel 80386 is significantly easier than AMD64 architecture,
                                   and support ended with `i686`, Intel 80686, the most advanced
                                   32-bit architecture used by Intel Pentium Pro released in 1995
                                   before Intel fully commited to 64bit architecture starting from
                                   Intel Core series.
                                   Intel 80386 is simpler and easier than advanced architectures
                                   with instructions dealing with things like AES256 that are not
                                   exactly related to system programming.

## Why Use CMake?

This project uses CMake as its default build system.
While Makefiles can be simpler, CMake is preferred due to its
seamless compatibility with CLion, which has limited support for Makefiles.

**Note:** This guide primarily focuses on 80386 assembly programming.
Detailed CMake instructions are beyond its scope.

## CMake Modules Overview

<table>
  <tr>
    <th>Module File</th>
    <th>Function</th>
    <th>Explanation</th>
  </tr>

  <!-- check_for_program_availability.cmake -->
  <tr>
    <td>check_for_program_availability.cmake</td>
    <td><code>check_for_program_availability(EXEC, CMD)</code></td>
    <td>
      Checks for the availability of a program.<br>
      <b>EXEC</b>: Macro to store the program's full path.<br>
      <b>CMD</b>: Basename of the program.
    </td>
  </tr>

  <!-- add_binary_target.cmake -->
  <tr>
    <td rowspan="2">add_binary_target.cmake</td>
    <td><code>add_singular_binary_target(TARGET_NAME, OUTPUT_FILENAME, INPUT_FILENAME)</code></td>
    <td>
      Compiles a single file into a pure binary.<br>
      <b>TARGET_NAME</b>: Name used by the build system.<br>
      <b>OUTPUT_FILENAME</b>: Name of the output binary file.<br>
      <b>INPUT_FILENAME</b>: Source file for the binary.
    </td>
  </tr>
  <tr>
    <td><code>concatenate_files(OUTPUT_FILENAME, FILE1, [FILE2...])</code></td>
    <td>
      Concatenate files into one, with 512 block alignment configuration for disk I/O support.<br>
      The target name used by the build system is automatically generated,
      named as <code>concatenate_file_${OUTPUT_FILENAME]</code>.<br>
      <b>OUTPUT_FILENAME</b>: Name of the output file.<br>
      <b>FILE1, [FILE2...]</b>: Name of the input file that wished to be concatenated.<br>
    </td>
  </tr>

  <!-- qemu-emulator.cmake -->
  <tr>
    <td rowspan="3">qemu-emulator.cmake</td>
    <td><code>add_qemu_emulation_target(TARGET_NAME, BOOT_SECTOR_FILE_NAME)</code></td>
    <td>
      Links a boot sector to QEMU for emulation.<br>
      <b>TARGET_NAME</b>: Name used by the build system.<br>
      <b>BOOT_SECTOR_FILE_NAME</b>: Name of the boot sector file.
    </td>
  </tr>

  <tr>
    <td><code>add_qemu_debug_target(TARGET_NAME, BOOT_SECTOR_FILE_NAME)</code></td>
    <td>
      Links a boot sector to QEMU for emulation <b><i>with GDB support</i></b>.<br>
      <b>TARGET_NAME</b>: Name used by the build system.<br>
      <b>BOOT_SECTOR_FILE_NAME</b>: Name of the boot sector file.
    </td>
  </tr>

  <tr>
    <td><code>create_virtual_disk_from_bin(DISK_NAME, DISK_FORMAT, RAW_FILE_NAME)</code></td>
    <td>
      Create a virtual disk from a raw binary file generated by NASM.<br>
      <b>DISK_NAME</b>: Disk name.<br>
      <b>DISK_FORMAT</b>: Disk format. Available format as following:<br>
        <ol>
          <li><b>VMwareDiskFormat</b>: VMware Disk Format, *.vmdk.</li>
          <li><b>VirtualBoxDiskFormat</b>: VirtualBox Disk Format, *.vhi</li>
          <li><b>MicrosoftVirtualHardDisk</b>: Microsoft Virtual Hard Disk, *.vhdx (Note: *.vhd files are obsolete and
                deprecated, and is replaced by *.vhdx).</li>
          <li><b>QEMUCopyOnWrite</b></li>: QEMU Copy On Write format (version 2), *.qcow2.
        </ol>
      <b>RAW_FILE_NAME</b>: Raw binary file name.<br>
    </td>
  </tr>

</table>
