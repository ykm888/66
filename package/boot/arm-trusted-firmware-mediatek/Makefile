#
# Copyright (C) 2024-2026 ykm888
# 物理修复：针对 SL-3000 (NOR-Boot + 1024M DDR4) 救砖架构
#

include $(TOPDIR)/rules.mk

PKG_NAME:=arm-trusted-firmware-mediatek
PKG_RELEASE:=2

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/mtk-openwrt/arm-trusted-firmware.git
PKG_SOURCE_DATE:=2023-07-24
PKG_SOURCE_VERSION:=00ac6db375b76e57e1f5e9e9bffa033e907c3581
PKG_MIRROR_HASH:=74fc18395532c4292f530da8d00fa1873ada4e05e600c0077a7b7f85ace0d913

PKG_MAINTAINER:=Daniel Golle <daniel@makrotopia.org>

include $(INCLUDE_DIR)/kernel.mk
include $(INCLUDE_DIR)/trusted-firmware-a.mk
include $(INCLUDE_DIR)/package.mk

define Trusted-Firmware-A/Default
  BUILD_TARGET:=mediatek
  # 物理修正：显式声明需要同步的产物，包含 U-Boot 需要的 bin 和合成脚本需要的 img
  TFA_IMAGE:=bl2.bin bl2.img bl31.bin
  PLAT:=mt7981
endef

# --- 物理核心：定义 SL-3000 (NOR-DDR4) 编译目标 ---
define Trusted-Firmware-A/mt7981-nor-ddr4
  NAME:=MediaTek MT7981 (SPI-NOR, DDR4-1024M)
  BOOT_DEVICE:=nor
  BUILD_SUBTARGET:=filogic
  DDR_TYPE:=ddr4
endef

TFA_TARGETS:= \
	mt7981-nor-ddr4

# 物理修正：确保 DRAM_USE_DDR4 参数物理传递给编译器，用于初始化 1GB 内存
TFA_MAKE_FLAGS += \
	BOOT_DEVICE=$(BOOT_DEVICE) \
	$(if $(findstring ddr4,$(DDR_TYPE)),DRAM_USE_DDR4=1) \
	all

# --- 物理安装逻辑：解决 "No such file or directory" 报错 ---
# 此段代码将产物物理投送到 Staging 目录，并统一命名规范
define Package/trusted-firmware-a-mediatek/install
	$(INSTALL_DIR) $(STAGING_DIR_IMAGE)
	# 物理拷贝 BL2 (救砖心脏)
	$(CP) $(PKG_BUILD_DIR)/build/$(PLAT)/release/bl2.bin $(STAGING_DIR_IMAGE)/$(1)-bl2.bin
	$(CP) $(PKG_BUILD_DIR)/build/$(PLAT)/release/bl2.bin $(STAGING_DIR_IMAGE)/$(1)-bl2.img
	# 物理拷贝 BL31 (电源管理/多核协调)
	$(CP) $(PKG_BUILD_DIR)/build/$(PLAT)/release/bl31.bin $(STAGING_DIR_IMAGE)/$(1)-bl31.bin
endef

$(eval $(call BuildPackage/Trusted-Firmware-A))
