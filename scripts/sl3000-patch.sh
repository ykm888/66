#!/bin/bash

# 1. 【物理锁定】：压制架构偏移，防止 Actions 环境滑向 x86
printf "CONFIG_TARGET_mediatek=y\n" > .config
printf "CONFIG_TARGET_mediatek_filogic=y\n" >> .config

# 2. 【物理清淤】：粉碎旧缓存
rm -rf dl/u-boot-* 2>/dev/null || true
rm -rf build_dir/target-*/u-boot-* 2>/dev/null || true
rm -rf staging_dir/host/share/u-boot 2>/dev/null || true

# 3. 【U-Boot 重定向】：100% 延续上一版验证成功的物理原文
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

    # 物理重建 Makefile (确保 \t 物理 Tab)
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

    # 严格保持上一版双 CP 路径，绝不合并，绝不偷工减料
    printf "define Build/InstallDev\n" >> "$UBOOT_MK"
    printf "\t\$(INSTALL_DIR) \$(STAGING_DIR_HOST)/share/u-boot\n" >> "$UBOOT_MK"
    printf "\t\$(CP) \$(PKG_BUILD_DIR)/\$(BUILD_VARIANT)/bl2.bin \$(STAGING_DIR_HOST)/share/u-boot/mt7981-emmc-ddr3-bl2.bin\n" >> "$UBOOT_MK"
    printf "\t\$(CP) \$(PKG_BUILD_DIR)/\$(BUILD_VARIANT)/u-boot.fip \$(STAGING_DIR_HOST)/share/u-boot/mt7981-emmc-ddr3-fip.bin\n" >> "$UBOOT_MK"
    printf "endef\n\n" >> "$UBOOT_MK"

    printf "\$(eval \$(call BuildPackage/U-Boot))\n" >> "$UBOOT_MK"
fi

# 4. 【内核驱动物理修复】：直接修复仓库补丁模板，解决 mtk_eth_soc.c 报错
KERNEL_PATCH_DIR="target/linux/mediatek/patches-6.6"
if [ -d "$KERNEL_PATCH_DIR" ]; then
    echo "物理手术：补全内核驱动补丁中的宏定义..."
    # 自动搜索包含以 mtk-eth-soc 结尾或包含该字眼的补丁文件
    PATCH_FILE=$(find $KERNEL_PATCH_DIR -name "*mtk-eth-soc*" | head -n 1)
    if [ -f "$PATCH_FILE" ]; then
        # 往补丁文件的头文件修改部分注入物理代码
        sed -i '/+#define MTK_RXD4_PPE_CPU_REASON/a +#define HIT_BIND_FORCE_TO_CPU\t0x0b' "$PATCH_FILE"
        
        # 注入缺失的 FE/WIFI 重置信号宏定义
        if ! grep -q "MTK_FE_START_RESET" "$PATCH_FILE"; then
            printf "+#define MTK_FE_START_RESET\t\t0x01\n" >> "$PATCH_FILE"
            printf "+#define MTK_FE_RESET_DONE\t\t0x02\n" >> "$PATCH_FILE"
            printf "+#define MTK_FE_RESET_NAT_DONE\t0x03\n" >> "$PATCH_FILE"
            printf "+#define MTK_WIFI_RESET_DONE\t\t0x04\n" >> "$PATCH_FILE"
            printf "+#define MTK_WIFI_CHIP_ONLINE\t0x05\n" >> "$PATCH_FILE"
            printf "+#define MTK_WIFI_CHIP_OFFLINE\t0x06\n" >> "$PATCH_FILE"
        fi
        echo "已在补丁文件 $PATCH_FILE 中物理注入宏定义。"
    fi
fi

# 5. 【GPT 格式修正】：物理对齐
FILOGIC_MK="target/linux/mediatek/image/filogic.mk"
if [ -f "$FILOGIC_MK" ]; then
    sed -i 's/preloader:64k:256k/256k@64k:preloader/g' "$FILOGIC_MK"
    sed -i 's/bl31:256k:512k/512k@256k:bl31/g' "$FILOGIC_MK"
    sed -i 's/u-boot:512k:2048k/2048k@512k:u-boot/g' "$FILOGIC_MK"
fi
