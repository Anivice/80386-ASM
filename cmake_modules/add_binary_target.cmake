cmake_minimum_required(VERSION 3.29)

include(${CMAKE_CURRENT_LIST_DIR}/check_for_program_availability.cmake)
check_for_program_availability(NASM_EXECUTABLE nasm)

function(add_singular_binary_target
        TARGET_NAME         # Target name that the build system referred to
        OUTPUT_FILENAME     # output filename for the binary file
        INPUT_FILENAME      # input file (singular) for the binary
)

    # Generate binary file from assembly source
    add_custom_command(
            OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${OUTPUT_FILENAME}
            COMMAND ${NASM_EXECUTABLE} -f bin ${CMAKE_CURRENT_SOURCE_DIR}/${INPUT_FILENAME} -o ${CMAKE_CURRENT_BINARY_DIR}/${OUTPUT_FILENAME}
            DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/${INPUT_FILENAME}
            COMMENT "Assembling ${INPUT_FILENAME} with NASM (Singular mode)"
    )

    # Create a target to manage dependencies and build
    add_custom_target(${TARGET_NAME} ALL
            DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/${OUTPUT_FILENAME}
            COMMENT "Building binary target ${TARGET_NAME} (Singular mode)"
    )
endfunction()
