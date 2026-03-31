include_guard(GLOBAL)

include(CacheUtils)
include(SystemInfo)

# -----------------------------
# JSON 读取
# -----------------------------
function(_fd_json_get out_var json_text)
    set(_path ${ARGN})
    string(JSON _value GET "${json_text}" ${_path})
    set(${out_var} "${_value}" PARENT_SCOPE)
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

    # 兼容 ${xxx} 写法（可选）
    string(REPLACE "\${name}"         "${dep_name}" _result "${_result}")
    string(REPLACE "\${ver}"          "${dep_ver}"  _result "${_result}")
    string(REPLACE "\${version}"      "${dep_ver}"  _result "${_result}")
    string(REPLACE "\${system_name}"  "${sys_name}" _result "${_result}")
    string(REPLACE "\${system_arch}"  "${sys_arch}" _result "${_result}")
    string(REPLACE "\${system_target}"  "${sys_target}" _result "${_result}")

    set(${out_var} "${_result}" PARENT_SCOPE)
endfunction()

# -----------------------------
# 单个 fetch 规则
# -----------------------------
function(_fd_add_one_fetch_rule dep_name dep_url dep_filename output_dir)
    set(_stamp_dir "${CMAKE_CURRENT_BINARY_DIR}/fetch_stamps")
    file(MAKE_DIRECTORY "${_stamp_dir}")

    set(_out_file   "${output_dir}/${dep_filename}")
    set(_stamp_file "${_stamp_dir}/${dep_name}.stamp")

    add_custom_command(
        OUTPUT "${_stamp_file}"
        COMMAND ${CMAKE_COMMAND} -E make_directory "${output_dir}"
        COMMAND ${CMAKE_COMMAND}
                -DURL=${dep_url}
                -DOUT="${_out_file}"
                -DSTAMP="${_stamp_file}"
                -DFD_FORCE_DOWNLOAD=${FD_FORCE_DOWNLOAD}
                -P "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/build_time/FetchFile.cmake"
        DEPENDS "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/build_time/FetchFile.cmake"
        COMMENT "Fetching ${dep_name}"
        VERBATIM
    )

    add_custom_target("fetch_${dep_name}" DEPENDS "${_stamp_file}")
endfunction()

# -----------------------------
# 主函数
# -----------------------------
function(add_fetch_all_target)
    set(options)
    set(oneValueArgs TARGET_NAME JSON_FILE OUTPUT_DIR)
    cmake_parse_arguments(FD "${options}" "${oneValueArgs}" "" ${ARGN})

    if(NOT FD_TARGET_NAME)
        set(FD_TARGET_NAME fetch_all)
    endif()

    cache_set_default(FD_JSON_FILE FILEPATH "${CMAKE_SOURCE_DIR}/deps.json"
    "Path to dependency JSON file")

    cache_set_default(FD_OUTPUT_DIR PATH "${CMAKE_BINARY_DIR}/downloads"
    "Directory to store downloaded files")

    cache_set_default(FD_FORCE_DOWNLOAD BOOL OFF
    "Force re-download of files even if they exist")

    if(NOT FD_JSON_FILE)
        message(FATAL_ERROR "JSON_FILE required")
    endif()

    if(NOT FD_OUTPUT_DIR)
        message(FATAL_ERROR "OUTPUT_DIR required")
    endif()

    file(READ "${FD_JSON_FILE}" _json)

    # 获取系统信息
    system_name(_sys_name)
    system_arch(_sys_arch)
    system_target(_sys_target)

    message(STATUS "System: ${_sys_name}-${_sys_arch}")

    string(JSON _len LENGTH "${_json}" deps)
    math(EXPR _last "${_len} - 1")

    set(_targets)

    foreach(i RANGE 0 ${_last})
        _fd_json_get(_name "${_json}" deps ${i} name)
        _fd_json_get(_ver  "${_json}" deps ${i} version)
        _fd_json_get(_url_tpl  "${_json}" deps ${i} url)
        _fd_json_get(_file_tpl "${_json}" deps ${i} filename)

        # 模板渲染
        _fd_render_template(_url  "${_url_tpl}"  "${_name}" "${_ver}" "${_sys_name}" "${_sys_arch}" "${_sys_target}")
        _fd_render_template(_file "${_file_tpl}" "${_name}" "${_ver}" "${_sys_name}" "${_sys_arch}" "${_sys_target}")

        message(STATUS "dep: ${_name}")
        message(STATUS " url: ${_url}")
        message(STATUS " out: ${_file}")

        _fd_add_one_fetch_rule("${_name}" "${_url}" "${_file}" "${FD_OUTPUT_DIR}")
        list(APPEND _targets "fetch_${_name}")

        string(REPLACE "-" "_" _name_var "${_name}")
        set_property(GLOBAL PROPERTY "FD_DEPEND_FILE_${_name_var}" "${_file}")
        set_property(GLOBAL PROPERTY "FD_DEPEND_VERSION_${_name_var}" "${_ver}")

        get_property(_dep_file GLOBAL PROPERTY FD_DEPEND_FILE_${_name_var})
        get_property(_dep_ver GLOBAL PROPERTY FD_DEPEND_VERSION_${_name_var})

        message(STATUS " PROPERTY: FD_DEPEND_FILE_${_name_var} -> ${FD_OUTPUT_DIR}/${_dep_file}  added")
        message(STATUS " PROPERTY: FD_DEPEND_VERSION_${_name_var} -> ${_dep_ver}  added")

    endforeach()

    add_custom_target(${FD_TARGET_NAME} DEPENDS ${_targets})
endfunction()