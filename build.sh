#!/bin/bash
set -e

NAME=llvm_build
IMAGE=registry.cn-hangzhou.aliyuncs.com/zarra/centos:x-tools-base
ROOT="$(cd $(dirname "$(realpath "$0")");pwd)"
ARCH=`uname -m`

LLVM_VERSION=${1:-"7.1.0"}

if [ "$LLVM_VERSION" == "7.1.0" ]; then
    SCRIPT="build_llvm71.sh"
else
    SCRIPT="build_llvm.sh"
    #IMAGE=registry.cn-hangzhou.aliyuncs.com/zarra/centos:x-tools-base
fi


DOCKER=${DOCKER:-podman}

ARCHIVE_DIR=$ROOT/archive
WORKSPACE=$ROOT/build
DEST_DIR=$ROOT/dist
OUTPUT_DIR=$ROOT/out

mkdir -p $ARCHIVE_DIR
mkdir -p $DEST_DIR
mkdir -p $OUTPUT_DIR
rm -rf $WORKSPACE
#rm -rf "$DEST_DIR"
mkdir -p $WORKSPACE
mkdir -p "$DEST_DIR"

DOCKER=${DOCKER:-podman}



$DOCKER run -it --rm --name=$NAME  \
        -e LINES=50 -e COLUMNS=160 \
        -v $WORKSPACE:/workspace/build:z,U \
        -v $ARCHIVE_DIR:/workspace/archive:z,U \
        -v $DEST_DIR:/opt/x-tools/compilers:z,U \
        -v $ROOT/script:/script:z,U \
    	$IMAGE /bin/bash -c "/script/$SCRIPT $LLVM_VERSION"