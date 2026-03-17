#!/bin/bash
set -e

WORKSPACE="$GITHUB_WORKSPACE"
SOURCE_DIR="$WORKSPACE/source-repo"
CONFIG_DIR="$WORKSPACE/main-repo/888"
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

# ========== 3. 编译 ImmortalWrt (磁盘优化点) ==========
cd $WORKSPACE
# 优化：复制后物理删除不再需要的 ATF 和 U-Boot 源码以释放空间
cp -r $SOURCE_DIR/immortalwrt immortalwrt-build
rm -rf $SOURCE_DIR/arm-trusted-firmware $SOURCE_DIR/u-boot
cd immortalwrt-build

cp $CONFIG_DIR/mt7981-sl-3000-emmc.dts target/linux/mediatek/dts/ 2>/dev/null || echo "Warning: mt7981-sl-3000-emmc.dts not found"
cp $CONFIG_DIR/mt7981.mk target/linux/mediatek/image/
cp $CONFIG_DIR/sl3000.config .config || { echo "Error: sl3000.config not found in $CONFIG_DIR"; exit 1; }

./scripts/feeds update -a
./scripts/feeds install -a
make defconfig
make -j$(nproc) V=s 2>&1 | tee build.log

find bin/targets/ -type f \( -name "*.bin" -o -name "*.img.gz" -o -name "*sysupgrade*" \) -exec cp {} $OUTPUT_DIR/firmware/ \;
cp build.log $OUTPUT_DIR/firmware/

# 优化：最后清理编译产生的 build_dir
rm -rf build_dir

# ========== 4. 打包 mtk_uartboot ==========
# 物理溯源：如果前面删了 source-repo，需确保此工具还在
cd $SOURCE_DIR/mtk_uartboot 2>/dev/null || echo "UART tools skipped or already moved"
[ -d "." ] && tar -czf $OUTPUT_DIR/mtk_uartboot.tar.gz .

echo "✅ 构建完成，产物位于: $OUTPUT_DIR"
ls -la $OUTPUT_DIR/atf $OUTPUT_DIR/uboot $OUTPUT_DIR/firmware
