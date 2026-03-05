#!/bin/bash

# 1. 【物理锁定】：压制架构偏移，锁定 Mediatek 目标
printf "CONFIG_TARGET_mediatek=y\n" > .config
printf "CONFIG_TARGET_mediatek_filogic=y\n" >> .config

# 2. 【原文照抄】：物理清淤
rm -rf dl/u-boot-* 2>/dev/null || true
rm -rf build_dir/target-*/u-boot-* 2>/dev/null || true
rm -rf staging_dir/host/share/u-boot 2>/dev/null || true

# 3. 【原文照抄】：U-Boot 重定向与 Makefile 像素级重构（延续上一版双 CP 路径）
UBOOT_MK="package/boot/uboot-mediatek/Makefile"
if [ -f "$UBOOT_MK" ]; then
    echo "物理注入：重定向 U-Boot 源码仓库..."
    sed -i "s|PKG_SOURCE_URL:=.*|PKG_SOURCE_URL:=https://github.com/ykm888/66.git|g" "$UBOOT_MK"
    sed -i "s|PKG_SOURCE_VERSION:=.*|PKG_SOURCE_VERSION:=sl3000-uboot-base|g" "$UBOOT_MK"
    sed -i "s|PKG_MIRROR_HASH:=.*|PKG_MIRROR_HASH:=skip|g" "$UBOOT_MK"
    sed -i "s/UBOOT_TARGETS :=.*/UBOOT_TARGETS := mt7981_sl_3000-emmc/g" "$UBOOT_MK"

    START_LINE=$(grep -n "define Build/fip-image" "$UBOOT_MK" | cut -d: -f1)
    if [ ! -z "$START_LINE" ]; then
        sed -i "${START_LINE},\$d" "$UBOOT_MK"
    fi

    printf "define Build/fip-image\n" >> "$UBOOT_MK"
    printf "\t\$(STAGING_DIR_HOST)/bin/fiptool create \\\\\n" >> "$UBOOT_MK"
    printf "\t\t--soc-fw \$(STAGING_DIR_IMAGE)/mt7981-emmc-ddr3-bl31.bin \\\\\n" >> "$UBOOT_MK"
    printf "\t\t--nt-fw \$(PKG_BUILD_DIR)/\$(BUILD_VARIANT)/u-boot.bin \\\\\n" >> "$UBOOT_MK"
    printf "\t\t\$(PKG_BUILD_DIR)/\$(BUILD_VARIANT)/u-boot.fip\n" >> "$UBOOT_MK"
    printf "endef\n\n" >> "$UBOOT_MK"

    printf "define Build/Configure\n" >> "$UBOOT_MK"
    printf "\t\$(call Build/Configure/U-Boot)\n" >> "$UBOOT_MK"
    printf "\tsed -i 's/CONFIG_TOOLS_LIBCRYPTO=y/# CONFIG_TOOLS_LIBCRYPTO is not set/' \$(PKG_BUILD_DIR)/.config\n" >> "$UBOOT_MK"
    printf "endef\n\n" >> "$UBOOT_MK"

    printf "define Build/Compile\n" >> "$UBOOT_MK"
    printf "\t\$(call Build/Compile/U-Boot)\n" >> "$UBOOT_MK"
    printf "ifeq (\$(UBOOT_IMAGE),u-boot.fip)\n" >> "$UBOOT_MK"
    printf "\t\$(call Build/fip-image)\n" >> "$UBOOT_MK"
    printf "endif\n" >> "$UBOOT_MK"
    printf "endef\n\n" >> "$UBOOT_MK"

    printf "define Build/InstallDev\n" >> "$UBOOT_MK"
    printf "\t\$(INSTALL_DIR) \$(STAGING_DIR_HOST)/share/u-boot\n" >> "$UBOOT_MK"
    printf "\t\$(CP) \$(PKG_BUILD_DIR)/\$(BUILD_VARIANT)/bl2.bin \$(STAGING_DIR_HOST)/share/u-boot/mt7981-emmc-ddr3-bl2.bin\n" >> "$UBOOT_MK"
    printf "\t\$(CP) \$(PKG_BUILD_DIR)/\$(BUILD_VARIANT)/u-boot.fip \$(STAGING_DIR_HOST)/share/u-boot/mt7981-emmc-ddr3-fip.bin\n" >> "$UBOOT_MK"
    printf "endef\n\n" >> "$UBOOT_MK"

    printf "\$(eval \$(call BuildPackage/U-Boot))\n" >> "$UBOOT_MK"
fi

# 4. 【补丁手术】：针对 999-2714 补丁文件进行物理闭环修复
PATCH_FILE="target/linux/mediatek/patches-6.6/999-2714-net-fix-eee-struct-for-mtk-eth-soc-and-net-dsa-due-to-eee-backport.patch"

if [ -f "$PATCH_FILE" ]; then
    echo "物理手术：为补丁文件 999-2714 注入缺失的头文件逻辑..."
    
    # 物理追加：通过构造伪 diff 块，强制在补丁应用时修改 mtk_eth_soc.h
    # 注入 HIT_BIND_FORCE_TO_CPU 和 Reset 系列宏定义
    printf "\n--- a/drivers/net/ethernet/mediatek/mtk_eth_soc.h\n+++ b/drivers/net/ethernet/mediatek/mtk_eth_soc.h\n@@ -10,6 +10,14 @@\n #define MTK_ETH_SOC_H\n \n+#define HIT_BIND_FORCE_TO_CPU\t0x0b\n+#define MTK_FE_START_RESET\t\t0x01\n+#define MTK_FE_RESET_DONE\t\t0x02\n+#define MTK_FE_RESET_NAT_DONE\t0x03\n+#define MTK_WIFI_RESET_DONE\t\t0x04\n+#define MTK_WIFI_CHIP_ONLINE\t0x05\n+#define MTK_WIFI_CHIP_OFFLINE\t0x06\n+\n #include <linux/ethtool.h>\n" >> "$PATCH_FILE"
    
    echo "物理补完：补丁文件现在已具备完整的头文件声明。"
fi

# 5. 【原文照抄】：GPT 强制修正
FILOGIC_MK="target/linux/mediatek/image/filogic.mk"
if [ -f "$FILOGIC_MK" ]; then
    sed -i 's/preloader:64k:256k/256k@64k:preloader/g' "$FILOGIC_MK"
    sed -i 's/bl31:256k:512k/512k@256k:bl31/g' "$FILOGIC_MK"
    sed -i 's/u-boot:512k:2048k/2048k@512k:u-boot/g' "$FILOGIC_MK"
fi
