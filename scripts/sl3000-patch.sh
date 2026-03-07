#!/bin/bash

UBOOT_BRANCH=$1
[ -z "$UBOOT_BRANCH" ] && UBOOT_BRANCH="sl3000-uboot-base"

echo ">>> 启动 SL-3000 物理增强工序 (MT7531 DSA + 1024M 磁盘工具)..."

# 1. 物理破除 1024M 识别限制 (内核层)
if [ -f "openwrt/target/linux/mediatek/filogic/base-files/lib/upgrade/platform.sh" ]; then
    sed -i 's/256m/1024m/g' openwrt/target/linux/mediatek/filogic/base-files/lib/upgrade/platform.sh
fi

# 2. 物理彻底切除 Warp/WED 冲突源 (源码层)
# 物理逻辑：彻底阻断会导致 6.6 内核崩溃的旧版私有加速模块
rm -rf openwrt/package/mtk/drivers/warp
rm -rf openwrt/package/mtk/drivers/files_t7981

# 3. 物理修复 mt_wifi 源码报错 (代码层)
WHNAT_HDR="openwrt/package/mtk/drivers/mt_wifi/files/mt_wifi/embedded/plug_in/whnat/woe_mt7981.h"
if [ -f "$WHNAT_HDR" ]; then
    sed -i '1i #define WF_WFDMA_EXT_WRAP_CSR_PCI_BASE(p) (p)' "$WHNAT_HDR"
    sed -i '1i #define WIFI_WPDMA_GLO_CFG (0x4000)' "$WHNAT_HDR"
fi

# 4. 物理注入核心驱动与磁盘工具 (配置层锁死)
# 物理逻辑：确保 MT7531 交换机和磁盘工具在编译时不被剔除
cat <<EOF >> openwrt/.config
# MT7531 DSA & HNAT 物理锁死
CONFIG_PACKAGE_kmod-mediatek_eth=y
CONFIG_PACKAGE_kmod-mediatek_hnat=y
CONFIG_PACKAGE_kmod-mt7531=y
CONFIG_PACKAGE_kmod-net-mediatek-mdio=y
CONFIG_PACKAGE_bridge=y
CONFIG_PACKAGE_kmod-bridge=y

# 1024M 物理磁盘操作工具
CONFIG_PACKAGE_fdisk=y
CONFIG_PACKAGE_lsblk=y
CONFIG_PACKAGE_block-mount=y
CONFIG_PACKAGE_kmod-fs-ext4=y
CONFIG_PACKAGE_kmod-fs-vfat=y
EOF

# 5. 物理构建救砖 U-Boot (维持 1024M Bank)
sudo apt-get update -qq && sudo apt-get install -y -qq gcc-aarch64-linux-gnu build-essential flex bison bc python3-dev
git clone --depth 1 -b $UBOOT_BRANCH https://github.com/ykm888/66.git uboot-src
cd uboot-src
export ARCH=arm
export CROSS_COMPILE=aarch64-linux-gnu-
make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE mt7981_emmc_defconfig
sed -i 's/CONFIG_NR_DRAM_BANKS=.*/CONFIG_NR_DRAM_BANKS=1/g' .config
echo "CONFIG_NR_DRAM_BANKS=1" >> .config
make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE -j$(nproc) || exit 1
[ -f "u-boot.bin" ] && cp u-boot.bin ../sl3000-uboot.bin || cp u-boot-mtk.bin ../sl3000-uboot.bin
cd ..

echo ">>> 脚本物理增强完成，工作流可直接启动。"
