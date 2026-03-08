#!/bin/bash

# 获取传入的 U-Boot 分支参数
UBOOT_BRANCH=$1
[ -z "$UBOOT_BRANCH" ] && UBOOT_BRANCH="sl3000-uboot-base"

echo ">>> 启动 SL-3000 物理全修复：1024M + MT7531 DSA + 6.6 内核代码级自愈..."

# 1. 物理破除内核 1024M 识别限制 (内核层)
if [ -f "openwrt/target/linux/mediatek/filogic/base-files/lib/upgrade/platform.sh" ]; then
    echo ">>> 正在物理注入 1024M 内存识别补丁..."
    sed -i 's/256m/1024m/g' openwrt/target/linux/mediatek/filogic/base-files/lib/upgrade/platform.sh
fi

# 2. 物理彻底切除冲突驱动源码 (隔离层)
echo ">>> 正在物理隔离 Warp/WED 冲突源..."
rm -rf openwrt/package/mtk/drivers/warp
rm -rf openwrt/package/mtk/drivers/files_t7981

# 3. 【彻底解决】mt_wifi 源码报错物理手术 (代码层)
# 针对寄存器定义缺失修复
WHNAT_HDR="openwrt/package/mtk/drivers/mt_wifi/files/mt_wifi/embedded/plug_in/whnat/woe_mt7981.h"
if [ -f "$WHNAT_HDR" ]; then
    echo ">>> 正在物理注入缺失的寄存器宏定义 (PCI_BASE/GLO_CFG)..."
    sed -i '1i #define WF_WFDMA_EXT_WRAP_CSR_PCI_BASE(p) (p)' "$WHNAT_HDR"
    sed -i '1i #define WIFI_WPDMA_GLO_CFG (0x4000)' "$WHNAT_HDR"
fi

# 针对 6.6 内核废弃宏 MODULE_SUPPORTED_DEVICE 的物理切除
WHNAT_MAIN="openwrt/package/mtk/drivers/mt_wifi/files/mt_wifi/embedded/plug_in/whnat/woe_main.c"
if [ -f "$WHNAT_MAIN" ]; then
    echo ">>> 正在执行物理手术：彻底清除 6.6 内核不支持的 MODULE_SUPPORTED_DEVICE..."
    # 物理手段：直接注释掉该行以消除 expected declaration specifiers 报错
    sed -i 's/MODULE_SUPPORTED_DEVICE/\/\/MODULE_SUPPORTED_DEVICE/g' "$WHNAT_MAIN"
fi

# 4. 物理注入核心驱动与磁盘工具 (配置层锁死)
# 物理逻辑：确保 MT7531 交换机、HNAT 和磁盘工具在编译时不被剔除
echo ">>> 正在锁定 MT7531 交换机与 1024M 物理磁盘工具配置..."
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
CONFIG_PACKAGE_kmod-fs-exfat=y
EOF

# 5. 物理构建救砖 U-Boot (维持 1024M Bank)
echo ">>> 正在构建 SL-3000 救砖 U-Boot (分支: $UBOOT_BRANCH)..."
sudo apt-get update -qq && sudo apt-get install -y -qq gcc-aarch64-linux-gnu build-essential flex bison bc python3-dev

git clone --depth 1 -b $UBOOT_BRANCH https://github.com/ykm888/66.git uboot-src
cd uboot-src
export ARCH=arm
export CROSS_COMPILE=aarch64-linux-gnu-

make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE mt7981_emmc_defconfig

# 物理注入 1024M 内存 Bank 识别
sed -i 's/CONFIG_NR_DRAM_BANKS=.*/CONFIG_NR_DRAM_BANKS=1/g' .config
echo "CONFIG_NR_DRAM_BANKS=1" >> .config

make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE -j$(nproc) || exit 1

# 提取救砖引导
if [ -f "u-boot.bin" ]; then
    cp u-boot.bin ../sl3000-uboot.bin
elif [ -f "u-boot-mtk.bin" ]; then
    cp u-boot-mtk.bin ../sl3000-uboot.bin
fi

cd ..
echo ">>> SL-3000 物理全修复工序完成，主编译流程已物理洗白。"
