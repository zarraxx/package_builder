include_guard(GLOBAL)

include(utils/BaseUtils)
include(utils/BuildTimeUtils)
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


function(_fd_add_one_fetch_rule dep_name dep_url dep_filename output_dir)
    set(_out_file  "${output_dir}/${dep_filename}")

    _fd_add_build_time_rule(
        TARGET_PREFIX fetch_
        TARGET_NAME "${dep_name}"
     #   STAMP_DIR "${_stamp_dir}"
        SCRIPT "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/build_time/FetchFile.cmake"
        COMMENT_TEXT "Fetching ${dep_name}"
        SCRIPT_ARGS
            -DURL=${dep_url}
            -DOUT=${_out_file}
            -DFD_FORCE_DOWNLOAD=${FD_FORCE_DOWNLOAD}
        EXTRA_DEPENDS
    )
endfunction()

function(_fd_add_one_extract_rule dep_name archive_file extract_dir_root)
    #set(_stamp_dir    "${CMAKE_CURRENT_BINARY_DIR}/extract_stamps")
    set(_archive_path "${FD_DOWNLOAD_DIR}/${archive_file}")
    set(_dest_dir     "${extract_dir_root}")

    _fd_add_build_time_rule(
        TARGET_PREFIX extract_
        TARGET_NAME "${dep_name}"
        #STAMP_DIR "${_stamp_dir}"
        SCRIPT "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/build_time/ExtractFile.cmake"
        COMMENT_TEXT "Extracting ${dep_name}"
        SCRIPT_ARGS
            -DARCHIVE=${_archive_path}
            -DDESTINATION=${_dest_dir}/${dep_name}
            -DFD_FORCE_EXTRACT=${FD_FORCE_EXTRACT}
        EXTRA_DEPENDS
            "fetch_${dep_name}"
    )
endfunction()

# -----------------------------
# 主函数
# -----------------------------
function(add_fetch_deps_target)
    set(options)
    set(oneValueArgs FETCH_TARGET_NAME EXTRACT_TARGET_NAME JSON_FILE OUTPUT_DIR)
    cmake_parse_arguments(FD "${options}" "${oneValueArgs}" "" ${ARGN})

    if(NOT FD_FETCH_TARGET_NAME)
        set(FD_FETCH_TARGET_NAME fetch_all)
    endif()

    if(NOT FD_EXTRACT_TARGET_NAME)
        set(FD_EXTRACT_TARGET_NAME extract_all)
    endif()

    if(NOT FD_EXTRACT_TARGET_NAME)
        set(FD_EXTRACT_TARGET_NAME extract_all)
    endif()

    cache_set_default(FD_JSON_FILE FILEPATH "${CMAKE_SOURCE_DIR}/deps.json"
    "Path to dependency JSON file")

    cache_set_default(FD_DOWNLOAD_DIR PATH "${CMAKE_BINARY_DIR}/downloads"
    "Directory to store downloaded files")

    cache_set_default(FD_EXTRACT_DIR PATH "${CMAKE_SOURCE_DIR}/dependency"
        "Directory to extract downloaded archives")

    cache_set_default(FD_FORCE_DOWNLOAD BOOL OFF
    "Force re-download of files even if they exist")

    cache_set_default(FD_FORCE_EXTRACT BOOL OFF
    "Force re-extract archives even if destination exists")

    if(NOT FD_JSON_FILE)
        message(FATAL_ERROR "JSON_FILE required")
    endif()

    if(NOT FD_DOWNLOAD_DIR)
        message(FATAL_ERROR "DOWNLOAD_DIR required")
    endif()

    if(NOT FD_EXTRACT_DIR)
        message(FATAL_ERROR "EXTRACT_DIR required")
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
        _fd_json_get(_ver_tpl  "${_json}" deps ${i} version)
        _fd_json_get(_url_tpl  "${_json}" deps ${i} url)
        _fd_json_get(_file_tpl "${_json}" deps ${i} filename)

        # 模板渲染
        _fd_render_template(_ver  "${_ver_tpl}"  "${_name}" "" "${_sys_name}" "${_sys_arch}" "${_sys_target}" )
        
        _fd_render_template(_url  "${_url_tpl}"  "${_name}" "${_ver}" "${_sys_name}" "${_sys_arch}" "${_sys_target}")
        _fd_render_template(_file "${_file_tpl}" "${_name}" "${_ver}" "${_sys_name}" "${_sys_arch}" "${_sys_target}" )

        message(STATUS "dep: ${_name}")
        message(STATUS " url: ${_url}")
        message(STATUS " out: ${_file}")

        _fd_add_one_fetch_rule("${_name}" "${_url}" "${_file}" "${FD_DOWNLOAD_DIR}")
        list(APPEND _fetch_targets "fetch_${_name}")

        _fd_add_one_extract_rule("${_name}" "${_file}" "${FD_EXTRACT_DIR}")
        list(APPEND _extract_targets "extract_${_name}")

        string(REPLACE "-" "_" _name_var "${_name}")
        set_property(GLOBAL PROPERTY "FD_DEPEND_NAME_${_name_var}" "${_name}")
        set_property(GLOBAL PROPERTY "FD_DEPEND_FILE_${_name_var}" "${_file}")
        set_property(GLOBAL PROPERTY "FD_DEPEND_VERSION_${_name_var}" "${_ver}")
        set_property(GLOBAL PROPERTY "FD_DEPEND_EXTRACT_DIR_${_name_var}" "${FD_EXTRACT_DIR}/${_name}")
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

    add_custom_target(${FD_FETCH_TARGET_NAME} DEPENDS ${_fetch_targets})
    add_custom_target(${FD_EXTRACT_TARGET_NAME} DEPENDS ${FD_FETCH_TARGET_NAME} ${_extract_targets})
endfunction()