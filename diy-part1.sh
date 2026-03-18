#!/bin/bash
set -e

# ========== 1. 物理环境与全文件检测 ==========
echo "=== Checking all required source files ==="

WORKSPACE=$(pwd)
SOURCE_DIR="$WORKSPACE/source-repo"      # ykm99999 (ATF/UBoot)
FIRMWARE_DIR="$WORKSPACE/firmware-repo"  # ykm888 (系统源码 - 扁平结构)
CONFIG_DIR="$WORKSPACE/main-repo/888"    # 配置文件目录
OUTPUT_DIR="$WORKSPACE/output"
IMMORTALWRT_BUILD="$WORKSPACE/immortalwrt-build"
STAGING_DIR_IMAGE="$IMMORTALWRT_BUILD/staging_dir/image"

mkdir -p $OUTPUT_DIR/atf $OUTPUT_DIR/uboot $OUTPUT_DIR/firmware $STAGING_DIR_IMAGE

# 物理校验：检查关键编译文件是否存在
MISSING_FILES=()
FILES_TO_CHECK=(
    "arm-trusted-firmware/plat/mediatek/mt7981/platform.mk"
    "u-boot/configs/mt7981_emmc_rfb_defconfig"
)
for FILE in "${FILES_TO_CHECK[@]}"; do
    [ ! -e "$SOURCE_DIR/$FILE" ] && MISSING_FILES+=("$SOURCE_DIR/$FILE")
done

if [ ${#MISSING_FILES[@]} -ne 0 ]; then
    echo "❌ Missing required source files:"
    printf "   - %s\n" "${MISSING_FILES[@]}"
    exit 1
fi

export CROSS_COMPILE=aarch64-linux-gnu-
export ARCH=arm64

# ========== 2. 编译 ATF (像素级复刻) ==========
cd $SOURCE_DIR/arm-trusted-firmware

echo "=== Building ATF (512M & 1G EMMC) ==="
# 编译 512M 版
make clean
make CROSS_COMPILE=aarch64-linux-gnu- PLAT=mt7981 DEBUG=0 DDR3_FLY=0 USE_NMBM=0 BOOT_DEVICE=emmc LOG_LEVEL=20 DRAM_SIZE=512
find build/mt7981/release -name "bl2*.bin" -exec cp {} $OUTPUT_DIR/atf/bl2-512m-emmc.bin \;
# 编译 1G 版并保留 bl31 用于打包 FIP
make clean
make CROSS_COMPILE=aarch64-linux-gnu- PLAT=mt7981 DEBUG=0 DDR3_FLY=0 USE_NMBM=0 BOOT_DEVICE=emmc LOG_LEVEL=20 DRAM_SIZE=1024
find build/mt7981/release -name "bl2*.bin" -exec cp {} $OUTPUT_DIR/atf/bl2-1g-emmc.bin \;
cp build/mt7981/release/bl31.bin $STAGING_DIR_IMAGE/mt7981-emmc-ddr4-bl31.bin

# 编译 1G NOR 版 (救砖用)
make clean
make CROSS_COMPILE=aarch64-linux-gnu- PLAT=mt7981 DEBUG=0 DDR3_FLY=0 USE_NMBM=0 BOOT_DEVICE=nor LOG_LEVEL=20 DRAM_SIZE=1024
find build/mt7981/release -name "bl2*.bin" -exec cp {} $OUTPUT_DIR/atf/bl2-1g-nor.bin \;

echo "=== Compiling ATF fiptool ==="
make -C tools/fiptool CROSS_COMPILE=
FIPTOOL="$PWD/tools/fiptool/fiptool"

# ========== 3. 编译 U-Boot 并物理合成 FIP ==========
cd $SOURCE_DIR/u-boot
make clean
make CROSS_COMPILE=aarch64-linux-gnu- mt7981_emmc_rfb_defconfig
echo "CONFIG_MTK_FIP_SUPPORT=y" >> .config
make olddefconfig
make CROSS_COMPILE=aarch64-linux-gnu- -j$(nproc)

# 物理合成 FIP.bin (解决 cp: cannot stat 'fip.bin' 报错)
if [ ! -f fip.bin ]; then
    echo "⚠️ fip.bin not found, manually creating FIP..."
    "$FIPTOOL" create \
        --soc-fw $STAGING_DIR_IMAGE/mt7981-emmc-ddr4-bl31.bin \
        --nt-fw u-boot.bin \
        fip.bin
fi
cp fip.bin $OUTPUT_DIR/uboot/fip-emmc.bin
cp u-boot.bin $OUTPUT_DIR/uboot/u-boot-emmc.bin

# ========== 4. 编译系统固件 (针对扁平源码结构修复) ==========
cd $WORKSPACE
rm -rf $IMMORTALWRT_BUILD
mkdir -p $IMMORTALWRT_BUILD
# 【物理修正】：直接搬运扁平化的 ykm888 源码
echo "=== Copying flat firmware source ==="
cp -r $FIRMWARE_DIR/. $IMMORTALWRT_BUILD/
cd $IMMORTALWRT_BUILD

# --- 物理切除 problematic packages (防 olddefconfig 崩溃) ---
echo "=== Purging problematic feeds ==="
./scripts/feeds update -a
rm -rf feeds/video
rm -rf feeds/packages/net/onionshare-cli
./scripts/feeds update -i
./scripts/feeds install -a

# --- 物理拉起 888 配置三件套 ---
echo "=== Injecting SL3000 Device Files ==="
cp -v $CONFIG_DIR/mt7981-sl-3000-emmc-1g.dts target/linux/mediatek/dts/
cp -v $CONFIG_DIR/mt7981-sl-3000-emmc-512m.dts target/linux/mediatek/dts/
cp -v $CONFIG_DIR/mt7981.mk target/linux/mediatek/image/
cp -v $CONFIG_DIR/sl3000.config .config

# --- 物理激活设备定义 ---
echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl_3000-emmc-1g=y" >> .config
echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl_3000-emmc-512m=y" >> .config

# 执行配置修复
make olddefconfig || make oldconfig
make -j$(nproc) V=s 2>&1 | tee build.log

# ========== 5. 产物搜集 ==========
find bin/targets/ -type f \( -name "*.bin" -o -name "*.img.gz" -o -name "*sysupgrade*" \) -exec cp -v {} $OUTPUT_DIR/firmware/ \;
cp build.log $OUTPUT_DIR/firmware/

# 打包工具链
if [ -d "$SOURCE_DIR/mtk_uartboot" ]; then
    cd $SOURCE_DIR/mtk_uartboot
    tar -czf $OUTPUT_DIR/mtk_uartboot.tar.gz .
fi

echo "✅ SL3000 Build Complete. Results in $OUTPUT_DIR"
