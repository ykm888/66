#!/bin/bash
set -e

# ========== 1. 环境与路径初始化 ==========
WORKSPACE=$(pwd)
SOURCE_DIR="$WORKSPACE/source-repo"
FIRMWARE_DIR="$WORKSPACE/firmware-repo"
CONFIG_DIR="$WORKSPACE/main-repo/888"
OUTPUT_DIR="$WORKSPACE/output"
IMMORTALWRT_BUILD="$WORKSPACE/immortalwrt-build"
STAGING_DIR_IMAGE="$IMMORTALWRT_BUILD/staging_dir/image"

mkdir -p $OUTPUT_DIR/atf $OUTPUT_DIR/uboot $OUTPUT_DIR/firmware $STAGING_DIR_IMAGE

export CROSS_COMPILE=aarch64-linux-gnu-
export ARCH=arm64

# ========== 2. 编译 ATF & U-Boot (保持物理稳定性) ==========
# --- ATF 编译 ---
cd $SOURCE_DIR/arm-trusted-firmware
make clean
make CROSS_COMPILE=aarch64-linux-gnu- PLAT=mt7981 DEBUG=0 DDR3_FLY=0 USE_NMBM=0 BOOT_DEVICE=emmc LOG_LEVEL=20 DRAM_SIZE=1024
find build/mt7981/release -name "bl2.bin" -exec cp {} $OUTPUT_DIR/atf/bl2-1g-emmc.bin \;
cp build/mt7981/release/bl31.bin $STAGING_DIR_IMAGE/mt7981-emmc-ddr4-bl31.bin
make -C tools/fiptool CROSS_COMPILE=
FIPTOOL="$PWD/tools/fiptool/fiptool"

# --- U-Boot 编译 ---
cd $SOURCE_DIR/u-boot
make clean
make CROSS_COMPILE=aarch64-linux-gnu- mt7981_emmc_rfb_defconfig
echo "CONFIG_MTK_FIP_SUPPORT=y" >> .config
make olddefconfig
make CROSS_COMPILE=aarch64-linux-gnu- -j$(nproc)

# --- FIP 物理合成 ---
if [ ! -f fip.bin ]; then
    "$FIPTOOL" create --soc-fw $STAGING_DIR_IMAGE/mt7981-emmc-ddr4-bl31.bin --nt-fw u-boot.bin fip.bin
fi
cp fip.bin $OUTPUT_DIR/uboot/fip-emmc.bin
cp u-boot.bin $OUTPUT_DIR/uboot/u-boot-emmc.bin

# ========== 3. 编译系统固件 (核心修复依赖死锁) ==========
cd $WORKSPACE
rm -rf $IMMORTALWRT_BUILD && mkdir -p $IMMORTALWRT_BUILD

echo "=== 正在物理同步系统源码基座 ==="
cp -a $FIRMWARE_DIR/. $IMMORTALWRT_BUILD/
cd $IMMORTALWRT_BUILD

# 【关键修复】：重建 5.4 内核特有的物理路径
DTS_PATH="target/linux/mediatek/files-5.4/arch/arm64/boot/dts/mediatek"
MK_PATH="target/linux/mediatek/image"
mkdir -p "$DTS_PATH" "$MK_PATH"

echo "=== 正在注入 SL3000 变体文件 ==="
cp -f "$CONFIG_DIR/mt7981-sl-3000-emmc-1g.dts" "$DTS_PATH/mt7981-sl-3000-emmc-1g.dts"
cp -f "$CONFIG_DIR/mt7981-sl-3000-emmc-512m.dts" "$DTS_PATH/mt7981-sl-3000-emmc-512m.dts"
cp -f "$CONFIG_DIR/mt7981.mk" "$MK_PATH/mt7981.mk"
cp -f "$CONFIG_DIR/sl3000.config" ".config"

# --- 物理净化 feeds (解决 Broken Pipe 和依赖缺失) ---
echo "=== 执行依赖树物理净化 ==="
./scripts/feeds update -a
# 强力删除报错日志中提到的所有问题包和无用 feed
rm -rf feeds/video feeds/telephony feeds/packages/net/dae* feeds/packages/net/libreswan
./scripts/feeds update -i
./scripts/feeds install -a

# --- 配置修复策略 (解决 olddefconfig Error 1) ---
echo "=== 正在修复 .config 兼容性 ==="
# 1. 物理删除所有会导致依赖断裂的 kmod 引用（让系统自动重新生成）
sed -i '/kmod-xdp-sockets-diag/d' .config
sed -i '/kmod-crypto-chacha20poly1305/d' .config
sed -i '/kmod-qrtr/d' .config
sed -i '/onionshare/d' .config

# 2. 强制使用单线程 oldconfig 交互式自动处理
# 使用 yes "" 模拟回车，自动选择默认选项处理冲突
yes "" | make oldconfig

# 3. 最终应用 defconfig
make defconfig

# --- 执行编译 ---
echo "=== 开始编译系统固件 ==="
make -j$(nproc) V=s 2>&1 | tee build.log

# ========== 4. 产物收集 ==========
find bin/targets/ -type f \( -name "*.bin" -o -name "*.img.gz" -o -name "*sysupgrade*" \) -exec cp -v {} $OUTPUT_DIR/firmware/ \;

echo "✅ SL3000 V1 终极闭环版本构建成功"
