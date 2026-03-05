#!/bin/bash

# 1. 【物理锁定】：锁定架构与设备
printf "CONFIG_TARGET_mediatek=y\n" > .config
printf "CONFIG_TARGET_mediatek_filogic=y\n" >> .config
printf "CONFIG_TARGET_mediatek_filogic_DEVICE_sl_3000-emmc=y\n" >> .config
sed -i 's/CONFIG_TARGET_x86=y/# CONFIG_TARGET_x86 is not set/' .config

# 2. 【物理清淤】：删除所有可能冲突的自定义补丁（确保 prepare 能过）
rm -f target/linux/mediatek/patches-6.6/999-sl3000-atomic-fix.patch
rm -f target/linux/mediatek/patches-6.6/999-2714-net-fix-eee-struct-for-mtk-eth-soc-and-net-dsa-due-to-eee-backport.patch

# 3. 【原文照抄】：U-Boot 重定向逻辑
UBOOT_MK="package/boot/uboot-mediatek/Makefile"
if [ -f "$UBOOT_MK" ]; then
    sed -i "s|PKG_SOURCE_URL:=.*|PKG_SOURCE_URL:=https://github.com/ykm888/66.git|g" "$UBOOT_MK"
    sed -i "s|PKG_SOURCE_VERSION:=.*|PKG_SOURCE_VERSION:=sl3000-uboot-base|g" "$UBOOT_MK"
    sed -i "s|PKG_MIRROR_HASH:=.*|PKG_MIRROR_HASH:=skip|g" "$UBOOT_MK"
    sed -i "s/UBOOT_TARGETS :=.*/UBOOT_TARGETS := mt7981_sl_3000-emmc/g" "$UBOOT_MK"

    START_LINE=$(grep -n "define Build/fip-image" "$UBOOT_MK" | cut -d: -f1)
    [ ! -z "$START_LINE" ] && sed -i "${START_LINE},\$d" "$UBOOT_MK"

    printf "define Build/fip-image\n\t\$(STAGING_DIR_HOST)/bin/fiptool create \\\\\n\t\t--soc-fw \$(STAGING_DIR_IMAGE)/mt7981-emmc-ddr3-bl31.bin \\\\\n\t\t--nt-fw \$(PKG_BUILD_DIR)/\$(BUILD_VARIANT)/u-boot.bin \\\\\n\t\t\$(PKG_BUILD_DIR)/\$(BUILD_VARIANT)/u-boot.fip\nendef\n\n" >> "$UBOOT_MK"
    printf "define Build/Configure\n\t\$(call Build/Configure/U-Boot)\n\tsed -i 's/CONFIG_TOOLS_LIBCRYPTO=y/# CONFIG_TOOLS_LIBCRYPTO is not set/' \$(PKG_BUILD_DIR)/.config\nendef\n\n" >> "$UBOOT_MK"
    printf "define Build/Compile\n\t\$(call Build/Compile/U-Boot)\nifeq (\$(UBOOT_IMAGE),u-boot.fip)\n\t\$(call Build/fip-image)\nendif\nendef\n\n" >> "$UBOOT_MK"
    printf "define Build/InstallDev\n\t\$(INSTALL_DIR) \$(STAGING_DIR_HOST)/share/u-boot\n\t\$(CP) \$(PKG_BUILD_DIR)/\$(BUILD_VARIANT)/bl2.bin \$(STAGING_DIR_HOST)/share/u-boot/mt7981-emmc-ddr3-bl2.bin\n\t\$(CP) \$(PKG_BUILD_DIR)/\$(BUILD_VARIANT)/u-boot.fip \$(STAGING_DIR_HOST)/share/u-boot/mt7981-emmc-ddr3-fip.bin\nendef\n\n" >> "$UBOOT_MK"
    printf "\$(eval \$(call BuildPackage/U-Boot))\n" >> "$UBOOT_MK"
fi
