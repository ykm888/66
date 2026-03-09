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

# --- 物理修正：适配 NOR+eMMC 混合逻辑 ---
define U-Boot/mt7981_sl_3000-nor-emmc
  NAME:=SL-3000 (NOR-Boot-eMMC-1024M)
  BUILD_SUBTARGET:=filogic
  # 【核心修复】：必须与源码 configs/ 下的文件名完全对齐（去掉 _defconfig 后缀）
  UBOOT_CONFIG:=mt7981_nor_emmc_rfb
  # 物理对齐：产物文件名必须与 filogic.mk 匹配
  UBOOT_IMAGE:=mt7981_sl_3000-nor-u-boot.fip
  # 物理引导介质锁定为 nor (用于从 NOR 启动 BL2)
  BL2_BOOTDEV:=nor
  BL2_SOC:=mt7981
  # 物理核心：1024M 内存通常对应 ddr4 初始化
  BL2_DDRTYPE:=ddr4
  # 物理依赖：强制链接由 trusted-firmware-a 编译出的二进制包
  DEPENDS:=+trusted-firmware-a-mt7981-nor-ddr4
endef

# 修改变量名以匹配上面的定义
UBOOT_TARGETS := mt7981_sl_3000-nor-emmc

# 物理构建指令：将 U-Boot 与 NOR 版 BL31 合体生成 FIP
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

# --- 物理分发逻辑修正 ---
define Package/u-boot-mediatek/install
	$(INSTALL_DIR) $(STAGING_DIR_IMAGE) $(BIN_DIR)/sl3000-recovery-kits
	
	# 1. 物理同步 FIP (U-Boot 核心)
	$(CP) $(PKG_BUILD_DIR)/$(UBOOT_IMAGE) $(STAGING_DIR_IMAGE)/
	$(CP) $(PKG_BUILD_DIR)/$(UBOOT_IMAGE) $(BIN_DIR)/sl3000-recovery-kits/uboot-fip-nor-recovery.bin

	# 2. 物理转换与导出 BL2 (NOR 救砖心脏)
	# BL2 是由 trusted-firmware-a 包生成的，我们在这里将其同步到 bin 目录方便用户下载
	if [ -f $(STAGING_DIR_IMAGE)/mt7981-nor-ddr4-bl2.bin ]; then \
		$(CP) $(STAGING_DIR_IMAGE)/mt7981-nor-ddr4-bl2.bin $(STAGING_DIR_IMAGE)/mt7981-nor-ddr4-bl2.img; \
		$(CP) $(STAGING_DIR_IMAGE)/mt7981-nor-ddr4-bl2.bin $(BIN_DIR)/sl3000-recovery-kits/bl2-nor-ddr4.bin; \
	fi
endef

$(eval $(call BuildPackage/U-Boot))
