#!/bin/bash
# =========================================================
# SL-3000 全链路自愈脚本 (禁止使用 EOF，采用 printf 物理注入)
# =========================================================

TARGET_DIR="$(pwd)/openwrt"
PKG_DIR="$TARGET_DIR/package/boot/arm-trusted-firmware-mediatek"

echo "--- [1/3] 物理审计：重写 Makefile (纠正变体与路径) ---"
mkdir -p "$PKG_DIR"
printf 'include $(TOPDIR)/rules.mk\nPKG_NAME:=arm-trusted-firmware-mediatek\nPKG_RELEASE:=1\nPKG_VERSION:=sl3000\nPKG_SOURCE_PROTO:=git\nPKG_SOURCE_URL:=https://github.com/ykm888/66.git\nPKG_SOURCE_VERSION:=sl3000-clean-source\ninclude $(INCLUDE_DIR)/trusted-firmware-a.mk\ninclude $(INCLUDE_DIR)/package.mk\ndefine Trusted-Firmware-A/Default\n  BUILD_TARGET:=mediatek\n  BUILD_SUBTARGET:=filogic\n  PLAT:=mt7981\n  TFA_IMAGE:=bl2.bin fip.bin\nendef\ndefine Trusted-Firmware-A/mt7981-nor-ddr4\n  NAME:=SL-3000-NOR\n  TFA_MAKE_FLAGS:=BOOT_DEVICE=nor DRAM_USE_DDR4=1\nendef\nTFA_TARGETS:=mt7981-nor-ddr4\ndefine Package/trusted-firmware-a-$(1)/install\n\t$(call Package/trusted-firmware-a/install/default,$(1))\n\t$(INSTALL_DIR) $(BIN_DIR)/sl3000-recovery\n\t[ -f $(PKG_BUILD_DIR)/build/$(PLAT)/release/bl2.bin ] && cp $(PKG_BUILD_DIR)/build/$(PLAT)/release/bl2.bin $(BIN_DIR)/sl3000-recovery/bl2.img\n\t[ -f $(PKG_BUILD_DIR)/build/$(PLAT)/release/fip.bin ] && cp $(PKG_BUILD_DIR)/build/$(PLAT)/release/fip.bin $(BIN_DIR)/sl3000-recovery/fip.bin\nendef\n$(eval $(call BuildPackage/Trusted-Firmware-A))\n' > "$PKG_DIR/Makefile"

echo "--- [2/3] 架构死锁：清除 x86 纠偏为 MT7981 ---"
# 物理删除所有默认配置
true > "$TARGET_DIR/.config"
printf "CONFIG_TARGET_mediatek=y\nCONFIG_TARGET_mediatek_filogic=y\nCONFIG_TARGET_mediatek_filogic_DEVICE_mediatek_mt7981-rfb-flash=y\n" >> "$TARGET_DIR/.config"
printf "CONFIG_PACKAGE_arm-trusted-firmware-mediatek-mt7981-nor-ddr4=y\n" >> "$TARGET_DIR/.config"
printf "CONFIG_PACKAGE_uboot-mediatek-mt7981_sl3000=y\n" >> "$TARGET_DIR/.config"

echo "--- [3/3] 物理重置索引 ---"
rm -rf "$TARGET_DIR/tmp"
