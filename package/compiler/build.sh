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

echo "Building version: $VERSION"
mkdir -p $ARCHIVE_DIR
mkdir -p $BUILD_DIR
mkdir -p $DEST_DIR

if [ $VERSION == "gcc-11.5.0" ]; then
    TARGET='aarch64-unknown-linux-gnu-gcc11 x86_64-unknown-linux-gnu-gcc11'
    $ROOT/build_ctng.sh "$TARGET" "$ARCHIVE_DIR" "$BUILD_DIR" "$DEST_DIR" "$COMMAND"
elif [ $VERSION == "gcc-12.5.0" ]; then
    TARGET='aarch64-unknown-linux-gnu-gcc12 x86_64-unknown-linux-gnu-gcc12'
    $ROOT/build_ctng.sh "$TARGET" "$ARCHIVE_DIR" "$BUILD_DIR" "$DEST_DIR" "$COMMAND"
elif [ $VERSION == "gcc-15.2.0" ]; then
    #TARGET='aarch64-unknown-linux-gnu-gcc15 x86_64-unknown-linux-gnu-gcc15 loongarch64-unknown-linux-gnu-gcc15 riscv64-unknown-linux-gnu-gcc15'
    TARGET='aarch64-unknown-linux-gnu-gcc15 x86_64-unknown-linux-gnu-gcc15 loongarch64-unknown-linux-gnu-gcc15 riscv64-unknown-linux-gnu-gcc15 x86_64-w64-mingw32-gcc15'
    $ROOT/build_ctng.sh "$TARGET" "$ARCHIVE_DIR" "$BUILD_DIR" "$DEST_DIR" "$COMMAND"
elif [ $VERSION == "loongarch64-gcc-15.2.0" ]; then
    TARGET='loongarch64-unknown-linux-gnu-gcc15'
    $ROOT/build_ctng.sh "$TARGET" "$ARCHIVE_DIR" "$BUILD_DIR" "$DEST_DIR" "$COMMAND"
elif [ $VERSION == "riscv64-gcc-15.2.0" ]; then
    TARGET='riscv64-unknown-linux-gnu-gcc15'
    $ROOT/build_ctng.sh "$TARGET" "$ARCHIVE_DIR" "$BUILD_DIR" "$DEST_DIR" "$COMMAND"
elif [ $VERSION == "mingw32-gcc-15.2.0" ]; then
    TARGET='x86_64-w64-mingw32-gcc15'
    $ROOT/build_ctng.sh "$TARGET" "$ARCHIVE_DIR" "$BUILD_DIR" "$DEST_DIR" "$COMMAND"
elif [ $VERSION == "llvm-7.1.0" ]; then
    $ROOT/build_llvm71.sh "$TARGET" "$ARCHIVE_DIR" "$BUILD_DIR" "$DEST_DIR" "$COMMAND"
elif [ $VERSION == "llvm-15.0.7" ]; then
    $ROOT/build_llvm.sh "15.0.7" "$ARCHIVE_DIR" "$BUILD_DIR" "$DEST_DIR" "$COMMAND"
elif [ $VERSION == "llvm-16.0.6" ]; then
    $ROOT/build_llvm.sh "16.0.6" "$ARCHIVE_DIR" "$BUILD_DIR" "$DEST_DIR" "$COMMAND"
elif [ $VERSION == "llvm-17.0.6" ]; then
    $ROOT/build_llvm.sh "17.0.6" "$ARCHIVE_DIR" "$BUILD_DIR" "$DEST_DIR" "$COMMAND"
elif [ $VERSION == "llvm-18.1.8" ]; then
    $ROOT/build_llvm.sh "18.1.8" "$ARCHIVE_DIR" "$BUILD_DIR" "$DEST_DIR" "$COMMAND"
elif [ $VERSION == "ctng" ]; then
    $ROOT/build_ctng.sh "ctng" "$ARCHIVE_DIR" "$BUILD_DIR" "$DEST_DIR" "$COMMAND"
else
    echo "Unsupported version: $VERSION"
    exit 1
fi