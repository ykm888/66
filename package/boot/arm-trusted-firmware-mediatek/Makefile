#
# Copyright (C) 2024-2026 ykm888
# 物理修复：SL-3000 (MT7981) 救砖零件物理对齐
# 源码分支：atf-sl3000-base (已同步至本地仓库)
#

include $(TOPDIR)/rules.mk

PKG_NAME:=arm-trusted-firmware-mediatek
PKG_RELEASE:=1

# 物理重定向：指向你自己的仓库和固化分支
PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/ykm888/66.git
PKG_SOURCE_VERSION:=atf-sl3000-base

PKG_MAINTAINER:=ykm888

include $(INCLUDE_DIR)/kernel.mk
include $(INCLUDE_DIR)/trusted-firmware-a.mk
include $(INCLUDE_DIR)/package.mk

define Trusted-Firmware-A/Default
  BUILD_TARGET:=mediatek
  BUILD_SUBTARGET:=filogic
  PLAT:=mt7981
  # 产出核心镜像
  TFA_IMAGE:=bl2.bin bl31.bin
endef

# 定义 SL-3000 专属硬件变体：NOR 启动 + DDR4 内存
define Trusted-Firmware-A/mt7981-nor-ddr4
  NAME:=SL-3000 (NOR-DDR4-1024M)
  BOOT_DEVICE:=nor
  DDR_TYPE:=ddr4
endef

TFA_TARGETS:=mt7981-nor-ddr4

# 物理加固：锁定关键宏定义，确保 DDR4 训练代码生效
TFA_MAKE_FLAGS += \
	DRAM_USE_DDR4=1 \
	BOOT_DEVICE=nor \
	TRUSTED_BOARD_BOOT=0

# --- 核心物理修复：建立零件桥梁 ---
# 这里的 $(1) 会自动替换为 mt7981-nor-ddr4
define Package/arm-trusted-firmware-mediatek-$(1)/install
	$(call Package/trusted-firmware-a-$(1)/install/default,$(1))
	
	# 物理强行分发：将变体命名的 bin 物理复制为通用名称，供 filogic.mk 合成使用
	$(CP) $(STAGING_DIR_IMAGE)/$(1)-bl2.bin $(STAGING_DIR_IMAGE)/bl2.img
	$(CP) $(STAGING_DIR_IMAGE)/$(1)-bl31.bin $(STAGING_DIR_IMAGE)/bl31.bin
	
	# 额外物理备份：在 bin/targets 目录下创建 recovery 文件夹方便提取
	$(INSTALL_DIR) $(BIN_DIR)/sl3000-recovery
	$(CP) $(STAGING_DIR_IMAGE)/$(1)-bl2.bin $(BIN_DIR)/sl3000-recovery/bl2.img
	$(CP) $(STAGING_DIR_IMAGE)/$(1)-bl31.bin $(BIN_DIR)/sl3000-recovery/bl31.bin
endef

$(eval $(call BuildPackage/Trusted-Firmware-A))
