cmake_minimum_required(VERSION 3.29)

# Function to check for program availability
function(check_for_program_availability EXEC CMD)
    find_program(${EXEC} ${CMD} REQUIRED)
    if (NOT ${EXEC})
        message(FATAL_ERROR "${CMD} not found. Please install ${CMD} and ensure it's in your PATH.")
    endif()

    message(STATUS "${CMD} found at ${${EXEC}}")
endfunction()
