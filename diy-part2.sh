#!/bin/bash

# 1. 物理目录准备：确保 DTS 和固件定义路径存在
mkdir -p target/linux/mediatek/dts/
mkdir -p target/linux/mediatek/image/
mkdir -p target/linux/mediatek/files-5.15/arch/arm64/boot/dts/mediatek/

# 2. 注入 SL-3000 (eMMC) 专用设备树
# 这里的 DTS 应该包含你 128G eMMC 的分区定义和 1024M 内存地址映射
[ -e $GITHUB_WORKSPACE/custom-config/mt7981-sl-3000-emmc.dts ] && \
cp -f $GITHUB_WORKSPACE/custom-config/mt7981-sl-3000-emmc.dts target/linux/mediatek/dts/ && \
cp -f $GITHUB_WORKSPACE/custom-config/mt7981-sl-3000-emmc.dts target/linux/mediatek/files-5.15/arch/arm64/boot/dts/mediatek/

# 3. 注入固件生成规则 (filogic.mk)
# 确保该文件内有定义：IMAGE/sysupgrade.bin := append-metadata | check-size 120000k
[ -e $GITHUB_WORKSPACE/custom-config/filogic.mk ] && \
cp -f $GITHUB_WORKSPACE/custom-config/filogic.mk target/linux/mediatek/image/

# 4. --- ATF (TF-A) 物理拦截与手术 ---
# 既然我们用了精修的 atf-sl3000-base 源码，必须删除自带补丁，防止路径和内存定义被改回 256M
echo "Physical Fix: Removing conflicting ATF patches..."
rm -rf package/boot/arm-trusted-firmware-mediatek/patches/

# 5. --- 解决 Kconfig 循环依赖报错 ---
# 物理切断 wpa-supplicant 导致的逻辑环路，强制使用 wpad-mesh-openssl
echo "Physical Fix: Solving Kconfig recursive dependency..."
sed -i 's/CONFIG_PACKAGE_wpa-supplicant-mesh-openssl=y/# CONFIG_PACKAGE_wpa-supplicant-mesh-openssl is not set/g' .config
sed -i 's/CONFIG_PACKAGE_wpa-supplicant=y/# CONFIG_PACKAGE_wpa-supplicant is not set/g' .config
echo "CONFIG_PACKAGE_wpad-mesh-openssl=y" >> .config

# 6. --- 修正编译参数：强制开启 1024M 寻址 ---
# 确保内核配置能看到 1GB 空间
sed -i 's/CONFIG_ARM64_VA_BITS_39=y/CONFIG_ARM64_VA_BITS_39=y/g' .config || echo "CONFIG_ARM64_VA_BITS_39=y" >> .config
echo "CONFIG_ZONE_DMA32=y" >> .config

# 7. 修正 U-Boot 引导偏移 (针对 eMMC)
# 如果你的 eMMC 布局需要特定的偏移，可以在此处通过 sed 修改 uboot 源码
