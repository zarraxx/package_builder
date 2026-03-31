include_guard(GLOBAL)

# 转义正则特殊字符
function(_tf_escape_regex out_var input)
    string(REGEX REPLACE "([][+.*^$(){}|\\\\?])" "\\\\\\1" _escaped "${input}")
    set(${out_var} "${_escaped}" PARENT_SCOPE)
endfunction()

# 判断一个目录是否像工具链根目录
# 条件：
#   1. 存在 bin 目录
#   2. bin 下至少有：
#        <triple>-gcc
#        <triple>-cc
#        gcc
function(_tf_is_valid_toolchain_root out_var candidate_dir target_triple)
    set(_ok FALSE)
    set(_bin_dir "${candidate_dir}/bin")

    if(EXISTS "${_bin_dir}" AND IS_DIRECTORY "${_bin_dir}")
        if(EXISTS "${_bin_dir}/${target_triple}-gcc")
            set(_ok TRUE)
        elseif(EXISTS "${_bin_dir}/${target_triple}-cc")
            set(_ok TRUE)
        elseif(EXISTS "${_bin_dir}/gcc")
            set(_ok TRUE)
        endif()
    endif()

    set(${out_var} "${_ok}" PARENT_SCOPE)
endfunction()

# 收集 root_dir 下、最大深度 max_depth 内的所有目录
# 返回绝对路径列表
function(_tf_collect_dirs out_var root_dir max_depth)
    get_filename_component(_root "${root_dir}" ABSOLUTE)

    set(_all_dirs "${_root}")
    set(_current_level "${_root}")

    if(max_depth LESS 1)
        set(${out_var} "${_all_dirs}" PARENT_SCOPE)
        return()
    endif()

    foreach(_depth RANGE 1 ${max_depth})
        set(_next_level "")
        foreach(_dir IN LISTS _current_level)
            file(GLOB _children LIST_DIRECTORIES true "${_dir}/*")
            foreach(_child IN LISTS _children)
                if(IS_DIRECTORY "${_child}")
                    list(APPEND _all_dirs "${_child}")
                    list(APPEND _next_level "${_child}")
                endif()
            endforeach()
        endforeach()

        if(_next_level STREQUAL "")
            break()
        endif()

        set(_current_level "${_next_level}")
    endforeach()

    list(REMOVE_DUPLICATES _all_dirs)
    set(${out_var} "${_all_dirs}" PARENT_SCOPE)
endfunction()

