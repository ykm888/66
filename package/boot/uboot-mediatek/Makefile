include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

# 物理锁定 U-Boot 版本与哈希
PKG_VERSION:=2023.07.02
PKG_HASH:=6b6a48581c14abb0f95bd87c1af4d740922406d7b801002a9f94727fdde021d5
PKG_BUILD_DEPENDS:=arm-trusted-firmware-tools/host

UBOOT_USE_INTREE_DTC:=1

include $(INCLUDE_DIR)/u-boot.mk
include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/host-build.mk

define U-Boot/Default
  BUILD_TARGET:=mediatek
  UBOOT_IMAGE:=u-boot-mtk.bin
  HIDDEN:=1
endef

# 【物理核心】：唯一保留的 SL-3000 eMMC 定义
define U-Boot/mt7981_sl_3000-emmc
  NAME:=SL-3000 (eMMC-1024M)
  BUILD_SUBTARGET:=filogic
  BUILD_DEVICES:=sl_3000-emmc
  UBOOT_CONFIG:=mt7981_sl_3000-emmc
  UBOOT_IMAGE:=u-boot.fip
  BL2_BOOTDEV:=emmc
  BL2_SOC:=mt7981
  BL2_DDRTYPE:=ddr3
  DEPENDS:=+trusted-firmware-a-mt7981-emmc-ddr3
endef

# 物理锁定编译目标，仅此一个
UBOOT_TARGETS := \
	mt7981_sl_3000-emmc

ifdef CONFIG_TARGET_mediatek
UBOOT_MAKE_FLAGS += $(UBOOT_IMAGE:.fip=.bin)
endif

define Build/fip-image
	$(STAGING_DIR_HOST)/bin/fiptool create \
		--soc-fw $(STAGING_DIR_IMAGE)/$(if $(BL2_SOC),$(BL2_SOC),$(BUILD_SUBTARGET))-$(BL2_BOOTDEV)-$(if $(BL2_DDRTYPE),$(BL2_DDRTYPE)-)$(if $(BL2_DDRBLOB),$(BL2_DDRBLOB)ddr-)bl31.bin \
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

# 物理屏蔽安装到 bindir，由 target/linux/mediatek/image/*.mk 接管
ifdef CONFIG_TARGET_mediatek
define Package/u-boot/install
endef
endif

define Build/InstallDev
	$(INSTALL_DIR) $(STAGING_DIR_IMAGE)
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/$(UBOOT_IMAGE) $(STAGING_DIR_IMAGE)/$(BUILD_VARIANT)-$(UBOOT_IMAGE)
endef

$(eval $(call BuildPackage/U-Boot))
