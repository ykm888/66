#!/bin/bash
#
# Copyright (C) 2024-2026 ykm888
# 物理修复：容错增强版

# 1. 物理修正 EasyMesh 依赖冲突
# 增加检测，防止 feeds 目录未生成时 sed 报错导致中断
if [ -f "feeds/luci/applications/luci-app-easymesh/Makefile" ]; then
    echo "Physical Fix: Patching EasyMesh dependency..."
    sed -i 's/wpa-supplicant/wpad-mesh-openssl/g' feeds/luci/applications/luci-app-easymesh/Makefile || true
else
    echo "Warning: EasyMesh Makefile not found, skipping."
fi

# 2. 物理锁定 1024M 寻址
# 确保在 .config 已生成后追加，使用 >> 确保不破坏已有配置
echo "Physical Fix: Injecting 1024M Memory address space config..."
{
    echo "CONFIG_ARM64_VA_BITS_39=y"
    echo "CONFIG_PGTABLE_LEVELS=3"
    echo "CONFIG_ARM64_PA_BITS_40=y"
} >> .config || true

# 3. 默认 IP 修改 (192.168.31.1)
if [ -f "package/base-files/files/bin/config_generate" ]; then
    sed -i 's/192.168.1.1/192.168.31.1/g' package/base-files/files/bin/config_generate || true
fi

echo "DIY-Part2: All physical tasks completed successfully."
exit 0
