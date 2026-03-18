#!/bin/bash
set -e

# --- 物理路径锚定 ---
WORKSPACE=$(pwd)
SCRIPT_DIR="$WORKSPACE/main-repo"
SOURCE_DIR="$WORKSPACE/source-repo"
FIRMWARE_DIR="$WORKSPACE/firmware-repo"
CONFIG_DIR="$SCRIPT_DIR/888"
OUTPUT_DIR="$WORKSPACE/output"

mkdir -p $OUTPUT_DIR/atf $OUTPUT_DIR/uboot $OUTPUT_DIR/firmware

export CROSS_COMPILE=aarch64-linux-gnu-
export ARCH=arm64

# ========== 1. 编译 ATF (BL2/BL31) ==========
echo "=== Building ATF ==="
cd $SOURCE_DIR/arm-trusted-firmware
# 1G EMMC 版作为示例 (按需复刻 512M)
make clean
make CROSS_COMPILE=aarch64-linux-gnu- PLAT=mt7981 DEBUG=0 DDR3_FLY=0 USE_NMBM=0 BOOT_DEVICE=emmc LOG_LEVEL=20 DRAM_SIZE=1024
# 物理搜集 ATF 产物
find build/mt7981/release -name "bl2.bin" -exec cp {} $OUTPUT_DIR/atf/bl2-1g-emmc.bin \;
find build/mt7981/release -name "bl31.bin" -exec cp {} $WORKSPACE/bl31.bin \; # 暂存 bl31 用于打包 FIP

# ========== 2. 编译 U-Boot (BL33) ==========
echo "=== Building U-Boot ==="
cd $SOURCE_DIR/u-boot
make clean
make CROSS_COMPILE=aarch64-linux-gnu- mt7981_emmc_rfb_defconfig
make CROSS_COMPILE=aarch64-linux-gnu- -j$(nproc)

# 【物理修复点】：检查并拷贝 U-Boot 核心文件
if [ -f "u-boot.bin" ]; then
    cp u-boot.bin $OUTPUT_DIR/uboot/u-boot-emmc.bin
    echo "✅ u-boot.bin 编译成功"
else
    echo "❌ u-boot.bin 未生成！" && exit 1
fi

# 【逻辑修正】：如果你的仓库没有自动打包 FIP，则跳过 cp fip.bin，或使用编译生成的 u-boot-mtk.bin
[ -f "u-boot-mtk.bin" ] && cp u-boot-mtk.bin $OUTPUT_DIR/uboot/u-boot-mtk-emmc.bin
[ -f "fip.bin" ] && cp fip.bin $OUTPUT_DIR/uboot/fip-emmc.bin || echo "⚠️ 提示：当前目录下未直接发现 fip.bin，已跳过。"

# ========== 3. 编译 系统固件 (保持原文) ==========
cd $WORKSPACE
mkdir -p immortalwrt-build
cp -r $FIRMWARE_DIR/. immortalwrt-build/
cd immortalwrt-build

# 物理拉起 888 资源
cp "$CONFIG_DIR/mt7981-sl-3000-emmc-1g.dts" target/linux/mediatek/dts/
cp "$CONFIG_DIR/mt7981-sl-3000-emmc-512m.dts" target/linux/mediatek/dts/
cp "$CONFIG_DIR/mt7981.mk" target/linux/mediatek/image/
cp "$CONFIG_DIR/sl3000.config" .config

# 净化配置
sed -i '/onionshare/d' .config
sed -i '/CONFIG_PACKAGE_onionshare-cli/d' .config

./scripts/feeds update -a
./scripts/feeds install -a
make olddefconfig
make -j$(nproc) V=s
