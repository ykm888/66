#!/bin/bash
#
# Copyright (C) 2024-2026 ykm888
# 物理修复 9 版：物理环节熔断机制，严禁空跑浪费时间
#

# --- 1. 物理环境强力清场 ---
rm -rf package/boot/arm-trusted-firmware-mediatek
rm -rf package/boot/uboot-mediatek

# --- 2. 物理跨分支搬运 (增加物理熔断) ---
git clone -b sl3000-clean-source https://github.com/ykm888/66.git /tmp/source_repo || { echo "!!! Git Clone Failed !!!"; exit 1; }

mkdir -p package/boot/arm-trusted-firmware-mediatek
mkdir -p package/boot/uboot-mediatek

# 物理搬运并立即验证 Makefile 存在性
cp -fR /tmp/source_repo/atf/* package/boot/arm-trusted-firmware-mediatek/
[ -f "package/boot/arm-trusted-firmware-mediatek/Makefile" ] || { echo "!!! ATF Makefile Missing !!!"; exit 1; }

cp -fR /tmp/source_repo/u-boot/* package/boot/uboot-mediatek/
[ -f "package/boot/uboot-mediatek/Makefile" ] || { echo "!!! U-Boot Makefile Missing !!!"; exit 1; }

# --- 3. 物理心脏移植 (验证驱动注入) ---
if [ -f "888/bl2_dev_spi_nor.c" ]; then
    TARGET_DRV="package/boot/arm-trusted-firmware-mediatek/src/plat/mediatek/mt7981/bl2_dev_spi_nor.c"
    mkdir -p $(dirname "$TARGET_DRV")
    cp -f 888/bl2_dev_spi_nor.c "$TARGET_DRV"
    [ -f "$TARGET_DRV" ] || { echo "!!! Core Driver Injection Failed !!!"; exit 1; }
fi

# --- 4. 物理地图与合成宏覆盖 ---
cp -f 888/mt7981-sl-3000-emmc.dts target/linux/mediatek/dts/mt7981-sl-3000-emmc.dts
cp -f 888/filogic.mk target/linux/mediatek/image/filogic.mk
[ -f "target/linux/mediatek/image/filogic.mk" ] || { echo "!!! filogic.mk Missing !!!"; exit 1; }

# --- 5. 1MB 物理边界强制校准 ---
sed -i 's/pad-to 512k/pad-to 1024k/g' target/linux/mediatek/image/filogic.mk
sed -i 's/seek=512/seek=1024/g' target/linux/mediatek/image/filogic.mk

# --- 6. 激活物理索引与零件生产开关 ---
rm -rf /tmp/source_repo
./scripts/feeds update -i
./scripts/feeds install -a

# [最高级修补]：强制在 .config 中开启物理开关，确保 make 进程必须生产 ATF/U-Boot
# 如果这一步不打通，后面缝合必碎，所以现在就强制写入
echo "CONFIG_PACKAGE_arm-trusted-firmware-mediatek=y" >> .config
echo "CONFIG_PACKAGE_uboot-mediatek=y" >> .config

echo "DIY-Part2: All physical links verified. Proceeding to build."
