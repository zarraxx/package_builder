#!/bin/bash

NAME=ctng_build
IMAGE=registry.cn-hangzhou.aliyuncs.com/zarra/centos:ctng
ROOT="$(cd $(dirname "$(realpath "$0")");pwd)"

TARGET="${1:-"ctng"}"
ARCHIVE_DIR="${2:-"$ROOT/archive"}"
BUILD_DIR="${3:-"$ROOT/build"}"
DEST_DIR="${4:-"$ROOT/dist"}"
COMMAND="${5:-"build"}"

CTNG_HOME=$BUILD_DIR
WORKSPACE=$ROOT/ctng_workspace

mkdir -p $CTNG_HOME
rm -rf $CTNG_HOME/*
mkdir -p $WORKSPACE
mkdir -p $CTNG_HOME


# Check if container with same name exists, stop and remove it
if podman ps -a --format '{{.Names}}' | grep -q "^${NAME}$"; then
    echo "Container $NAME already exists, stopping and removing it..."
    podman stop $NAME 2>/dev/null || true
    podman rm $NAME 2>/dev/null || true
fi



echo "Building for target: $TARGET"


if [ "$TARGET" == "ctng" ]; then
    CMD_ARGS=() 
else 
    CMD_ARGS=("-c" "/script/build_xtools.sh $TARGET")
fi


set -x
# podman run -it --rm --name=$NAME  \
#         --userns=keep-id \
#         -e LINES=50 -e COLUMNS=160 \
#         -e CT_PREFIX=/opt/x-tools/compilers \
#         -e CTNG_COMMAND="${COMMAND}" \
#         -v $CTNG_HOME/:/home/ctng:z,U \
#         -v $WORKSPACE/:/home/ctng/workspace:z,U \
#         -v $ARCHIVE_DIR/:/home/ctng/src:z,U \
#         -v $DEST_DIR/:/opt/x-tools/compilers:z,U \
#         -v $ROOT/example/:/example:z,U \
#         -v $ROOT/script:/script:z,U \
#     	$IMAGE /bin/bash  "${CMD_ARGS[@]}"

touch $DEST_DIR/dummy.txt