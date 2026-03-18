#!/bin/bash
set -e

# --- 物理路径自动锚定 ---
# WORKSPACE 是 Actions 的根目录 (包含 main-repo, source-repo, firmware-repo)
WORKSPACE=$(pwd)
# SCRIPT_DIR 是脚本所在的目录 (main-repo)
SCRIPT_DIR="$WORKSPACE/main-repo"

SOURCE_DIR="$WORKSPACE/source-repo"
FIRMWARE_DIR="$WORKSPACE/firmware-repo"
CONFIG_DIR="$SCRIPT_DIR/888"
OUTPUT_DIR="$WORKSPACE/output"

mkdir -p $OUTPUT_DIR/atf $OUTPUT_DIR/uboot $OUTPUT_DIR/firmware

export CROSS_COMPILE=aarch64-linux-gnu-
export ARCH=arm64

# ========== 1. 编译 ATF (原文照抄) ==========
echo "=== Building ATF (512M & 1G) ==="
cd $SOURCE_DIR/arm-trusted-firmware
# 512M EMMC
make clean
make CROSS_COMPILE=aarch64-linux-gnu- PLAT=mt7981 DEBUG=0 DDR3_FLY=0 USE_NMBM=0 BOOT_DEVICE=emmc LOG_LEVEL=20 DRAM_SIZE=512
find build/mt7981/release -name "bl2*.bin" -exec cp {} $OUTPUT_DIR/atf/bl2-512m-emmc.bin \;
# 1G EMMC
make clean
make CROSS_COMPILE=aarch64-linux-gnu- PLAT=mt7981 DEBUG=0 DDR3_FLY=0 USE_NMBM=0 BOOT_DEVICE=emmc LOG_LEVEL=20 DRAM_SIZE=1024
find build/mt7981/release -name "bl2*.bin" -exec cp {} $OUTPUT_DIR/atf/bl2-1g-emmc.bin \;

# ========== 2. 编译 U-Boot (原文照抄) ==========
echo "=== Building U-Boot ==="
cd $SOURCE_DIR/u-boot
make clean
make CROSS_COMPILE=aarch64-linux-gnu- mt7981_emmc_rfb_defconfig
make CROSS_COMPILE=aarch64-linux-gnu- -j$(nproc)
cp fip.bin $OUTPUT_DIR/uboot/fip-emmc.bin

# ========== 3. 编译 系统固件 (物理对齐) ==========
cd $WORKSPACE
mkdir -p immortalwrt-build
# 物理搬运扁平化源码
cp -r $FIRMWARE_DIR/. immortalwrt-build/
cd immortalwrt-build

# 【物理复刻：拉起 888 资源】
echo "=== 正在从 $CONFIG_DIR 物理拉起配置 ==="
cp "$CONFIG_DIR/mt7981-sl-3000-emmc-1g.dts" target/linux/mediatek/dts/
cp "$CONFIG_DIR/mt7981-sl-3000-emmc-512m.dts" target/linux/mediatek/dts/
cp "$CONFIG_DIR/mt7981.mk" target/linux/mediatek/image/
cp "$CONFIG_DIR/sl3000.config" .config

# --- 物理止损：处理不存在的 onionshare-cli 导致的 olddefconfig 崩溃 ---
echo "=== 正在清理影子依赖 ==="
sed -i '/onionshare/d' .config
sed -i '/CONFIG_PACKAGE_onionshare-cli/d' .config

# 更新并安装 feeds
./scripts/feeds update -a
./scripts/feeds install -a

# 执行配置生成 (使用 V=s 确保报错可见)
make olddefconfig || { echo "❌ 配置冲突！请检查 .config 是否引用了不存在的包"; exit 1; }
make defconfig
make -j$(nproc) V=s

# 收集固件
find bin/targets/ -type f \( -name "*.bin" -o -name "*.img.gz" \) -exec cp {} $OUTPUT_DIR/firmware/ \;

echo "✅ V1 构建任务物理闭环完成"
