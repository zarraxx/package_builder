include_guard(GLOBAL)


# ------------------------------------------------------------------------------
# 函数: _fd_add_build_time_rule
#
# 作用:
#   在“构建阶段”执行一个 cmake -P 脚本，并自动为该脚本创建：
#
#     1. stamp 文件
#     2. custom command
#     3. custom target
#
#   这个函数是 fetch / extract / patch 等构建阶段操作的通用封装，
#   用来避免重复写 add_custom_command(...) 和 add_custom_target(...)。
#
# ------------------------------------------------------------------------------
#
# 设计思路:
#
#   本函数只负责“执行一个 build_time 脚本”这件事，
#   不关心具体业务逻辑。
#
#   具体业务逻辑应写在独立的脚本文件中，例如：
#
#     - build_time/FetchFile.cmake
#     - build_time/ExtractFile.cmake
#
#   本函数负责把这些脚本包装成可构建的 target。
#
# ------------------------------------------------------------------------------
#
# 最终生成内容:
#
#   1. stamp 文件
#        <STAMP_DIR>/<TARGET_NAME>.stamp
#
#   2. target 名
#        <TARGET_PREFIX><TARGET_NAME>
#
#      例如：
#        TARGET_PREFIX = fetch_
#        TARGET_NAME   = gcc
#
#      则最终 target 名为：
#        fetch_gcc
#
# ------------------------------------------------------------------------------
#
# 参数说明
#
# 【单值参数 oneValueArgs】
#
#   TARGET_NAME
#       必填
#       当前规则的基础名字。
#
#       用途：
#         - 用于生成最终 target 名
#         - 用于生成 stamp 文件名
#
#       示例：
#         gcc
#         zlib
#         loongarch64-gcc
#
#
#   TARGET_PREFIX
#       可选
#       target 名前缀。
#
#       最终 target 名为：
#         <TARGET_PREFIX><TARGET_NAME>
#
#       一般建议带上下划线，例如：
#         fetch_
#         extract_
#
#       示例：
#         TARGET_PREFIX = fetch_
#         TARGET_NAME   = gcc
#         => target 名 = fetch_gcc
#
#       如果不传，则最终 target 名就是 TARGET_NAME。
#
#
#   STAMP_DIR
#       可选
#       stamp 文件目录。
#
#       如果不指定，会自动生成默认目录：
#
#         ${CMAKE_CURRENT_BINARY_DIR}/buildtime_<prefix>_stamps
#
#       例如：
#         fetch_   -> buildtime_fetch_stamps
#         extract_ -> buildtime_extract_stamps
#
#
#   SCRIPT
#       必填
#       要执行的 cmake -P 脚本路径。
#
#       示例：
#         ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/build_time/FetchFile.cmake
#         ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/build_time/ExtractFile.cmake
#
#
#   COMMENT_TEXT
#       可选
#       构建输出时显示的说明文字。
#
#       示例：
#         "Fetching gcc"
#         "Extracting zlib"
#
# ------------------------------------------------------------------------------
#
# 【多值参数 multiValueArgs】
#
#   SCRIPT_ARGS
#       可选
#       传递给 build_time 脚本的 -D 参数列表。
#
#       这些参数会直接拼到：
#         cmake ... -P <SCRIPT>
#
#       例如：
#         SCRIPT_ARGS
#             -DURL=${dep_url}
#             -DOUT=${_out_file}
#             -DFD_FORCE_DOWNLOAD=${FD_FORCE_DOWNLOAD}
#
#       注意：
#         本函数会自动追加：
#             -DSTAMP=<stamp_file>
#         所以调用方不需要自己传 STAMP。
#
#
#   EXTRA_DEPENDS
#       可选
#       额外依赖项，可以是 target 或文件。
#
#       常用于定义阶段顺序，例如：
#         extract 依赖 fetch
#
#       示例：
#         EXTRA_DEPENDS
#             fetch_gcc
#
# ------------------------------------------------------------------------------
#
# 典型用途
#
#   1. fetch 阶段
#
#     _fd_add_build_time_rule(
#         TARGET_PREFIX fetch_
#         TARGET_NAME gcc
#         SCRIPT "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/build_time/FetchFile.cmake"
#         COMMENT_TEXT "Fetching gcc"
#         SCRIPT_ARGS
#             -DURL=${dep_url}
#             -DOUT=${_out_file}
#             -DFD_FORCE_DOWNLOAD=${FD_FORCE_DOWNLOAD}
#     )
#
#
#   2. extract 阶段
#
#     _fd_add_build_time_rule(
#         TARGET_PREFIX extract_
#         TARGET_NAME gcc
#         SCRIPT "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/build_time/ExtractFile.cmake"
#         COMMENT_TEXT "Extracting gcc"
#         SCRIPT_ARGS
#             -DARCHIVE=${_archive_path}
#             -DDESTINATION=${_dest_dir}
#             -DFD_FORCE_EXTRACT=${FD_FORCE_EXTRACT}
#         EXTRA_DEPENDS
#             fetch_gcc
#     )
#
# ------------------------------------------------------------------------------
#
# 注意事项
#
#   1. SCRIPT_ARGS 里的 -D 参数不要写成带额外引号的形式，例如：
#
#        -DURL=${url}      ✔ 推荐
#        -DURL="${url}"    ✘ 可能把引号传进脚本值里
#
#
#   2. stamp 文件用于标记规则已执行。
#      如果想强制重新执行，可以：
#
#        - 删除对应 stamp 文件
#        - 或通过脚本内部的 FORCE 变量控制
#
#
#   3. 本函数不负责处理下载、解压、补丁等具体业务逻辑，
#      这些逻辑应放在 SCRIPT 指定的 build_time 脚本中实现。
#
#
#   4. 本函数只负责把“某个脚本”包装成“一个构建 target”。
#
# ------------------------------------------------------------------------------
function(_fd_add_build_time_rule)
    set(options)
    set(oneValueArgs
        TARGET_NAME
        TARGET_PREFIX
      #  ITEM_NAME
        STAMP_DIR
        SCRIPT
        COMMENT_TEXT
    )
    set(multiValueArgs
        SCRIPT_ARGS
        EXTRA_DEPENDS
    )

    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if(NOT ARG_TARGET_PREFIX)
        #message(FATAL_ERROR "_fd_add_build_time_rule: TARGET_PREFIX is required")
        set(ARG_TARGET_PREFIX "")
    endif()

    if(NOT ARG_TARGET_NAME)
        message(FATAL_ERROR "_fd_add_build_time_rule: TARGET_NAME is required")
    endif()

    set(ARG_FINAL_TARGET_NAME "${ARG_TARGET_PREFIX}${ARG_TARGET_NAME}")

    if(NOT ARG_STAMP_DIR)
        string(REGEX REPLACE "_$" "" _prefix_name "${ARG_TARGET_PREFIX}")
        if(_prefix_name STREQUAL "")
            set(_prefix_name "generic")
        endif()
        set(ARG_STAMP_DIR "${CMAKE_CURRENT_BINARY_DIR}/buildtime_${_prefix_name}_stamps")
    endif()

    if(NOT ARG_SCRIPT)
        message(FATAL_ERROR "_fd_add_build_time_rule: SCRIPT is required")
    endif()

    file(MAKE_DIRECTORY "${ARG_STAMP_DIR}")

    set(_stamp_file "${ARG_STAMP_DIR}/${ARG_TARGET_NAME}.stamp")

    add_custom_command(
        OUTPUT "${_stamp_file}"
        COMMAND ${CMAKE_COMMAND}
                ${ARG_SCRIPT_ARGS}
                -DSTAMP=${_stamp_file}
                -P "${ARG_SCRIPT}"
        DEPENDS
            "${ARG_SCRIPT}"
            ${ARG_EXTRA_DEPENDS}
        COMMENT "${ARG_COMMENT_TEXT}"
        VERBATIM
    )

    add_custom_target("${ARG_FINAL_TARGET_NAME}" DEPENDS "${_stamp_file}")
endfunction()