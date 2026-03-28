#!/bin/bash
set -e
ROOT=$(cd `dirname $0` && pwd)
ARCH=`uname -m`

export LLVM_VERSION=${1:-"7.1.0"}
echo "LLVM_VERSION: ${LLVM_VERSION}"

yum install -y gcc gcc-c++ binutils libstdc++-static

export BUILD_DIR=/workspace/build
export DEST_DIR=/opt/x-tools/utils
export ARCHIVE_DIR=/workspace/archive

mkdir -p ${BUILD_DIR}
mkdir -p ${DEST_DIR}
mkdir -p ${ARCHIVE_DIR}


export PATH=${DEST_DIR}/bin:$PATH

if [ "$ARCH" == "aarch64" ]; then
    export STAGE1TARGET="AArch64"
else
    if [ "$ARCH" == "x86_64"  ]; then
        export STAGE1TARGET="X86"
    else
        export STAGE1TARGET="X86;AArch64"
    fi
fi

download_file_llvm() {
    local filename=$1-${LLVM_VERSION}.src.tar.xz
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
    download_file_llvm llvm
    download_file_llvm cfe
    download_file_llvm compiler-rt
    download_file_llvm lld
    download_file_llvm libcxx
    download_file_llvm libcxxabi
    download_file_llvm libunwind

    cd $BUILD_DIR
    rm -rf llvm* cfe* compiler-rt* lld* libcxx* libcxxabi* libunwind*

    tar --no-same-owner -xf $ARCHIVE_DIR/llvm-$LLVM_VERSION.src.tar.xz
    tar --no-same-owner -xf $ARCHIVE_DIR/cfe-$LLVM_VERSION.src.tar.xz
    tar --no-same-owner -xf $ARCHIVE_DIR/lld-$LLVM_VERSION.src.tar.xz


    tar --no-same-owner -xf $ARCHIVE_DIR/compiler-rt-$LLVM_VERSION.src.tar.xz
    tar --no-same-owner -xf $ARCHIVE_DIR/libcxx-$LLVM_VERSION.src.tar.xz
    tar --no-same-owner -xf $ARCHIVE_DIR/libcxxabi-$LLVM_VERSION.src.tar.xz
    tar --no-same-owner -xf $ARCHIVE_DIR/libunwind-$LLVM_VERSION.src.tar.xz

    mv cfe-$LLVM_VERSION.src llvm-$LLVM_VERSION.src/tools/clang
    mv lld-$LLVM_VERSION.src llvm-$LLVM_VERSION.src/tools/lld

    mv compiler-rt-$LLVM_VERSION.src llvm-$LLVM_VERSION.src/projects/compiler-rt
    mv libcxx-$LLVM_VERSION.src llvm-$LLVM_VERSION.src/projects/libcxx
    mv libcxxabi-$LLVM_VERSION.src llvm-$LLVM_VERSION.src/projects/libcxxabi
    mv libunwind-$LLVM_VERSION.src llvm-$LLVM_VERSION.src/projects/libunwind


    cd llvm-$LLVM_VERSION.src

    rm -rf _stage1 && mkdir _stage1 && cd _stage1

    #STAGE1_DEST=${BUILD_DIR}/stage1
    cmake -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=${LLVM_DEST_DIR} \
    \
    -DLLVM_TARGETS_TO_BUILD="${STAGE1TARGET}" \
    -DLLVM_ENABLE_ASSERTIONS=OFF \
    -DLLVM_INCLUDE_TESTS=OFF \
    -DCLANG_DEFAULT_LINKER=lld ..

    ninja -j$(nproc) 
    ninja install

#     cd $BUILD_DIR
#     rm -rf _stage2 && mkdir _stage2 && cd _stage2

#     CXX_ABI_PATH=$(find "$STAGE1_DEST/include" -name "cxxabi.h")
#     cmake -G Ninja \
#     -DCMAKE_C_COMPILER=${STAGE1_DEST}/bin/clang \
#     -DCMAKE_CXX_COMPILER=${STAGE1_DEST}/bin/clang++ \
#     -DCMAKE_LINKER=${STAGE1_DEST}/bin/ld.lld \
#     -DCMAKE_AR=${STAGE1_DEST}/bin/llvm-ar \
#     -DCMAKE_RANLIB=${STAGE1_DEST}/bin/llvm-ranlib \
#     \
#     -DCMAKE_CXX_FLAGS="-stdlib=libc++ -I${STAGE1_DEST}/include/c++/v1" \
#     -DCMAKE_EXE_LINKER_FLAGS="-stdlib=libc++ -lc++abi -Wl,-rpath,${STAGE1_DEST}/lib:\$ORIGIN:\$ORIGIN/../lib" \
#     \
#     -DCMAKE_BUILD_TYPE=Release \
#     -DCMAKE_INSTALL_PREFIX=${LLVM_DEST_DIR} \
#     \
#     -DLIBUNWIND_ENABLE_SHARED=ON \
#     -DLIBUNWIND_ENABLE_STATIC=ON \
#     -DLIBUNWIND_USE_COMPILER_RT=ON \
#     -DLIBCXXABI_USE_LLVM_UNWIND=ON \
#     \
#     -DLIBCXXABI_USE_COMPILER_RT=ON \
#     -DLIBCXXABI_ENABLE_STATIC=ON \
#     -DLIBCXXABI_ENABLE_SHARED=ON \
#     -DLIBCXX_CXX_ABI=libcxxabi \
#     -DLIBCXX_CXX_ABI_INCLUDE_PATHS=$CXX_ABI_PATH \
#     \
#     -DLIBCXX_USE_COMPILER_RT=ON \
#     -DLIBCXX_ENABLE_STATIC=ON \
#     -DLIBCXX_ENABLE_SHARED=ON \
#     \
#     -DLLVM_TARGETS_TO_BUILD="X86;AArch64" \
#     -DLLVM_ENABLE_ASSERTIONS=OFF \
#     -DLLVM_INCLUDE_TESTS=OFF \
#     -DCLANG_DEFAULT_LINKER=lld ..

#   ninja -j$(nproc) 
#   ninja install


}



export LLVM_DEST_DIR=/opt/x-tools/compilers/llvm-${LLVM_VERSION}
build_llvm
