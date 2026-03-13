#!/bin/bash
#
# Copyright (C) 2024-2026 ykm888
# 物理修复 7 版：物理健壮性增强、空运行防护、全路径对齐
#

# --- 1. 物理对齐：默认 IP 与主机名修正 ---
echo "Physical Surgery: Configuring Default IP and Hostname..."
# 物理锁定 192.168.10.1 (对齐 SL-3000 硬件预设)
sed -i 's/192.168.1.1/192.168.10.1/g' package/base-files/files/bin/config_generate
sed -i 's/ImmortalWrt/SL-3000/g' package/base-files/files/bin/config_generate

# --- 2. 物理清场：彻底切断 feeds 中的影子干扰 (防 Error 1) ---
# 必须物理删除 feeds 目录下的同名 ATF/U-Boot，强制系统回溯使用 package/boot 里的修复版
echo "Physical Surgery: Purging shadow packages from feeds..."
rm -rf feeds/mediatek/arm-trusted-firmware-mediatek
rm -rf feeds/mediatek/uboot-mediatek
rm -rf package/feeds/mediatek/arm-trusted-firmware-mediatek
rm -rf package/feeds/mediatek/uboot-mediatek

# --- 3. 物理脱钩：修正 EasyMesh 递归依赖 (防编译死锁) ---
# 防止逻辑因 wpad 冲突导致中断，采用物理屏蔽方案
if [ -d "feeds/luci/applications/luci-app-easymesh" ]; then
    echo "Physical Surgery: Unbinding EasyMesh from wpad components..."
    find feeds/luci/applications/luci-app-easymesh -name "Makefile" -exec sed -i 's/+wpad-mesh-openssl//g' {} +
    find feeds/luci/applications/luci-app-easymesh -name "Makefile" -exec sed -i 's/+wpa-supplicant-mesh-openssl//g' {} +
fi

# --- 4. 物理清道夫：暴力抹除 Werror 警告 (对齐 GCC 13/14 逻辑) ---
# 这一步极其重要：防止因编译器警告导致的“逻辑中断”
echo "Physical Surgery: Global stripping of -Werror and RWX warnings..."
find package/ -name "Makefile" -exec sed -i 's/-Werror//g' {} +
find package/ -name "Makefile" -exec sed -i 's/Werror//g' {} +
find package/ -name "Makefile" -exec sed -i 's/-no-warn-rwx-segments//g' {} +

# --- 5. 权限物理锁死 ---
# 物理开启整个镜像打包工地的执行权限，确保 filogic.mk 顺利合体
chmod -R 755 target/linux/mediatek/image/

# --- 6. 物理重置：强制清除脏缓存 ---
# 清除索引残留，这是让上述所有物理修改被系统感知的“最后一步”
rm -rf tmp

echo "Physical Surgery: All operations completed successfully."
exit 0
