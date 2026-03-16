#!/bin/bash
# =========================================================
# SL-3000 救砖全链路物理修复脚本 (自愈版)
# =========================================================

# 1. 物理创建零件工厂路径
mkdir -p package/boot/arm-trusted-firmware-mediatek
mkdir -p package/boot/uboot-mediatek

# 2. 物理平铺：从 clone 的 sl3000-repo 中提取子目录源码
# 解决 OpenWrt 无法识别嵌套子目录 Makefile 的问题
if [ -d "../sl3000-repo/atf" ]; then
    cp -rf ../sl3000-repo/atf/* package/boot/arm-trusted-firmware-mediatek/
    echo "✅ ATF 源码已平铺到标准路径"
fi

if [ -d "../sl3000-repo/u-boot" ]; then
    cp -rf ../sl3000-repo/u-boot/* package/boot/uboot-mediatek/
    echo "✅ U-Boot 源码已平铺到标准路径"
fi

# 3. 物理修正 U-Boot 1MB 偏移与 31.1 救砖 IP
UBOOT_DEF="package/boot/uboot-mediatek/configs/mt7981_nor_emmc_rfb_defconfig"
if [ -f "$UBOOT_DEF" ]; then
    # 修正救砖 IP
    sed -i 's/CONFIG_IPADDR=.*/CONFIG_IPADDR="192.168.31.1"/' "$UBOOT_DEF"
    # 修正分区表 1MB 物理对齐 (1024k)
    sed -i 's/CONFIG_MTDPARTS_DEFAULT=.*/CONFIG_MTDPARTS_DEFAULT="nor0:1024k(bl2),2048k(fip),-(storage)"/' "$UBOOT_DEF"
    # 注入 BL2 跳转基地址：0x40000000 + 1MB
    grep -q "CONFIG_SYS_UBOOT_BASE" "$UBOOT_DEF" || echo "CONFIG_SYS_UBOOT_BASE=0x40100000" >> "$UBOOT_DEF"
    echo "✅ U-Boot defconfig 物理修正完成"
fi

# 4. 彻底删除旧索引缓存
rm -rf tmp
