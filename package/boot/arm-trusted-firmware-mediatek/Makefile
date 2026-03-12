#
# Copyright (C) 2024-2026 ykm888
# 物理修复：锁定 atf-20220606 稳定版，物理对齐 SL-3000 DDR4
#

include $(TOPDIR)/rules.mk

PKG_NAME:=arm-trusted-firmware-mediatek
PKG_RELEASE:=1

# 物理锁定：使用 hanwckf 稳定分支
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

# 物理变体定义：SL-3000 专用的 NOR+DDR4 组合
define Trusted-Firmware-A/mt7981-nor-ddr4
  NAME:=SL-3000 (NOR-DDR4-512M/1024M)
  VARIANT:=mt7981-nor-ddr4
  BOOT_DEVICE:=nor
  DDR_TYPE:=ddr4
endef

TFA_TARGETS:=mt7981-nor-ddr4

# 物理核心：强制锁定 DDR4，屏蔽所有 Werror 警告防止 GCC 13 报错
TFA_MAKE_FLAGS += \
	DRAM_USE_DDR4=1 \
	BOOT_DEVICE=nor \
	TRUSTED_BOARD_BOOT=0 \
	WERROR=0 \
	DEBUG=0

define Build/Prepare
	$(call Build/Prepare/Default)
	@echo "Physical Surgery: Extracting ATF 20220606 source..."
	# 物理平铺：将子目录内的源码移动到 PKG_BUILD_DIR 根目录
	if [ -d "$(PKG_BUILD_DIR)/$(ATF_SRC_DIR)" ]; then \
		cp -rf $(PKG_BUILD_DIR)/$(ATF_SRC_DIR)/* $(PKG_BUILD_DIR)/; \
	fi
	# 物理清道夫：抹除 GCC 13+ 冲突参数
	find $(PKG_BUILD_DIR) -type f -exec sed -i 's/-Werror//g' {} + || true
	find $(PKG_BUILD_DIR) -type f -exec sed -i 's/-no-warn-rwx-segments//g' {} + || true
endef

define Package/arm-trusted-firmware-mediatek-$(1)/install
	$(INSTALL_DIR) $(STAGING_DIR_IMAGE)
	# 物理抓取逻辑：绕过宏定义，直接从编译输出目录提取二进制零件
	[ -f $(PKG_BUILD_DIR)/build/$(PLAT)/release/bl2.bin ] && \
		$(CP) $(PKG_BUILD_DIR)/build/$(PLAT)/release/bl2.bin $(STAGING_DIR_IMAGE)/$(1)-bl2.bin
	[ -f $(PKG_BUILD_DIR)/build/$(PLAT)/release/bl31.bin ] && \
		$(CP) $(PKG_BUILD_DIR)/build/$(PLAT)/release/bl31.bin $(STAGING_DIR_IMAGE)/$(1)-bl31.bin
	
	# 物理对齐：产出 filogic.mk 需要的通用零件名 bl2.img
	$(CP) $(STAGING_DIR_IMAGE)/$(1)-bl2.bin $(STAGING_DIR_IMAGE)/bl2.img
	
	# 物理备份：执行救砖包工序 (sl3000-recovery)
	$(INSTALL_DIR) $(BIN_DIR)/sl3000-recovery
	$(CP) $(STAGING_DIR_IMAGE)/bl2.img $(BIN_DIR)/sl3000-recovery/bl2.img
	$(CP) $(STAGING_DIR_IMAGE)/$(1)-bl31.bin $(BIN_DIR)/sl3000-recovery/bl31.bin
endef

$(eval $(call BuildPackage/Trusted-Firmware-A))
