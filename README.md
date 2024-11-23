# 80386 Assembly Guide

Welcome to the 80386 assembly programming guide!
This resource provides a comprehensive walkthrough for writing functional
80386 code in both Real Mode and Protected Mode.

---

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
    <td>add_binary_target.cmake</td>
    <td><code>add_singular_binary_target(TARGET_NAME, OUTPUT_FILENAME, INPUT_FILENAME)</code></td>
    <td>
      Compiles a single file into a pure binary.<br>
      <b>TARGET_NAME</b>: Name used by the build system.<br>
      <b>OUTPUT_FILENAME</b>: Name of the output binary file.<br>
      <b>INPUT_FILENAME</b>: Source file for the binary.
    </td>
  </tr>

  <!-- qemu-emulator.cmake -->
  <tr>
    <td>qemu-emulator.cmake</td>
    <td><code>add_qemu_emulation_target(TARGET_NAME, BOOT_SECTOR_FILE_NAME)</code></td>
    <td>
      Links a boot sector to QEMU for emulation.<br>
      <b>TARGET_NAME</b>: Name used by the build system.<br>
      <b>BOOT_SECTOR_FILE_NAME</b>: Name of the boot sector file.
    </td>
  </tr>
</table>

---

## Table of Contents
- [Chapter 1: Overview](documentation/overview.md)
- [Chapter 2: Assembly and NASM](documentation/assembly_and_nasm.md)
