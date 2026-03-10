#
# Copyright (C) 2024-2026 ykm888
# 物理修复：SL-3000 救砖零件物理对齐
#

include $(TOPDIR)/rules.mk

PKG_NAME:=trusted-firmware-a-mt7981
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/mtk-openwrt/arm-trusted-firmware.git
PKG_SOURCE_DATE:=2023-07-24
PKG_SOURCE_VERSION:=00ac6db375b76e57e1f5e9e9bffa033e907c3581

include $(INCLUDE_DIR)/kernel.mk
include $(INCLUDE_DIR)/trusted-firmware-a.mk
include $(INCLUDE_DIR)/package.mk

define Trusted-Firmware-A/Default
  BUILD_TARGET:=mediatek
  BUILD_SUBTARGET:=filogic
  PLAT:=mt7981
  # 物理锁定：框架产出标准 .bin 零件
  TFA_IMAGE:=bl2.bin bl31.bin
endef

define Trusted-Firmware-A/mt7981-nor-ddr4
  NAME:=SL-3000 (NOR-DDR4-1024M)
  BOOT_DEVICE:=nor
  DDR_TYPE:=ddr4
endef

TFA_TARGETS:=mt7981-nor-ddr4

# 物理加固：锁定 1024M DDR4 初始化参数
TFA_MAKE_FLAGS += DRAM_USE_DDR4=1

# --- 物理核心修复：拦截并对齐安装工序 ---
# 此步骤物理解决了 "ERROR: BL2零件(bl2.img)缺失"
define Package/trusted-firmware-a-$(1)/install
	$(call Package/trusted-firmware-a-$(1)/install/default,$(1))
	# 物理强行复刻：将带变体前缀的 .bin 复制为合成脚本所需的 bl2.img
	$(CP) $(STAGING_DIR_IMAGE)/$(1)-bl2.bin $(STAGING_DIR_IMAGE)/bl2.img
	$(CP) $(STAGING_DIR_IMAGE)/$(1)-bl31.bin $(STAGING_DIR_IMAGE)/bl31.bin
endef

$(eval $(call BuildPackage/Trusted-Firmware-A))
