#!/bin/bash
set -e

[ -z "$GITHUB_WORKSPACE" ] && GITHUB_WORKSPACE=$(pwd)
BUILD_DIR=$(cat "$GITHUB_WORKSPACE/build_path.txt")
OUTPUT_DIR="$GITHUB_WORKSPACE/output"

cd "$BUILD_DIR"

echo "=== 启动 SL3000 512M 全量构建流程 ==="

# 1. 物理安装 Tools 和 Toolchain (确保护映 ld-musl 等文件)
make tools/install -j$(nproc)
make toolchain/install -j$(nproc)
# 显式安装 mbedtls 供上层包的 CMake 搜索
make package/libs/mbedtls/install -j$(nproc)

# 2. 全量并行编译
echo "=== 开始全量并行编译固件 ==="
make -j$(nproc) || make -j1 V=s

# 3. 产物搜集
echo "=== 正在搜集固件与计算校验码 ==="
mkdir -p "$OUTPUT_DIR/firmware"
find bin/targets/ -type f \( -name "*.bin" -o -name "*.img.gz" -o -name "*sysupgrade*" \) -exec cp -v {} "$OUTPUT_DIR/firmware/" \;

cd "$OUTPUT_DIR/firmware"
for file in *; do
    [ -f "$file" ] && [ "${file##*.}" != "md5" ] && md5sum "$file" > "${file}.md5"
done
