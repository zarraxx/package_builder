#!/bin/bash
set -e

ROOT=$(cd `dirname $0` && pwd)

# $1 package 
# $2 version
# $3 command
# $4 archive dir
# $5 dest dir
# $6 build dir


PACKAGE="${1:-"compiler"}"
VERSION="${2:-"gcc-11.5.0"}"
COMMAND="${3:-"build"}"
ARCHIVE_DIR="${4:-"$ROOT/archive"}"
DEST_DIR="${5:-"$ROOT/dist"}"
BUILD_DIR="${6:-"$ROOT/build"}"


mkdir -p $ARCHIVE_DIR
mkdir -p $BUILD_DIR
mkdir -p $DEST_DIR

$ROOT/package/$PACKAGE/build.sh "$VERSION" "$ARCHIVE_DIR" "$BUILD_DIR" "$DEST_DIR" "$COMMAND"