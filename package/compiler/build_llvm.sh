#!/bin/bash
set -e

NAME=llvm_build
IMAGE=registry.cn-hangzhou.aliyuncs.com/zarra/centos:x-tools-base
ROOT="$(cd $(dirname "$(realpath "$0")");pwd)"
ARCH=`uname -m`

if [ "$LLVM_VERSION" == "7.1.0" ]; then
    SCRIPT="build_llvm71.sh"
else
    SCRIPT="build_llvm.sh"
    #IMAGE=registry.cn-hangzhou.aliyuncs.com/zarra/centos:x-tools-base
fi


DOCKER=${DOCKER:-podman}

LLVM_VERSION="${1:-"15.0.7"}"
ARCHIVE_DIR="${2:-"$ROOT/archive"}"
BUILD_DIR="${3:-"$ROOT/build"}"
DEST_DIR="${4:-"$ROOT/dist"}"
COMMAND="${5:-"build"}"




if [ "$COMMAND" == "build" ]; then
    echo "Building LLVM ${LLVM_VERSION}..."

    mkdir -p $ARCHIVE_DIR
    mkdir -p $BUILD_DIR
    mkdir -p "$DEST_DIR"

    DOCKER=${DOCKER:-podman}



    $DOCKER run -it --rm --name=$NAME  \
            -e LINES=50 -e COLUMNS=160 \
            -v $BUILD_DIR:/workspace/build:z,U \
            -v $ARCHIVE_DIR:/workspace/archive:z,U \
            -v $DEST_DIR:/opt/x-tools/compilers:z,U \
            -v $ROOT/script:/script:z,U \
            $IMAGE /bin/bash -c "/script/$SCRIPT $LLVM_VERSION"
else
    echo "Unsupported command: $COMMAND"
    exit 0
fi
