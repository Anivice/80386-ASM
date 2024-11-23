cmake_minimum_required(VERSION 3.29)
project(80386ASM ASM C CXX)

include(cmake_modules/add_binary_target.cmake)
include(cmake_modules/qemu-emulator.cmake)

add_singular_binary_target(example example.bin nasm_setup/main.asm)
add_qemu_emulation_target(boot_example example.bin)
