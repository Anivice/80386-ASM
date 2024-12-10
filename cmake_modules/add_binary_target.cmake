cmake_minimum_required(VERSION 3.29)

include(${CMAKE_CURRENT_LIST_DIR}/check_for_program_availability.cmake)
check_for_program_availability(NASM_EXECUTABLE      nasm)
check_for_program_availability(DD_EXECUTABLE        dd)
check_for_program_availability(CAT_EXECUTABLE       cat)
check_for_program_availability(SH_EXECUTABLE        sh)
check_for_program_availability(OBJCOPY_EXECUTABLE   objcopy)
check_for_program_availability(CP_EXECUTABLE        cp)
check_for_program_availability(STRIP_EXECUTABLE     strip)
set(CMAKE_C_FLAGS "-m32 -O0 -nostdlib -nostartfiles -nodefaultlibs -ffreestanding -fno-builtin -fno-pic -no-pie -T ${CMAKE_SOURCE_DIR}/src_for_doc/link.ld")

function(add_singular_binary_target
        TARGET_NAME         # Target name that the build system referred to
        OUTPUT_FILENAME     # output filename for the binary file
        INPUT_FILENAME      # input file (singular) for the binary
)

    # Generate binary file from assembly source
    add_custom_command(
            OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${OUTPUT_FILENAME}
            COMMAND ${NASM_EXECUTABLE} -O0 -X gnu -f bin ${CMAKE_CURRENT_SOURCE_DIR}/${INPUT_FILENAME} -o ${CMAKE_CURRENT_BINARY_DIR}/${OUTPUT_FILENAME}
            DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/${INPUT_FILENAME}
            COMMENT "Assembling ${INPUT_FILENAME} with NASM (Singular mode)"
    )

    # Create a target to manage dependencies and build
    add_custom_target(${TARGET_NAME} ALL
            DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/${OUTPUT_FILENAME}
            COMMENT "Building binary target ${TARGET_NAME} (Singular mode)"
    )
endfunction()

function(bin2bin_sector_fill
        BIN_OUT
        BIN_IN
)
    add_custom_command(
            OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${BIN_OUT}
            COMMAND ${DD_EXECUTABLE} bs=130560 conv=sync,fdatasync iflag=fullblock
                    if=${CMAKE_CURRENT_BINARY_DIR}/${BIN_IN}
                    of=${CMAKE_CURRENT_BINARY_DIR}/${BIN_OUT} 2> /dev/null
            DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/${BIN_IN}
            COMMENT "Copy binary ${BIN_IN} to be full sector"
    )

    add_custom_target(b2b_${BIN_OUT} ALL
            DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/${BIN_OUT}
            COMMENT "Copy binary ${BIN_IN} to be full sector"
    )
endfunction()

function(add_singular_c_target
        TARGET_NAME         # Target name that the build system referred to
        OUTPUT_BIN          # output filename for the binary file
        OUTPUT_ELF32        # output filename for the elf file
        INPUT_FILENAME      # input file (singular) for the binary
)
    add_library(${TARGET_NAME}.lib SHARED ${INPUT_FILENAME})

    # Generate binary file from assembly source
    add_custom_command(
            OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${OUTPUT_BIN} ${CMAKE_CURRENT_BINARY_DIR}/${OUTPUT_ELF32}
            COMMAND ${CP_EXECUTABLE} ${CMAKE_CURRENT_BINARY_DIR}/lib${TARGET_NAME}.lib.so ${CMAKE_CURRENT_BINARY_DIR}/${OUTPUT_ELF32}
            COMMAND ${OBJCOPY_EXECUTABLE}
                    -O binary
                    --only-section=.text
                    ${CMAKE_CURRENT_BINARY_DIR}/lib${TARGET_NAME}.lib.so ${CMAKE_CURRENT_BINARY_DIR}/${OUTPUT_BIN}
            DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/${INPUT_FILENAME} ${TARGET_NAME}.lib ${CMAKE_SOURCE_DIR}/src_for_doc/link.ld
            COMMENT "Assembling ${INPUT_FILENAME} with NASM (Singular mode)"
    )

    # Create a target to manage dependencies and build
    add_custom_target(${TARGET_NAME} ALL
            DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/${OUTPUT_BIN} ${CMAKE_CURRENT_BINARY_DIR}/${OUTPUT_ELF32}
            COMMENT "Building binary and ELF target ${TARGET_NAME} (Dual mode)"
    )
endfunction()

function(concatenate_files)
    if (${ARGC} LESS 2)
        message(FATAL_ERROR "Incorrect use of this function. Expecting at least two arguments.")
    endif ()

    set(arg_list ${ARGN})
    list(GET arg_list 0 output_filename)
    list(REMOVE_AT arg_list 0)

    set(DD_COMMAND "${DD_EXECUTABLE} of=${output_filename} bs=512 conv=sync,fdatasync iflag=fullblock")
    set(CAT_COMMAND "${CAT_EXECUTABLE}")
    foreach(arg IN LISTS arg_list)
        set(CAT_COMMAND "${CAT_COMMAND} ${arg}")
    endforeach()

    set(COMMAND "${CAT_COMMAND} | ${DD_COMMAND} 2> /dev/null > /dev/null")

    set(file_dep)
    set(comment)
    foreach(arg IN LISTS arg_list)
        LIST(APPEND file_dep "${CMAKE_CURRENT_BINARY_DIR}/${arg}")
        set(comment "${comment} ${arg}")
    endforeach()

    add_custom_command(
            OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${output_filename}
            COMMAND ${SH_EXECUTABLE} -c ${COMMAND}
            DEPENDS ${file_dep}
            COMMENT "Concatenating files${comment} to ${output_filename}"
            VERBATIM
    )

    add_custom_target(concatenate_file_${output_filename} ALL
            DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/${output_filename}
            COMMENT "Concatenating files for target concatenate_file_${output_filename}"
    )
endfunction()
