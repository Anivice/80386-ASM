cmake_minimum_required(VERSION 3.29)
project(80386ASM ASM C CXX)

include(cmake_modules/add_binary_target.cmake)
include(cmake_modules/qemu-emulator.cmake)

add_singular_binary_target(example example.bin nasm_setup/main.asm)
add_qemu_emulation_target(boot_example example.bin)

add_singular_binary_target(chapter2 chapter2.bin src_for_doc/chapter2.asm)

add_singular_binary_target(chapter3 chapter3.bin src_for_doc/chapter3.asm)
add_qemu_emulation_target(boot_chapter3 chapter3.bin)
add_qemu_debug_target(debug_chapter3 chapter3.bin)

add_singular_binary_target(print print.bin src_for_doc/Examples/print.asm)
add_qemu_emulation_target(boot_print print.bin)
add_qemu_debug_target(debug_print print.bin)

add_singular_binary_target(chapter4 chapter4.bin src_for_doc/chapter4.asm)
add_qemu_emulation_target(boot_chapter4 chapter4.bin)
add_qemu_debug_target(debug_chapter4 chapter4.bin)
