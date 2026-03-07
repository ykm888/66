#!/bin/bash

UBOOT_BRANCH=$1
[ -z "$UBOOT_BRANCH" ] && UBOOT_BRANCH="sl3000-uboot-base"

echo ">>> 启动 SL-3000 彻底物理修复工序..."

# 1. 物理破除内核 1024M 识别限制
if [ -f "openwrt/target/linux/mediatek/filogic/base-files/lib/upgrade/platform.sh" ]; then
    sed -i 's/256m/1024m/g' openwrt/target/linux/mediatek/filogic/base-files/lib/upgrade/platform.sh
fi

# 2. 物理彻底切除冲突驱动源码 (Warp/Files)
rm -rf openwrt/package/mtk/drivers/warp
rm -rf openwrt/package/mtk/drivers/files_t7981

# 3. 【彻底修复】mt_wifi WHNAT 宏定义冲突
# 物理路径锁定：针对 MT7981 的 WHNAT 头文件
WHNAT_HDR="openwrt/package/mtk/drivers/mt_wifi/files/mt_wifi/embedded/plug_in/whnat/woe_mt7981.h"
if [ -f "$WHNAT_HDR" ]; then
    echo ">>> 正在执行代码级物理修复：注入缺失的 WF_WFDMA_EXT_WRAP_CSR_PCI_BASE 宏..."
    # 检查是否已定义，若无则在文件头部物理注入对齐定义
    if ! grep -q "WF_WFDMA_EXT_WRAP_CSR_PCI_BASE" "$WHNAT_HDR"; then
        sed -i '1i #define WF_WFDMA_EXT_WRAP_CSR_PCI_BASE(p) (p)' "$WHNAT_HDR"
    fi
fi

# 4. 物理对齐：修正 MODULE_SUPPORTED_DEVICE 报错
# 在新内核中该宏已被移除，物理将其注释掉以消除 Error
WHNAT_MAIN="openwrt/package/mtk/drivers/mt_wifi/files/mt_wifi/embedded/plug_in/whnat/woe_main.c"
if [ -f "$WHNAT_MAIN" ]; then
    echo ">>> 正在物理切除过时的 MODULE_SUPPORTED_DEVICE 定义..."
    sed -i 's/MODULE_SUPPORTED_DEVICE/\/\/MODULE_SUPPORTED_DEVICE/g' "$WHNAT_MAIN"
fi

# 5. 物理初始化并构建救砖 U-Boot (维持 1024M Bank 逻辑)
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

echo ">>> 彻底修复完成，物理工序锁死。"
