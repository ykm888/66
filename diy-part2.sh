#!/bin/bash
#
# Copyright (C) 2024-2026 ykm888
# 物理修正：仅保留 Makefile 无法触及的 Feeds 补丁
#

# 1. 物理切断 EasyMesh 与 wpad 的 Kconfig 递归依赖
# 这是因为 feeds 包是动态下载的，无法物理预存在仓库里
echo "Patching EasyMesh Feed dependency..."
sed -i 's/wpa-supplicant/wpad-mesh-openssl/g' feeds/luci/applications/luci-app-easymesh/Makefile || true

# 2. 物理锁定 5.15 内核 1024M 寻址
# 再次加固 .config，确保 VA_BITS_39 具有最高优先级
echo "Forcing 1024M Kernel Address Mapping..."
{
    echo "CONFIG_ARM64_VA_BITS_39=y"
    echo "CONFIG_PGTABLE_LEVELS=3"
    echo "CONFIG_ARM64_PA_BITS_40=y"
} >> .config

# 3. 修改默认 IP 为 31.1 (小米/SL-3000 常用段)
sed -i 's/192.168.1.1/192.168.31.1/g' package/base-files/files/bin/config_generate

echo "DIY-Part2: Physical alignment complete."
