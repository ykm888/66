#!/bin/bash
set -e

# 1. 物理环境初始化
WORKSPACE=$(pwd)
SOURCE_DIR="$WORKSPACE/source-repo"      # ykm99999 引导源
FIRMWARE_DIR="$WORKSPACE/firmware-repo"  # ykm888 系统源 (扁平结构)
CONFIG_DIR="$WORKSPACE/888"              # 你的配置目录 (脚本同级)
OUTPUT_DIR="$WORKSPACE/output"           # 全局产物目录

mkdir -p $OUTPUT_DIR/atf $OUTPUT_DIR/uboot $OUTPUT_DIR/firmware

export CROSS_COMPILE=aarch64-linux-gnu-
export ARCH=arm64

# ========== 1. 编译 ATF (原文照抄) ==========
echo "=== Building ATF 512M (EMMC) ==="
cd $SOURCE_DIR/arm-trusted-firmware
make clean
make CROSS_COMPILE=aarch64-linux-gnu- PLAT=mt7981 DEBUG=0 DDR3_FLY=0 USE_NMBM=0 BOOT_DEVICE=emmc LOG_LEVEL=20 DRAM_SIZE=512
find build/mt7981/release -name "bl2*.bin" -exec cp {} $OUTPUT_DIR/atf/bl2-512m-emmc.bin \; 2>/dev/null

make clean
make CROSS_COMPILE=aarch64-linux-gnu- PLAT=mt7981 DEBUG=0 DDR3_FLY=0 USE_NMBM=0 BOOT_DEVICE=emmc LOG_LEVEL=20 DRAM_SIZE=1024
find build/mt7981/release -name "bl2*.bin" -exec cp {} $OUTPUT_DIR/atf/bl2-1g-emmc.bin \; 2>/dev/null

echo "=== Building ATF 1G (NOR - for rescue) ==="
make clean
make CROSS_COMPILE=aarch64-linux-gnu- PLAT=mt7981 DEBUG=0 DDR3_FLY=0 USE_NMBM=0 BOOT_DEVICE=nor LOG_LEVEL=20 DRAM_SIZE=1024
find build/mt7981/release -name "bl2*.bin" -exec cp {} $OUTPUT_DIR/atf/bl2-1g-nor.bin \; 2>/dev/null

# ========== 2. 编译 U-Boot (原文照抄) ==========
echo "=== Building U-Boot (eMMC) ==="
cd $SOURCE_DIR/u-boot
make clean
make CROSS_COMPILE=aarch64-linux-gnu- mt7981_emmc_rfb_defconfig
make CROSS_COMPILE=aarch64-linux-gnu- -j$(nproc)
[ -f fip.bin ] && cp fip.bin $OUTPUT_DIR/uboot/fip-emmc.bin
[ -f u-boot.bin ] && cp u-boot.bin $OUTPUT_DIR/uboot/u-boot-emmc.bin

# ========== 3. 编译 ImmortalWrt (修正扁平搬运逻辑) ==========
cd $WORKSPACE
mkdir -p immortalwrt-build
# 【核心修正】：物理搬运扁平化源码，跳过不存在的 immortalwrt 目录名
cp -r $FIRMWARE_DIR/. immortalwrt-build/
# 磁盘空间释放
rm -rf $SOURCE_DIR/arm-trusted-firmware $SOURCE_DIR/u-boot
cd immortalwrt-build

# 【物理复刻：拉起 888 目录下的 1G/512M DTS】
echo "=== 正在物理拉起 888 资源 ==="
cp "$CONFIG_DIR/mt7981-sl-3000-emmc-1g.dts" target/linux/mediatek/dts/
cp "$CONFIG_DIR/mt7981-sl-3000-emmc-512m.dts" target/linux/mediatek/dts/
cp "$CONFIG_DIR/mt7981.mk" target/linux/mediatek/image/
cp "$CONFIG_DIR/sl3000.config" .config || { echo "Error: sl3000.config not found"; exit 1; }

# 更新并编译
./scripts/feeds update -a
./scripts/feeds install -a
make defconfig
make -j$(nproc) V=s 2>&1 | tee build.log

# 搜集产物
find bin/targets/ -type f \( -name "*.bin" -o -name "*.img.gz" -o -name "*sysupgrade*" \) -exec cp {} $OUTPUT_DIR/firmware/ \;
cp build.log $OUTPUT_DIR/firmware/

# ========== 4. 打包 mtk_uartboot ==========
cd $SOURCE_DIR/mtk_uartboot
tar -czf $OUTPUT_DIR/mtk_uartboot.tar.gz .

echo "✅ V1 构建完成，产物位于: $OUTPUT_DIR"
