cmake_minimum_required(VERSION 3.20)
project(libcxx NONE)
include(MyPackageTools)

#append_module_path_if_exists("${CMAKE_SOURCE_DIR}/cmake")
#append_module_path_if_exists("${CMAKE_SOURCE_DIR}/.cmake")

include("cmake/SysrootPackager.cmake")

if(NOT MY_PACKAGE_NAME)
    set (MY_PACKAGE_NAME ${PROJECT_NAME})
endif(NOT MY_PACKAGE_NAME)

if(NOT MY_PACKAGE_VERSION)
    set (MY_PACKAGE_VERSION "15.2.0")
endif(NOT MY_PACKAGE_VERSION)

message(STATUS "Project name = ${PROJECT_NAME}")

set(PB_STAGE "configure" CACHE STRING "Stage: fetch or configure")
set_property(CACHE PB_STAGE PROPERTY STRINGS fetch configure)

message(STATUS "PB_STAGE = ${PB_STAGE}")

if(PB_STAGE STREQUAL "fetch")
    add_fetch_deps_target()
    return()
elseif(NOT PB_STAGE STREQUAL "configure")
    message(FATAL_ERROR "Unsupported PB_STAGE='${PB_STAGE}', expected fetch or configure")
endif()

# ---------- 正常配置阶段 ----------


cache_set_default(TOOLCHAIN_SEARCH_ROOT PATH "${CMAKE_SOURCE_DIR}/dependency"
    "Prepared toolchain root directory")

if(NOT EXISTS "${TOOLCHAIN_SEARCH_ROOT}")
    message(FATAL_ERROR
        "Toolchain directory not found: ${TOOLCHAIN_SEARCH_ROOT}\n"
        "Run dependency preparation first:\n"
        "  cmake -S . -B build-fetch -DPB_STAGE=fetch\n"
        "  cmake --build build-fetch --target extract_all"
    )
endif()


if(NOT SUPPORTED_TARGETS)
    set(SUPPORTED_TARGETS
        x86_64-unknown-linux-gnu
        aarch64-unknown-linux-gnu
        loongarch64-unknown-linux-gnu
        riscv64-unknown-linux-gnu
    )
endif(NOT SUPPORTED_TARGETS)

# foreach(_target ${SUPPORTED_TARGETS})
#     message(STATUS "TARGET:${_target}")

#     target_for_var_name(_target_var "${_target}")
#     set(_toolchain_var "TOOLCHAIN_ROOT_${_target_var}")
    
#     find_toolchain_for_target(${_toolchain_var}
#       "${TOOLCHAIN_SEARCH_ROOT}"
#       "${_target}"
#       GCC_VERSION 15.2.0
#     )

#     message(STATUS "find ${_target} TOOLCHAIN_ROOT: ${${_toolchain_var}}")
# endforeach()


add_package_sysroots_target(
    TARGET_NAME package_sysroots
    TOOLCHAIN_SEARCH_ROOT "${TOOLCHAIN_SEARCH_ROOT}"
    OUTPUT_DIR "${CMAKE_BINARY_DIR}/sysroot_archives"
    GCC_VERSION "${MY_PACKAGE_VERSION}"
    TARGETS ${SUPPORTED_TARGETS}
)


