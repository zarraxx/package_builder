#!/bin/bash
set -e

ROOT=$(cd `dirname $0` && pwd)
BASE_NAME=$( basename $ROOT )
# $1 version
# $2 archive dir
# $3 build dir
# $4 dest dir


echo "Building package: $BASE_NAME"

VERSION="${1:-"gcc-11.5.0"}"
ARCHIVE_DIR="${2:-"$ROOT/archive"}"
BUILD_DIR="${3:-"$ROOT/build"}/$BASE_NAME/$VERSION"
DEST_DIR="${4:-"$ROOT/dist"}/"
COMMAND="${5:-"build"}"

mkdir -p $ARCHIVE_DIR
mkdir -p $BUILD_DIR
mkdir -p $DEST_DIR

if [ $VERSION == "gcc-11.5.0" ]; then
    TARGET='aarch64-unknown-linux419-gnu217 x86_64-unknown-linux310-gnu217'
    $ROOT/build_ctng.sh "$TARGET" "$ARCHIVE_DIR" "$BUILD_DIR" "$DEST_DIR" "$COMMAND"
elif [ $VERSION == "gcc-15.2.0" ]; then
    $ROOT/build_ctng.sh "$TARGET" "$ARCHIVE_DIR" "$BUILD_DIR" "$DEST_DIR" "$COMMAND"
elif [ $VERSION == "llvm-7.1.0" ]; then
    $ROOT/build_llvm71.sh "$TARGET" "$ARCHIVE_DIR" "$BUILD_DIR" "$DEST_DIR" "$COMMAND"
elif [ $VERSION == "llvm-15" ]; then
    $ROOT/build_llvm.sh "$TARGET" "$ARCHIVE_DIR" "$BUILD_DIR" "$DEST_DIR" "$COMMAND"
elif [ $VERSION == "ctng" ]; then
    $ROOT/build_ctng.sh "ctng" "$ARCHIVE_DIR" "$BUILD_DIR" "$DEST_DIR" "$COMMAND"
else
    echo "Unsupported version: $VERSION"
    exit 1
fi