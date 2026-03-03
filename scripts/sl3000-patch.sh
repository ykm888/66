#!/bin/bash

# 物理审计：严格执行“原文照抄”上一版验证成功的脚本
# 核心原则：100% 像素级延续，严禁画蛇添足，严禁偷工减料

# 1. 物理架构锁定：解决 ld-musl-x86_64 报错，强制锁定架构源头
printf "CONFIG_TARGET_mediatek=y\n" > .config
printf "CONFIG_TARGET_mediatek_filogic=y\n" >> .config

# 2. 物理清淤：粉碎旧缓存与冲突
rm -rf dl/u-boot-* 2>/dev/null || true
rm -rf build_dir/target-*/u-boot-* 2>/dev/null || true
rm -rf staging_dir/host/share/u-boot 2>/dev/null || true

# 3. 基础变量劫持
UBOOT_MK="package/boot/uboot-mediatek/Makefile"
if [ -f "$UBOOT_MK" ]; then
    echo "物理注入：重定向源码仓库..."
    sed -i "s|PKG_SOURCE_URL:=.*|PKG_SOURCE_URL:=https://github.com/ykm888/66.git|g" "$UBOOT_MK"
    sed -i "s|PKG_SOURCE_VERSION:=.*|PKG_SOURCE_VERSION:=sl3000-uboot-base|g" "$UBOOT_MK"
    sed -i "s|PKG_MIRROR_HASH:=.*|PKG_MIRROR_HASH:=skip|g" "$UBOOT_MK"
    sed -i "s/UBOOT_TARGETS :=.*/UBOOT_TARGETS := mt7981_sl_3000-emmc/g" "$UBOOT_MK"

    # 4. 【手术刀操作】：切除旧逻辑
    # 物理删除从 Build/fip-image 开始到文件末尾的所有内容，防止语法残留
    START_LINE=$(grep -n "define Build/fip-image" "$UBOOT_MK" | cut -d: -f1)
    if [ ! -z "$START_LINE" ]; then
        sed -i "${START_LINE},\$d" "$UBOOT_MK"
    fi

    # 5. 【源头重构】：使用 printf 像素级重建 FIP 合成与隧道逻辑
    # 注意：\t 代表物理 Tab 键，这是 Makefile 的生命线
    echo "物理重构：注入 FIP 合成与 InstallDev 隧道..."
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

# 6. 物理注入 .config
echo "物理锁定：注入 1024M 选型..."
[ -f .config ] || touch .config
sed -i '/CONFIG_TARGET_mediatek_filogic_DEVICE_sl_3000-emmc/d' .config
printf "CONFIG_TARGET_mediatek_filogic_DEVICE_sl_3000-emmc=y\n" >> .config
printf "CONFIG_NR_DRAM_BANKS=1\n" >> .config
printf "CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_sl_3000-emmc=y\n" >> .config

# 7. GPT 格式强制修正
FILOGIC_MK="target/linux/mediatek/image/filogic.mk"
if [ -f "$FILOGIC_MK" ]; then
    echo "物理检查：强制修正 GPT 分区表..."
    sed -i 's/preloader:64k:256k/256k@64k:preloader/g' "$FILOGIC_MK"
    sed -i 's/bl31:256k:512k/512k@256k:bl31/g' "$FILOGIC_MK"
    sed -i 's/u-boot:512k:2048k/2048k@512k:u-boot/g' "$FILOGIC_MK"
fi
