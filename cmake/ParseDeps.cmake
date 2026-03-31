include_guard(GLOBAL)

include(utils/BaseUtils)
include(utils/BuildTimeUtils)
include(SystemInfo)

# -----------------------------
# JSON 读取
# -----------------------------
function(_fd_json_get out_var json)
    set(options)
    set(oneValueArgs DEFAULT)
    set(multiValueArgs PATH)
    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    # PATH 是 json 路径，比如 deps 0 name
    if(NOT ARG_PATH)
        message(FATAL_ERROR "_fd_json_get: PATH is required")
    endif()

    # 尝试获取
    set(_value "")
    set(_ok TRUE)

    # 用 try-catch 模拟（CMake 没有异常，只能用 RESULT_VARIABLE）
    string(JSON _value ERROR_VARIABLE _err GET "${json}" ${ARG_PATH})

    if(_err)
        set(_ok FALSE)
    endif()

    if(_ok)
        set(${out_var} "${_value}" PARENT_SCOPE)
    else()
        if(DEFINED ARG_DEFAULT)
            set(${out_var} "${ARG_DEFAULT}" PARENT_SCOPE)
        else()
            # 不提供默认值就报错
            message(FATAL_ERROR
                "_fd_json_get: key not found and no default provided\n"
                "  PATH = ${ARG_PATH}"
            )
        endif()
    endif()
endfunction()
# -----------------------------
# 模板替换（增强版）
# 支持：
#   @name@ @ver@ @version@
#   @system_name@ @system_arch@
# -----------------------------
function(_fd_render_template out_var template_text dep_name dep_ver sys_name sys_arch sys_target)
    set(_result "${template_text}")

    # 基础变量
    string(REPLACE "@name@"    "${dep_name}" _result "${_result}")
    string(REPLACE "@ver@"     "${dep_ver}"  _result "${_result}")
    string(REPLACE "@version@" "${dep_ver}"  _result "${_result}")

    # 系统变量
    string(REPLACE "@system_name@" "${sys_name}" _result "${_result}")
    string(REPLACE "@system_arch@" "${sys_arch}" _result "${_result}")
    string(REPLACE "@system_target@" "${sys_target}" _result "${_result}")

    string(REPLACE "@system_target@" "${sys_target}" _result "${_result}")
    string(REPLACE "@package_name@" "${MY_PACKAGE_NAME}" _result "${_result}")
    string(REPLACE "@package_version@" "${MY_PACKAGE_VERSION}" _result "${_result}")

    # 兼容 ${xxx} 写法（可选）
    string(REPLACE "\${name}"         "${dep_name}" _result "${_result}")
    string(REPLACE "\${ver}"          "${dep_ver}"  _result "${_result}")
    string(REPLACE "\${version}"      "${dep_ver}"  _result "${_result}")
    string(REPLACE "\${system_name}"  "${sys_name}" _result "${_result}")
    string(REPLACE "\${system_arch}"  "${sys_arch}" _result "${_result}")
    string(REPLACE "\${system_target}"  "${sys_target}" _result "${_result}")

    string(REPLACE "\${package_name}"  "${MY_PACKAGE_NAME}" _result "${_result}")
    string(REPLACE "\${package_version}"  "${MY_PACKAGE_VERSION}" _result "${_result}")

    set(${out_var} "${_result}" PARENT_SCOPE)
endfunction()

function(parse_dependencies_file)
    set(options)
    set(oneValueArgs JSON_FILE )
    cmake_parse_arguments(FD "${options}" "${oneValueArgs}" "" ${ARGN})

    if(NOT FD_JSON_FILE)
        message(FATAL_ERROR "JSON_FILE required")
    endif()

    # 获取系统信息
    system_name(_sys_name)
    system_arch(_sys_arch)
    system_target(_sys_target)

    file(READ "${FD_JSON_FILE}" _json)

    
    string(JSON _len LENGTH "${_json}" deps)
    math(EXPR _last "${_len} - 1")

    set(_targets)

    foreach(i RANGE 0 ${_last})
        _fd_json_get(_name "${_json}" 
            PATH deps ${i} name
        )
        _fd_json_get(_ver_tpl  "${_json}" 
            PATH deps ${i} version
        )
        _fd_json_get(_url_tpl  "${_json}" 
            PATH deps ${i} url
        )
        _fd_json_get(_file_tpl "${_json}" 
            PATH deps ${i} filename
        )

        _fd_json_get(_extract_tpl "${_json}" 
            PATH deps ${i} extract  
            DEFAULT ${_name}
        )

        # 模板渲染
        _fd_render_template(_ver  "${_ver_tpl}"  "${_name}" "" "${_sys_name}" "${_sys_arch}" "${_sys_target}" )
        _fd_render_template(_url  "${_url_tpl}"  "${_name}" "${_ver}" "${_sys_name}" "${_sys_arch}" "${_sys_target}")
        _fd_render_template(_file "${_file_tpl}" "${_name}" "${_ver}" "${_sys_name}" "${_sys_arch}" "${_sys_target}" )
        _fd_render_template(_extract_name "${_extract_tpl}" "${_name}" "${_ver}" "${_sys_name}" "${_sys_arch}" "${_sys_target}" )


        message(STATUS "dep: ${_name}")
        message(STATUS " url: ${_url}")
        message(STATUS " out: ${_file}")

        string(REPLACE "-" "_" _name_var "${_name}")
        set_property(GLOBAL PROPERTY "FD_DEPEND_NAME_${_name_var}" "${_name}")
        set_property(GLOBAL PROPERTY "FD_DEPEND_FILE_${_name_var}" "${_file}")
        set_property(GLOBAL PROPERTY "FD_DEPEND_VERSION_${_name_var}" "${_ver}")
        set_property(GLOBAL PROPERTY "FD_DEPEND_EXTRACT_DIR_${_name_var}" "${FD_EXTRACT_DIR}/${_extract_name}")
        set_property(GLOBAL APPEND PROPERTY FD_DEPEND_KEYS "${_name_var}")

        get_property(_dep_name GLOBAL PROPERTY FD_DEPEND_NAME_${_name_var})
        get_property(_dep_file GLOBAL PROPERTY FD_DEPEND_FILE_${_name_var})
        get_property(_dep_ver GLOBAL PROPERTY FD_DEPEND_VERSION_${_name_var})
        get_property(_dep_extract_dir GLOBAL PROPERTY "FD_DEPEND_EXTRACT_DIR_${_name_var}")

        message(STATUS " ADD PROPERTY: FD_DEPEND_NAME_${_name_var} -> ${_dep_name}  ")
        message(STATUS " ADD PROPERTY: FD_DEPEND_FILE_${_name_var} -> ${FD_DOWNLOAD_DIR}/${_dep_file}  ")
        message(STATUS " ADD PROPERTY: FD_DEPEND_VERSION_${_name_var} -> ${_dep_ver}  ")
        message(STATUS " ADD PROPERTY: FD_DEPEND_EXTRACT_DIR_${_name_var} -> ${_dep_extract_dir}  ")

    endforeach()
    
endfunction()