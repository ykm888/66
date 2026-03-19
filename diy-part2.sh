#!/bin/bash
set -e

[ -z "$GITHUB_WORKSPACE" ] && GITHUB_WORKSPACE=$(pwd)
BUILD_DIR=$(cat "$GITHUB_WORKSPACE/build_path.txt")
OUTPUT_DIR="$GITHUB_WORKSPACE/output"

cd "$BUILD_DIR"

echo "=== 启动 SL3000 512M 构建流程 ==="

# 1. 物理安装核心工具 (解决 ld-musl 缺失)
make tools/install -j$(nproc)
make toolchain/install -j$(nproc)

# 2. 全量并行编译
echo "=== 正式全量编译 ==="
make -j$(nproc) || make -j1 V=s

# 3. 产物搜集
echo "=== 搜集固件与计算 MD5 ==="
mkdir -p "$OUTPUT_DIR/firmware"
find bin/targets/ -type f \( -name "*.bin" -o -name "*.img.gz" -o -name "*sysupgrade*" \) -exec cp -v {} "$OUTPUT_DIR/firmware/" \;

cd "$OUTPUT_DIR/firmware"
for file in *; do
    [ -f "$file" ] && [ "${file##*.}" != "md5" ] && md5sum "$file" > "${file}.md5"
done

echo "✅ SL3000 救砖固件编译完成"
