#!/bin/bash
# [物理执行三准则 - 第 13 版]
# 目标：DDR4 硬件环境全零件物理合拢

# 1. 物理清场
rm -rf package/boot/arm-trusted-firmware-mediatek
rm -rf package/boot/uboot-mediatek
mkdir -p package/boot/arm-trusted-firmware-mediatek
mkdir -p package/boot/uboot-mediatek

# 2. 搬运基础零件
git clone -b sl3000-clean-source https://github.com/ykm888/66.git /tmp/source_repo
cp -fR /tmp/source_repo/atf/* package/boot/arm-trusted-firmware-mediatek/
cp -fR /tmp/source_repo/u-boot/* package/boot/uboot-mediatek/

# 3. 零件注入：从指挥部 (888 目录) 搬运加固图纸
cp -f 888/atf-Makefile package/boot/arm-trusted-firmware-mediatek/Makefile
cp -f 888/uboot-Makefile package/boot/uboot-mediatek/Makefile
cp -f 888/bl2.mk package/boot/arm-trusted-firmware-mediatek/src/plat/mediatek/mt7981/bl2.mk
cp -f 888/platform.mk package/boot/arm-trusted-firmware-mediatek/src/plat/mediatek/mt7981/platform.mk
cp -f 888/bl2_dev_spi_nor.c package/boot/arm-trusted-firmware-mediatek/src/plat/mediatek/mt7981/bl2_dev_spi_nor.c

# 4. 地图与缝合逻辑注入
cp -f 888/*.dts target/linux/mediatek/dts/ 2>/dev/null || true
[ -f "888/filogic.mk" ] && cp -f 888/filogic.mk target/linux/mediatek/image/filogic.mk

# 5. 物理偏移锁定 (1MB) 与 DDR4 产物索引修正
sed -i 's/pad-to 512k/pad-to 1024k/g' target/linux/mediatek/image/filogic.mk
sed -i 's/seek=512/seek=1024/g' target/linux/mediatek/image/filogic.mk

# 强制修正索引名，确保最终镜像能够找到 DDR4 的 bl2
sed -i 's/mt7981-bl2.bin/mt7981-bl2-nor-ddr4.bin/g' target/linux/mediatek/image/filogic.mk 2>/dev/null || true

# 6. 激活索引并清理
rm -rf /tmp/source_repo
./scripts/feeds update -i
./scripts/feeds install -a
