cmake_minimum_required(VERSION 3.29)
project(80386ASM ASM C CXX)

include(cmake_modules/add_binary_target.cmake)
include(cmake_modules/qemu-emulator.cmake)

add_singular_binary_target(example example.bin nasm_setup/main.asm)
add_qemu_emulation_target(boot_example example.bin)

add_singular_binary_target(chapter2 chapter2.bin src_for_doc/chapter2.asm)

function(add_chapter_src CHAPTER)
    add_singular_binary_target(${CHAPTER} ${CHAPTER}.bin src_for_doc/${CHAPTER}.asm)
    add_qemu_emulation_target(boot_${CHAPTER} ${CHAPTER}.bin)
    add_qemu_debug_target(debug_${CHAPTER} ${CHAPTER}.bin)
endfunction()

add_chapter_src(chapter3)
add_chapter_src(chapter3.1)
add_chapter_src(chapter3.2)
add_chapter_src(chapter3.3)

add_singular_binary_target(chapter4.reader chapter4.reader.bin src_for_doc/chapter4.reader.asm)
add_singular_binary_target(chapter4.data chapter4.data.bin src_for_doc/chapter4.data.asm)
concatenate_files(chapter4.bin chapter4.reader.bin chapter4.data.bin)
add_qemu_emulation_target(boot_chapter4 chapter4.bin)
add_qemu_debug_target(debug_chapter4 chapter4.bin)
