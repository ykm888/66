#!/bin/bash
# =========================================================
# SL-3000 全链路自愈：物理切除与单体注入
# =========================================================

TARGET_DIR="$(pwd)/openwrt"
PKG_DIR="$TARGET_DIR/package/custom-atf"

echo "--- [1/4] 物理切除：清除系统自带冲突包 ---"
rm -rf "$TARGET_DIR/package/boot/arm-trusted-firmware-mediatek"
rm -rf "$TARGET_DIR/package/feeds/base/arm-trusted-firmware-mediatek"

echo "--- [2/4] 单体注入：原地构建 ATF 编译环境 ---"
mkdir -p "$PKG_DIR"
# 物理写入 Makefile，直接硬编码，不留任何配置空隙
printf 'include $(TOPDIR)/rules.mk\nPKG_NAME:=arm-trusted-firmware-mediatek\nPKG_RELEASE:=1\nPKG_VERSION:=sl3000\nPKG_SOURCE_PROTO:=git\nPKG_SOURCE_URL:=https://github.com/ykm888/66.git\nPKG_SOURCE_VERSION:=sl3000-clean-source\ninclude $(INCLUDE_DIR)/trusted-firmware-a.mk\ninclude $(INCLUDE_DIR)/package.mk\ndefine Trusted-Firmware-A/Default\n  BUILD_TARGET:=mediatek\n  BUILD_SUBTARGET:=filogic\n  PLAT:=mt7981\n  TFA_IMAGE:=bl2.bin fip.bin\nendef\ndefine Trusted-Firmware-A/mt7981-nor-ddr4\n  NAME:=SL-3000-NOR\n  TFA_MAKE_FLAGS:=BOOT_DEVICE=nor DRAM_USE_DDR4=1\nendef\nTFA_TARGETS:=mt7981-nor-ddr4\ndefine Package/trusted-firmware-a-$(1)/install\n\t$(call Package/trusted-firmware-a/install/default,$(1))\n\t$(INSTALL_DIR) $(BIN_DIR)/sl3000-recovery\n\t[ -f $(PKG_BUILD_DIR)/build/$(PLAT)/release/bl2.bin ] && cp $(PKG_BUILD_DIR)/build/$(PLAT)/release/bl2.bin $(BIN_DIR)/sl3000-recovery/bl2.img\n\t[ -f $(PKG_BUILD_DIR)/build/$(PLAT)/release/fip.bin ] && cp $(PKG_BUILD_DIR)/build/$(PLAT)/release/fip.bin $(BIN_DIR)/sl3000-recovery/fip.bin\nendef\n$(eval $(call BuildPackage/Trusted-Firmware-A))\n' > "$PKG_DIR/Makefile"

echo "--- [3/4] 架构死锁：初始化 .config ---"
# 彻底清空，防止 x86 干扰
true > "$TARGET_DIR/.config"
printf "CONFIG_TARGET_mediatek=y\n" >> "$TARGET_DIR/.config"
printf "CONFIG_TARGET_mediatek_filogic=y\n" >> "$TARGET_DIR/.config"
printf "CONFIG_TARGET_mediatek_filogic_DEVICE_mediatek_mt7981-rfb-flash=y\n" >> "$TARGET_DIR/.config"
printf "CONFIG_PACKAGE_arm-trusted-firmware-mediatek-mt7981-nor-ddr4=y\n" >> "$TARGET_DIR/.config"

echo "--- [4/4] 强制刷新索引 ---"
rm -rf "$TARGET_DIR/tmp"
