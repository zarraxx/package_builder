#!/bin/bash

set -e
ROOT=$(cd `dirname $0` && pwd)
ARCH=`uname -m`

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


export PATH=/opt/x-tools/utils/bin:$PATH

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

    LLVM_SRC=$(pwd)/llvm
    STAGE1_DIR=$BUILD_DIR/llvm-stage1
    STAGE1_INSTALL=$BUILD_DIR/llvm-${LLVM_VERSION}-stage1
    #STAGE1_INSTALL=/opt/x-tools/compilers/llvm-${LLVM_VERSION}-stage1


    echo "Building LLVM ${LLVM_VERSION} stage 1..."
    cmake -G Ninja -S $LLVM_SRC -B $STAGE1_DIR \
    -DCMAKE_BUILD_TYPE=Release \
    -DLLVM_ENABLE_PROJECTS="clang;lld" \
    -DLLVM_ENABLE_RUNTIMES="compiler-rt;libcxx;libcxxabi;libunwind" \
    -DLLVM_TARGETS_TO_BUILD="Native" \
    -DCMAKE_INSTALL_PREFIX=$STAGE1_INSTALL \
    -DLLVM_INCLUDE_TESTS=OFF \
    -DLLVM_BUILD_LLVM_DYLIB=OFF \
    -DLLVM_LINK_LLVM_DYLIB=OFF

    ninja -C $STAGE1_DIR -j$(nproc)
    ninja -C $STAGE1_DIR install



    echo "Building LLVM ${LLVM_VERSION} stage 2..."
    STAGE2_DIR=$BUILD_DIR/llvm-stage2
    LLVM_DEST_DIR=/opt/x-tools/compilers/llvm-${LLVM_VERSION}

   DETECTED_FILE=$(find "$STAGE1_INSTALL/lib" \
    \( -name "libc++.so" -o -name "libc++.dylib" -o -name "libc++.dll" \) \
    | head -n 1)

    if [ -n "$DETECTED_FILE" ]; then
        DETECTED_LIB_DIR=$(dirname "$DETECTED_FILE")
    fi

    if [ -z "$DETECTED_LIB_DIR" ]; then
        echo "FATAL: Cannot find libc++.so in $STAGE1_INSTALL/lib"
        exit 1
    fi

    echo "Detected libc shared library directory: $DETECTED_LIB_DIR"

    STAGE2_LIBCXX_DIR="$(basename "$DETECTED_LIB_DIR")"

    echo "Final will use libc++ from: $STAGE2_LIBCXX_DIR"

    export STAGE1_LIB_DIR="$DETECTED_LIB_DIR"
    export LD_LIBRARY_PATH="$STAGE1_LIB_DIR:$LD_LIBRARY_PATH"
    export LDFLAGS="-L$STAGE1_LIB_DIR $LDFLAGS"

    cmake -G Ninja $LLVM_SRC -B $STAGE2_DIR \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=$LLVM_DEST_DIR \
    \
    -DCMAKE_C_COMPILER=$STAGE1_INSTALL/bin/clang \
    -DCMAKE_CXX_COMPILER=$STAGE1_INSTALL/bin/clang++ \
    -DCMAKE_LINKER=$STAGE1_INSTALL/bin/ld.lld \
    -DCMAKE_BUILD_RPATH="$STAGE1_INSTALL/lib/$ARCH-unknown-linux-gnu" \
    \
    -DLLVM_ENABLE_PROJECTS="clang;lld;clang-tools-extra" \
    -DLLVM_ENABLE_RUNTIMES="compiler-rt;libcxx;libcxxabi;libunwind" \
    -DCLANG_DEFAULT_LINKER="lld" \
    \
    -DLLVM_BUILD_LLVM_DYLIB=ON \
    -DLLVM_LINK_LLVM_DYLIB=ON \
    -DCLANG_LINK_CLANG_DYLIB=ON \
    -DCLANG_BUILD_TOOLS=ON \
    -DLIBCLANG_BUILD_STATIC=OFF \
    \
    -DLLVM_ENABLE_LIBCXX=ON \
    \
    -DCLANG_DEFAULT_CXX_STDLIB="libc++" \
    -DCLANG_DEFAULT_RTLIB="compiler-rt" \
    -DCLANG_DEFAULT_UNWINDLIB="libunwind" \
    \
    -DLIBUNWIND_USE_COMPILER_RT=ON\
    -DLIBCXX_USE_COMPILER_RT=ON \
    -DLIBCXXABI_USE_COMPILER_RT=ON \
    -DLIBCXXABI_USE_LLVM_UNWIND=ON \
    \
    -DCOMPILER_RT_BUILD_BUILTINS=ON \
    -DCOMPILER_RT_BUILD_SANITIZERS=ON \
    -DCOMPILER_RT_ENABLE_STATIC_HELPER=ON \
    \
    -DRUNTIMES_LIBUNWIND_USE_COMPILER_RT=ON \
    -DRUNTIMES_LIBUNWIND_HAS_GCC_S_LIB=OFF \
    -DRUNTIMES_LIBCXXABI_USE_COMPILER_RT=ON \
    -DRUNTIMES_LIBCXXABI_USE_LLVM_UNWIND=ON \
    -DRUNTIMES_LIBCXX_USE_COMPILER_RT=ON \
    \
    -DRUNTIMES_COMPILER_RT_BUILD_BUILTINS=ON \
    -DRUNTIMES_COMPILER_RT_BUILD_SANITIZERS=ON \
    -DRUNTIMES_COMPILER_RT_ENABLE_STATIC_HELPER=ON \
    \
    -DRUNTIMES_CMAKE_SHARED_LINKER_FLAGS="-nostdlib++ -rtlib=compiler-rt" \
    -DRUNTIMES_CMAKE_EXE_LINKER_FLAGS="-nostdlib++ -rtlib=compiler-rt" \
    \
    -DCMAKE_INSTALL_RPATH='$ORIGIN;$ORIGIN/../lib;''$ORIGIN/'"${STAGE2_LIBCXX_DIR};"'$ORIGIN/../lib/'"${STAGE2_LIBCXX_DIR}" \
    -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON \
    -DCMAKE_INSTALL_RPATH_USE_LINK_PATH=OFF \
    \
    -DLLVM_TARGETS_TO_BUILD="X86;AArch64;RISCV" \
    -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD="WebAssembly;LoongArch" \
    -DLLVM_ENABLE_RTTI=ON \
    -DLLVM_INSTALL_UTILS=ON \
    -DLLVM_INCLUDE_TESTS=OFF \
    -DLLVM_INCLUDE_EXAMPLES=OFF \
    -DLLVM_ENABLE_ZLIB=ON \
    -DLLVM_ENABLE_TERMINFO=OFF \
    \
    -DCMAKE_EXE_LINKER_FLAGS="-rtlib=compiler-rt --unwindlib=libunwind -stdlib=libc++" \
    -DCMAKE_SHARED_LINKER_FLAGS="-rtlib=compiler-rt --unwindlib=libunwind -stdlib=libc++"

    ninja -C $STAGE2_DIR -j$(nproc)
    ninja -C $STAGE2_DIR install

    # rm -rf _build && mkdir _build && cd _build
    # cmake -G Ninja \
    #  -DCMAKE_BUILD_TYPE=Release \
    #   -DPython3_EXECUTABLE=$PYTHON_EXE \
    #   -DCMAKE_INSTALL_PREFIX=${LLVM_DEST_DIR} \
    #   \
    #   -DLLVM_ENABLE_PROJECTS="clang;lld" \
    #   -DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi;libunwind;compiler-rt" \
    #   -DCLANG_DEFAULT_LINKER="lld" \
    #   \
    #   -DLLVM_TARGETS_TO_BUILD="X86;AArch64" \
    #   \
    #   -DLLVM_ENABLE_RTTI=ON \
    #   -DLLVM_INSTALL_UTILS=ON \
    #   -DLLVM_BUILD_LLVM_DYLIB=ON \
    #   -DLLVM_LINK_LLVM_DYLIB=ON \
    #   -DCLANG_LINK_CLANG_DYLIB=ON \
    #   \
    #   -DLLVM_INCLUDE_TESTS=OFF \
    #   -DLLVM_INCLUDE_EXAMPLES=OFF \
    #   -DLLVM_ENABLE_TERMINFO=OFF \
    #   -DLLVM_ENABLE_ZLIB=ON \
    #   -DLLVM_ENABLE_LIBXML2=OFF \
    #   \
    #   -DCOMPILER_RT_BUILD_BUILTINS=ON \
    #   -DCOMPILER_RT_BUILD_SANITIZERS=ON \
    #   -DCOMPILER_RT_ENABLE_STATIC_HELPER=ON \
    #   \
    #   \
    #   -DCMAKE_INSTALL_RPATH="\$ORIGIN;\$ORIGIN/../lib" \
    #   -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON \
    #    ../llvm

    # ninja -j$(nproc) 
    # ninja install


}



build_llvm
