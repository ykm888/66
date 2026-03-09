#
# Copyright (C) 2024-2026 ykm888
# 物理修复：SL-3000 专用（NOR 引导 + 1024M DDR4 + eMMC 存储）
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=uboot-mediatek
PKG_VERSION:=2024.10
PKG_RELEASE:=1

# 物理锁定：使用你仓库中的救砖分支
PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/ykm888/66.git
PKG_SOURCE_VERSION:=sl3000-uboot-base
PKG_MIRROR_HASH:=skip

PKG_MAINTAINER:=ykm888
PKG_LICENSE:=GPL-2.0
PKG_LICENSE_FILES:=Licenses/README

# 物理依赖：必须依赖主机端的 fiptool 以合成 FIP 包
PKG_BUILD_DEPENDS:=arm-trusted-firmware-tools/host

include $(INCLUDE_DIR)/u-boot.mk
include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/host-build.mk

define U-Boot/Default
  BUILD_TARGET:=mediatek
  UBOOT_IMAGE:=u-boot-mtk.bin
  HIDDEN:=1
endef

# --- 物理修正：适配 NOR+eMMC 混合逻辑 ---
define U-Boot/mt7981_sl_3000-nor-emmc
  NAME:=SL-3000 (NOR-Boot-eMMC-1024M)
  BUILD_SUBTARGET:=filogic
  # 【核心修复】：物理对齐源码 configs/ 下的真实文件名
  UBOOT_CONFIG:=mt7981_nor_emmc_rfb
  # 物理对齐：产物文件名必须与 filogic.mk 的合成逻辑匹配
  UBOOT_IMAGE:=mt7981_sl_3000-nor-u-boot.fip
  BL2_BOOTDEV:=nor
  BL2_SOC:=mt7981
  BL2_DDRTYPE:=ddr4
  # 物理链接：确保先编译 ATF 的 NOR-DDR4 版本
  DEPENDS:=+trusted-firmware-a-mt7981-nor-ddr4
endef

UBOOT_TARGETS := mt7981_sl_3000-nor-emmc

# 物理构建指令：使用 fiptool 将 BL31 与 U-Boot 合体
define Build/fip-image
	$(STAGING_DIR_HOST)/bin/fiptool create \
		--soc-fw $(STAGING_DIR_IMAGE)/mt7981-nor-ddr4-bl31.bin \
		--nt-fw $(PKG_BUILD_DIR)/u-boot.bin \
		$(PKG_BUILD_DIR)/$(UBOOT_IMAGE)
endef

define Build/Compile
	$(call Build/Compile/U-Boot)
	$(call Build/fip-image)
endef

# --- 物理分发逻辑：修复“No such file or directory”报错 ---
define Package/u-boot-mediatek/install
	$(INSTALL_DIR) $(STAGING_DIR_IMAGE) $(BIN_DIR)/sl3000-recovery-kits

	# 1. 物理同步 FIP 到 Staging 目录供 filogic.mk 使用
	$(CP) $(PKG_BUILD_DIR)/$(UBOOT_IMAGE) $(STAGING_DIR_IMAGE)/
	# 物理同步 FIP 到 Bin 目录供用户救砖下载
	$(CP) $(PKG_BUILD_DIR)/$(UBOOT_IMAGE) $(BIN_DIR)/sl3000-recovery-kits/uboot-fip-nor-recovery.bin

	# 2. 物理桥接：将 ATF 生成的 .bin 同步为 .img 
	# 逻辑：既然 filogic.mk 在找 .img，我们在这里物理创建一个副本
	if [ -f $(STAGING_DIR_IMAGE)/mt7981-nor-ddr4-bl2.bin ]; then \
		$(CP) $(STAGING_DIR_IMAGE)/mt7981-nor-ddr4-bl2.bin $(STAGING_DIR_IMAGE)/mt7981-nor-ddr4-bl2.img; \
		$(CP) $(STAGING_DIR_IMAGE)/mt7981-nor-ddr4-bl2.bin $(BIN_DIR)/sl3000-recovery-kits/bl2-nor-ddr4.bin; \
	else \
		echo "WARNING: mt7981-nor-ddr4-bl2.bin not found! Check ATF build." >&2; \
	fi
endef

$(eval $(call BuildPackage/U-Boot))
