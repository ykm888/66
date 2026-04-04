#!/bin/bash
set -euo pipefail

WORKSPACE="$GITHUB_WORKSPACE"
SOURCE_DIR="$WORKSPACE/source-repo"
OUTPUT_DIR="$WORKSPACE/output"

cd "$SOURCE_DIR"

# 只更新 feeds，不装多余包
./scripts/feeds update -a
./scripts/feeds install -a

# 只编译工具链 + uboot/atf，不编译整个固件
make defconfig
make toolchain/compile -j$(nproc)
make package/arm-trusted-firmware-mediatek/compile -j$(nproc)
make package/u-boot-mediatek/compile -j$(nproc)

# 自动提取救砖文件
find build_dir -name "bl2.bin"  -o -name "bl2.img"  | xargs -I {} cp {} $OUTPUT_DIR/atf/
find build_dir -name "fip.bin"                        | xargs -I {} cp {} $OUTPUT_DIR/atf/
find build_dir -name "u-boot.bin"                    | xargs -I {} cp {} $OUTPUT_DIR/uboot/

ls -lh $OUTPUT_DIR/atf/ $OUTPUT_DIR/uboot/
