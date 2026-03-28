#!/bin/bash
set -e

ROOT=$(cd `dirname $0` && pwd)

# $1 package 
# $2 version
# $3 archive dir
# $4 build dir
# $5 dest dir

PACKAGE="${1:-"compiler"}"
VERSION="${2:-"gcc-11.5.0"}"
COMMAND="${3:-"build"}"
ARCHIVE_DIR="${4:-"$ROOT/archive"}"
BUILD_DIR="${5:-"$ROOT/build"}"
DEST_DIR="${6:-"$ROOT/dist"}"

mkdir -p $ARCHIVE_DIR
mkdir -p $BUILD_DIR
mkdir -p $DEST_DIR

$ROOT/package/$PACKAGE/build.sh "$VERSION" "$ARCHIVE_DIR" "$BUILD_DIR" "$DEST_DIR" "$COMMAND"