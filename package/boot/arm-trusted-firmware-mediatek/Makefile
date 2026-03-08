include $(TOPDIR)/rules.mk

PKG_NAME:=arm-trusted-firmware-mediatek
PKG_RELEASE:=2

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL=https://github.com/mtk-openwrt/arm-trusted-firmware.git
PKG_SOURCE_DATE:=2023-07-24
PKG_SOURCE_VERSION:=00ac6db375b76e57e1f5e9e9bffa033e907c3581
PKG_MIRROR_HASH:=74fc18395532c4292f530da8d00fa1873ada4e05e600c0077a7b7f85ace0d913

PKG_MAINTAINER:=Daniel Golle <daniel@makrotopia.org>

include $(INCLUDE_DIR)/kernel.mk
include $(INCLUDE_DIR)/trusted-firmware-a.mk
include $(INCLUDE_DIR)/package.mk

define Trusted-Firmware-A/Default
  BUILD_TARGET:=mediatek
  TFA_IMAGE:=bl2.img bl31.bin
  PLAT:=mt7981
endef

define Trusted-Firmware-A/mt7981-nor-ddr3
  NAME:=MediaTek MT7981 (SPI-NOR, DDR3)
  BOOT_DEVICE:=nor
  BUILD_SUBTARGET:=filogic
  DDR_TYPE:=ddr3
endef

define Trusted-Firmware-A/mt7981-nor-ddr4
  NAME:=MediaTek MT7981 (SPI-NOR, DDR4)
  BOOT_DEVICE:=nor
  BUILD_SUBTARGET:=filogic
  DDR_TYPE:=ddr4
endef

TFA_TARGETS:= \
	mt7981-nor-ddr3 \
	mt7981-nor-ddr4

TFA_MAKE_FLAGS += \
	BOOT_DEVICE=$(BOOT_DEVICE) \
	$(if $(findstring ddr4,$(DDR_TYPE)),DRAM_USE_DDR4=1) \
	all

$(eval $(call BuildPackage/Trusted-Firmware-A))
