#
# Copyright (C) 2024-2026 ykm888
# 物理修复：对齐 hanwckf 稳定 ATF 源依赖 & 锁定 SL-3000 1024M 编译位
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=uboot-mediatek
PKG_RELEASE:=1

# 物理锁定：使用你仓库中锁定的 U-Boot 分支
PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/ykm888/66.git
PKG_SOURCE_VERSION:=sl3000-uboot-base

PKG_MAINTAINER:=ykm888
PKG_LICENSE:=GPL-2.0
PKG_LICENSE_FILES:=Licenses/gpl-2.0.txt

PKG_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/u-boot.mk
include $(INCLUDE_DIR)/package.mk

define U-Boot/Default
  BUILD_TARGET:=mediatek
  BUILD_SUBTARGET:=filogic
  UBOOT_CONFIG:=mt7981_sl3000_defconfig
  UBOOT_IMAGE:=u-boot.bin
endef

# 物理修复核心：此处的名称必须与 ATF Makefile 中定义的 VARIANT 严格物理对应
define U-Boot/mt7981-nor-ddr4
  NAME:=SL-3000 (NOR-DDR4-1024M)
  BUILD_DEVICES:=ykm888_sl-3000
  # 物理链接：指向 hanwckf 源产出的 ATF 零件
  DEPENDS:=+arm-trusted-firmware-mediatek-mt7981-nor-ddr4
  UBOOT_CONFIG:=mt7981_sl3000_defconfig
endef

UBOOT_TARGETS:=mt7981-nor-ddr4

define Build/Prepare
	$(call Build/Prepare/Default)
	# 物理清道夫：同步清理 U-Boot 源码中可能存在的非法参数
	find $(PKG_BUILD_DIR) -type f -name "Makefile" -o -name "*.mk" | xargs sed -i 's/-no-warn-rwx-segments//g' || true
endef

define Build/Compile
	$(call Build/Compile/Default)
endef

define Package/uboot-mediatek-$(1)/install
	$(INSTALL_DIR) $(STAGING_DIR_IMAGE)
	# 物理产出：将 u-boot.bin 存入分发目录
	$(CP) $(PKG_BUILD_DIR)/u-boot.bin $(STAGING_DIR_IMAGE)/$(1)-u-boot.bin
	
	# 物理备份：执行救砖包工序 (sl3000-recovery)
	$(INSTALL_DIR) $(BIN_DIR)/sl3000-recovery
	$(CP) $(PKG_BUILD_DIR)/u-boot.bin $(BIN_DIR)/sl3000-recovery/u-boot.bin
endef

$(eval $(call BuildPackage/U-Boot))
