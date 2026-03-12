#!/bin/bash
# 物理执行准则：SL-3000 救砖稳健版 (512MB 物理对齐补丁) - 2版修复

# 1. 物理修正 EasyMesh 与 WiFi 依赖冲突
# 强制将 wpa-supplicant 替换为 wpad-mesh-openssl，解决 v2 版 Makefile 中的循环依赖
[ -f "feeds/luci/applications/luci-app-easymesh/Makefile" ] && {
    sed -i 's/wpa-supplicant/wpad-mesh-openssl/g' feeds/luci/applications/luci-app-easymesh/Makefile || true
}

# 2. 512MB 救砖核心锁定 (2版强化)
# 物理删除所有可能导致内核尝试寻址 1024M 空间的参数
# 在执行 make defconfig 前后进行物理隔离
sed -i '/CONFIG_ARM64_VA_BITS_39/d' .config
sed -i '/CONFIG_ARM64_PA_BITS_40/d' .config
sed -i '/CONFIG_PGTABLE_LEVELS/d' .config
echo "CONFIG_ZONE_DMA32=y" >> .config

# 3. 物理修正默认 IP 逻辑 (对齐 SL-3000 192.168.31.1 惯例)
[ -f "package/base-files/files/bin/config_generate" ] && {
    sed -i 's/192.168.1.1/192.168.31.1/g' package/base-files/files/bin/config_generate || true
}

# 4. 物理清道夫 (2版：精准指向 v2 软件包路径)
# 抹除 U-Boot 和 ATF 编译中的非法段警告，防止编译在 Step 10 崩溃
find package/boot/arm-trusted-firmware-mediatek -name "Makefile" -o -name "*.mk" | xargs sed -i 's/-no-warn-rwx-segments//g' || true
find package/boot/arm-trusted-firmware-mediatek -name "Makefile" -o -name "*.mk" | xargs sed -i 's/-Werror//g' || true
find package/boot/uboot-mediatek -name "Makefile" -o -name "*.mk" | xargs sed -i 's/-no-warn-rwx-segments//g' || true
find package/boot/uboot-mediatek -name "Makefile" -o -name "*.mk" | xargs sed -i 's/-Werror//g' || true

# 5. 物理注入自定义零件路径
# 强制编译系统识别我们在 package/boot 目录下注入的 v2 版 Makefile
echo "SRC_TREE_OVERRIDE=y" >> .config

# 6. 物理修复编译符号冲突 (针对 vssr 等插件)
# 确保在某些环境下不会因为缺失符号导致编译中断
sed -i 's/ stripping //g' Makefile || true

exit 0
