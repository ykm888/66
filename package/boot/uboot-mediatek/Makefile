#
# Copyright (C) 2024 ykm888
# 物理修正：针对 SL-3000 NOR-BOOT + eMMC-STORAGE + 1024M 架构
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=uboot-mediatek
PKG_VERSION:=2024.10
PKG_RELEASE:=1

# 物理锁定：严格使用你指定的 U-Boot 源码分支
PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/ykm888/66.git
PKG_SOURCE_VERSION:=sl3000-uboot-base
PKG_MIRROR_HASH:=skip

PKG_MAINTAINER:=ykm888
PKG_LICENSE:=GPL-2.0
PKG_LICENSE_FILES:=Licenses/README

# 物理依赖：必须依赖主机端的 fiptool 封包工具
PKG_BUILD_DEPENDS:=arm-trusted-firmware-tools/host

include $(INCLUDE_DIR)/u-boot.mk
include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/host-build.mk

define U-Boot/Default
  BUILD_TARGET:=mediatek
  UBOOT_IMAGE:=u-boot-mtk.bin
  HIDDEN:=1
endef

# --- 物理修正：适配 NOR 引导逻辑 ---
define U-Boot/mt7981_sl_3000-nor
  NAME:=SL-3000 (NOR-Boot-1024M)
  BUILD_SUBTARGET:=filogic
  # 物理指向：源码中针对 NOR 启动的 defconfig
  UBOOT_CONFIG:=mt7981_nor
  # 物理对齐：产物文件名必须与 filogic.mk 匹配
  UBOOT_IMAGE:=mt7981_sl_3000-nor-u-boot.fip
  # 【核心修正】物理引导介质锁定为 nor
  BL2_BOOTDEV:=nor
  BL2_SOC:=mt7981
  # 物理核心：锁定针对 DDR4 (1024M) 的初始化脚本
  BL2_DDRTYPE:=ddr4
  # 物理依赖：强制链接 NOR 版的 TF-A
  DEPENDS:=+trusted-firmware-a-mt7981-nor-ddr4
endef

UBOOT_TARGETS := mt7981_sl_3000-nor

# 物理构建指令：将 U-Boot 与 NOR 版 BL31 合体
define Build/fip-image
	$(STAGING_DIR_HOST)/bin/fiptool create \
		--soc-fw $(STAGING_DIR_IMAGE)/mt7981-nor-ddr4-bl31.bin \
		--nt-fw $(PKG_BUILD_DIR)/u-boot.bin \
		$(PKG_BUILD_DIR)/$(UBOOT_IMAGE)
endef

define Build/Compile
	$(call Build/Compile/U-Boot)
ifeq ($(UBOOT_IMAGE),mt7981_sl_3000-nor-u-boot.fip)
	$(call Build/fip-image)
endif
endef

# --- 物理分发逻辑修正 ---
define Package/u-boot-mediatek/install
	$(INSTALL_DIR) $(STAGING_DIR_IMAGE) $(BIN_DIR)/sl3000-recovery-kits
	
	# 1. 物理同步 FIP (U-Boot 核心)
	$(CP) $(PKG_BUILD_DIR)/$(UBOOT_IMAGE) $(STAGING_DIR_IMAGE)/
	$(CP) $(PKG_BUILD_DIR)/$(UBOOT_IMAGE) $(BIN_DIR)/sl3000-recovery-kits/uboot-fip-nor-recovery.bin

	# 2. 物理转换与导出 BL2 (NOR 救砖心脏)
	# 确保生成的 .img 供 filogic.mk 最终合成 32MB 固件
	if [ -f $(STAGING_DIR_IMAGE)/mt7981-nor-ddr4-bl2.bin ]; then \
		$(CP) $(STAGING_DIR_IMAGE)/mt7981-nor-ddr4-bl2.bin $(STAGING_DIR_IMAGE)/mt7981-nor-ddr4-bl2.img; \
		$(CP) $(STAGING_DIR_IMAGE)/mt7981-nor-ddr4-bl2.bin $(BIN_DIR)/sl3000-recovery-kits/bl2-nor-ddr4.bin; \
	fi
endef

define Package/u-boot/install/default
	$(INSTALL_DIR) $(1)
	$(CP) $(PKG_BUILD_DIR)/$(UBOOT_IMAGE) $(1)/
endef

$(eval $(call BuildPackage/U-Boot))
