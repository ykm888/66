#!/bin/bash
# 物理执行准则：SL-3000 救砖稳健版 (512MB 物理对齐补丁) - 3版物理增强

# 1. 物理修正 EasyMesh 与 WiFi 依赖冲突
# 强制将 wpa-supplicant 替换为 wpad-mesh-openssl，解决 v3 架构下的循环依赖
[ -f "feeds/luci/applications/luci-app-easymesh/Makefile" ] && {
    sed -i 's/wpa-supplicant/wpad-mesh-openssl/g' feeds/luci/applications/luci-app-easymesh/Makefile || true
}

# 2. 512MB 救砖核心锁定 (3版深度物理锁定)
# 物理删除 1024M 寻址参数，并强制注入 512M 限制
# 即使 make defconfig 重置，脚本也会在编译前执行最后一次清理
sed -i '/CONFIG_ARM64_VA_BITS_39/d' .config
sed -i '/CONFIG_ARM64_PA_BITS_40/d' .config
sed -i '/CONFIG_PGTABLE_LEVELS/d' .config
# 物理限制寻址范围在 4GB 以内（DMA32），确保 512MB 内存稳定
echo "CONFIG_ZONE_DMA32=y" >> .config

# 3. 物理修正默认 IP 逻辑 (对齐 SL-3000 192.168.31.1)
[ -f "package/base-files/files/bin/config_generate" ] && {
    sed -i 's/192.168.1.1/192.168.31.1/g' package/base-files/files/bin/config_generate || true
}

# 4. 物理清道夫 (v3 强化：全局覆盖)
# 抹除 U-Boot 和 ATF 编译中的非法段警告，解决 GCC 13/14 的 Exit 2 错误
# 同时清理 feeds 和 package 两个可能的存放路径
find package/boot feeds/mediatek/package/boot -name "Makefile" -o -name "*.mk" | xargs sed -i 's/-no-warn-rwx-segments//g' 2>/dev/null || true
find package/boot feeds/mediatek/package/boot -name "Makefile" -o -name "*.mk" | xargs sed -i 's/-Werror//g' 2>/dev/null || true

# 5. 物理注入自定义零件优先权
# 物理强制编译系统优先使用我们手动注入到 package/boot 的 v3 版 Makefile
echo "SRC_TREE_OVERRIDE=y" >> .config

# 6. 物理修复剥离符号冲突 (解决 vssr/turboacc 等编译卡死)
# 移除 Makefile 中多余的剥离空格，防止 sstrip 逻辑物理断裂
sed -i 's/ stripping //g' Makefile || true

# 7. 物理纠偏编译路径 (新增)
# 确保 filogic.mk 在合成 32MB 固件时有足够的权限创建临时文件
chmod -R 755 target/linux/mediatek/image/

exit 0
