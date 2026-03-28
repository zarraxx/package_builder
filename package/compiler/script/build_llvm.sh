#!/bin/bash

set -e
ROOT=$(cd `dirname $0` && pwd)

export LLVM_VERSION=${1:-"15.0.7"}

yum install -y \
    devtoolset-10-gcc \
    devtoolset-10-gcc-c++ \
    devtoolset-10-binutils \
    && yum clean all

source /opt/rh/rh-python38/enable
source /opt/rh/devtoolset-10/enable


export BUILD_DIR=/workspace/build
export ARCHIVE_DIR=/workspace/archive


mkdir -p ${BUILD_DIR}
mkdir -p ${ARCHIVE_DIR}


export PATH=${DEST_DIR}/bin:$PATH

download_file_llvm() {
    local filename=llvm-project-${LLVM_VERSION}.src.tar.xz
    local archive_dir=$ARCHIVE_DIR
    local base_url="https://github.com/llvm/llvm-project/releases/download/"
    local file_path="${archive_dir}/${filename}"
    
    if [ -f "${file_path}" ]; then
        echo "文件已存在，跳过下载: ${filename}"
        return 0
    fi
    
    echo "正在下载: ${filename}"
    wget -P "${archive_dir}" "${base_url}/llvmorg-${LLVM_VERSION}/${filename}"
    
    if [ $? -eq 0 ]; then
        echo "下载完成: ${filename}"
    else
        echo "下载失败: ${filename}"
        return 1
    fi
}

build_llvm(){
    download_file_llvm
    cd $BUILD_DIR
    rm -rf llvm*
    tar xf $ARCHIVE_DIR/llvm-project-$LLVM_VERSION.src.tar.xz
    PYTHON_EXE=$(which python3)
    cd llvm-project-$LLVM_VERSION.src
    rm -rf _build && mkdir _build && cd _build
    cmake -G Ninja \
     -DCMAKE_BUILD_TYPE=Release \
      -DPython3_EXECUTABLE=$PYTHON_EXE \
      -DCMAKE_INSTALL_PREFIX=${LLVM_DEST_DIR} \
      \
      -DLLVM_ENABLE_PROJECTS="clang;lld" \
      -DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi;libunwind;compiler-rt" \
      -DCLANG_DEFAULT_LINKER="lld" \
      \
      -DLLVM_TARGETS_TO_BUILD="X86;AArch64" \
      \
      -DLLVM_ENABLE_RTTI=ON \
      -DLLVM_INSTALL_UTILS=ON \
      -DLLVM_BUILD_LLVM_DYLIB=ON \
      -DLLVM_LINK_LLVM_DYLIB=ON \
      -DCLANG_LINK_CLANG_DYLIB=ON \
      \
      -DLLVM_INCLUDE_TESTS=OFF \
      -DLLVM_INCLUDE_EXAMPLES=OFF \
      -DLLVM_ENABLE_TERMINFO=OFF \
      -DLLVM_ENABLE_ZLIB=ON \
      -DLLVM_ENABLE_LIBXML2=OFF \
      \
      -DCOMPILER_RT_BUILD_BUILTINS=ON \
      -DCOMPILER_RT_BUILD_SANITIZERS=ON \
      -DCOMPILER_RT_ENABLE_STATIC_HELPER=ON \
      \
      \
      -DCMAKE_INSTALL_RPATH="\$ORIGIN;\$ORIGIN/../lib" \
      -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON \
       ../llvm

    #   -DCLANG_DEFAULT_RTLIB="compiler-rt" \
    #   -DCLANG_DEFAULT_UNWINDLIB="libunwind" \
    #   -DLIBCXX_USE_COMPILER_RT=ON \

    ninja -j$(nproc) 
    ninja install


}



export LLVM_DEST_DIR=/opt/x-tools/compilers/llvm-${LLVM_VERSION}
build_llvm
