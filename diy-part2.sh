#!/bin/bash
set -euo pipefail

WORKSPACE="$GITHUB_WORKSPACE"
SOURCE_DIR="$WORKSPACE/source-repo"
OUTPUT_DIR="$WORKSPACE/output"

export CROSS_COMPILE=aarch64-linux-gnu-
export ARCH=arm64

cd "$SOURCE_DIR"

# ==============================
# 编译 ATF (bl2 + fip)
# ==============================
echo "=== 编译 ATF ==="
make -j$(nproc) toolchain/install
make -j$(nproc) package/arm-trusted-firmware-mediatek/compile

# 复制ATF到输出目录
find build_dir/* -name "bl2.img" -o -name "bl2.bin" | head -1 | xargs -I {} cp {} $OUTPUT_DIR/atf/
find build_dir/* -name "fip.bin" | head -1 | xargs -I {} cp {} $OUTPUT_DIR/atf/

# ==============================
# 编译 U-Boot
# ==============================
echo "=== 编译 U-Boot ==="
make -j$(nproc) package/u-boot-mediatek/compile

# 复制uboot到输出目录
find build_dir/* -name "u-boot.bin" | head -1 | xargs -I {} cp {} $OUTPUT_DIR/uboot/

# ==============================
# 打包 mtk_uartboot
# ==============================
echo "=== 打包 mtk_uartboot ==="
mkdir -p mtk_uartboot
cd mtk_uartboot
wget https://github.com/frank-w/mtk_uartboot/archive/refs/heads/main.tar.gz -O mtk_uartboot.tar.gz
cp mtk_uartboot.tar.gz $OUTPUT_DIR/

echo "=== 救砖全家桶已完成 ==="
ls -lh $OUTPUT_DIR/{atf,uboot}/*
