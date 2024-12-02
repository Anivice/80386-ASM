cmake_minimum_required(VERSION 3.29)

include(${CMAKE_CURRENT_LIST_DIR}/check_for_program_availability.cmake)
check_for_program_availability(QEMU_EXECUTABLE  qemu-system-i386)
check_for_program_availability(GDB_EXECUTABLE   gdb)
check_for_program_availability(QEMU_IMG_EXEC    qemu-img)

function(add_qemu_emulation_target
        TARGET_NAME
        BOOT_SECTOR_FILE_NAME)
    add_custom_target(${TARGET_NAME}
            DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/${BOOT_SECTOR_FILE_NAME}
            COMMAND ${QEMU_EXECUTABLE} -smp 1 -cpu 486 -drive format=raw,file=${CMAKE_CURRENT_BINARY_DIR}/${BOOT_SECTOR_FILE_NAME} -m 32M
            USES_TERMINAL
            COMMENT "Starting emulation for ${BOOT_SECTOR_FILE_NAME}"
    )
endfunction()

function(add_qemu_debug_target
        TARGET_NAME
        BOOT_SECTOR_FILE_NAME)
    add_custom_target(${TARGET_NAME}
            DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/${BOOT_SECTOR_FILE_NAME}
            COMMAND ${QEMU_EXECUTABLE} -smp 1 -cpu 486 -drive format=raw,file=${CMAKE_CURRENT_BINARY_DIR}/${BOOT_SECTOR_FILE_NAME} -m 32M -s -S -monitor stdio -d int,in_asm,cpu,exec -D qemu_debug_${TARGET_NAME}.log
            USES_TERMINAL
            COMMENT "Starting debug emulation for ${BOOT_SECTOR_FILE_NAME}. Emulation will start once gdb connects"
    )
endfunction()

function(create_virtual_disk_from_bin
        DISK_NAME
        DISK_FORMAT
        RAW_FILE_NAME)

    set(format)
    if (${DISK_FORMAT} STREQUAL "VMwareDiskFormat")
        set(format "vmdk")
    elseif (${DISK_FORMAT} STREQUAL "VirtualBoxDiskFormat")
        set(format "vdi")
    elseif (${DISK_FORMAT} STREQUAL "MicrosoftVirtualHardDisk")
        set(format "vhdx")
    elseif (${DISK_FORMAT} STREQUAL "QEMUCopyOnWrite")
        set(format "qcow2")
    else()
        message(FATAL_ERROR "Unknown disk format!")
    endif ()

    add_custom_target(${DISK_NAME} ALL
            DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/${RAW_FILE_NAME}
            COMMAND ${QEMU_IMG_EXEC} convert -f raw -O ${format} ${CMAKE_CURRENT_BINARY_DIR}/${RAW_FILE_NAME} ${CMAKE_CURRENT_BINARY_DIR}/${DISK_NAME}
            COMMENT "Converting disk ${RAW_FILE_NAME} from RAW Binary file to ${DISK_NAME} in format ${DISK_FORMAT}..."
            VERBATIM
    )
endfunction()
