#!/bin/bash
# 物理执行准则：SL-3000 救砖稳健版 (512MB 物理对齐) - 3版源头解耦补丁

# ----------------------------------------------------------------
# 1. 物理斩断循环依赖 (解决 PACKAGE_wpad-mesh-openssl 递归死锁)
# ----------------------------------------------------------------
# 原因是 easymesh 强制依赖了 wpad，而 wpad 又反向依赖了加密库。
# 我们物理抹除其 Makefile 中的强制依赖 (+wpad...)，让 .config 手动控制。
if [ -d "feeds/luci/applications/luci-app-easymesh" ]; then
    echo "Physical Surgery: Cutting EasyMesh recursive dependencies..."
    find feeds/luci/applications/luci-app-easymesh -name "Makefile" | xargs sed -i 's/+wpad-mesh-openssl//g' || true
    find feeds/luci/applications/luci-app-easymesh -name "Makefile" | xargs sed -i 's/+wpa-supplicant-mesh-openssl//g' || true
fi

# ----------------------------------------------------------------
# 2. 512MB 救砖核心锁定 (3版深度物理锁定)
# ----------------------------------------------------------------
# 物理删除所有 1024M/大内存寻址参数，防止内核在 512MB 设备上由于地址越界崩溃
sed -i '/CONFIG_ARM64_VA_BITS_39/d' .config
sed -i '/CONFIG_ARM64_PA_BITS_40/d' .config
sed -i '/CONFIG_PGTABLE_LEVELS/d' .config
# 强制开启 DMA32 寻址锁定，确保 WiFi 驱动在低地址空间运行
echo "CONFIG_ZONE_DMA32=y" >> .config

# ----------------------------------------------------------------
# 3. 物理修正默认 IP 逻辑 (对齐 SL-3000 192.168.31.1)
# ----------------------------------------------------------------
[ -f "package/base-files/files/bin/config_generate" ] && {
    sed -i 's/192.168.1.1/192.168.31.1/g' package/base-files/files/bin/config_generate || true
}

# ----------------------------------------------------------------
# 4. 物理清道夫 (v3 强化：抹除警告自毁开关)
# ----------------------------------------------------------------
# 解决 GCC 13/14 环境下因警告被视为错误（Werror）导致的编译中断
find package/boot feeds/mediatek/package/boot -name "Makefile" -o -name "*.mk" 2>/dev/null | xargs sed -i 's/-no-warn-rwx-segments//g' || true
find package/boot feeds/mediatek/package/boot -name "Makefile" -o -name "*.mk" 2>/dev/null | xargs sed -i 's/-Werror//g' || true

# ----------------------------------------------------------------
# 5. 物理修正零件优先权与编译环境
# ----------------------------------------------------------------
# 确保系统优先使用注入的 Makefile
echo "SRC_TREE_OVERRIDE=y" >> .config

# 移除 Makefile 中可能导致 vssr/turboacc 编译卡死的符号冲突
sed -i 's/ stripping //g' Makefile || true

# 赋予镜像目录物理权限，确保 filogic.mk 能顺利执行 truncate 合成 32MB 固件
chmod -R 755 target/linux/mediatek/image/ 2>/dev/null || true

echo "SL-3000 Physical DIY-Part2 Fix Applied Successfully."
exit 0
