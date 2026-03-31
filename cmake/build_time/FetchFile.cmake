# -----------------------------
# Required variables:
#   URL
#   OUT
#   STAMP
#
# Optional:
#   FT_FORCE_DOWNLOAD
# -----------------------------

if(NOT DEFINED URL OR URL STREQUAL "")
    message(FATAL_ERROR "URL is not defined")
endif()

if(NOT DEFINED OUT OR OUT STREQUAL "")
    message(FATAL_ERROR "OUT is not defined")
endif()

if(NOT DEFINED STAMP OR STAMP STREQUAL "")
    message(FATAL_ERROR "STAMP is not defined")
endif()

# 去掉可能被 -D 传进来的外层引号
string(REGEX REPLACE "^\"(.*)\"$" "\\1" URL "${URL}")
string(REGEX REPLACE "^\"(.*)\"$" "\\1" OUT "${OUT}")
string(REGEX REPLACE "^\"(.*)\"$" "\\1" STAMP "${STAMP}")

# 默认不开启强制下载
if(NOT DEFINED FD_FORCE_DOWNLOAD OR FD_FORCE_DOWNLOAD STREQUAL "")
    set(FD_FORCE_DOWNLOAD OFF)
endif()

string(TOUPPER "${FD_FORCE_DOWNLOAD}" _fd_force_download)

#根据文件名获取 所在目录，并创建目录
get_filename_component(_out_dir "${OUT}" DIRECTORY)
file(MAKE_DIRECTORY "${_out_dir}")

# 如果文件已存在且未强制下载，则跳过
if(EXISTS "${OUT}"
   AND NOT _fd_force_download STREQUAL "ON"
   AND NOT _fd_force_download STREQUAL "TRUE"
   AND NOT _fd_force_download STREQUAL "1"
   AND NOT _fd_force_download STREQUAL "YES")
    message(STATUS "File already exists, skip download:")
    message(STATUS "  OUT: ${OUT}")
    file(WRITE "${STAMP}" "cached\n")
    return()
endif()

message(STATUS "Downloading:")
message(STATUS "  URL: ${URL}")
message(STATUS "  OUT: ${OUT}")

file(DOWNLOAD
    "${URL}"
    "${OUT}"
    SHOW_PROGRESS
    STATUS _status
    LOG _log
)

list(GET _status 0 _code)
list(GET _status 1 _msg)

if(NOT _code EQUAL 0)
    message(FATAL_ERROR
        "Download failed\n"
        "URL: ${URL}\n"
        "OUT: ${OUT}\n"
        "STATUS: ${_code}; ${_msg}\n"
        "LOG:\n${_log}"
    )
endif()

file(WRITE "${STAMP}" "ok\n")