# ------------------------------------------------------------------------------
# find_toolchain_for_target
#
# 用法:
#   find_toolchain_for_target(OUT_VAR ROOT_DIR TARGET_TRIPLE
#       [GCC_VERSION <ver>]
#       [MAX_DEPTH <n>]
#   )
#
# 示例:
#   find_toolchain_for_target(TOOLCHAIN_ROOT
#       "${CMAKE_SOURCE_DIR}/extracted"
#       "aarch64-unknown-linux-gnu"
#   )
#
#   find_toolchain_for_target(TOOLCHAIN_ROOT
#       "${CMAKE_SOURCE_DIR}/extracted"
#       "x86_64-unknown-linux-gnu"
#       GCC_VERSION 15.2.0
#       MAX_DEPTH 4
#   )
#
# 规则:
#   1. 优先匹配:
#        <triple>-gcc<gcc_version>
#      例如:
#        aarch64-unknown-linux-gnu-gcc15.2.0
#
#   2. 如果没有精确匹配，则匹配:
#        <triple><glibc_version>-gcc<gcc_version>
#      例如:
#        aarch64-unknown-linux-gnu2.28-gcc15.2.0
#
#   3. 多个 glibc 版本候选时，返回最老的 glibc 版本（最小版本号）
#
#   4. 候选目录必须通过简单工具链检查：
#        - 存在 bin/
#        - bin 下存在 <triple>-gcc 或 <triple>-cc 或 gcc
#
# 返回:
#   成功:
#     OUT_VAR = 找到的完整目录路径
#
#   失败:
#     FATAL_ERROR
# ------------------------------------------------------------------------------
function(find_toolchain_for_target out_var root_dir target_triple)
    set(options)
    set(oneValueArgs GCC_VERSION MAX_DEPTH)
    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "" ${ARGN})

    if(NOT out_var)
        message(FATAL_ERROR "find_toolchain_for_target: missing out_var")
    endif()

    if(NOT root_dir)
        message(FATAL_ERROR "find_toolchain_for_target: ROOT_DIR is required")
    endif()

    if(NOT target_triple)
        message(FATAL_ERROR "find_toolchain_for_target: TARGET_TRIPLE is required")
    endif()

    if(NOT ARG_GCC_VERSION)
        set(ARG_GCC_VERSION "15.2.0")
    endif()

    if(NOT ARG_MAX_DEPTH)
        set(ARG_MAX_DEPTH 4)
    endif()

    get_filename_component(_root "${root_dir}" ABSOLUTE)
    if(NOT EXISTS "${_root}")
        message(FATAL_ERROR "find_toolchain_for_target: root dir not found: ${_root}")
    endif()

    set(_exact_dir_name "${target_triple}-gcc${ARG_GCC_VERSION}")

    _tf_escape_regex(_triple_re "${target_triple}")
    _tf_escape_regex(_gcc_ver_re "${ARG_GCC_VERSION}")

    set(_glibc_pattern "^${_triple_re}([0-9]+\\.[0-9]+)-gcc${_gcc_ver_re}$")

    _tf_collect_dirs(_all_dirs "${_root}" "${ARG_MAX_DEPTH}")

    set(_exact_match "")
    set(_best_glibc_dir "")
    set(_best_glibc_ver "")

    foreach(_entry IN LISTS _all_dirs)
        if(NOT IS_DIRECTORY "${_entry}")
            continue()
        endif()

        get_filename_component(_base "${_entry}" NAME)

        # 1) 优先找精确匹配
        if(_base STREQUAL "${_exact_dir_name}")
            _tf_is_valid_toolchain_root(_is_valid "${_entry}" "${target_triple}")
            if(_is_valid)
                set(_exact_match "${_entry}")
                break()
            endif()
        endif()

        # 2) 否则找带 glibc 版本的候选
        if(_base MATCHES "${_glibc_pattern}")
            _tf_is_valid_toolchain_root(_is_valid "${_entry}" "${target_triple}")
            if(NOT _is_valid)
                continue()
            endif()

            set(_glibc_ver "${CMAKE_MATCH_1}")

            if(_best_glibc_ver STREQUAL "" OR _glibc_ver VERSION_LESS _best_glibc_ver)
                set(_best_glibc_ver "${_glibc_ver}")
                set(_best_glibc_dir "${_entry}")
            endif()
        endif()
    endforeach()

    if(NOT _exact_match STREQUAL "")
        set(${out_var} "${_exact_match}" PARENT_SCOPE)
        return()
    endif()

    if(NOT _best_glibc_dir STREQUAL "")
        set(${out_var} "${_best_glibc_dir}" PARENT_SCOPE)
        return()
    endif()

    message(FATAL_ERROR
        "find_toolchain_for_target: no matching toolchain found.\n"
        "  ROOT_DIR      = ${_root}\n"
        "  TARGET_TRIPLE = ${target_triple}\n"
        "  GCC_VERSION   = ${ARG_GCC_VERSION}\n"
        "  MAX_DEPTH     = ${ARG_MAX_DEPTH}\n"
        "  Tried exact   = ${_exact_dir_name}\n"
        "  Tried pattern = ${target_triple}<glibc>-gcc${ARG_GCC_VERSION}\n"
        "  Extra check   = bin/<triple>-gcc or bin/<triple>-cc or bin/gcc must exist"
    )
endfunction()