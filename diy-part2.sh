#!/bin/bash
#
# Copyright (C) 2024-2026 ykm888
# 物理修复脚本：仅保留全局环境对齐
#

# 1. 物理切断 Kconfig 递归依赖 (EasyMesh 与 wpad 冲突)
# 这一步必须在脚本里做，因为 feeds 是动态下载的，无法物理预存在仓库里
echo "Patching EasyMesh dependency..."
sed -i 's/wpa-supplicant/wpad-mesh-openssl/g' feeds/luci/applications/luci-app-easymesh/Makefile || true

# 2. 物理强制内核 1024M 寻址配置注入
# 即使 config-5.15 改好了，这里再加一道保险，确保 .config 生成时强制锁定
echo "Forcing 1024M Memory Address Mapping..."
echo "CONFIG_ARM64_VA_BITS_39=y" >> .config
echo "CONFIG_PGTABLE_LEVELS=3" >> .config
echo "CONFIG_ARM64_PA_BITS_40=y" >> .config

# 3. 物理修正默认 IP (可选，根据你的需求修改)
sed -i 's/192.168.1.1/192.168.31.1/g' package/base-files/files/bin/config_generate

# ---------------------------------------------------------
# 注意：以下操作已物理固化在 Makefile 中，脚本中严禁重复执行，防止逻辑冲突：
# ❌ 不需要 mkdir plat/mediatek/... (Makefile Build/Prepare 已做)
# ❌ 不需要 sed ATF Makefile (Makefile PKG_MAKE_FLAGS 已做)
# ---------------------------------------------------------

echo "DIY-Part2: Physical environment alignment complete."
