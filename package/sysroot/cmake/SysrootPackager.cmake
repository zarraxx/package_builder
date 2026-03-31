include_guard(GLOBAL)

#include("${CMAKE_CURRENT_LIST_DIR}/ToolchainFinder.cmake")

function(_sp_normalize_target_name out_var target_triple)
    string(REPLACE "-" "_" _norm "${target_triple}")
    set(${out_var} "${_norm}" PARENT_SCOPE)
endfunction()

function(_sp_add_one_package_rule target_triple toolchain_root output_dir)

    target_for_var_name(_target_norm "${target_triple}")
    set(_pkg_target "${_target_norm}")
    set(_archive_name "${MY_PACKAGE_NAME}-${MY_PACKAGE_VERSION}-${target_triple}.tar.xz")
    set(_archive_path "${output_dir}/${_archive_name}")

    set(_working_dir "${toolchain_root}/${target_triple}")
    set(_input_dir_name "sysroot")

    _fd_add_build_time_rule(
        TARGET_PREFIX "package_sysroot_"
        TARGET_NAME "${_pkg_target}"
        SCRIPT "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/build_time/PackageSysroot.cmake"
        COMMENT_TEXT "Packaging sysroot for ${target_triple}"
        SCRIPT_ARGS
            -DWORKING_DIR=${_working_dir}
            -DINPUT_DIR_NAME=${_input_dir_name}
            -DOUT=${_archive_path}
            -DCREATE_ARCHIVE_SCRIPT=${CMAKE_CURRENT_FUNCTION_LIST_DIR}/build_time/CreateArchive.cmake
            -DFD_FORCE_PACKAGE=${FD_FORCE_PACKAGE}
    )

    set(_sp_last_archive_path "${_archive_path}" PARENT_SCOPE)
    set(_sp_last_target_name "package_sysroot_${_pkg_target}" PARENT_SCOPE)
endfunction()

function(add_package_sysroots_target)
    set(options)
    set(oneValueArgs
        TARGET_NAME
        TOOLCHAIN_SEARCH_ROOT
        OUTPUT_DIR
        GCC_VERSION
        INSTALL_DESTINATION
    )
    set(multiValueArgs TARGETS)
    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if(NOT ARG_TARGET_NAME)
        set(ARG_TARGET_NAME package_sysroots)
    endif()

    if(NOT ARG_TOOLCHAIN_SEARCH_ROOT)
        message(FATAL_ERROR "add_package_sysroots_target: TOOLCHAIN_SEARCH_ROOT is required")
    endif()

    if(NOT ARG_OUTPUT_DIR)
        set(ARG_OUTPUT_DIR "${CMAKE_CURRENT_BINARY_DIR}/sysroot_archives")
    endif()

    if(NOT ARG_GCC_VERSION)
        set(ARG_GCC_VERSION "15.2.0")
    endif()

    if(NOT ARG_INSTALL_DESTINATION)
        set(ARG_INSTALL_DESTINATION "archives")
    endif()

    if(NOT ARG_TARGETS)
        message(FATAL_ERROR "add_package_sysroots_target: TARGETS is required")
    endif()

    cache_set_default(FD_FORCE_PACKAGE BOOL OFF
        "Force re-package sysroot archives even if they already exist")

    set(_all_targets)
    set(_all_archives)

    foreach(_target IN LISTS ARG_TARGETS)
        find_toolchain_for_target(_toolchain_root
            "${ARG_TOOLCHAIN_SEARCH_ROOT}"
            "${_target}"
            GCC_VERSION "${ARG_GCC_VERSION}"
            MAX_DEPTH 6
        )

        message(STATUS "sysroot pack: ${_target}")
        message(STATUS "  toolchain root: ${_toolchain_root}")

        _sp_add_one_package_rule(
            "${_target}"
            "${_toolchain_root}"
            "${ARG_OUTPUT_DIR}"
        )

        list(APPEND _all_targets "${_sp_last_target_name}")
        list(APPEND _all_archives "${_sp_last_archive_path}")
    endforeach()

    add_custom_target("${ARG_TARGET_NAME}" ALL DEPENDS ${_all_targets})

    install(FILES ${_all_archives} DESTINATION "${ARG_INSTALL_DESTINATION}")
endfunction()