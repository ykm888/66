#
# Copyright (C) 2024-2026 ykm888
# 物理修复：SL-3000 U-Boot 零件合成 (NOR+eMMC)
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=uboot-mediatek
PKG_VERSION:=2024.10
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/ykm888/66.git
PKG_SOURCE_VERSION:=sl3000-uboot-base

PKG_MAINTAINER:=ykm888

# 物理依赖：必须依赖主机端工具和我们自己的 ATF 零件
PKG_BUILD_DEPENDS:=arm-trusted-firmware-tools/host arm-trusted-firmware-mediatek

include $(INCLUDE_DIR)/u-boot.mk
include $(INCLUDE_DIR)/package.mk

define U-Boot/Default
  BUILD_TARGET:=mediatek
  UBOOT_IMAGE:=u-boot.bin
  HIDDEN:=1
endef

define U-Boot/mt7981_sl_3000-nor-emmc
  NAME:=SL-3000 (NOR-Boot-eMMC-1024M)
  BUILD_SUBTARGET:=filogic
  UBOOT_CONFIG:=mt7981_nor_emmc_rfb
  # 物理产物名：暂定为 fip.bin 以匹配 filogic.mk
  UBOOT_IMAGE:=fip.bin
  # 物理链接：确保 ATF 先行编译 (注意包名归位)
  DEPENDS:=+arm-trusted-firmware-mediatek-mt7981-nor-ddr4
endef

UBOOT_TARGETS := mt7981_sl_3000-nor-emmc

# --- 物理合成：将 ATF 的 BL31 与 U-Boot 合体 ---
define Build/fip-image
	# 物理定位 ATF 产出的 BL31
	$(STAGING_DIR_HOST)/bin/fiptool create \
		--soc-fw $(STAGING_DIR_IMAGE)/mt7981-nor-ddr4-bl31.bin \
		--nt-fw $(PKG_BUILD_DIR)/u-boot.bin \
		$(PKG_BUILD_DIR)/fip.bin
endef

define Build/Compile
	$(call Build/Compile/U-Boot)
	$(call Build/fip-image)
endef

# --- 物理分发：将零件推送到合成现场 ---
define Package/u-boot-$(1)/install
	$(INSTALL_DIR) $(STAGING_DIR_IMAGE)
	# 物理重命名：确保 filogic.mk 里的 test -f $(STAGING_DIR_IMAGE)/fip.bin 绝对命中
	$(CP) $(PKG_BUILD_DIR)/fip.bin $(STAGING_DIR_IMAGE)/fip.bin
	# 物理备份：供用户下载
	$(INSTALL_DIR) $(BIN_DIR)/sl3000-recovery
	$(CP) $(PKG_BUILD_DIR)/fip.bin $(BIN_DIR)/sl3000-recovery/u-boot-fip.bin
endef

$(eval $(call BuildPackage/U-Boot))
