cmake_minimum_required(VERSION 3.29)

include(${CMAKE_CURRENT_LIST_DIR}/check_for_program_availability.cmake)
check_for_program_availability(QEMU_EXECUTABLE qemu-system-i386)
check_for_program_availability(GDB_EXECUTABLE gdb)

function(add_qemu_emulation_target
        TARGET_NAME
        BOOT_SECTOR_FILE_NAME)
    add_custom_target(${TARGET_NAME}
            DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/${BOOT_SECTOR_FILE_NAME}
            COMMAND taskset -c 0 ${QEMU_EXECUTABLE} -smp 1 -cpu 486 -drive format=raw,file=${CMAKE_CURRENT_BINARY_DIR}/${BOOT_SECTOR_FILE_NAME} -m 32M
            USES_TERMINAL
            COMMENT "Starting emulation for ${BOOT_SECTOR_FILE_NAME}"
    )
endfunction()

function(add_qemu_debug_target
        TARGET_NAME
        BOOT_SECTOR_FILE_NAME)
    add_custom_target(${TARGET_NAME}
            DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/${BOOT_SECTOR_FILE_NAME}
            COMMAND taskset -c 0 ${QEMU_EXECUTABLE} -smp 1 -cpu 486 -drive format=raw,file=${CMAKE_CURRENT_BINARY_DIR}/${BOOT_SECTOR_FILE_NAME} -m 32M -s -S -monitor stdio -d int,in_asm,cpu,exec -D qemu_debug_${TARGET_NAME}.log
            USES_TERMINAL
            COMMENT "Starting debug emulation for ${BOOT_SECTOR_FILE_NAME}. Emulation will start once gdb connects"
    )
endfunction()
