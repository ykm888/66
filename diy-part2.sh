#!/bin/bash
# 物理执行准则：SL-3000 1024M 寻址与依赖物理对齐补丁

# 1. 物理修正 EasyMesh 冲突 (防止 wpa-supplicant 导致编译失败)
[ -f "feeds/luci/applications/luci-app-easymesh/Makefile" ] && {
    sed -i 's/wpa-supplicant/wpad-mesh-openssl/g' feeds/luci/applications/luci-app-easymesh/Makefile || true
}

# 2. 物理锁定 1024M 内核寻址空间 (关键：解决大内存启动死机)
echo "CONFIG_ARM64_VA_BITS_39=y" >> .config
echo "CONFIG_ARM64_PA_BITS_40=y" >> .config
echo "CONFIG_PGTABLE_LEVELS=3" >> .config

# 3. 物理修正默认 IP 逻辑 (对齐 SL-3000 惯例)
[ -f "package/base-files/files/bin/config_generate" ] && {
    sed -i 's/192.168.1.1/192.168.31.1/g' package/base-files/files/bin/config_generate || true
}

# 4. 物理对齐编译参数 (抹除 GCC 13+ 冲突参数)
# 针对 ATF 和 U-Boot 源码执行物理清道夫动作
find package/boot/arm-trusted-firmware-mediatek -name "Makefile" -o -name "*.mk" | xargs sed -i 's/-no-warn-rwx-segments//g' || true
find package/boot/arm-trusted-firmware-mediatek -name "Makefile" -o -name "*.mk" | xargs sed -i 's/-Werror//g' || true
find package/boot/uboot-mediatek -name "Makefile" -o -name "*.mk" | xargs sed -i 's/-no-warn-rwx-segments//g' || true

exit 0
