include_guard(GLOBAL)

function(system_name out_var)
    if(NOT out_var)
        message(FATAL_ERROR "system_name(out_var): missing output variable name")
    endif()

    if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
        set(_name "linux")
    elseif(CMAKE_SYSTEM_NAME STREQUAL "Windows")
        set(_name "mingw-w64")
    elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
        set(_name "darwin")
    else()
        message(FATAL_ERROR
            "Unsupported system: CMAKE_SYSTEM_NAME='${CMAKE_SYSTEM_NAME}'. "
            "Supported systems are Linux, Windows, Darwin."
        )
    endif()

    set(${out_var} "${_name}" PARENT_SCOPE)
endfunction()

function(system_arch out_var)
    if(NOT out_var)
        message(FATAL_ERROR "system_arch(out_var): missing output variable name")
    endif()

    string(TOLOWER "${CMAKE_SYSTEM_PROCESSOR}" _proc)

    # Normalize common 64-bit architectures
    if(_proc STREQUAL "x86_64" OR _proc STREQUAL "amd64")
        set(_arch "x86_64")

    elseif(_proc STREQUAL "aarch64" OR _proc STREQUAL "arm64")
        set(_arch "aarch64")

    elseif(_proc STREQUAL "loongarch64")
        set(_arch "loongarch64")

    elseif(_proc STREQUAL "riscv64")
        set(_arch "riscv64")

    # Explicitly reject common 32-bit architectures
    elseif(
        _proc STREQUAL "x86"
        OR _proc STREQUAL "i386"
        OR _proc STREQUAL "i486"
        OR _proc STREQUAL "i586"
        OR _proc STREQUAL "i686"
        OR _proc STREQUAL "arm"
        OR _proc STREQUAL "armv6"
        OR _proc STREQUAL "armv7"
        OR _proc STREQUAL "armv7l"
        OR _proc STREQUAL "armhf"
        OR _proc STREQUAL "armel"
        OR _proc STREQUAL "riscv32"
        OR _proc STREQUAL "loongarch32"
    )
        message(FATAL_ERROR
            "Unsupported 32-bit architecture: CMAKE_SYSTEM_PROCESSOR='${CMAKE_SYSTEM_PROCESSOR}'. "
            "Only 64-bit architectures are supported: x86_64, aarch64, loongarch64, riscv64."
        )

    else()
        message(FATAL_ERROR
            "Unsupported architecture: CMAKE_SYSTEM_PROCESSOR='${CMAKE_SYSTEM_PROCESSOR}'. "
            "Supported architectures are x86_64, aarch64/arm64, loongarch64, riscv64."
        )
    endif()

    set(${out_var} "${_arch}" PARENT_SCOPE)
endfunction()


function(system_target out_var)
    if(NOT out_var)
        message(FATAL_ERROR "system_target(out_var): missing output variable name")
    endif()

    system_name(_sys_name)
    system_arch(_sys_arch)

    set(${out_var} "${_sys_name}-${_sys_arch}" PARENT_SCOPE)
endfunction()