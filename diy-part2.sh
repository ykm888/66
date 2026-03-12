#!/bin/bash
# 物理切断 EasyMesh 造成的递归依赖链
if [ -d "feeds/luci/applications/luci-app-easymesh" ]; then
    find feeds/luci/applications/luci-app-easymesh -name "Makefile" | xargs sed -i 's/+wpad-mesh-openssl//g' || true
    find feeds/luci/applications/luci-app-easymesh -name "Makefile" | xargs sed -i 's/+wpa-supplicant-mesh-openssl//g' || true
fi

# 512MB 物理锁定
sed -i '/CONFIG_ARM64_VA_BITS_39/d' .config
sed -i '/CONFIG_ARM64_PA_BITS_40/d' .config
sed -i '/CONFIG_PGTABLE_LEVELS/d' .config
echo "CONFIG_ZONE_DMA32=y" >> .config

# 修正 IP
[ -f "package/base-files/files/bin/config_generate" ] && {
    sed -i 's/192.168.1.1/192.168.31.1/g' package/base-files/files/bin/config_generate || true
}

# 屏蔽 Werror 警告导致的中断
find package/boot feeds/mediatek -name "Makefile" 2>/dev/null | xargs sed -i 's/-Werror//g' || true
find package/boot feeds/mediatek -name "Makefile" 2>/dev/null | xargs sed -i 's/-no-warn-rwx-segments//g' || true

chmod -R 755 target/linux/mediatek/image/
exit 0
