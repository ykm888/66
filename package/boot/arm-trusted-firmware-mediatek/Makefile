#
# Copyright (C) 2024-2026 ykm888
# 物理锁定：使用 atf-20220606 稳定零件，物理对齐 SL-3000 1024M
#

include $(TOPDIR)/rules.mk

PKG_NAME:=arm-trusted-firmware-mediatek
PKG_RELEASE:=1

# 物理锁定：你的 hanwckf-stable-source 分支
PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/ykm888/66.git
PKG_SOURCE_VERSION:=hanwckf-stable-source

PKG_MAINTAINER:=ykm888

# 物理坐标定位：精准锁定仓库内的 ATF 子目录
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

# 物理修复准则：定义 SL-3000 专用的 1024M 变体
define Trusted-Firmware-A/mt7981-nor-ddr4
  NAME:=SL-3000 (NOR-DDR4-1024M)
  VARIANT:=mt7981-nor-ddr4
  BOOT_DEVICE:=nor
  DDR_TYPE:=ddr4
endef

TFA_TARGETS:=mt7981-nor-ddr4

# 物理核心：开启 DDR4 与 1024M 寻址开关，屏蔽警告
TFA_MAKE_FLAGS += \
	DRAM_USE_DDR4=1 \
	BOOT_DEVICE=nor \
	TRUSTED_BOARD_BOOT=0 \
	WERROR=0 \
	DEBUG=0

define Build/Prepare
	$(call Build/Prepare/Default)
	@echo "Physical Surgery: Extracting ATF 20220606 source..."
	# 物理手术：将子目录内的 ATF 源码物理移动到编译根目录
	if [ -d "$(PKG_BUILD_DIR)/$(ATF_SRC_DIR)" ]; then \
		cp -rf $(PKG_BUILD_DIR)/$(ATF_SRC_DIR)/* $(PKG_BUILD_DIR)/; \
	fi
	# 物理清道夫：针对新版 GCC 的兼容性处理
	find $(PKG_BUILD_DIR) -type f -exec sed -i 's/-Werror//g' {} + || true
	find $(PKG_BUILD_DIR) -type f -exec sed -i 's/-no-warn-rwx-segments//g' {} + || true
endef

define Package/arm-trusted-firmware-mediatek-$(1)/install
	$(call Package/trusted-firmware-a-$(1)/install/default,$(1))
	$(INSTALL_DIR) $(STAGING_DIR_IMAGE)
	# 产出物理对齐
	$(CP) $(STAGING_DIR_IMAGE)/$(1)-bl2.bin $(STAGING_DIR_IMAGE)/bl2.img
	$(CP) $(STAGING_DIR_IMAGE)/$(1)-bl31.bin $(STAGING_DIR_IMAGE)/bl31.bin
	# 物理备份至 recovery 目录
	$(INSTALL_DIR) $(BIN_DIR)/sl3000-recovery
	$(CP) $(STAGING_DIR_IMAGE)/$(1)-bl2.bin $(BIN_DIR)/sl3000-recovery/bl2.img
	$(CP) $(STAGING_DIR_IMAGE)/$(1)-bl31.bin $(BIN_DIR)/sl3000-recovery/bl31.bin
endef

$(eval $(call BuildPackage/Trusted-Firmware-A))
