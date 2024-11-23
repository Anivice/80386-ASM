cmake_minimum_required(VERSION 3.29)

include(${CMAKE_CURRENT_LIST_DIR}/check_for_program_availability.cmake)
check_for_program_availability(QEMU_EXECUTABLE qemu-system-i386)

function(add_qemu_emulation_target
        TARGET_NAME
        BOOT_SECTOR_FILE_NAME)
    add_custom_target(${TARGET_NAME}
            DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/${BOOT_SECTOR_FILE_NAME}
            COMMAND ${QEMU_EXECUTABLE} -drive format=raw,file=${CMAKE_CURRENT_BINARY_DIR}/${BOOT_SECTOR_FILE_NAME} -m 32M
            COMMENT "Starting emulation for ${BOOT_SECTOR_FILE_NAME}"
    )
endfunction()
