#!/bin/bash
set -e

# 物理路径定义
WORKSPACE="/home/runner/work/66/66"
SOURCE_DIR="$WORKSPACE/source-repo"
MAIN_REPO="$WORKSPACE/main-repo"
CONFIG_DIR="$MAIN_REPO/888"
OUTPUT_DIR="$MAIN_REPO/output"

mkdir -p $OUTPUT_DIR/atf $OUTPUT_DIR/uboot $OUTPUT_DIR/firmware

# 物理对齐：确保工具链在路径中
export CROSS_COMPILE=aarch64-linux-gnu-
export ARCH=arm64

# ========== 1. 编译 ATF (MT7981 专用 BL2) ==========
echo "🚀 开始构建 ATF..."
cd $SOURCE_DIR/arm-trusted-firmware

# 编译 512M EMMC 版
make clean
make CROSS_COMPILE=aarch64-linux-gnu- PLAT=mt7981 DEBUG=0 DDR3_FLY=0 USE_NMBM=0 BOOT_DEVICE=emmc LOG_LEVEL=20 DRAM_SIZE=512
cp build/mt7981/release/bl2.img $OUTPUT_DIR/atf/bl2-512m-emmc.img 2>/dev/null || cp build/mt7981/release/bl2.bin $OUTPUT_DIR/atf/bl2-512m-emmc.bin

# 编译 1G EMMC 版
make clean
make CROSS_COMPILE=aarch64-linux-gnu- PLAT=mt7981 DEBUG=0 DDR3_FLY=0 USE_NMBM=0 BOOT_DEVICE=emmc LOG_LEVEL=20 DRAM_SIZE=1024
cp build/mt7981/release/bl2.img $OUTPUT_DIR/atf/bl2-1g-emmc.img 2>/dev/null || cp build/mt7981/release/bl2.bin $OUTPUT_DIR/atf/bl2-1g-emmc.bin

# 编译 1G NOR 版 (救砖专用)
make clean
make CROSS_COMPILE=aarch64-linux-gnu- PLAT=mt7981 DEBUG=0 DDR3_FLY=0 USE_NMBM=0 BOOT_DEVICE=nor LOG_LEVEL=20 DRAM_SIZE=1024
cp build/mt7981/release/bl2.img $OUTPUT_DIR/atf/bl2-1g-nor.img 2>/dev/null || cp build/mt7981/release/bl2.bin $OUTPUT_DIR/atf/bl2-1g-nor.bin

# ========== 2. 编译 U-Boot (FIP 封装) ==========
echo "🚀 开始构建 U-Boot..."
cd $SOURCE_DIR/u-boot
make clean
# 物理对齐：使用 mt7981_emmc_rfb_defconfig
if [ -f configs/mt7981_emmc_rfb_defconfig ]; then
    make CROSS_COMPILE=aarch64-linux-gnu- mt7981_emmc_rfb_defconfig
    make CROSS_COMPILE=aarch64-linux-gnu- -j$(nproc)
    cp fip.bin $OUTPUT_DIR/uboot/fip-emmc.bin 2>/dev/null || echo "fip.bin not found"
    cp u-boot.bin $OUTPUT_DIR/uboot/u-boot-emmc.bin
else
    echo "❌ 配置文件缺失，跳过 U-Boot 编译"
fi

# ========== 3. 编译 ImmortalWrt (核心固件) ==========
echo "🚀 开始构建 ImmortalWrt..."
cd $WORKSPACE
# 使用 rsync 物理同步避免文件夹嵌套
rsync -a $SOURCE_DIR/immortalwrt/ ./immortalwrt-build/
cd immortalwrt-build

# 注入 SL3000 特有的物理配置
[ -f $CONFIG_DIR/mt7981-sl-3000-emmc.dts ] && cp $CONFIG_DIR/mt7981-sl-3000-emmc.dts target/linux/mediatek/dts/
[ -f $CONFIG_DIR/mt7981.mk ] && cp $CONFIG_DIR/mt7981.mk target/linux/mediatek/image/
[ -f $CONFIG_DIR/sl3000.config ] && cp $CONFIG_DIR/sl3000.config .config

./scripts/feeds update -a
./scripts/feeds install -a
make defconfig
# 开始物理极限编译
make -j$(nproc) || make -j1 V=s

# 收集产物
find bin/targets/ -type f \( -name "*.bin" -o -name "*.img.gz" -o -name "*sysupgrade*" \) -exec cp {} $OUTPUT_DIR/firmware/ \;

echo "✅ 所有物理产物已就绪"
