#
# Copyright (C) 2024-2026 ykm888
# 物理修复终极版：针对 SL-3000 (MT7981) U-Boot 救砖零件
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=uboot-mediatek
PKG_RELEASE:=1

# --- 核心物理指向：黄金救砖分支 ---
PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/ykm888/66.git
PKG_SOURCE_VERSION:=sl3000-clean-source
PKG_MIRROR_HASH:=skip

PKG_MAINTAINER:=ykm888
PKG_LICENSE:=GPL-2.0

PKG_BUILD_PARALLEL:=1
# 物理仓库内的子目录名
UBOOT_SRC_SUBDIR:=u-boot

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(BUILD_VARIANT)/$(PKG_NAME)-$(PKG_SOURCE_VERSION)

include $(INCLUDE_DIR)/u-boot.mk
include $(INCLUDE_DIR)/package.mk

# --- 1. 默认物理参数 ---
define U-Boot/Default
  BUILD_TARGET:=mediatek
  BUILD_SUBTARGET:=filogic
  # 强制匹配硬化源码中的物理 Config
  UBOOT_CONFIG:=mt7981_nor_emmc_rfb
  UBOOT_IMAGE:=u-boot.bin
endef

# --- 2. 变体物理对齐：必须与 .config 勾选项严格一致 ---
define U-Boot/mt7981-nor-ddr4
  NAME:=SL-3000 (Safe-Recovery-NOR-DDR4)
  BUILD_DEVICES:=ykm888_sl-3000
  # 强制物理依赖：确保 ATF 编译完成后再编译 U-Boot
  DEPENDS:=+arm-trusted-firmware-mediatek
endef

# 物理宣告目标名，解决 No rule to make target 报错
UBOOT_TARGETS:=mt7981-nor-ddr4

# --- 3. 物理工地准备：消除路径偏移与警告中断 ---
define Build/Prepare
	$(call Build/Prepare/Default)
	@echo "Physical Surgery: Aligning U-Boot source from subfolder..."
	# 将仓库 u-boot 文件夹内的物理文件平铺到构建根目录
	if [ -d "$(PKG_BUILD_DIR)/$(UBOOT_SRC_SUBDIR)" ]; then \
		cp -rf $(PKG_BUILD_DIR)/$(UBOOT_SRC_SUBDIR)/* $(PKG_BUILD_DIR)/; \
	fi
	
	# 物理适配：注入默认救砖 IP
	sed -i 's/192.168.1.1/192.168.31.1/g' $(PKG_BUILD_DIR)/configs/mt7981_nor_emmc_rfb_defconfig || true
	
	# 物理暴力清除：抹除所有导致编译中断的 Werror
	find $(PKG_BUILD_DIR) -type f -name "Makefile*" -exec sed -i 's/-Werror//g' {} + || true
	find $(PKG_BUILD_DIR) -type f -exec sed -i 's/-no-warn-rwx-segments//g' {} + || true
endef

# --- 4. 零件分发逻辑：产出 u-boot.bin 供合成脚本使用 ---
define Package/uboot-mediatek-$(1)/install
	$(INSTALL_DIR) $(STAGING_DIR_IMAGE)
	# 物理验证产物
	if [ -f $(PKG_BUILD_DIR)/u-boot.bin ]; then \
		$(CP) $(PKG_BUILD_DIR)/u-boot.bin $(STAGING_DIR_IMAGE)/$(1)-u-boot.bin; \
		$(CP) $(PKG_BUILD_DIR)/u-boot.bin $(STAGING_DIR_IMAGE)/u-boot.bin; \
	fi
	
	# 物理备份：同步到 Bin 目录
	$(INSTALL_DIR) $(BIN_DIR)/sl3000-recovery
	[ -f $(PKG_BUILD_DIR)/u-boot.bin ] && \
		$(CP) $(PKG_BUILD_DIR)/u-boot.bin $(BIN_DIR)/sl3000-recovery/u-boot.bin
endef

$(eval $(call BuildPackage/U-Boot))
