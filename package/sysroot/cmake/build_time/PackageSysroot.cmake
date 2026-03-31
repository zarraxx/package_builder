if(NOT DEFINED WORKING_DIR OR WORKING_DIR STREQUAL "")
    message(FATAL_ERROR "WORKING_DIR is not defined")
endif()

if(NOT DEFINED INPUT_DIR_NAME OR INPUT_DIR_NAME STREQUAL "")
    message(FATAL_ERROR "INPUT_DIR_NAME is not defined")
endif()

if(NOT DEFINED OUT OR OUT STREQUAL "")
    message(FATAL_ERROR "OUT is not defined")
endif()

if(NOT DEFINED STAMP OR STAMP STREQUAL "")
    message(FATAL_ERROR "STAMP is not defined")
endif()

if(NOT DEFINED CREATE_ARCHIVE_SCRIPT OR CREATE_ARCHIVE_SCRIPT STREQUAL "")
    message(FATAL_ERROR "CREATE_ARCHIVE_SCRIPT is not defined")
endif()

string(REGEX REPLACE "^\"(.*)\"$" "\\1" WORKING_DIR "${WORKING_DIR}")
string(REGEX REPLACE "^\"(.*)\"$" "\\1" INPUT_DIR_NAME "${INPUT_DIR_NAME}")
string(REGEX REPLACE "^\"(.*)\"$" "\\1" OUT "${OUT}")
string(REGEX REPLACE "^\"(.*)\"$" "\\1" STAMP "${STAMP}")
string(REGEX REPLACE "^\"(.*)\"$" "\\1" CREATE_ARCHIVE_SCRIPT "${CREATE_ARCHIVE_SCRIPT}")

if(NOT DEFINED FD_FORCE_PACKAGE OR FD_FORCE_PACKAGE STREQUAL "")
    set(FD_FORCE_PACKAGE OFF)
endif()

string(TOUPPER "${FD_FORCE_PACKAGE}" _fd_force_package)

set(_input_path "${WORKING_DIR}/${INPUT_DIR_NAME}")

if(NOT EXISTS "${WORKING_DIR}")
    message(FATAL_ERROR "WORKING_DIR does not exist: ${WORKING_DIR}")
endif()

if(NOT EXISTS "${_input_path}")
    message(FATAL_ERROR "Input directory does not exist: ${_input_path}")
endif()

get_filename_component(_out_dir "${OUT}" DIRECTORY)
file(MAKE_DIRECTORY "${_out_dir}")

if(EXISTS "${OUT}"
   AND NOT _fd_force_package STREQUAL "ON"
   AND NOT _fd_force_package STREQUAL "TRUE"
   AND NOT _fd_force_package STREQUAL "1"
   AND NOT _fd_force_package STREQUAL "YES")
    message(STATUS "Archive already exists, skip package:")
    message(STATUS "  OUT: ${OUT}")
    file(WRITE "${STAMP}" "cached\n")
    return()
endif()

file(REMOVE "${OUT}")

get_filename_component(_stamp_dir "${STAMP}" DIRECTORY)
get_filename_component(_stamp_name_we "${STAMP}" NAME_WE)
set(_staging_dir "${_stamp_dir}/package_stage_${_stamp_name_we}")

file(REMOVE_RECURSE "${_staging_dir}")
file(MAKE_DIRECTORY "${_staging_dir}")

message(STATUS "Packaging sysroot:")
message(STATUS "  WORKING_DIR: ${WORKING_DIR}")
message(STATUS "  INPUT_DIR:   ${INPUT_DIR_NAME}")
message(STATUS "  OUT:         ${OUT}")

# staging_dir/sysroot
file(COPY "${_input_path}" DESTINATION "${_staging_dir}")

execute_process(
    COMMAND ${CMAKE_COMMAND} -E chdir "${_staging_dir}"
            ${CMAKE_COMMAND}
            -DOUT=${OUT}
            -DINPUT_DIR_NAME=${INPUT_DIR_NAME}
            -P "${CREATE_ARCHIVE_SCRIPT}"
    RESULT_VARIABLE _rc
)

if(NOT _rc EQUAL 0)
    message(FATAL_ERROR "Archive creation failed: ${OUT}")
endif()

file(REMOVE_RECURSE "${_staging_dir}")
file(WRITE "${STAMP}" "ok\n")