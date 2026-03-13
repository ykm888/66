#
# Copyright (C) 2024-2026 ykm888
# 物理修复终极版：针对 SL-3000 (MT7981) 适配黄金救砖分支
#

include $(TOPDIR)/rules.mk

PKG_NAME:=arm-trusted-firmware-mediatek
PKG_RELEASE:=1

# --- 核心修改：切换至物理硬化后的黄金分支 ---
PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/ykm888/66.git
PKG_SOURCE_VERSION:=sl3000-clean-source
PKG_MIRROR_HASH:=skip

PKG_MAINTAINER:=ykm888

# 对应你仓库中的物理目录名
ATF_SRC_SUBDIR:=atf

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

# --- 2. 物理变体定义：SL-3000 ---
define Trusted-Firmware-A/mt7981-sl3000
  NAME:=SL-3000 (NOR-DDR3/4-Recovery)
  VARIANT:=mt7981-sl3000
  BOOT_DEVICE:=emmc
  # 根据你之前的适配，这里建议保持 emmc/nor 兼容配置
endef

TFA_TARGETS:=mt7981-sl3000

# --- 3. 物理编译选项：注入救砖所需的关键参数 ---
TFA_MAKE_FLAGS += \
	BOOT_DEVICE=emmc \
	TRUSTED_BOARD_BOOT=0 \
	WERROR=0 \
	DEBUG=0

# --- 4. 物理工地准备：平铺目录并移除 Git 索引干扰 ---
define Build/Prepare
	$(call Build/Prepare/Default)
	@echo "Physical Surgery: Aligning ATF source from subfolder..."
	# 将仓库 atf 文件夹内的物理文件平铺到构建根目录
	if [ -d "$(PKG_BUILD_DIR)/$(ATF_SRC_SUBDIR)" ]; then \
		cp -rf $(PKG_BUILD_DIR)/$(ATF_SRC_SUBDIR)/* $(PKG_BUILD_DIR)/; \
	fi
	
	# 物理暴力清除编译警告中断
	find $(PKG_BUILD_DIR) -type f -name "Makefile*" -exec sed -i 's/-Werror//g' {} + || true
	find $(PKG_BUILD_DIR) -type f -name "*.mk" -exec sed -i 's/-Werror//g' {} + || true
	find $(PKG_BUILD_DIR) -type f -exec sed -i 's/-no-warn-rwx-segments//g' {} + || true
endef

# --- 5. 零件分发逻辑：产出 bl2.img 供镜像脚本合成 ---
define Package/trusted-firmware-a-$(1)/install
	$(INSTALL_DIR) $(STAGING_DIR_IMAGE)
	# 寻找编译出的物理零件
	if [ -f $(PKG_BUILD_DIR)/build/$(PLAT)/release/bl2.bin ]; then \
		$(CP) $(PKG_BUILD_DIR)/build/$(PLAT)/release/bl2.bin $(STAGING_DIR_IMAGE)/$(1)-bl2.bin; \
		$(CP) $(PKG_BUILD_DIR)/build/$(PLAT)/release/bl2.bin $(STAGING_DIR_IMAGE)/bl2.img; \
		$(CP) $(PKG_BUILD_DIR)/build/$(PLAT)/release/bl2.bin $(STAGING_DIR_IMAGE)/bl2.bin; \
	fi
	
	if [ -f $(PKG_BUILD_DIR)/build/$(PLAT)/release/bl31.bin ]; then \
		$(CP) $(PKG_BUILD_DIR)/build/$(PLAT)/release/bl31.bin $(STAGING_DIR_IMAGE)/$(1)-bl31.bin; \
		$(CP) $(PKG_BUILD_DIR)/build/$(PLAT)/release/bl31.bin $(STAGING_DIR_IMAGE)/bl31.bin; \
	fi
	
	# 物理备份：同步到 Bin 目录方便下载
	$(INSTALL_DIR) $(BIN_DIR)/sl3000-recovery
	[ -f $(STAGING_DIR_IMAGE)/bl2.img ] && \
		$(CP) $(STAGING_DIR_IMAGE)/bl2.img $(BIN_DIR)/sl3000-recovery/bl2.img; \
	[ -f $(STAGING_DIR_IMAGE)/bl31.bin ] && \
		$(CP) $(STAGING_DIR_IMAGE)/bl31.bin $(BIN_DIR)/sl3000-recovery/bl31.bin
endef

$(eval $(call BuildPackage/Trusted-Firmware-A))
