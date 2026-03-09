#!/bin/bash
#
# Copyright (C) 2024-2026 ykm888
# 物理修复脚本：SL-3000 (1024M + eMMC + NOR Boot) 终极闭环版
#

# --- 1. 物理强制注入 .config 选项 (解决你缺失配置的问题) ---
# 确保在编译开始前，这些救砖核心组件被强制选中
echo "CONFIG_PACKAGE_trusted-firmware-a-mt7981-nor-ddr4=y" >> .config
echo "CONFIG_PACKAGE_uboot-mediatek_mt7981_sl_3000-nor-emmc=y" >> .config

# --- 2. 物理注入内核配置：确保识别 eMMC 的 GPT 分区表 ---
# 防止内核启动时找不到 PARTLABEL=production
echo "CONFIG_EFI_PARTITION=y" >> target/linux/mediatek/filogic/config-5.15
echo "CONFIG_PARTITION_ADVANCED=y" >> target/linux/mediatek/filogic/config-5.15
echo "CONFIG_MSDOS_PARTITION=y" >> target/linux/mediatek/filogic/config-5.15

# --- 3. 物理锁定 eMMC 驱动：从模块 (m) 改为内建 (y) ---
sed -i 's/CONFIG_MMC_MTK=m/CONFIG_MMC_MTK=y/g' target/linux/mediatek/filogic/config-5.15

# --- 4. 物理注入修复好的 DTS 文件 ---
# 将你仓库中 custom-config 下的 DTS 覆盖到内核源码目录
if [ -f "custom-config/mt7981-sl-3000-emmc.dts" ]; then
    cp -f custom-config/mt7981-sl-3000-emmc.dts target/linux/mediatek/files-5.15/arch/arm64/boot/dts/mediatek/mt7981-sl-3000-emmc.dts
    echo "DTS 文件已物理同步到内核目录。"
fi

# --- 5. 物理修正通用设备树内存定义 (锁定 1024M) ---
# 防止某些源码强制将内存截断为 512M 或 256M
sed -i 's/reg = <0 0x40000000 0 0x20000000>/reg = <0 0x40000000 0 0x40000000>/g' target/linux/mediatek/files-5.15/arch/arm64/boot/dts/mediatek/mt7981.dtsi

# --- 6. 物理清理与 PPE 状态保险 ---
# 确保 &ppe 节点不会被之前的 sed 命令误删，并保持 okay 状态
sed -i 's/status = "disabled";/status = "okay";/g' target/linux/mediatek/files-5.15/arch/arm64/boot/dts/mediatek/mt7981-sl-3000-emmc.dts

# --- 7. 刷新配置依赖 ---
# 这一步至关重要，它会让刚才 echo 进去的配置真正生效
make defconfig

echo "diy-part2.sh 物理修复执行完毕！"
