#!/bin/bash
set -euo pipefail

WORKSPACE="$GITHUB_WORKSPACE"
SOURCE_DIR="$WORKSPACE/source-repo"
OUTPUT_DIR="$WORKSPACE/output"

# 交叉编译工具
export CROSS_COMPILE=aarch64-linux-gnu-
export ARCH=arm64

cd $SOURCE_DIR

# ==============================
# 1. 编译 ATF (BL2 + FIP)
# ==============================
echo "=== 编译 ATF ==="
cd atf
make realclean
make PLAT=mt7981 BL33=../uboot/u-boot.bin all
cp build/mt7981/release/bl2.bin      $OUTPUT_DIR/atf/
cp build/mt7981/release/fip.bin      $OUTPUT_DIR/atf/

# ==============================
# 2. 编译 U-Boot
# ==============================
echo "=== 编译 U-Boot ==="
cd ../uboot
make distclean
make mt7981_sl3000_defconfig        # 换成你实际defconfig
make -j$(nproc)
cp u-boot.bin $OUTPUT_DIR/uboot/

# ==============================
# 3. 打包串口救砖工具
# ==============================
echo "=== 打包 mtk_uartboot ==="
cd ../mtk_uartboot
make clean
make -j$(nproc)
tar -zcf $OUTPUT_DIR/mtk_uartboot.tar.gz mtk_uartboot

echo "=== 救砖全家桶编译完成 ==="
ls -lh $OUTPUT_DIR/{atf,uboot,mtk_uartboot*}
