#!/usr/bin/env bash
set -euox pipefail

# 用法:
#   ./merge-package.sh <input_dir> <output_tar>
#
# 示例:
#   ./merge-package.sh ./archives ./sysroot-15.2.0-multi-linux-gnu.tar.xz

INPUT_DIR="${1:?missing input dir}"
OUTPUT_DIR="${2:?missing output dir}"
FILE_NAME_PREFIX="${3:?missing output tar file name}"

TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

echo "INPUT_DIR  = $INPUT_DIR"
echo "OUTPUT_DIR = $OUTPUT_DIR"
echo "FILE_NAME_PREFIX = $FILE_NAME_PREFIX"
echo "TMP_ROOT   = $TMP_ROOT"

shopt -s nullglob

found_any=0

for tarfile in "$INPUT_DIR"/*.tar "$INPUT_DIR"/*.tar.gz "$INPUT_DIR"/*.tar.xz "$INPUT_DIR"/*.tar.bz2 "$INPUT_DIR"/*.tgz; do
    [ -e "$tarfile" ] || continue
    found_any=1

    base="$(basename "$tarfile")"

    # 从文件名中提取 arch
    #
    # 规则：
    #   找出末尾类似：
    #     -<arch>-unknown-linux-gnu.tar.*
    #
    # 例如：
    #   sysroot-15.2.0-riscv64-unknown-linux-gnu.tar.xz
    #   -> riscv64
    #
    arch="$(printf '%s\n' "$base" \
        | sed -E 's/^(.*-)?([^-]+)-unknown-linux-gnu\.tar(\..+)?$/\2/')"

    # 如果没有匹配成功，sed 会原样返回；这里做个校验
    if [[ "$arch" == "$base" ]]; then
        echo "skip: cannot parse arch from filename: $base" >&2
        continue
    fi

    dest="$TMP_ROOT/${FILE_NAME_PREFIX}/${arch}-unknown-linux-gnu"
    mkdir -p "$dest"

    echo "extract: $tarfile -> $dest"
    tar xf "$tarfile" -C "$dest"
done

if [[ "$found_any" -eq 0 ]]; then
    echo "no tar archives found in: $INPUT_DIR" >&2
    exit 1
fi

# 打总包：包内顶层是各个 arch 目录
#parent_dir="$(dirname "$OUTPUT_TAR")"
mkdir -p "$OUTPUT_DIR"

echo "pack multi archive: $OUTPUT_DIR/$FILE_NAME_PREFIX-linux.tar.xz"
#cd "$TMP_ROOT"
tar caf "$OUTPUT_DIR/$FILE_NAME_PREFIX-linux.tar.xz" -C "$TMP_ROOT" "$FILE_NAME_PREFIX"

echo "done: $OUTPUT_DIR/$FILE_NAME_PREFIX-linux.tar.xz"