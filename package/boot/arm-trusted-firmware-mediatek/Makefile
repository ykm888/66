#
# Copyright (C) 2024-2026 ykm888
# 物理修复 3 版：修正大小写敏感、增强提取鲁棒性、对齐 FIP 链路
#

include $(TOPDIR)/rules.mk

PKG_NAME:=arm-trusted-firmware-mediatek
PKG_RELEASE:=1

# 物理锁定：hanwckf 稳定分支
PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/ykm888/66.git
PKG_SOURCE_VERSION:=hanwckf-stable-source

PKG_MAINTAINER:=ykm888

# 物理坐标锁定
ATF_SRC_DIR:=atf-20220606-637ba581b
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(BUILD_VARIANT)/$(PKG_NAME)-$(PKG_SOURCE_VERSION)

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
  NAME:=SL-3000 (NOR-DDR4-512M)
  VARIANT:=mt7981-nor-ddr4
  BOOT_DEVICE:=nor
  DDR_TYPE:=ddr4
endef

TFA_TARGETS:=mt7981-nor-ddr4

# 物理核心参数：确保 DDR4 锁定，WERROR=0 跳过 GCC 13 报错
TFA_MAKE_FLAGS += \
	DRAM_USE_DDR4=1 \
	BOOT_DEVICE=nor \
	TRUSTED_BOARD_BOOT=0 \
	WERROR=0 \
	DEBUG=0

define Build/Prepare
	$(call Build/Prepare/Default)
	@echo "Physical Surgery: Extracting ATF source and flattening structure..."
	# 物理平铺逻辑：如果子目录存在，则提取并覆盖到根目录
	[ -d "$(PKG_BUILD_DIR)/$(ATF_SRC_DIR)" ] && { \
		cp -rf $(PKG_BUILD_DIR)/$(ATF_SRC_DIR)/* $(PKG_BUILD_DIR)/; \
		rm -rf $(PKG_BUILD_DIR)/$(ATF_SRC_DIR); \
	}
	# 物理清道夫：移除所有可能中断编译的警告限制
	find $(PKG_BUILD_DIR) -type f -exec sed -i 's/-Werror//g' {} + || true
	find $(PKG_BUILD_DIR) -type f -exec sed -i 's/-no-warn-rwx-segments//g' {} + || true
endef

define Package/arm-trusted-firmware-mediatek-$(1)/install
	$(INSTALL_DIR) $(STAGING_DIR_IMAGE)
	# 物理分发逻辑：BL2 -> bl2.img (供 U-Boot/fiptool 合成使用)
	if [ -f $(PKG_BUILD_DIR)/build/$(PLAT)/release/bl2.bin ]; then \
		$(CP) $(PKG_BUILD_DIR)/build/$(PLAT)/release/bl2.bin $(STAGING_DIR_IMAGE)/$(1)-bl2.bin; \
		$(CP) $(PKG_BUILD_DIR)/build/$(PLAT)/release/bl2.bin $(STAGING_DIR_IMAGE)/bl2.img; \
	fi
	
	# 物理分发逻辑：BL31 -> 影子备份
	if [ -f $(PKG_BUILD_DIR)/build/$(PLAT)/release/bl31.bin ]; then \
		$(CP) $(PKG_BUILD_DIR)/build/$(PLAT)/release/bl31.bin $(STAGING_DIR_IMAGE)/$(1)-bl31.bin; \
		$(CP) $(PKG_BUILD_DIR)/build/$(PLAT)/release/bl31.bin $(STAGING_DIR_IMAGE)/bl31.bin; \
	fi
	
	# 物理备份：救砖包零件区
	$(INSTALL_DIR) $(BIN_DIR)/sl3000-recovery
	[ -f $(STAGING_DIR_IMAGE)/bl2.img ] && \
		$(CP) $(STAGING_DIR_IMAGE)/bl2.img $(BIN_DIR)/sl3000-recovery/bl2.img
	[ -f $(STAGING_DIR_IMAGE)/bl31.bin ] && \
		$(CP) $(STAGING_DIR_IMAGE)/bl31.bin $(BIN_DIR)/sl3000-recovery/bl31.bin
endef

$(eval $(call BuildPackage/Trusted-Firmware-A))
