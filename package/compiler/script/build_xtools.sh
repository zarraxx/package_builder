#!/bin/bash

set -e
ROOT=$(cd `dirname $0` && pwd)
COMMAND="${CTNG_COMMAND:-"build"}"


build_xtools(){

    local target=$1

    echo "Building for target: $target"

    cd $HOME/workspace/$target
    ls -la
    rm -rf .build
    ct-ng $COMMAND


    cp /script/enable $CT_PREFIX/enable
    chmod +x $CT_PREFIX/enable

    if [ $target == "aarch64-unknown-linux419-gnu217" ]; then
        cd $CT_PREFIX
        ln -sf aarch64-unknown-linux-gnu2.17-gcc11.5.0 aarch64-unknown-linux-gnu
    fi


    if [ $target == "x86_64-unknown-linux310-gnu217" ]; then
        cd $CT_PREFIX
        ln -sf x86_64-unknown-linux-gnu2.17-gcc11.5.0 x86_64-unknown-linux-gnu
    fi
}

for TARGET in "$@"; do
    echo "正在构建: $TARGET"
    build_xtools "$TARGET"
done




