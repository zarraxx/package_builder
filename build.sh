#!/bin/bash
set -e

ROOT=$(cd `dirname $0` && pwd)

# $1 package 
# $2 version
# $3 command
# $4 archive dir
# $5 dest dir
# $6 build dir


export GLOBAL_PACKAGE="${1:-"compiler"}"
export GLOBAL_VERSION="${2:-"gcc-11.5.0"}"
export GLOBAL_COMMAND="${3:-"build"}"
export GLOBAL_ARCHIVE_DIR="${4:-"$ROOT/archive"}"
export GLOBAL_DEST_DIR="${5:-"$ROOT/dist"}"
export GLOBAL_BUILD_DIR="${6:-"$ROOT/build"}"
export GLOBAL_CACHE_DIR="${7:-"$ROOT/cache"}"

mkdir -p $GLOBAL_ARCHIVE_DIR
mkdir -p $GLOBAL_BUILD_DIR
mkdir -p $GLOBAL_DEST_DIR
mkdir -p $GLOBAL_CACHE_DIR

export MY_CMAKE_MODULE_PATH="$ROOT/cmake"
export CMAKE_MODULE_PATH="$ROOT/cmake;$CMAKE_MODULE_PATH"

$ROOT/package/$GLOBAL_PACKAGE/build.sh "$GLOBAL_VERSION" "$GLOBAL_ARCHIVE_DIR" "$GLOBAL_BUILD_DIR" "$GLOBAL_DEST_DIR" "$GLOBAL_COMMAND"