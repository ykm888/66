#!/bin/bash
set -e

WORKSPACE="$GITHUB_WORKSPACE"
SOURCE_DIR="$WORKSPACE/source-repo"      # ykm99999 (ATF/UBoot)
FIRMWARE_DIR="$WORKSPACE/firmware-repo"  # ykm888 (ImmortalWrt 扁平源)
CONFIG_DIR="$WORKSPACE/main-repo/888"    # 存放配置、MK和独立DTS的目录
OUTPUT_DIR="$WORKSPACE/output"

mkdir -p $OUTPUT_DIR/atf $OUTPUT_DIR/uboot $OUTPUT_DIR/firmware

export CROSS_COMPILE=aarch64-linux-gnu-
export ARCH=arm64

# ========== 1. 编译 ATF (EMMC版: 512M 和 1G) ==========
echo "=== Building ATF 512M (EMMC) ==="
cd $SOURCE_DIR/arm-trusted-firmware
make clean
make CROSS_COMPILE=aarch64-linux-gnu- PLAT=mt7981 DEBUG=0 DDR3_FLY=0 USE_NMBM=0 BOOT_DEVICE=emmc LOG_LEVEL=20 DRAM_SIZE=512
find build/mt7981/release -name "bl2*.bin" -exec cp {} $OUTPUT_DIR/atf/bl2-512m-emmc.bin \; 2>/dev/null || echo "No bl2.bin for 512M emmc"
find build/mt7981/release -name "bl2*.elf" -exec cp {} $OUTPUT_DIR/atf/bl2-512m-emmc.elf \; 2>/dev/null || echo "No bl2.elf for 512M emmc"

make clean
make CROSS_COMPILE=aarch64-linux-gnu- PLAT=mt7981 DEBUG=0 DDR3_FLY=0 USE_NMBM=0 BOOT_DEVICE=emmc LOG_LEVEL=20 DRAM_SIZE=1024
find build/mt7981/release -name "bl2*.bin" -exec cp {} $OUTPUT_DIR/atf/bl2-1g-emmc.bin \; 2>/dev/null || echo "No bl2.bin for 1G emmc"
find build/mt7981/release -name "bl2*.elf" -exec cp {} $OUTPUT_DIR/atf/bl2-1g-emmc.elf \; 2>/dev/null || echo "No bl2.elf for 1G emmc"

# ========== 新增：编译 ATF (NOR版: 1G，用于救砖) ==========
echo "=== Building ATF 1G (NOR - for rescue) ==="
make clean
make CROSS_COMPILE=aarch64-linux-gnu- PLAT=mt7981 DEBUG=0 DDR3_FLY=0 USE_NMBM=0 BOOT_DEVICE=nor LOG_LEVEL=20 DRAM_SIZE=1024
find build/mt7981/release -name "bl2*.bin" -exec cp {} $OUTPUT_DIR/atf/bl2-1g-nor.bin \; 2>/dev/null || echo "No bl2.bin for 1G nor"
find build/mt7981/release -name "bl2*.elf" -exec cp {} $OUTPUT_DIR/atf/bl2-1g-nor.elf \; 2>/dev/null || echo "No bl2.elf for 1G nor"

# ========== 2. 编译 U-Boot ==========
echo "=== Building U-Boot ==="
cd $SOURCE_DIR/u-boot
make clean
if [ -f configs/mt7981_emmc_rfb_defconfig ]; then
    make CROSS_COMPILE=aarch64-linux-gnu- mt7981_emmc_rfb_defconfig
else
    echo "❌ mt7981_emmc_rfb_defconfig not found!"
    exit 1
fi
make CROSS_COMPILE=aarch64-linux-gnu- -j$(nproc)
[ -f fip.bin ] && cp fip.bin $OUTPUT_DIR/uboot/fip-emmc.bin
[ -f u-boot.bin ] && cp u-boot.bin $OUTPUT_DIR/uboot/u-boot-emmc.bin

# ========== 3. 编译 ImmortalWrt (核心物理注入) ==========
cd $WORKSPACE
mkdir -p immortalwrt-build
# 物理搬运 ykm888 源码
cp -r $FIRMWARE_DIR/. immortalwrt-build/
# 磁盘优化
rm -rf $SOURCE_DIR/arm-trusted-firmware $SOURCE_DIR/u-boot
cd immortalwrt-build

# 【物理对齐：拉起你指定的两个 DTS】
echo "=== 正在物理拉起两个独立 DTS 文件 ==="
cp "$CONFIG_DIR/mt7981-sl-3000-emmc-1g.dts" target/linux/mediatek/dts/
cp "$CONFIG_DIR/mt7981-sl-3000-emmc-512m.dts" target/linux/mediatek/dts/

# 注入 MK 和 CONFIG
cp "$CONFIG_DIR/mt7981.mk" target/linux/mediatek/image/
cp "$CONFIG_DIR/sl3000.config" .config

./scripts/feeds update -a
./scripts/feeds install -a
make defconfig
make -j$(nproc) V=s 2>&1 | tee build.log

# 搜集产物
find bin/targets/ -type f \( -name "*.bin" -o -name "*.img.gz" -o -name "*sysupgrade*" \) -exec cp {} $OUTPUT_DIR/firmware/ \;
cp build.log $OUTPUT_DIR/firmware/

# 优化：清理构建目录
rm -rf build_dir

# ========== 4. 打包 mtk_uartboot ==========
cd $SOURCE_DIR/mtk_uartboot 2>/dev/null || echo "UART tools skipped"
[ -d "." ] && tar -czf $OUTPUT_DIR/mtk_uartboot.tar.gz .

echo "✅ V1 复刻版构建完成"
ls -la $OUTPUT_DIR/atf $OUTPUT_DIR/uboot $OUTPUT_DIR/firmware
