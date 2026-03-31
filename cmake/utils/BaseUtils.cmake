include_guard(GLOBAL)

# 用法：
#   cache_set_default(VAR TYPE DEFAULT DOC)
#
# 规则：
# - 如果 VAR 未定义或为空，用 DEFAULT
# - 如果 VAR 已有值，保留原值
# - 最终一定写回 CACHE
function(cache_set_default var_name var_type default_value doc_string)
    if(DEFINED ${var_name} AND NOT "${${var_name}}" STREQUAL "")
        set(_value "${${var_name}}")
    else()
        set(_value "${default_value}")
    endif()

    set(${var_name} "${_value}" CACHE ${var_type} "${doc_string}" FORCE)
endfunction()

function(append_module_path_if_exists dir)
    if(EXISTS "${dir}" AND IS_DIRECTORY "${dir}")
        list(FIND CMAKE_MODULE_PATH "${dir}" _idx)
        if(_idx EQUAL -1)
            list(APPEND CMAKE_MODULE_PATH "${dir}")
            message(STATUS "Added to CMAKE_MODULE_PATH: ${dir}")
        endif()
    endif()
endfunction()