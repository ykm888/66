#
# Copyright (C) 2024-2026 ykm888
# 物理修复终极版：针对 SL-3000 (MT7981) NOR-DDR4 零件闭环生产
#

include $(TOPDIR)/rules.mk

PKG_NAME:=arm-trusted-firmware-mediatek
PKG_RELEASE:=1

# 物理坐标：锁定 hanwckf 稳定分支及子目录路径
PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/ykm888/66.git
PKG_SOURCE_VERSION:=hanwckf-stable-source
ATF_SRC_DIR:=atf-20220606-637ba581b

PKG_MAINTAINER:=ykm888

# 物理工地路径定义
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(BUILD_VARIANT)/$(PKG_NAME)-$(PKG_SOURCE_VERSION)

include $(INCLUDE_DIR)/kernel.mk
include $(INCLUDE_DIR)/trusted-firmware-a.mk
include $(INCLUDE_DIR)/package.mk

# --- 1. 零件工艺默认参数 ---
define Trusted-Firmware-A/Default
  BUILD_TARGET:=mediatek
  BUILD_SUBTARGET:=filogic
  PLAT:=mt7981
  TFA_IMAGE:=bl2.bin bl31.bin
endef

# --- 2. 物理变体定义：SL-3000 (NOR-DDR4) ---
define Trusted-Firmware-A/mt7981-nor-ddr4
  NAME:=SL-3000 (NOR-DDR4-512M)
  VARIANT:=mt7981-nor-ddr4
  BOOT_DEVICE:=nor
  DDR_TYPE:=ddr4
endef

TFA_TARGETS:=mt7981-nor-ddr4

# --- 3. 物理编译选项：锁死 DDR4 并禁用警告中断 ---
TFA_MAKE_FLAGS += \
	DRAM_USE_DDR4=1 \
	BOOT_DEVICE=nor \
	TRUSTED_BOARD_BOOT=0 \
	WERROR=0 \
	DEBUG=0

# --- 4. 物理工地准备：平铺目录并清理 Werror ---
define Build/Prepare
	$(call Build/Prepare/Default)
	@echo "Physical Surgery: Flattening source structure..."
	# 如果存在嵌套的源码文件夹，则物理平铺到根工地
	if [ -d "$(PKG_BUILD_DIR)/$(ATF_SRC_DIR)" ]; then \
		cp -rf $(PKG_BUILD_DIR)/$(ATF_SRC_DIR)/* $(PKG_BUILD_DIR)/; \
		rm -rf $(PKG_BUILD_DIR)/$(ATF_SRC_DIR); \
	fi
	# 物理暴力清除：防止 GCC 13 将警告当成错误导致编译中断
	find $(PKG_BUILD_DIR) -type f -name "Makefile*" -exec sed -i 's/-Werror//g' {} + || true
	find $(PKG_BUILD_DIR) -type f -name "*.mk" -exec sed -i 's/-Werror//g' {} + || true
	find $(PKG_BUILD_DIR) -type f -exec sed -i 's/-no-warn-rwx-segments//g' {} + || true
endef

# --- 5. 零件分发逻辑：满足 filogic.mk 的所有物理搜寻路径 ---
define Package/trusted-firmware-a-$(1)/install
	$(INSTALL_DIR) $(STAGING_DIR_IMAGE)
	# 物理生产 BL2 零件
	if [ -f $(PKG_BUILD_DIR)/build/$(PLAT)/release/bl2.bin ]; then \
		$(CP) $(PKG_BUILD_DIR)/build/$(PLAT)/release/bl2.bin $(STAGING_DIR_IMAGE)/$(1)-bl2.bin; \
		$(CP) $(PKG_BUILD_DIR)/build/$(PLAT)/release/bl2.bin $(STAGING_DIR_IMAGE)/bl2.img; \
		$(CP) $(PKG_BUILD_DIR)/build/$(PLAT)/release/bl2.bin $(STAGING_DIR_IMAGE)/bl2.bin; \
	fi
	# 物理生产 BL31 零件
	if [ -f $(PKG_BUILD_DIR)/build/$(PLAT)/release/bl31.bin ]; then \
		$(CP) $(PKG_BUILD_DIR)/build/$(PLAT)/release/bl31.bin $(STAGING_DIR_IMAGE)/$(1)-bl31.bin; \
		$(CP) $(PKG_BUILD_DIR)/build/$(PLAT)/release/bl31.bin $(STAGING_DIR_IMAGE)/bl31.bin; \
	fi
	# 物理备份：同步到 Bin 目录方便手动救砖使用
	$(INSTALL_DIR) $(BIN_DIR)/sl3000-recovery
	[ -f $(STAGING_DIR_IMAGE)/bl2.img ] && \
		$(CP) $(STAGING_DIR_IMAGE)/bl2.img $(BIN_DIR)/sl3000-recovery/bl2.img; \
	[ -f $(STAGING_DIR_IMAGE)/bl31.bin ] && \
		$(CP) $(STAGING_DIR_IMAGE)/bl31.bin $(BIN_DIR)/sl3000-recovery/bl31.bin
endef

$(eval $(call BuildPackage/Trusted-Firmware-A))
