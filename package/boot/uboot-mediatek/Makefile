#
# Copyright (C) 2024 ykm888
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=uboot-mediatek
PKG_VERSION:=2024.10
PKG_RELEASE:=1

# 物理锁定：指向你维护的 U-Boot 源码分支
PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/ykm888/66.git
PKG_SOURCE_VERSION:=sl3000-uboot-base
PKG_MIRROR_HASH:=skip

PKG_MAINTAINER:=ykm888
PKG_LICENSE:=GPL-2.0
PKG_LICENSE_FILES:=Licenses/README

# 物理依赖：必须依赖针对 DDR4 编译的 TF-A
PKG_BUILD_DEPENDS:=arm-trusted-firmware-tools/host

include $(INCLUDE_DIR)/u-boot.mk
include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/host-build.mk

define U-Boot/Default
  BUILD_TARGET:=mediatek
  UBOOT_IMAGE:=u-boot-mtk.bin
  HIDDEN:=1
endef

# 物理适配：司络 SL-3000 1024M DDR4 + eMMC 版本
define U-Boot/mt7981_sl_3000-emmc
  NAME:=SL-3000 (DDR4-1024M-eMMC)
  BUILD_SUBTARGET:=filogic
  UBOOT_CONFIG:=mt7981_sl_3000-emmc
  UBOOT_IMAGE:=u-boot.fip
  BL2_BOOTDEV:=emmc
  BL2_SOC:=mt7981
  # 【物理核心】必须锁定 DDR4，否则无法初始化 P3A8GL4MLF 颗粒
  BL2_DDRTYPE:=ddr4
  # 物理链接 TF-A 镜像
  DEPENDS:=+trusted-firmware-a-mt7981-emmc-ddr4
endef

UBOOT_TARGETS := mt7981_sl_3000-emmc

# 物理构建指令：生成 FIP (Firmware Image Package)
define Build/fip-image
	$(STAGING_DIR_HOST)/bin/fiptool create \
		--soc-fw $(STAGING_DIR_IMAGE)/mt7981-emmc-ddr4-bl31.bin \
		--nt-fw $(PKG_BUILD_DIR)/u-boot.bin \
		$(PKG_BUILD_DIR)/u-boot.fip
endef

define Build/Compile
	$(call Build/Compile/U-Boot)
ifeq ($(UBOOT_IMAGE),u-boot.fip)
	$(call Build/fip-image)
endif
endef

# 物理安装：将 BL2 和 FIP 拷贝至编译产物目录
define Package/u-boot/install/default
	$(INSTALL_DIR) $(1)
	$(CP) $(PKG_BUILD_DIR)/$(UBOOT_IMAGE) $(1)/
	# 救砖关键：物理导出适配 DDR4 的 BL2 镜像
	[ -f $(STAGING_DIR_IMAGE)/mt7981-emmc-ddr4-bl2.bin ] && \
		$(CP) $(STAGING_DIR_IMAGE)/mt7981-emmc-ddr4-bl2.bin $(1)/sl3000-emmc-ddr4-bl2.bin
endef

$(eval $(call BuildPackage/U-Boot))
