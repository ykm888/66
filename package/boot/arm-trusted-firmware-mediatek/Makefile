#
# Copyright (C) 2024-2026 ykm888
# 物理修复：SL-3000 (MT7981) 路径终极对齐 & 链接参数兼容性修补
#

include $(TOPDIR)/rules.mk

PKG_NAME:=arm-trusted-firmware-mediatek
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/ykm888/66.git
PKG_SOURCE_VERSION:=atf-sl3000-base

PKG_MAINTAINER:=ykm888

HOST_BUILD_DIR:=$(BUILD_DIR_HOST)/$(PKG_NAME)

include $(INCLUDE_DIR)/host-build.mk
include $(INCLUDE_DIR)/kernel.mk
include $(INCLUDE_DIR)/trusted-firmware-a.mk
include $(INCLUDE_DIR)/package.mk

PKG_MAKE_FLAGS += WERROR=0

define Trusted-Firmware-A/Default
  BUILD_TARGET:=mediatek
  BUILD_SUBTARGET:=filogic
  PLAT:=mt7981
  TFA_IMAGE:=bl2.bin bl31.bin
endef

define Trusted-Firmware-A/mt7981-nor-ddr4
  NAME:=SL-3000 (NOR-DDR4-1024M)
  BOOT_DEVICE:=nor
  DDR_TYPE:=ddr4
endef

TFA_TARGETS:=mt7981-nor-ddr4

TFA_MAKE_FLAGS += \
	DRAM_USE_DDR4=1 \
	BOOT_DEVICE=nor \
	TRUSTED_BOARD_BOOT=0 \
	DEBUG=0

define Host/Prepare
	$(call Host/Prepare/Default)
	mkdir -p $(HOST_BUILD_DIR)/plat/mediatek/apsoc_common/include
	[ -d $(HOST_BUILD_DIR)/plat/mediatek/apsoc_common/bl2/include ] && \
		cp -f $(HOST_BUILD_DIR)/plat/mediatek/apsoc_common/bl2/include/*.h \
		      $(HOST_BUILD_DIR)/plat/mediatek/apsoc_common/include/ || true
endef

define Host/Compile
	$(MAKE) -C $(HOST_BUILD_DIR)/tools/fiptool \
		LDFLAGS="$(HOST_LDFLAGS)" \
		CPPFLAGS="$(HOST_CPPFLAGS) -I$(HOST_BUILD_DIR)/include"
endef

define Host/Install
	$(INSTALL_DIR) $(STAGING_DIR_HOST)/bin
	$(INSTALL_BIN) $(HOST_BUILD_DIR)/tools/fiptool/fiptool $(STAGING_DIR_HOST)/bin/
endef

define Build/Prepare
	$(call Build/Prepare/Default)
	@echo "Physical Surgery: Fixing include paths and compatibility..."
	mkdir -p $(PKG_BUILD_DIR)/plat/mediatek/apsoc_common/include
	if [ -d $(PKG_BUILD_DIR)/plat/mediatek/apsoc_common/bl2/include ]; then \
		cp -f $(PKG_BUILD_DIR)/plat/mediatek/apsoc_common/bl2/include/*.h \
		      $(PKG_BUILD_DIR)/plat/mediatek/apsoc_common/include/ || true; \
	fi
	# 物理修复准则：切除旧版 GCC 不支持的链接参数，防止报错 exit code 2
	find $(PKG_BUILD_DIR) -name "*.mk" -o -name "Makefile" | xargs sed -i 's/-no-warn-rwx-segments//g' || true
	find $(PKG_BUILD_DIR) -name "*.mk" -o -name "Makefile" | xargs sed -i 's/-Werror//g' || true
endef

define Build/Compile
	$(call Build/Compile/Default, \
		WERROR=0 \
		CPPFLAGS="$(TARGET_CPPFLAGS) -I$(PKG_BUILD_DIR)/plat/mediatek/apsoc_common/include" \
	)
endef

define Package/arm-trusted-firmware-mediatek-$(1)/install
	$(call Package/trusted-firmware-a-$(1)/install/default,$(1))
	$(INSTALL_DIR) $(STAGING_DIR_IMAGE)
	$(CP) $(STAGING_DIR_IMAGE)/$(1)-bl2.bin $(STAGING_DIR_IMAGE)/bl2.img
	$(CP) $(STAGING_DIR_IMAGE)/$(1)-bl31.bin $(STAGING_DIR_IMAGE)/bl31.bin
	$(INSTALL_DIR) $(BIN_DIR)/sl3000-recovery
	$(CP) $(STAGING_DIR_IMAGE)/$(1)-bl2.bin $(BIN_DIR)/sl3000-recovery/bl2.img
	$(CP) $(STAGING_DIR_IMAGE)/$(1)-bl31.bin $(BIN_DIR)/sl3000-recovery/bl31.bin
endef

$(eval $(call HostBuild))
$(eval $(call BuildPackage/Trusted-Firmware-A))
