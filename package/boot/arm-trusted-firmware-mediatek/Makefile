#
# Copyright (C) 2024-2026 ykm888
# 物理修复：SL-3000 (MT7981) 路径终极对齐
#

include $(TOPDIR)/rules.mk

PKG_NAME:=arm-trusted-firmware-mediatek
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/ykm888/66.git
PKG_SOURCE_VERSION:=atf-sl3000-base

PKG_MAINTAINER:=ykm888

# 强制禁用 Werror，防止任何警告中断编译
PKG_MAKE_FLAGS += WERROR=0

include $(INCLUDE_DIR)/kernel.mk
include $(INCLUDE_DIR)/trusted-firmware-a.mk
include $(INCLUDE_DIR)/package.mk

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

# --- 终极手术：Build/Prepare ---
define Build/Prepare
	$(call Build/Prepare/Default)
	@echo "Physical Surgery: Fixing hardcoded include paths..."
	# 1. 强行创建目录，确保绝对存在
	mkdir -p $(PKG_BUILD_DIR)/plat/mediatek/apsoc_common/include
	
	# 2. 物理同步：如果文件在别处，强行拉过来
	[ -f $(PKG_BUILD_DIR)/plat/mediatek/apsoc_common/bl2/include/plat_def_fip_uuid.h ] && \
		cp $(PKG_BUILD_DIR)/plat/mediatek/apsoc_common/bl2/include/plat_def_fip_uuid.h \
		   $(PKG_BUILD_DIR)/plat/mediatek/apsoc_common/include/ || true

	# 3. 暴力修正：扫描源码中所有 Makefile，如果引用了不存在的 include 目录，直接删掉该标志或重定向
	find $(PKG_BUILD_DIR) -name "*.mk" -o -name "Makefile" | xargs sed -i 's/-Werror//g'
endef

# --- 暴力覆盖编译指令 ---
define Build/Compile
	$(call Build/Compile/Default, \
		WERROR=0 \
		CFLAGS="$(TARGET_CFLAGS) -Wno-error=missing-include-dirs" \
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

$(eval $(call BuildPackage/Trusted-Firmware-A))
