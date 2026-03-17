#!/bin/bash
set -e

WORKSPACE="$GITHUB_WORKSPACE"
SOURCE_DIR="$WORKSPACE/source-repo"
FIRMWARE_DIR="$WORKSPACE/firmware-repo"
CONFIG_DIR="$WORKSPACE/main-repo/888"
OUTPUT_DIR="$WORKSPACE/output"

mkdir -p $OUTPUT_DIR/atf $OUTPUT_DIR/uboot $OUTPUT_DIR/firmware

export CROSS_COMPILE=aarch64-linux-gnu-
export ARCH=arm64

# ========== 1. 编译 ATF (来自 ykm99999/66:2410) ==========
echo "=== Building ATF ==="
cd $SOURCE_DIR/arm-trusted-firmware
make clean
# 编译 512M EMMC
make CROSS_COMPILE=aarch64-linux-gnu- PLAT=mt7981 DEBUG=0 DDR3_FLY=0 USE_NMBM=0 BOOT_DEVICE=emmc LOG_LEVEL=20 DRAM_SIZE=512
find build/mt7981/release -name "bl2*.bin" -exec cp {} $OUTPUT_DIR/atf/bl2-512m-emmc.bin \; 2>/dev/null
# 编译 1G NOR (救砖)
make clean
make CROSS_COMPILE=aarch64-linux-gnu- PLAT=mt7981 DEBUG=0 DDR3_FLY=0 USE_NMBM=0 BOOT_DEVICE=nor LOG_LEVEL=20 DRAM_SIZE=1024
find build/mt7981/release -name "bl2*.bin" -exec cp {} $OUTPUT_DIR/atf/bl2-1g-nor.bin \; 2>/dev/null

# ========== 2. 编译 U-Boot (来自 ykm99999/66:2410) ==========
echo "=== Building U-Boot ==="
cd $SOURCE_DIR/u-boot
make clean
make CROSS_COMPILE=aarch64-linux-gnu- mt7981_emmc_rfb_defconfig
make CROSS_COMPILE=aarch64-linux-gnu- -j$(nproc)
[ -f fip.bin ] && cp fip.bin $OUTPUT_DIR/uboot/fip-emmc.bin
[ -f u-boot.bin ] && cp u-boot.bin $OUTPUT_DIR/uboot/u-boot-emmc.bin

# ========== 3. 编译 ImmortalWrt (关键替换：来自 ykm888/66:2410) ==========
echo "=== Building Firmware from ykm888/66:2410 ==="
cd $WORKSPACE
# 注意：这里直接拷贝 firmware-repo 目录下的内容
cp -r $FIRMWARE_DIR/immortalwrt immortalwrt-build
cd immortalwrt-build

# 注入配置
cp $CONFIG_DIR/mt7981-sl-3000-emmc.dts target/linux/mediatek/dts/ 2>/dev/null || echo "DTS skip"
cp $CONFIG_DIR/mt7981.mk target/linux/mediatek/image/
cp $CONFIG_DIR/sl3000.config .config || { echo "Error: sl3000.config not found"; exit 1; }

./scripts/feeds update -a
./scripts/feeds install -a
make defconfig
make -j$(nproc) V=s 2>&1 | tee build.log

# 收集固件
find bin/targets/ -type f \( -name "*.bin" -o -name "*.img.gz" -o -name "*sysupgrade*" \) -exec cp {} $OUTPUT_DIR/firmware/ \;
cp build.log $OUTPUT_DIR/firmware/

# ========== 4. 打包 mtk_uartboot ==========
cd $SOURCE_DIR/mtk_uartboot
tar -czf $OUTPUT_DIR/mtk_uartboot.tar.gz .

echo "✅ 构建完成"
