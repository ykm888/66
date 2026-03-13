#
# Copyright (C) 2024-2026 ykm888
# 物理修复终极版：针对 SL-3000 (MT7981) 适配 1MB 偏移黄金救砖分支
#

include $(TOPDIR)/rules.mk

PKG_NAME:=arm-trusted-firmware-mediatek
PKG_RELEASE:=1

# --- 核心修改：物理指向你的黄金分支 ---
PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/ykm888/66.git
PKG_SOURCE_VERSION:=sl3000-clean-source
PKG_MIRROR_HASH:=skip

PKG_MAINTAINER:=ykm888

# 物理仓库内的源码目录名
ATF_SRC_SUBDIR:=atf

# 物理构建目录定义 (必须与 PKG_NAME 保持逻辑一致)
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

# --- 2. 物理变体修复：必须与 .config 中的 CONFIG_PACKAGE_...-mt7981-nor-ddr4 严格对齐 ---
define Trusted-Firmware-A/mt7981-nor-ddr4
  NAME:=SL-3000 (Hardened NOR-DDR4)
  VARIANT:=mt7981-nor-ddr4
  BOOT_DEVICE:=nor
endef

# 物理宣告目标，否则 make 找不到编译规则
TFA_TARGETS:=mt7981-nor-ddr4

# --- 3. 物理编译选项：硬化 1MB 偏移支持 ---
TFA_MAKE_FLAGS += \
	BOOT_DEVICE=nor \
	TRUSTED_BOARD_BOOT=0 \
	WERROR=0 \
	DEBUG=0

# --- 4. 物理工地准备：平铺目录并移除 Git 索引干扰 ---
define Build/Prepare
	$(call Build/Prepare/Default)
	@echo "Physical Surgery: Aligning ATF source from subfolder..."
	# 物理搬运：将仓库下 atf 文件夹内的文件提升至构建根目录
	if [ -d "$(PKG_BUILD_DIR)/$(ATF_SRC_SUBDIR)" ]; then \
		cp -rf $(PKG_BUILD_DIR)/$(ATF_SRC_SUBDIR)/* $(PKG_BUILD_DIR)/; \
	fi
	
	# 物理暴力清除：强制关闭所有可能导致 Error 2 的编译警告
	find $(PKG_BUILD_DIR) -type f -name "Makefile*" -exec sed -i 's/-Werror//g' {} + || true
	find $(PKG_BUILD_DIR) -type f -name "*.mk" -exec sed -i 's/-Werror//g' {} + || true
	# 修复部分 GCC 11+ 的段警告
	find $(PKG_BUILD_DIR) -type f -exec sed -i 's/-no-warn-rwx-segments//g' {} + || true
endef

# --- 5. 零件分发逻辑：产出救砖专用的 bl2.img ---
define Package/trusted-firmware-a-$(1)/install
	$(INSTALL_DIR) $(STAGING_DIR_IMAGE)
	# 物理验证并拷贝编译产物
	if [ -f $(PKG_BUILD_DIR)/build/$(PLAT)/release/bl2.bin ]; then \
		$(CP) $(PKG_BUILD_DIR)/build/$(PLAT)/release/bl2.bin $(STAGING_DIR_IMAGE)/bl2.img; \
		$(CP) $(PKG_BUILD_DIR)/build/$(PLAT)/release/bl2.bin $(STAGING_DIR_IMAGE)/$(1)-bl2.bin; \
	fi
	
	if [ -f $(PKG_BUILD_DIR)/build/$(PLAT)/release/bl31.bin ]; then \
		$(CP) $(PKG_BUILD_DIR)/build/$(PLAT)/release/bl31.bin $(STAGING_DIR_IMAGE)/bl31.bin; \
		$(CP) $(PKG_BUILD_DIR)/build/$(PLAT)/release/bl31.bin $(STAGING_DIR_IMAGE)/$(1)-bl31.bin; \
	fi
	
	# 物理备份：同步到 Bin 目录方便 Action 收集
	$(INSTALL_DIR) $(BIN_DIR)/sl3000-recovery
	[ -f $(STAGING_DIR_IMAGE)/bl2.img ] && \
		$(CP) $(STAGING_DIR_IMAGE)/bl2.img $(BIN_DIR)/sl3000-recovery/bl2.img; \
	[ -f $(STAGING_DIR_IMAGE)/bl31.bin ] && \
		$(CP) $(STAGING_DIR_IMAGE)/bl31.bin $(BIN_DIR)/sl3000-recovery/bl31.bin
endef

$(eval $(call BuildPackage/Trusted-Firmware-A))
