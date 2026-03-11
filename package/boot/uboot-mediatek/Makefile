#
# Copyright (C) 2024-2026 ykm888
# 物理修复：SL-3000 U-Boot 零件合成 (NOR+eMMC)
# 针对 1024M 内存寻址及 ATF 零件物理对齐
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

# 核心物理依赖：必须确保 ATF 已经产出 bl31.bin，且主机端有 fiptool
PKG_BUILD_DEPENDS:=arm-trusted-firmware-mediatek/host arm-trusted-firmware-mediatek

include $(INCLUDE_DIR)/u-boot.mk
include $(INCLUDE_DIR)/package.mk

# 定义 U-Boot 包的物理零件属性
define Package/u-boot-mediatek/Default
  SECTION:=boot
  CATEGORY:=Bootloaders
  TITLE:=U-Boot for MediaTek MT7981
  URL:=https://www.denx.de/wiki/U-Boot
  HIDDEN:=1
endef

define U-Boot/Default
  BUILD_TARGET:=mediatek
  UBOOT_IMAGE:=u-boot.bin
endef

# SL-3000 专属定义：NOR 启动 + eMMC 存储 + 1024M 内存对齐
define U-Boot/mt7981_sl_3000-nor-emmc
  NAME:=SL-3000 (NOR-Boot-eMMC-1024M)
  BUILD_SUBTARGET:=filogic
  UBOOT_CONFIG:=mt7981_nor_emmc_rfb
  UBOOT_IMAGE:=fip.bin
  # 物理零件桥梁：在此处锁定对 ATF 产出包的依赖
  DEPENDS:=+arm-trusted-firmware-mediatek-mt7981-nor-ddr4
endef

UBOOT_TARGETS := mt7981_sl_3000-nor-emmc

# --- 核心物理合成逻辑 ---
define Build/fip-image
	@echo "Physical Synthesis: Merging ATF BL31 with U-Boot..."
	# 检查关键零件是否存在
	[ -f $(STAGING_DIR_IMAGE)/mt7981-nor-ddr4-bl31.bin ] || { \
		echo "ERROR: ATF BL31 not found at $(STAGING_DIR_IMAGE)/mt7981-nor-ddr4-bl31.bin"; \
		exit 1; \
	}
	# 使用主机端 fiptool 将 ATF 的 BL31 与 U-Boot 的 NT-FW (u-boot.bin) 物理合体
	$(STAGING_DIR_HOST)/bin/fiptool create \
		--soc-fw $(STAGING_DIR_IMAGE)/mt7981-nor-ddr4-bl31.bin \
		--nt-fw $(PKG_BUILD_DIR)/u-boot.bin \
		$(PKG_BUILD_DIR)/fip.bin
endef

define Build/Compile
	$(call Build/Compile/U-Boot)
	$(call Build/fip-image)
endef

# --- 物理安装与分发 ---
define Package/u-boot-$(1)/install
	$(INSTALL_DIR) $(STAGING_DIR_IMAGE)
	# 物理同步：将合成后的 fip.bin 分发到镜像构建现场
	$(CP) $(PKG_BUILD_DIR)/fip.bin $(STAGING_DIR_IMAGE)/fip.bin
	$(CP) $(PKG_BUILD_DIR)/fip.bin $(STAGING_DIR_IMAGE)/$(1)-fip.bin
	
	# 物理备份：存放在 recovery 目录供后期手动救砖提取
	$(INSTALL_DIR) $(BIN_DIR)/sl3000-recovery
	$(CP) $(PKG_BUILD_DIR)/fip.bin $(BIN_DIR)/sl3000-recovery/u-boot-fip.bin
endef

$(foreach var,$(UBOOT_TARGETS), \
  $(eval $(call BuildPackage/U-Boot,$(var))) \
)
