#!/bin/bash
set -e

[ -z "$GITHUB_WORKSPACE" ] && GITHUB_WORKSPACE=$(pwd)
BUILD_DIR=$(cat "$GITHUB_WORKSPACE/build_path.txt")
OUTPUT_DIR="$GITHUB_WORKSPACE/output"

cd "$BUILD_DIR"

echo "=== 启动 SL3000 512M 救砖固件全量构建 ==="

# 1. 确保工具链完整安装（修复 ld-musl / 链接器依赖）
make tools/install -j$(nproc)
make toolchain/install -j$(nproc)
make package/libs/mbedtls/install -j$(nproc)

# 2. 只编译完整固件，不编译升级包
echo "=== 编译完整救砖固件（不含 sysupgrade） ==="
make -j$(nproc) || make -j1 V=s
# 3. 只搜集【完整救砖bin】，严格过滤升级包/冗余文件
echo "=== 只搜集救砖全量固件，剔除 sysupgrade ==="
mkdir -p "$OUTPUT/firmware"

# 只复制完整固件bin，排除任何 sysupgrade / initramfs / 升级包
find bin/targets/ -type f -name "*.bin" ! -name "*sysupgrade*" ! -name "*initramfs*" -exec cp -v {} "$OUTPUT_DIR/firmware/" \;

# 4. 生成校验和（只给救砖固件生成）
cd "$OUTPUT_DIR/firmware"
for file in *; do
  [ -f "$file" ] || continue
  [[ "$file" == *.md5 ]] && continue
  [[ "$file" == *sysupgrade* ]] && continue
  md5sum "$file" > "${file}.md5"
done

echo "=== SL3000 救砖固件构建完成 ==="
echo "输出目录：$OUTPUT_DIR/firmware"
ls -lh "$OUTPUT_DIR/firmware"
