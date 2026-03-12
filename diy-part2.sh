#!/bin/bash
# 物理执行准则：SL-3000 救砖稳健版 (512MB 物理对齐补丁)

# 1. 物理修正 EasyMesh 与 WiFi 依赖冲突
# 强制将 wpa-supplicant 替换为 wpad-mesh-openssl，解决编译循环依赖
[ -f "feeds/luci/applications/luci-app-easymesh/Makefile" ] && {
    sed -i 's/wpa-supplicant/wpad-mesh-openssl/g' feeds/luci/applications/luci-app-easymesh/Makefile || true
}

# 2. 1024M 寻址参数物理屏蔽 (救砖关键)
# 注意：在救砖成功前，严禁开启 VA_BITS_39。
# 我们在这里显式删除可能从 .config 继承的旧参数，确保 512MB 闭环。
sed -i '/CONFIG_ARM64_VA_BITS_39/d' .config
sed -i '/CONFIG_ARM64_PA_BITS_40/d' .config
sed -i '/CONFIG_PGTABLE_LEVELS/d' .config

# 3. 物理修正默认 IP 逻辑 (对齐 SL-3000 192.168.31.1 惯例)
# 这样你刷完机后，可以直接访问 192.168.31.1 进入后台
[ -f "package/base-files/files/bin/config_generate" ] && {
    sed -i 's/192.168.1.1/192.168.31.1/g' package/base-files/files/bin/config_generate || true
}

# 4. 物理清道夫动作 (针对 GCC 13+ 的兼容性修复)
# 抹除 U-Boot 和 ATF 编译中的非法段警告参数，防止 Exit 2 错误
find package/boot/arm-trusted-firmware-mediatek -name "Makefile" -o -name "*.mk" | xargs sed -i 's/-no-warn-rwx-segments//g' || true
find package/boot/arm-trusted-firmware-mediatek -name "Makefile" -o -name "*.mk" | xargs sed -i 's/-Werror//g' || true
find package/boot/uboot-mediatek -name "Makefile" -o -name "*.mk" | xargs sed -i 's/-no-warn-rwx-segments//g' || true

# 5. 物理注入自定义零件路径 (可选，增加安全性)
# 确保编译系统优先扫描 package/boot 目录下的自定义零件
echo "SRC_TREE_OVERRIDE=y" >> .config

exit 0
