include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=uboot-mediatek
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/ykm888/66.git
PKG_SOURCE_VERSION:=hanwckf-stable-source

PKG_MAINTAINER:=ykm888
PKG_LICENSE:=GPL-2.0

PKG_BUILD_PARALLEL:=1
UBOOT_SRC_DIR:=uboot-mtk-20250711
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(BUILD_VARIANT)/$(PKG_NAME)-$(PKG_SOURCE_VERSION)

include $(INCLUDE_DIR)/u-boot.mk
include $(INCLUDE_DIR)/package.mk

define U-Boot/Default
  BUILD_TARGET:=mediatek
  BUILD_SUBTARGET:=filogic
  UBOOT_CONFIG:=mt7981_nor_emmc_rfb
  UBOOT_IMAGE:=u-boot.bin
endef

define U-Boot/mt7981-nor-ddr4
  NAME:=SL-3000 (512MB-Safe-Recovery)
  BUILD_DEVICES:=ykm888_sl-3000
  # 物理修正：去掉 + 号，防止扫描阶段因 ATF 未完全索引导致的报错
  DEPENDS:=arm-trusted-firmware-mediatek
  UBOOT_CONFIG:=mt7981_nor_emmc_rfb
endef

UBOOT_TARGETS:=mt7981-nor-ddr4

define Build/Prepare
	$(call Build/Prepare/Default)
	if [ -d "$(PKG_BUILD_DIR)/$(UBOOT_SRC_DIR)" ]; then \
		cp -rf $(PKG_BUILD_DIR)/$(UBOOT_SRC_DIR)/* $(PKG_BUILD_DIR)/; \
	fi
	sed -i '/CONFIG_ARM64_VA_BITS_39/d' $(PKG_BUILD_DIR)/configs/mt7981_nor_emmc_rfb_defconfig
	sed -i 's/192.168.1.1/192.168.31.1/g' $(PKG_BUILD_DIR)/configs/mt7981_nor_emmc_rfb_defconfig || true
	find $(PKG_BUILD_DIR) -type f -exec sed -i 's/-no-warn-rwx-segments//g' {} + || true
endef

define Package/uboot-mediatek-$(1)/install
	$(INSTALL_DIR) $(STAGING_DIR_IMAGE)
	if [ -f $(PKG_BUILD_DIR)/u-boot.bin ]; then \
		$(CP) $(PKG_BUILD_DIR)/u-boot.bin $(STAGING_DIR_IMAGE)/$(1)-u-boot.bin; \
		$(CP) $(PKG_BUILD_DIR)/u-boot.bin $(STAGING_DIR_IMAGE)/u-boot.bin; \
	fi
	$(INSTALL_DIR) $(BIN_DIR)/sl3000-recovery
	[ -f $(PKG_BUILD_DIR)/u-boot.bin ] && \
		$(CP) $(PKG_BUILD_DIR)/u-boot.bin $(BIN_DIR)/sl3000-recovery/u-boot.bin
endef

$(eval $(call BuildPackage/U-Boot))
