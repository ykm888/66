#!/bin/bash
#
# Copyright (C) 2024-2026 ykm888
# 物理修复 6 版：全路径纠偏、影子包清场、对齐 IP 与主机名
#

# --- 1. 物理对齐：默认 IP 与主机名修正 ---
# 锁定 IP 为 192.168.10.1 (对齐 SL-3000 物理习惯)
# 锁定主机名为 SL-3000
echo "Physical Surgery: Configuring Default IP and Hostname..."
sed -i 's/192.168.1.1/192.168.10.1/g' package/base-files/files/bin/config_generate
sed -i 's/ImmortalWrt/SL-3000/g' package/base-files/files/bin/config_generate

# --- 2. 物理清场：彻底切断 feeds 中的影子干扰 (防 Error 1) ---
# 必须物理删除 feeds 目录下的同名 ATF/U-Boot，强制系统使用 package/boot 里的修复版
echo "Physical Surgery: Purging shadow packages from feeds..."
rm -rf feeds/mediatek/arm-trusted-firmware-mediatek || true
rm -rf feeds/mediatek/uboot-mediatek || true

# --- 3. 物理脱钩：修正 EasyMesh 递归依赖 (防 Error 2) ---
# 防止 wpad-mesh-openssl 与 wpad-basic 产生物理编译冲突
if [ -d "feeds/luci/applications/luci-app-easymesh" ]; then
    echo "Physical Surgery: Unbinding EasyMesh from wpad..."
    find feeds/luci/applications/luci-app-easymesh -name "Makefile" | xargs sed -i 's/+wpad-mesh-openssl//g' || true
    find feeds/luci/applications/luci-app-easymesh -name "Makefile" | xargs sed -i 's/+wpa-supplicant-mesh-openssl//g' || true
fi

# --- 4. 物理清道夫：暴力抹除 Werror 警告 (对齐 GCC 13 兼容逻辑) ---
# 确保所有 package 目录下的零件工厂都不会因为“警告变错误”而中断
echo "Physical Surgery: Global stripping of -Werror and RWX warnings..."
find package/ -name "Makefile" 2>/dev/null | xargs sed -i 's/-Werror//g' || true
find package/ -name "Makefile" 2>/dev/null | xargs sed -i 's/-no-warn-rwx-segments//g' || true

# --- 5. 权限物理锁死 ---
# 确保注入的零件 (如 filogic.mk) 拥有执行权限
chmod -R 755 target/linux/mediatek/image/

# --- 6. 物理重置：强制刷新索引缓存 ---
# 这一步是消除 "dependency does not exist" 警告的物理终点
rm -rf tmp

exit 0
