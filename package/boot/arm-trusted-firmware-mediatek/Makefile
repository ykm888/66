#
# Copyright (C) 2024-2026 ykm888
# 物理修复：SL-3000 (MT7981) 救砖零件物理对齐
# 源码源头：atf-sl3000-base
# 目标：彻底解决 cc1 路径报错 & 1024M 物理寻址
#

include $(TOPDIR)/rules.mk

PKG_NAME:=arm-trusted-firmware-mediatek
PKG_RELEASE:=1

# 物理重定向：确保直接拉取你已经物理重组好的分支
PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/ykm888/66.git
PKG_SOURCE_VERSION:=atf-sl3000-base

PKG_MAINTAINER:=ykm888

# 核心安全机制：源头屏蔽 Werror
# WERROR=0 用于告知 ATF 脚本本身关闭错误转换
# 增加编译标志强制 C 编译器忽略路径缺失的错误
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

# 定义 SL-3000 专属硬件变体：1024M 内存寻址锁定
define Trusted-Firmware-A/mt7981-nor-ddr4
  NAME:=SL-3000 (NOR-DDR4-1024M)
  BOOT_DEVICE:=nor
  DDR_TYPE:=ddr4
endef

TFA_TARGETS:=mt7981-nor-ddr4

# 物理加固：锁定 DDR4 参数，确保 DRAM 训练逻辑正确
TFA_MAKE_FLAGS += \
	DRAM_USE_DDR4=1 \
	BOOT_DEVICE=nor \
	TRUSTED_BOARD_BOOT=0 \
	DEBUG=0

# --- 源头手术：Build/Prepare ---
# 逻辑：在源码解压到 build_dir 后的第一时间，物理补齐路径
define Build/Prepare
	$(call Build/Prepare/Default)
	@echo "Physical Surgery: Aligning include paths in Build/Prepare..."
	mkdir -p $(PKG_BUILD_DIR)/plat/mediatek/apsoc_common/include
	mkdir -p $(PKG_BUILD_DIR)/plat/mediatek/common/include
	mkdir -p $(PKG_BUILD_DIR)/plat/mediatek/mt7981/include
	# 物理同步：确保 bl2 下的头文件在编译主路径中可见
	[ -d $(PKG_BUILD_DIR)/plat/mediatek/apsoc_common/bl2/include ] && \
		cp -rf $(PKG_BUILD_DIR)/plat/mediatek/apsoc_common/bl2/include/*.h $(PKG_BUILD_DIR)/plat/mediatek/apsoc_common/include/ || true
endef

# --- 核心暴力手术：重写编译指令 ---
# 逻辑：强制在 CC 命令行中加入 -Wno-error，这是对抗硬编码 -Werror 的终极手段
define Build/Compile
	$(call Build/Compile/Default, \
		WERROR=0 \
		CFLAGS="$(TARGET_CFLAGS) -Wno-error=missing-include-dirs -Wno-warn-backlight" \
	)
endef

# --- 物理安装：建立零件桥梁 ---
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
