if(NOT DEFINED ARCHIVE OR ARCHIVE STREQUAL "")
    message(FATAL_ERROR "ARCHIVE is not defined")
endif()

if(NOT DEFINED DESTINATION OR DESTINATION STREQUAL "")
    message(FATAL_ERROR "DESTINATION is not defined")
endif()

if(NOT DEFINED STAMP OR STAMP STREQUAL "")
    message(FATAL_ERROR "STAMP is not defined")
endif()

string(REGEX REPLACE "^\"(.*)\"$" "\\1" ARCHIVE "${ARCHIVE}")
string(REGEX REPLACE "^\"(.*)\"$" "\\1" DESTINATION "${DESTINATION}")
string(REGEX REPLACE "^\"(.*)\"$" "\\1" STAMP "${STAMP}")

if(NOT DEFINED FD_FORCE_EXTRACT OR FD_FORCE_EXTRACT STREQUAL "")
    set(FD_FORCE_EXTRACT OFF)
endif()

string(TOUPPER "${FD_FORCE_EXTRACT}" _fd_force_extract)

if(NOT EXISTS "${ARCHIVE}")
    message(FATAL_ERROR "Archive not found: ${ARCHIVE}")
endif()

# 目标目录已存在且未强制解压，则跳过
if(EXISTS "${DESTINATION}"
   AND NOT _fd_force_extract STREQUAL "ON"
   AND NOT _fd_force_extract STREQUAL "TRUE"
   AND NOT _fd_force_extract STREQUAL "1"
   AND NOT _fd_force_extract STREQUAL "YES")
    message(STATUS "Directory already exists, skip extract:")
    message(STATUS "  DESTINATION: ${DESTINATION}")
    file(WRITE "${STAMP}" "cached\n")
    return()
endif()

file(REMOVE_RECURSE "${DESTINATION}")
file(MAKE_DIRECTORY "${DESTINATION}")

message(STATUS "Extracting:")
message(STATUS "  ARCHIVE: ${ARCHIVE}")
message(STATUS "  DESTINATION: ${DESTINATION}")

file(ARCHIVE_EXTRACT
    INPUT "${ARCHIVE}"
    DESTINATION "${DESTINATION}"
)

file(WRITE "${STAMP}" "ok\n")