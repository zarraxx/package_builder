if(NOT DEFINED OUT OR OUT STREQUAL "")
    message(FATAL_ERROR "OUT is not defined")
endif()

if(NOT DEFINED INPUT_DIR_NAME OR INPUT_DIR_NAME STREQUAL "")
    message(FATAL_ERROR "INPUT_DIR_NAME is not defined")
endif()

string(REGEX REPLACE "^\"(.*)\"$" "\\1" OUT "${OUT}")
string(REGEX REPLACE "^\"(.*)\"$" "\\1" INPUT_DIR_NAME "${INPUT_DIR_NAME}")

if(NOT EXISTS "${INPUT_DIR_NAME}")
    message(FATAL_ERROR "Input directory does not exist in current working dir: ${INPUT_DIR_NAME}")
endif()

file(ARCHIVE_CREATE
    OUTPUT "${OUT}"
    PATHS "${INPUT_DIR_NAME}"
    FORMAT gnutar
    COMPRESSION XZ
)