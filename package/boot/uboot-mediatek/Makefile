# SPDX-License-Identifier: GPL-2.0-only
include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

# 自定义U-Boot配置（指向你的仓库）
PKG_NAME:=uboot-mediatek
PKG_VERSION:=custom
PKG_RELEASE:=1
PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/ykm888/66.git
PKG_SOURCE_VERSION:=sl3000-uboot-base  # 你的目标分支
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_MIRROR_HASH:=skip  # 跳过哈希校验

# 依赖配置
PKG_BUILD_DEPENDS:=arm-trusted-firmware-tools/host

UBOOT_USE_INTREE_DTC:=1

include $(INCLUDE_DIR)/u-boot.mk
include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/host-build.mk

# 仅保留你的SL-3000设备定义
define U-Boot/mt7981_sl_3000-emmc
  NAME:=SL-3000 (eMMC)
  BUILD_TARGET:=mediatek
  BUILD_SUBTARGET:=filogic
  BUILD_DEVICES:=sl_3000-emmc
  UBOOT_CONFIG:=mt7981_emmc  # 对应你的defconfig
  UBOOT_IMAGE:=u-boot.fip
  BL2_BOOTDEV:=emmc
  BL2_SOC:=mt7981
  BL2_DDRTYPE:=ddr3
  DEPENDS:=+trusted-firmware-a-mt7981-emmc-ddr3
endef

# 仅包含你的设备编译目标
UBOOT_TARGETS := mt7981_sl_3000-emmc

# FIP镜像合成（针对你的设备）
define Build/fip-image
	BL2_BIN="$(STAGING_DIR_IMAGE)/mt7981-emmc-ddr3-bl2.bin" ; \
	BL31_BIN="$(STAGING_DIR_IMAGE)/mt7981-emmc-ddr3-bl31.bin" ; \
	if [ ! -f "$$BL2_BIN" ]; then \
		echo "ERROR: BL2 not found at $$BL2_BIN"; exit 1; \
	fi ; \
	if [ ! -f "$$BL31_BIN" ]; then \
		echo "ERROR: BL31 not found at $$BL31_BIN"; exit 1; \
	fi ; \
	$(STAGING_DIR_HOST)/bin/fiptool create \
		--tb-fw $$BL2_BIN \
		--soc-fw $$BL31_BIN \
		--nt-fw $(PKG_BUILD_DIR)/mt7981_sl_3000-emmc/u-boot.bin \
		$(PKG_BUILD_DIR)/mt7981_sl_3000-emmc/u-boot.fip
endef

define Build/Compile
	$(call Build/Compile/U-Boot)
	$(call Build/fip-image)  # 生成你的设备所需的FIP镜像
endef

define Build/InstallDev
	$(INSTALL_DIR) $(STAGING_DIR_HOST)/share/u-boot
	$(CP) $(PKG_BUILD_DIR)/mt7981_sl_3000-emmc/$(UBOOT_IMAGE) \
		$(STAGING_DIR_HOST)/share/u-boot/sl_3000-emmc-u-boot.fip
endef

$(eval $(call BuildPackage,U-Boot))
