#!/bin/bash
set -xe
mkdir -p archives
rm -rf build
cmake -S . -B build -DFD_OUTPUT_DIR=./archives #-DFD_FORCE_DOWNLOAD=ON
cmake --build build --target fetch_all