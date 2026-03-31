cmake_minimum_required(VERSION 3.20)
project(fetch_demo NONE)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake")
include(MyPackageTools)



add_fetch_all_target(
    TARGET_NAME fetch_all
)