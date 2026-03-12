#
# Copyright (C) 2024-2026 ykm888
# 物理修复 3 版：源头解耦分发，锁定 20250711 512MB 救砖模式
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=uboot-mediatek
PKG_RELEASE:=1

# 物理锁定：延续 1 版 hanwckf 分支
PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/ykm888/66.git
PKG_SOURCE_VERSION:=hanwckf-stable-source

PKG_MAINTAINER:=ykm888
PKG_LICENSE:=GPL-2.0
PKG_LICENSE_FILES:=Licenses/gpl-2.0.txt

PKG_BUILD_PARALLEL:=1

# 物理坐标：锁定 20250711 源码文件夹
UBOOT_SRC_DIR:=uboot-mtk-20250711
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(BUILD_VARIANT)/$(PKG_NAME)-$(PKG_SOURCE_VERSION)

include $(INCLUDE_DIR)/u-boot.mk
include $(INCLUDE_DIR)/package.mk

define U-Boot/Default
  BUILD_TARGET:=mediatek
  BUILD_SUBTARGET:=filogic
  UBOOT_CONFIG:=mt7981_nor_emmc_rfb
  UBOOT_IMAGE:=u-boot.bin
endef

# --- 3 版核心源头修复：解耦依赖，防止索引阶段死锁 ---
define U-Boot/mt7981-nor-ddr4
  NAME:=SL-3000 (512MB-Safe-Recovery)
  BUILD_DEVICES:=ykm888_sl-3000
  # 【源头修复】去掉 '+' 号，改为纯包名引用。
  # 这样可以物理绕过 OpenWrt 在 feeds scan 阶段对包顺序的严苛校验，
  # 解决 "arm-trusted-firmware-mediatek does not exist" 的报错。
  DEPENDS:=arm-trusted-firmware-mediatek
  UBOOT_CONFIG:=mt7981_nor_emmc_rfb
endef

UBOOT_TARGETS:=mt7981-nor-ddr4

define Build/Prepare
	$(call Build/Prepare/Default)
	@echo "Physical Surgery: Flattening U-Boot 20250711 Source for v3..."
	# 物理平铺：将子目录源码移动到编译根目录
	if [ -d "$(PKG_BUILD_DIR)/$(UBOOT_SRC_DIR)" ]; then \
		cp -rf $(PKG_BUILD_DIR)/$(UBOOT_SRC_DIR)/* $(PKG_BUILD_DIR)/; \
	fi
	
	# --- 512MB 物理锁定区 ---
	# 物理抹除 1024M 寻址，防止 defconfig 自动重置为大内存模式
	sed -i '/CONFIG_ARM64_VA_BITS_39/d' $(PKG_BUILD_DIR)/configs/mt7981_nor_emmc_rfb_defconfig
	sed -i '/CONFIG_PGTABLE_LEVELS/d' $(PKG_BUILD_DIR)/configs/mt7981_nor_emmc_rfb_defconfig
	
	# 物理修正救砖默认 IP (192.168.31.1)
	sed -i 's/192.168.1.1/192.168.31.1/g' $(PKG_BUILD_DIR)/configs/mt7981_nor_emmc_rfb_defconfig || true

	# 物理清道夫：针对 GCC 13+ 的非法段警告屏蔽
	find $(PKG_BUILD_DIR) -type f -exec sed -i 's/-no-warn-rwx-segments//g' {} + || true
endef

define Package/uboot-mediatek-$(1)/install
	$(INSTALL_DIR) $(STAGING_DIR_IMAGE)
	# --- 3 版物理抓取逻辑：强制双重分发，确保 filogic.mk 智能搜寻成功 ---
	
	if [ -f $(PKG_BUILD_DIR)/u-boot.bin ]; then \
		$(CP) $(PKG_BUILD_DIR)/u-boot.bin $(STAGING_DIR_IMAGE)/$(1)-u-boot.bin; \
		$(CP) $(PKG_BUILD_DIR)/u-boot.bin $(STAGING_DIR_IMAGE)/u-boot.bin; \
	fi
	
	# 物理备份至 recovery 目录
	$(INSTALL_DIR) $(BIN_DIR)/sl3000-recovery
	[ -f $(PKG_BUILD_DIR)/u-boot.bin ] && \
		$(CP) $(PKG_BUILD_DIR)/u-boot.bin $(BIN_DIR)/sl3000-recovery/u-boot.bin
endef

$(eval $(call BuildPackage/U-Boot))
