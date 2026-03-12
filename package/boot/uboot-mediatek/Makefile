#
# Copyright (C) 2024-2026 ykm888
# 物理修复：定向使用 20230718 版本 U-Boot 并对齐 hanwckf 零件
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=uboot-mediatek
PKG_RELEASE:=1

# 物理锁定：使用你刚刚同步成功的 hanwckf 稳定源码分支
PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/ykm888/66.git
PKG_SOURCE_VERSION:=hanwckf-stable-source

PKG_MAINTAINER:=ykm888
PKG_LICENSE:=GPL-2.0
PKG_LICENSE_FILES:=Licenses/gpl-2.0.txt

PKG_BUILD_PARALLEL:=1

# 物理坐标定位：精准锁定三个文件夹中的黄金版本
UBOOT_SRC_DIR:=uboot-mtk-20230718-09eda825
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(BUILD_VARIANT)/$(PKG_NAME)-$(PKG_SOURCE_VERSION)

include $(INCLUDE_DIR)/u-boot.mk
include $(INCLUDE_DIR)/package.mk

define U-Boot/Default
  BUILD_TARGET:=mediatek
  BUILD_SUBTARGET:=filogic
  # 物理对齐：使用该版本自带的 RFB 默认配置
  UBOOT_CONFIG:=mt7981_nor_emmc_rfb
  UBOOT_IMAGE:=u-boot.bin
endef

# 物理修复核心：此处的名称必须与 ATF Makefile 中定义的 VARIANT 严格物理对应
define U-Boot/mt7981-nor-ddr4
  NAME:=SL-3000 (NOR-DDR4-1024M)
  BUILD_DEVICES:=ykm888_sl-3000
  # 物理链接：指向刚才修改好的 ATF 零件
  DEPENDS:=+arm-trusted-firmware-mediatek-mt7981-nor-ddr4
  UBOOT_CONFIG:=mt7981_nor_emmc_rfb
endef

UBOOT_TARGETS:=mt7981-nor-ddr4

define Build/Prepare
	$(call Build/Prepare/Default)
	@echo "Physical Surgery: Flattening U-Boot 20230718 Source..."
	# 物理手术：将子目录内的 U-Boot 源码物理平铺到编译根目录
	if [ -d "$(PKG_BUILD_DIR)/$(UBOOT_SRC_DIR)" ]; then \
		cp -rf $(PKG_BUILD_DIR)/$(UBOOT_SRC_DIR)/* $(PKG_BUILD_DIR)/; \
	fi
	
	# 物理注入 1024M 寻址补丁 (防止内核启动到一半死机)
	echo "CONFIG_ARM64_VA_BITS_39=y" >> $(PKG_BUILD_DIR)/configs/mt7981_nor_emmc_rfb_defconfig
	echo "CONFIG_PGTABLE_LEVELS=3" >> $(PKG_BUILD_DIR)/configs/mt7981_nor_emmc_rfb_defconfig
	
	# 物理修正救砖 IP (对齐 SL-3000 192.168.31.1 惯例)
	sed -i 's/192.168.1.1/192.168.31.1/g' $(PKG_BUILD_DIR)/configs/mt7981_nor_emmc_rfb_defconfig || true

	# 物理清道夫：抹除 GCC 13+ 不识别的链接参数
	find $(PKG_BUILD_DIR) -type f -exec sed -i 's/-no-warn-rwx-segments//g' {} + || true
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
