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

# 物理依赖：必须依赖针对 DDR4 编译的 TF-A 和 fiptool 主机工具
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
  # 物理指向：源码 configs/mt7981_emmc_defconfig
  UBOOT_CONFIG:=mt7981_emmc
  # 物理对齐：必须匹配 filogic.mk 中 Build/mt7981-bl31-uboot 宏的规律
  UBOOT_IMAGE:=mt7981_sl_3000-emmc-u-boot.fip
  BL2_BOOTDEV:=emmc
  BL2_SOC:=mt7981
  # 物理核心：锁定针对 P3A8GL4MLF-GJN 的 DDR4 训练脚本
  BL2_DDRTYPE:=ddr4
  # 物理依赖：强制链接 TF-A 产物，确保编译顺序正确
  DEPENDS:=+trusted-firmware-a-mt7981-emmc-ddr4
endef

UBOOT_TARGETS := mt7981_sl_3000-emmc

# 物理构建指令：使用 fiptool 将 U-Boot 与 TF-A 的 BL31 合体为 FIP 包
define Build/fip-image
	$(STAGING_DIR_HOST)/bin/fiptool create \
		--soc-fw $(STAGING_DIR_IMAGE)/mt7981-emmc-ddr4-bl31.bin \
		--nt-fw $(PKG_BUILD_DIR)/u-boot.bin \
		$(PKG_BUILD_DIR)/$(UBOOT_IMAGE)
endef

define Build/Compile
	$(call Build/Compile/U-Boot)
ifeq ($(UBOOT_IMAGE),mt7981_sl_3000-emmc-u-boot.fip)
	$(call Build/fip-image)
endif
endef

# 物理安装与救砖备份：将产物分发到 Staging 和 Bin 目录
define Package/u-boot-mediatek/install
	$(INSTALL_DIR) $(STAGING_DIR_IMAGE) $(BIN_DIR)/sl3000-recovery-kits
	
	# 1. 物理同步 FIP (U-Boot 核心)
	$(CP) $(PKG_BUILD_DIR)/$(UBOOT_IMAGE) $(STAGING_DIR_IMAGE)/
	$(CP) $(PKG_BUILD_DIR)/$(UBOOT_IMAGE) $(BIN_DIR)/sl3000-recovery-kits/uboot-fip-recovery.bin

	# 2. 物理转换与导出 BL2 (救砖心脏)
	# 将 TF-A 生成的 .bin 转换为 .img 供 filogic.mk 调用，同时备份到 bin 目录供烧录器使用
	if [ -f $(STAGING_DIR_IMAGE)/mt7981-emmc-ddr4-bl2.bin ]; then \
		$(CP) $(STAGING_DIR_IMAGE)/mt7981-emmc-ddr4-bl2.bin $(STAGING_DIR_IMAGE)/mt7981-emmc-ddr4-bl2.img; \
		$(CP) $(STAGING_DIR_IMAGE)/mt7981-emmc-ddr4-bl2.bin $(BIN_DIR)/sl3000-recovery-kits/bl2-emmc-ddr4.bin; \
	fi
endef

# 默认安装逻辑（兼容性保留）
define Package/u-boot/install/default
	$(INSTALL_DIR) $(1)
	$(CP) $(PKG_BUILD_DIR)/$(UBOOT_IMAGE) $(1)/
endef

$(eval $(call BuildPackage/U-Boot))
