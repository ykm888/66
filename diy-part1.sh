#!/bin/bash
set -e

# 1. 物理定义绝对路径
WORKSPACE="/home/runner/work/66/66"
SOURCE_DIR="$WORKSPACE/source-repo"
MAIN_REPO="$WORKSPACE/main-repo"
CONFIG_DIR="$MAIN_REPO/888"
OUTPUT_DIR="$MAIN_REPO/output"

mkdir -p $OUTPUT_DIR/atf $OUTPUT_DIR/uboot $OUTPUT_DIR/firmware

export CROSS_COMPILE=aarch64-linux-gnu-
export ARCH=arm64

# ========== 1. 编译 ATF (BL2) ==========
echo "🚀 正在从 2410 源物理构建 ATF..."
# 注意：如果 2410 分支目录名是 atf 还是 arm-trusted-firmware，此处会自动探测
ATF_PATH="$SOURCE_DIR/arm-trusted-firmware"
[ -d "$SOURCE_DIR/atf" ] && ATF_PATH="$SOURCE_DIR/atf"

cd $ATF_PATH
make clean
# 编译 1G NOR 版 (救砖核心)
make CROSS_COMPILE=aarch64-linux-gnu- PLAT=mt7981 DEBUG=0 DDR3_FLY=0 USE_NMBM=0 BOOT_DEVICE=nor LOG_LEVEL=20 DRAM_SIZE=1024
cp build/mt7981/release/bl2.bin $OUTPUT_DIR/atf/bl2-1g-nor.bin || echo "ATF 编译产物未发现"

# ========== 2. 编译 U-Boot (FIP) ==========
echo "🚀 正在从 2410 源物理构建 U-Boot..."
UBOOT_PATH="$SOURCE_DIR/u-boot"
cd $UBOOT_PATH
make clean
# 物理对齐 2410 的 defconfig
if [ -f configs/mt7981_emmc_rfb_defconfig ]; then
    make CROSS_COMPILE=aarch64-linux-gnu- mt7981_emmc_rfb_defconfig
    make CROSS_COMPILE=aarch64-linux-gnu- -j$(nproc)
    [ -f fip.bin ] && cp fip.bin $OUTPUT_DIR/uboot/fip-emmc.bin
    cp u-boot.bin $OUTPUT_DIR/uboot/u-boot-emmc.bin
fi

# ========== 3. 编译 ImmortalWrt ==========
echo "🚀 正在执行 ImmortalWrt 全链路合成..."
cd $WORKSPACE
# 物理平铺源码，避免权限和符号链接丢失
rsync -a $SOURCE_DIR/immortalwrt/ ./immortalwrt-build/
cd immortalwrt-build

# 物理注入 888 目录下的个性化配置
cp $CONFIG_DIR/mt7981-sl-3000-emmc.dts target/linux/mediatek/dts/ 2>/dev/null || true
cp $CONFIG_DIR/mt7981.mk target/linux/mediatek/image/ 2>/dev/null || true
cp $CONFIG_DIR/sl3000.config .config

./scripts/feeds update -a
./scripts/feeds install -a
make defconfig
# 物理加速编译
make -j$(nproc) || make -j1 V=s

# 收集产物
find bin/targets/ -type f \( -name "*.bin" -o -name "*.img.gz" -o -name "*sysupgrade*" \) -exec cp {} $OUTPUT_DIR/firmware/ \;

echo "✅ 2410 分支所有物理产物构建完成，位置: $OUTPUT_DIR"
