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
concatenate_files(chapter4_read_data.bin chapter4.reader.bin chapter4.data.bin)
add_qemu_emulation_target(boot_chapter4_reader chapter4_read_data.bin)
add_qemu_debug_target(debug_chapter4_reader chapter4_read_data.bin)

add_singular_binary_target(
        chapter4.loader
        chapter4.loader.bin
        src_for_doc/chapter4.loader.asm)
add_singular_binary_target(
        chapter4.user
        chapter4.user.bin
        src_for_doc/chapter4.user.asm)
concatenate_files(
        chapter4.prg.loader.bin
        chapter4.loader.bin chapter4.user.bin)
create_virtual_disk_from_bin(chapter4.program_loader.vhdx MicrosoftVirtualHardDisk chapter4.prg.loader.bin)

add_qemu_emulation_target(boot_chapter4_loader chapter4.prg.loader.bin)
add_qemu_debug_target(debug_chapter4_loader chapter4.prg.loader.bin)
