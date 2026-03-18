#!/bin/bash
set -e

# ========== 1. 物理环境初始化 ==========
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

# ========== 2. 编译 ATF (512M & 1G) ==========
cd $SOURCE_DIR/arm-trusted-firmware
echo "=== Building ATF (EMMC 1G) ==="
make clean
make CROSS_COMPILE=aarch64-linux-gnu- PLAT=mt7981 DEBUG=0 DDR3_FLY=0 USE_NMBM=0 BOOT_DEVICE=emmc LOG_LEVEL=20 DRAM_SIZE=1024
find build/mt7981/release -name "bl2.bin" -exec cp {} $OUTPUT_DIR/atf/bl2-1g-emmc.bin \;
cp build/mt7981/release/bl31.bin $STAGING_DIR_IMAGE/mt7981-emmc-ddr4-bl31.bin

# 编译 fiptool 用于后续合成
make -C tools/fiptool CROSS_COMPILE=
FIPTOOL="$PWD/tools/fiptool/fiptool"

# ========== 3. 编译 U-Boot 并物理合成 FIP ==========
cd $SOURCE_DIR/u-boot
make clean
make CROSS_COMPILE=aarch64-linux-gnu- mt7981_emmc_rfb_defconfig
echo "CONFIG_MTK_FIP_SUPPORT=y" >> .config
make olddefconfig
make CROSS_COMPILE=aarch64-linux-gnu- -j$(nproc)

# 【物理修复点】：手动合成 fip.bin
if [ ! -f fip.bin ]; then
    echo "⚠️ 手动合成 FIP.bin..."
    "$FIPTOOL" create --soc-fw $STAGING_DIR_IMAGE/mt7981-emmc-ddr4-bl31.bin --nt-fw u-boot.bin fip.bin
fi
cp fip.bin $OUTPUT_DIR/uboot/fip-emmc.bin
cp u-boot.bin $OUTPUT_DIR/uboot/u-boot-emmc.bin

# ========== 4. 编译系统固件 (5.4内核路径对齐) ==========
cd $WORKSPACE
rm -rf $IMMORTALWRT_BUILD && mkdir -p $IMMORTALWRT_BUILD
cp -a $FIRMWARE_DIR/. $IMMORTALWRT_BUILD/
cd $IMMORTALWRT_BUILD

# 【关键修复】：物理重建 ykm888 特有的 5.4 内核 DTS 路径
DTS_PATH="target/linux/mediatek/files-5.4/arch/arm64/boot/dts/mediatek"
MK_PATH="target/linux/mediatek/image"
mkdir -p "$DTS_PATH"
mkdir -p "$MK_PATH"

echo "=== 正在注入 SL3000 变体文件至底层路径 ==="
cp -f "$CONFIG_DIR/mt7981-sl-3000-emmc-1g.dts" "$DTS_PATH/mt7981-sl-3000-emmc-1g.dts"
cp -f "$CONFIG_DIR/mt7981-sl-3000-emmc-512m.dts" "$DTS_PATH/mt7981-sl-3000-emmc-512m.dts"
cp -f "$CONFIG_DIR/mt7981.mk" "$MK_PATH/mt7981.mk"
cp -f "$CONFIG_DIR/sl3000.config" ".config"

# --- Feeds 净化 (防止 telephony/video 崩溃) ---
./scripts/feeds update -a
rm -rf feeds/video feeds/telephony/onionshare*
./scripts/feeds update -i
./scripts/feeds install -a

# --- 配置与编译 ---
echo "CONFIG_TARGET_mediatek=y" >> .config
echo "CONFIG_TARGET_mediatek_filogic=y" >> .config
echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl_3000-emmc-1g=y" >> .config
echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl_3000-emmc-512m=y" >> .config

make olddefconfig
make -j$(nproc) V=s 2>&1 | tee build.log

# ========== 5. 产物搜集 ==========
find bin/targets/ -type f \( -name "*.bin" -o -name "*.img.gz" -o -name "*sysupgrade*" \) -exec cp -v {} $OUTPUT_DIR/firmware/ \;
cp build.log $OUTPUT_DIR/firmware/

echo "✅ SL3000 V1 构建任务物理全链路闭环"
