#
# Copyright (C) 2024-2026 ykm888
# 彻底修复：物理屏蔽非法链接参数 & 路径强制对齐
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

# 物理修复准则：显式锁定 VARIANT 名称，确保与 uboot-mediatek 依赖项物理对齐
define Trusted-Firmware-A/mt7981-nor-ddr4
  NAME:=SL-3000 (NOR-DDR4-1024M)
  VARIANT:=mt7981-nor-ddr4
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
	@echo "Physical Surgery: Removing unrecognized command-line options..."
	mkdir -p $(PKG_BUILD_DIR)/plat/mediatek/apsoc_common/include
	if [ -d $(PKG_BUILD_DIR)/plat/mediatek/apsoc_common/bl2/include ]; then \
		cp -f $(PKG_BUILD_DIR)/plat/mediatek/apsoc_common/bl2/include/*.h \
		      $(PKG_BUILD_DIR)/plat/mediatek/apsoc_common/include/ || true; \
	fi
	# 延续报错修复：延续你贴出的 bl2.elf 错误逻辑，物理切除所有非法参数
	find $(PKG_BUILD_DIR) -type f -exec sed -i 's/-no-warn-rwx-segments//g' {} + || true
	find $(PKG_BUILD_DIR) -type f -exec sed -i 's/-Werror//g' {} + || true
endef

define Build/Compile
	$(call Build/Compile/Default, \
		WERROR=0 \
		LDFLAGS="" \
		TF_LDFLAGS="" \
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
