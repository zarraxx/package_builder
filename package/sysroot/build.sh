#!/bin/bash
set -xe
ROOT=$(cd `dirname $0` && pwd)


export PACKAGE="${GLOBAL_PACKAGE:-"sysroot"}"
export PACKAGE_VERSION="${GLOBAL_VERSION:-"15.2.0"}"


export BUILD_DIR="${GLOBAL_BUILD_DIR:-"$ROOT/build"}/${PACKAGE}-${PACKAGE_VERSION}"
export FD_DOWNLOAD_DIR="${GLOBAL_ARCHIVE_DIR:-"$ROOT/archives"}"
export FD_EXTRACT_DIR="${GLOBAL_CACHE_DIR:-"$ROOT/cache"}"

mkdir -p $FD_DOWNLOAD_DIR
mkdir -p $FD_EXTRACT_DIR
rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR

CMAKE_BASE_OPTIONS=(
  -S "$ROOT"
  -DCMAKE_MODULE_PATH="$CMAKE_MODULE_PATH"
  -DMY_PACKAGE_NAME="$PACKAGE"
  -DMY_PACKAGE_VERSION="$PACKAGE_VERSION"
  -B $BUILD_DIR
)

if [ "$GLOBAL_COMMAND" == "source" ]; then
    cmake "${CMAKE_BASE_OPTIONS[@]}" -DPB_STAGE=fetch -DFD_DOWNLOAD_DIR=${FD_DOWNLOAD_DIR} -DFD_EXTRACT_DIR=${FD_EXTRACT_DIR} -DFD_FORCE_EXTRACT=ON 
    cmake --build $BUILD_DIR --target extract_all
fi

if [ "$GLOBAL_COMMAND" == "build" ]; then
    cmake "${CMAKE_BASE_OPTIONS[@]}" -DPB_STAGE=configure \
    -DTOOLCHAIN_SEARCH_ROOT=${FD_EXTRACT_DIR} \
    -DCMAKE_INSTALL_PREFIX=${GLOBAL_DEST_DIR}

    cmake --build $BUILD_DIR --target package_sysroots 
    cmake --install $BUILD_DIR  
fi