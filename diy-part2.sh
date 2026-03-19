#!/bin/bash
set -e

[ -z "$GITHUB_WORKSPACE" ] && GITHUB_WORKSPACE=$(pwd)
BUILD_DIR=$(cat "$GITHUB_WORKSPACE/build_path.txt")
OUTPUT_DIR="$GITHUB_WORKSPACE/output"

cd "$BUILD_DIR"

echo "=== 启动 SL3000 512M 构建流程 ==="

# 1. 显式物理安装编译地基 (关键步骤)
echo "=== 安装 Tools & Toolchain ==="
make tools/install -j$(nproc)
make toolchain/install -j$(nproc)

# 2. 全量并行编译固件
echo "=== 启动全量编译 ==="
make -j$(nproc) || make -j1 V=s

# 3. 产物搜集
echo "=== 搜集固件与计算校验码 ==="
mkdir -p "$OUTPUT_DIR/firmware"
find bin/targets/ -type f \( -name "*.bin" -o -name "*.img.gz" -o -name "*sysupgrade*" \) -exec cp -v {} "$OUTPUT_DIR/firmware/" \;

cd "$OUTPUT_DIR/firmware"
for file in *; do
    [ -f "$file" ] && [ "${file##*.}" != "md5" ] && md5sum "$file" > "${file}.md5"
done
