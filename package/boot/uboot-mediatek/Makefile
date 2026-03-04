#
# SPDX-License-Identifier: GPL-2.0-only
# 物理审计：本地集成版，使用 file://src 源码，禁用补丁
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

# 使用本地源码（由补丁脚本克隆到 src 目录）
PKG_SOURCE_URL:=file://src
PKG_SOURCE_PROTO:=file
PKG_SOURCE:=uboot-custom          # 新增：解决 Download/default 缺少 FILE 字段
PKG_VERSION:=custom
PKG_HASH:=skip

# 禁用补丁
PKG_PATCH_DIR:=

# 保持原有依赖定义
PKG_BUILD_DEPENDS:=!(TARGET_ramips||TARGET_mediatek_mt7623):arm-trusted-firmware-tools/host

UBOOT_USE_INTREE_DTC:=1

include $(INCLUDE_DIR)/u-boot.mk
include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/host-build.mk

# 定义 Package/U-Boot 模板（解决 TITLE 缺失错误）
define Package/U-Boot
  SECTION:=boot
  CATEGORY:=Boot Loaders
  TITLE:=U-Boot for MediaTek boards
  DEPENDS:=
endef

define U-Boot/Default
  BUILD_TARGET:=mediatek
  UBOOT_IMAGE:=u-boot-mtk.bin
  HIDDEN:=1
endef

define U-Boot/mt7981_sl_3000-emmc
  NAME:=SL 3000 (eMMC)
  BUILD_SUBTARGET:=filogic
  BUILD_DEVICES:=sl_3000-emmc
  UBOOT_CONFIG:=mt7981_emmc
  UBOOT_IMAGE:=u-boot.fip
  BL2_BOOTDEV:=emmc
  BL2_SOC:=mt7981
  BL2_DDRTYPE:=ddr3
  DEPENDS:=+trusted-firmware-a-mt7981-emmc-ddr3
endef

UBOOT_TARGETS := mt7981_sl_3000-emmc

UBOOT_CUSTOMIZE_CONFIG := \
	--disable TOOLS_KWBIMAGE \
	--disable TOOLS_LIBCRYPTO \
	--disable TOOLS_MKEFICAPSULE \
	--enable SERIAL_RX_BUFFER \
	--set-val SERIAL_RX_BUFFER_SIZE 256

ifdef CONFIG_TARGET_mediatek
UBOOT_MAKE_FLAGS += $(UBOOT_IMAGE:.fip=.bin)
endif

# 修复：FIP 合成加入 BL2（tb-fw），并检查文件存在性
define Build/fip-image
	# 查找 BL2 和 BL31 文件（由 ATF 包提供）
	BL2_BIN="$(STAGING_DIR_IMAGE)/mt7981-emmc-ddr3-bl2.bin" ; \
	BL31_BIN="$(STAGING_DIR_IMAGE)/mt7981-emmc-ddr3-bl31.bin" ; \
	if [ ! -f "$$BL2_BIN" ]; then \
		echo "ERROR: BL2 not found at $$BL2_BIN"; exit 1; \
	fi ; \
	if [ ! -f "$$BL31_BIN" ]; then \
		echo "ERROR: BL31 not found at $$BL31_BIN"; exit 1; \
	fi ; \
	$(STAGING_DIR_HOST)/bin/fiptool create \
		--tb-fw $$BL2_BIN \
		--soc-fw $$BL31_BIN \
		--nt-fw $(PKG_BUILD_DIR)/$(BUILD_VARIANT)/u-boot.bin \
		$(PKG_BUILD_DIR)/$(BUILD_VARIANT)/u-boot.fip
endef

define Build/Configure
	$(call Build/Configure/U-Boot)
	# 精确禁用 TOOLS_LIBCRYPTO
	sed -i '/^CONFIG_TOOLS_LIBCRYPTO=y/s/.*/# CONFIG_TOOLS_LIBCRYPTO is not set/' $(PKG_BUILD_DIR)/.config
endef

define Build/Compile
	$(call Build/Compile/U-Boot)
ifeq ($(UBOOT_IMAGE),u-boot.fip)
	$(call Build/fip-image)
endif
endef

ifdef CONFIG_TARGET_mediatek
define Package/u-boot/install
endef
endif

# 修复：BL2 从 STAGING_DIR_IMAGE 复制，而非 U-Boot 构建目录
define Build/InstallDev
	$(INSTALL_DIR) $(STAGING_DIR_HOST)/share/u-boot
	# 复制 BL2（来自 ATF 包）
	$(CP) $(STAGING_DIR_IMAGE)/mt7981-emmc-ddr3-bl2.bin \
		$(STAGING_DIR_HOST)/share/u-boot/mt7981-emmc-ddr3-bl2.bin
	# 复制 FIP（由本包生成）
	$(CP) $(PKG_BUILD_DIR)/$(BUILD_VARIANT)/u-boot.fip \
		$(STAGING_DIR_HOST)/share/u-boot/mt7981-emmc-ddr3-fip.bin
	$(INSTALL_DIR) $(STAGING_DIR_IMAGE)
	$(CP) $(STAGING_DIR_HOST)/share/u-boot/mt7981-emmc-ddr3-bl2.bin $(STAGING_DIR_IMAGE)/
	$(CP) $(STAGING_DIR_HOST)/share/u-boot/mt7981-emmc-ddr3-fip.bin $(STAGING_DIR_IMAGE)/
endef

$(eval $(call BuildPackage,U-Boot))
