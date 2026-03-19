#!/bin/bash
set -e

WORKSPACE="$GITHUB_WORKSPACE"
OUTPUT_DIR="$WORKSPACE/output"
BUILD_DIR=$(cat "$WORKSPACE/build_path.txt")

cd "$BUILD_DIR"

echo "=== 启动全量并行编译 ==="
# 如果并行失败，自动切换单线程获取详细日志
make -j$(nproc) || make -j1 V=s

echo "=== 正在执行产物搜集与校验 ==="
mkdir -p "$OUTPUT_DIR/firmware"

# 搜集所有符合 SL3000 特性的二进制文件
find bin/targets/ -type f \( -name "*.bin" -o -name "*.img.gz" -o -name "*sysupgrade*" \) -exec cp -v {} "$OUTPUT_DIR/firmware/" \;

# 生成 MD5 校验文件
cd "$OUTPUT_DIR/firmware"
for file in *; do
    [ -f "$file" ] && md5sum "$file" > "${file}.md5"
done

echo "✅ 固件编译与发布准备已完成"
