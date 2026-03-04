#!/bin/bash

# 物理审计：严格执行“原文照抄”上一版验证成功的脚本，并修复已知缺陷
# 核心原则：100% 像素级延续，严禁画蛇添足，严禁偷工减料
# 修复项：
#   - 移除架构锁定（改用自定义 config）
#   - BL2 来源更正为 STAGING_DIR_IMAGE（由 ATF 包提供）
#   - FIP 合成加入 BL2（根据 MT7981 平台要求）
#   - BL31 文件名使用通配符增强兼容性
#   - 增强 U-Boot 源码重定向的可靠性
#   - 增加调试输出，显示修改后的 Makefile 内容

# 1. 物理清淤：粉碎旧缓存与冲突
rm -rf dl/u-boot-* 2>/dev/null || true
rm -rf build_dir/target-*/u-boot-* 2>/dev/null || true
rm -rf staging_dir/host/share/u-boot 2>/dev/null || true

# 2. 基础变量劫持
UBOOT_MK="package/boot/uboot-mediatek/Makefile"
if [ -f "$UBOOT_MK" ]; then
    echo "物理注入：重定向源码仓库..."
    # 备份原文件
    cp "$UBOOT_MK" "$UBOOT_MK.bak"
    # 强制使用 git 协议，并设置分支
    sed -i "s|PKG_SOURCE_URL:=.*|PKG_SOURCE_URL:=https://github.com/ykm888/66.git|g" "$UBOOT_MK"
    sed -i "s|PKG_SOURCE_VERSION:=.*|PKG_SOURCE_VERSION:=sl3000-uboot-base|g" "$UBOOT_MK"
    sed -i "s|PKG_MIRROR_HASH:=.*|PKG_MIRROR_HASH:=skip|g" "$UBOOT_MK"
    # 确保使用 git 协议
    if ! grep -q "PKG_SOURCE_PROTO:=git" "$UBOOT_MK"; then
        sed -i '/PKG_SOURCE_URL:=/a PKG_SOURCE_PROTO:=git' "$UBOOT_MK"
    fi
    sed -i "s/UBOOT_TARGETS :=.*/UBOOT_TARGETS := mt7981_sl_3000-emmc/g" "$UBOOT_MK"

    # 输出修改后的 Makefile 以验证
    echo "===== Modified U-Boot Makefile ====="
    cat "$UBOOT_MK"
    echo "===================================="

    # 3. 【手术刀操作】：切除旧逻辑
    START_LINE=$(grep -n "define Build/fip-image" "$UBOOT_MK" | cut -d: -f1)
    if [ ! -z "$START_LINE" ]; then
        sed -i "${START_LINE},\$d" "$UBOOT_MK"
    fi

    # 4. 【源头重构】：使用 printf 像素级重建 FIP 合成与隧道逻辑
    #    修正：BL2 从 STAGING_DIR_IMAGE 获取，FIP 包含 BL2，BL31 使用通配符
    echo "物理重构：注入修复后的 FIP 合成与 InstallDev 隧道..."
    printf "define Build/fip-image\n" >> "$UBOOT_MK"
    printf "\t# 查找 BL2 和 BL31 文件（由 ATF 包提供）\n" >> "$UBOOT_MK"
    printf "\tBL2_BIN=\$\$(wildcard \$(STAGING_DIR_IMAGE)/mt7981-*-bl2.bin) ; \\\\\n" >> "$UBOOT_MK"
    printf "\tBL31_BIN=\$\$(wildcard \$(STAGING_DIR_IMAGE)/mt7981-*-bl31.bin) ; \\\\\n" >> "$UBOOT_MK"
    printf "\tif [ -z \"\$\$BL2_BIN\" ] || [ -z \"\$\$BL31_BIN\" ]; then \\\\\n" >> "$UBOOT_MK"
    printf "\t\techo \"ERROR: BL2 or BL31 not found in \$(STAGING_DIR_IMAGE)\"; exit 1; \\\\\n" >> "$UBOOT_MK"
    printf "\tfi\n" >> "$UBOOT_MK"
    printf "\t\$(STAGING_DIR_HOST)/bin/fiptool create \\\\\n" >> "$UBOOT_MK"
    printf "\t\t--tb-fw \$\$BL2_BIN \\\\\n" >> "$UBOOT_MK"
    printf "\t\t--soc-fw \$\$BL31_BIN \\\\\n" >> "$UBOOT_MK"
    printf "\t\t--nt-fw \$(PKG_BUILD_DIR)/\$(BUILD_VARIANT)/u-boot.bin \\\\\n" >> "$UBOOT_MK"
    printf "\t\t\$(PKG_BUILD_DIR)/\$(BUILD_VARIANT)/u-boot.fip\n" >> "$UBOOT_MK"
    printf "endef\n\n" >> "$UBOOT_MK"

    printf "define Build/Configure\n" >> "$UBOOT_MK"
    printf "\t\$(call Build/Configure/U-Boot)\n" >> "$UBOOT_MK"
    printf "\tsed -i 's/^CONFIG_TOOLS_LIBCRYPTO=y$$/# CONFIG_TOOLS_LIBCRYPTO is not set/' \$(PKG_BUILD_DIR)/.config\n" >> "$UBOOT_MK"
    printf "endef\n\n" >> "$UBOOT_MK"

    printf "define Build/Compile\n" >> "$UBOOT_MK"
    printf "\t\$(call Build/Compile/U-Boot)\n" >> "$UBOOT_MK"
    printf "ifeq (\$(UBOOT_IMAGE),u-boot.fip)\n" >> "$UBOOT_MK"
    printf "\t\$(call Build/fip-image)\n" >> "$UBOOT_MK"
    printf "endif\n" >> "$UBOOT_MK"
    printf "endef\n\n" >> "$UBOOT_MK"

    printf "define Build/InstallDev\n" >> "$UBOOT_MK"
    printf "\t\$(INSTALL_DIR) \$(STAGING_DIR_HOST)/share/u-boot\n" >> "$UBOOT_MK"
    printf "\t# BL2 从 STAGING_DIR_IMAGE 复制（由 ATF 包生成）\n" >> "$UBOOT_MK"
    printf "\t\$(CP) \$(STAGING_DIR_IMAGE)/mt7981-emmc-ddr3-bl2.bin \$(STAGING_DIR_HOST)/share/u-boot/mt7981-emmc-ddr3-bl2.bin\n" >> "$UBOOT_MK"
    printf "\t\$(CP) \$(PKG_BUILD_DIR)/\$(BUILD_VARIANT)/u-boot.fip \$(STAGING_DIR_HOST)/share/u-boot/mt7981-emmc-ddr3-fip.bin\n" >> "$UBOOT_MK"
    printf "endef\n\n" >> "$UBOOT_MK"

    printf "\$(eval \$(call BuildPackage/U-Boot))\n" >> "$UBOOT_MK"
fi

# 5. 补充必要配置选项（不覆盖用户已有配置）
echo "物理注入：补充必要配置选项..."
[ -f .config ] || touch .config
if ! grep -q "CONFIG_TARGET_mediatek_filogic_DEVICE_sl_3000-emmc=y" .config; then
    echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl_3000-emmc=y" >> .config
fi
if ! grep -q "CONFIG_NR_DRAM_BANKS=1" .config; then
    echo "CONFIG_NR_DRAM_BANKS=1" >> .config
fi
if ! grep -q "CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_sl_3000-emmc=y" .config; then
    echo "CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_sl_3000-emmc=y" >> .config
fi

echo "补丁脚本执行完毕，缺陷已修复。"
