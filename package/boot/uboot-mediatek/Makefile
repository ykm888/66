include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_VERSION:=2024.10
PKG_HASH:=b28daf4ac17e43156363078bf510297584137f6df50fced9b12df34f61a92fb0
PKG_BUILD_DEPENDS:=!(TARGET_ramips||TARGET_mediatek_mt7623):arm-trusted-firmware-tools/host

UBOOT_USE_INTREE_DTC:=1

include $(INCLUDE_DIR)/u-boot.mk
include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/host-build.mk

define U-Boot/Default
  BUILD_TARGET:=mediatek
  UBOOT_IMAGE:=u-boot-mtk.bin
  HIDDEN:=1
endef

# 物理死锁：SL-3000 EMMC 唯一救砖定义
define U-Boot/mt7981_sl_3000-emmc
  NAME:=SL 3000 (eMMC)
  BUILD_SUBTARGET:=filogic
  BUILD_DEVICES:=sl_3000-emmc
  UBOOT_CONFIG:=mt7981_sl_3000-emmc
  UBOOT_IMAGE:=u-boot.fip
  BL2_BOOTDEV:=emmc
  BL2_SOC:=mt7981
  BL2_DDRTYPE:=ddr3
  DEPENDS:=+trusted-firmware-a-mt7981-emmc-ddr3
endef

# 物理物理清单：彻底删除 ASR3000 等无关设备
UBOOT_TARGETS := \
	mt7981_sl_3000-emmc

UBOOT_CUSTOMIZE_CONFIG := \
	--disable TOOLS_KWBIMAGE \
	--disable TOOLS_LIBCRYPTO \
	--disable TOOLS_MKEFICAPSULE \
	--enable SERIAL_RX_BUFFER \
	--set-val SERIAL_RX_BUFFER_SIZE 256

ifdef CONFIG_TARGET_mediatek
UBOOT_MAKE_FLAGS += $(UBOOT_IMAGE:.fip=.bin)
endif

# 物理合成：FIP 镜像核心驱动逻辑
define Build/fip-image
	$(STAGING_DIR_HOST)/bin/fiptool create \
		--soc-fw $(STAGING_DIR_IMAGE)/mt7981-emmc-ddr3-bl31.bin \
		--nt-fw $(PKG_BUILD_DIR)/u-boot.bin \
		$(PKG_BUILD_DIR)/u-boot.fip
endef

define Build/Configure
	$(call Build/Configure/U-Boot)
	sed -i 's/CONFIG_TOOLS_LIBCRYPTO=y/# CONFIG_TOOLS_LIBCRYPTO is not set/' $(PKG_BUILD_DIR)/.config
endef

define Build/Compile
	$(call Build/Compile/U-Boot)
ifeq ($(UBOOT_IMAGE),u-boot.fip)
	$(call Build/fip-image)
endif
endef

ifdef CONFIG_TARGET_mediatek
define Package/u-boot/install
endef
endif

define Build/InstallDev
	$(INSTALL_DIR) $(STAGING_DIR_IMAGE)
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/$(UBOOT_IMAGE) $(STAGING_DIR_IMAGE)/$(BUILD_VARIANT)-$(UBOOT_IMAGE)
endef

$(eval $(call BuildPackage/U-Boot))
